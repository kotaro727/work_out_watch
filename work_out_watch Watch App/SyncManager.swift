import Foundation
import WatchConnectivity
import CoreData
import os.log

@MainActor
class SyncManager: NSObject, ObservableObject {
    private static let logger = Logger(subsystem: "com.workout.app", category: "Sync")
    
    @Published var isReachable = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingSyncCount = 0
    
    private let persistenceController: PersistenceController
    private let healthKitManager: HealthKitManager?
    private let isHealthKitEnabled: Bool
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    init(persistenceController: PersistenceController, healthKitManager: HealthKitManager?, isHealthKitEnabled: Bool) {
        self.persistenceController = persistenceController
        self.healthKitManager = healthKitManager
        self.isHealthKitEnabled = isHealthKitEnabled
        super.init()
        
        setupWatchConnectivity()
        updatePendingSyncCount()
    }
    
    // MARK: - WatchConnectivity Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            Self.logger.warning("WatchConnectivity not supported")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
        Self.logger.info("WatchConnectivity session activated")
    }
    
    // MARK: - Sync Operations
    
    func syncPendingData() async {
        guard WCSession.default.isReachable else {
            Self.logger.info("iPhone not reachable, skipping sync")
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // 1. 未同期のワークアウトセッションを取得
            let pendingSessions = try await fetchPendingSessions()
            
            for session in pendingSessions {
                try await syncSession(session)
            }
            
            // 2. HealthKit同期（無効化されていない場合のみ）
            if isHealthKitEnabled {
                try await syncToHealthKit()
            }
            
            await MainActor.run {
                syncStatus = .success
                lastSyncDate = Date()
                updatePendingSyncCount()
            }
            
            Self.logger.info("Sync completed successfully")
            
        } catch {
            await MainActor.run {
                syncStatus = .failed(error)
            }
            Self.logger.error("Sync failed: \(error)")
        }
    }
    
    private func fetchPendingSessions() async throws -> [WorkoutSession] {
        let context = persistenceController.container.viewContext
        
        return try await context.perform {
            let request = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
            request.predicate = NSPredicate(format: "syncStatus == %@ OR lastSyncedAt == nil", "pending")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.createdAt, ascending: true)]
            
            return try context.fetch(request)
        }
    }
    
    private func syncSession(_ session: WorkoutSession) async throws {
        // セッションデータをディクショナリに変換
        let sessionData = try createSessionData(from: session)
        
        // WatchConnectivityでiPhoneに送信
        try await sendDataToiPhone(sessionData)
        
        // 同期ステータスを更新
        let context = persistenceController.container.viewContext
        await context.perform {
            session.syncStatus = "synced"
            session.lastSyncedAt = Date()
            try? context.save()
        }
    }
    
    private func createSessionData(from session: WorkoutSession) throws -> [String: Any] {
        var data: [String: Any] = [
            "sessionID": session.sessionID?.uuidString ?? UUID().uuidString,
            "startTime": session.startTime ?? Date(),
            "isCompleted": session.isCompleted,
            "createdAt": session.createdAt ?? Date(),
            "updatedAt": session.updatedAt ?? Date()
        ]
        
        if let endTime = session.endTime {
            data["endTime"] = endTime
        }
        
        if let notes = session.notes {
            data["notes"] = notes
        }
        
        if session.totalCalories > 0 {
            data["totalCalories"] = session.totalCalories
        }
        
        // WorkoutSetのデータを追加
        if let sets = session.workoutSets?.allObjects as? [WorkoutSet] {
            let setsData = sets.map { set in
                return [
                    "setID": set.setID?.uuidString ?? UUID().uuidString,
                    "weight": set.weight,
                    "repetitions": set.repetitions,
                    "setNumber": set.setNumber,
                    "isCompleted": set.isCompleted,
                    "exerciseName": set.exercise?.name ?? "Unknown",
                    "createdAt": set.createdAt ?? Date(),
                    "updatedAt": set.updatedAt ?? Date()
                ]
            }
            data["workoutSets"] = setsData
        }
        
        return data
    }
    
    private func sendDataToiPhone(_ data: [String: Any]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(
                ["type": "workoutSession", "data": data],
                replyHandler: { reply in
                    Self.logger.info("Data sent successfully: \(reply)")
                    continuation.resume()
                },
                errorHandler: { error in
                    Self.logger.error("Failed to send data: \(error)")
                    continuation.resume(throwing: error)
                }
            )
        }
    }
    
    // MARK: - HealthKit Sync
    
    private func syncToHealthKit() async throws {
        guard let healthKitManager else { return }

        let context = persistenceController.container.viewContext

        let unsyncedSessions = try await context.perform {
            let request = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
            request.predicate = NSPredicate(format: "isSyncedToHealthKit == NO AND isCompleted == YES")
            return try context.fetch(request)
        }

        for session in unsyncedSessions {
            do {
                let healthKitWorkoutID = try await healthKitManager.saveWorkout(session: session)

                await context.perform {
                    session.isSyncedToHealthKit = true
                    session.healthKitWorkoutID = healthKitWorkoutID
                    try? context.save()
                }

                Self.logger.info("Session synced to HealthKit: \(session.sessionID?.uuidString ?? "unknown")")

            } catch {
                Self.logger.error("Failed to sync session to HealthKit: \(error)")
                // HealthKit同期失敗は致命的ではないので続行
            }
        }
    }
    
    // MARK: - Background Sync
    
    func scheduleBackgroundSync() {
        // バックグラウンドで定期的に同期を試行
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                if self.isReachable {
                    await self.syncPendingData()
                }
            }
        }
    }
    
    private func updatePendingSyncCount() {
        Task {
            do {
                let pendingSessions = try await fetchPendingSessions()
                await MainActor.run {
                    pendingSyncCount = pendingSessions.count
                }
            } catch {
                Self.logger.error("Failed to update pending sync count: \(error)")
            }
        }
    }
    
    // MARK: - Manual Sync Triggers
    
    func forceSyncNow() {
        Task {
            await syncPendingData()
        }
    }
    
    func markSessionForSync(_ session: WorkoutSession) {
        let context = persistenceController.container.viewContext
        context.perform {
            session.syncStatus = "pending"
            session.lastSyncedAt = nil
            try? context.save()
            
            Task { @MainActor in
                self.updatePendingSyncCount()
            }
        }
    }
}

// MARK: - WCSessionDelegate

extension SyncManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
        
        if let error = error {
            Self.logger.error("WCSession activation failed: \(error)")
        } else {
            Self.logger.info("WCSession activation completed with state: \(activationState.rawValue)")
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            
            // デバイスが接続されたら自動同期を試行
            if session.isReachable && self.pendingSyncCount > 0 {
                await self.syncPendingData()
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // iPhoneからのメッセージを処理
        Self.logger.info("Received message from iPhone: \(message)")
        
        if let type = message["type"] as? String {
            switch type {
            case "syncRequest":
                Task { @MainActor in
                    await self.syncPendingData()
                    replyHandler(["status": "success"])
                }
                
            case "healthKitStatus":
                // iPhoneのHealthKit設定状態を受信
                if let _ = message["enabled"] as? Bool {
                    // ユーザー設定を更新
                    replyHandler(["status": "received"])
                }
                
            default:
                replyHandler(["status": "unknown_type"])
            }
        }
    }
}

// fetchRequestはCore Dataで自動生成されるため、個別に実装する必要はありません
