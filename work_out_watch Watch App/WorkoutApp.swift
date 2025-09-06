import SwiftUI
import CoreData
import os.log

@MainActor
class WorkoutApp: ObservableObject {
    private static let logger = Logger(subsystem: "com.workout.app", category: "App")
    
    // Core managers
    let persistenceController = PersistenceController.shared
    let healthKitManager = HealthKitManager()
    let syncManager: SyncManager
    let dataRecoveryManager: DataRecoveryManager
    
    // App state
    @Published var isInitialized = false
    @Published var initializationError: Error?
    
    init() {
        // Initialize dependent managers
        syncManager = SyncManager(
            persistenceController: persistenceController,
            healthKitManager: healthKitManager
        )
        dataRecoveryManager = DataRecoveryManager(
            persistenceController: persistenceController
        )
        
        Task { [weak self] in
            await self?.initialize()
        }
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        Self.logger.info("Starting app initialization")
        
        do {
            // 1. Core Dataの整合性をチェック
            try await dataRecoveryManager.performDataIntegrityCheck()
            
            // 2. HealthKit権限を確認
            if await shouldRequestHealthKitAuthorization() {
                try await healthKitManager.requestAuthorization()
            }
            
            // 3. バックグラウンド同期を開始
            syncManager.scheduleBackgroundSync()
            
            // 4. 初期データを作成（必要に応じて）
            await createInitialDataIfNeeded()
            
            isInitialized = true
            Self.logger.info("App initialization completed successfully")
            
        } catch {
            Self.logger.error("App initialization failed: \(error)")
            initializationError = error
        }
    }
    
    private func shouldRequestHealthKitAuthorization() async -> Bool {
        // ユーザー設定に基づいてHealthKit権限リクエストの必要性を判定
        let context = persistenceController.container.viewContext
        
        return await context.perform {
            let request = NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
            
            do {
                let preferences = try context.fetch(request).first
                return preferences?.healthKitEnabled ?? true
            } catch {
                return true // デフォルトで有効
            }
        }
    }
    
    private func createInitialDataIfNeeded() async {
        let context = persistenceController.container.viewContext
        
        await context.perform {
            // Check if user preferences exist
            let prefRequest = NSFetchRequest<UserPreferences>(entityName: "UserPreferences")
            
            if (try? context.fetch(prefRequest).first) == nil {
                // Create default user preferences
                let preferences = UserPreferences(context: context)
                preferences.userID = UUID()
                preferences.healthKitEnabled = true
                preferences.autoSyncEnabled = true
                preferences.defaultRestTime = 60
                preferences.preferredUnit = "kg"
                preferences.createdAt = Date()
                preferences.updatedAt = Date()
                
                try? context.save()
                Self.logger.info("Created default user preferences")
            }
            
            // Check if default exercises exist
            let exerciseRequest = NSFetchRequest<Exercise>(entityName: "Exercise")
            exerciseRequest.predicate = NSPredicate(format: "isCustom == NO")
            
            if (try? context.fetch(exerciseRequest).isEmpty) == true {
                self.createDefaultExercises()
                try? context.save()
                Self.logger.info("Created default exercises")
            }
        }
    }
    
    private func createDefaultExercises() {
        let context = persistenceController.container.viewContext
        
        let defaultExercises = [
            ("ベンチプレス", "胸", "大胸筋、三角筋前部、上腕三頭筋"),
            ("インクラインベンチプレス", "胸", "大胸筋上部、三角筋前部"),
            ("スクワット", "脚", "大腿四頭筋、大臀筋、ハムストリング"),
            ("デッドリフト", "背中", "脊柱起立筋、広背筋、僧帽筋、大臀筋"),
            ("ショルダープレス", "肩", "三角筋、上腕三頭筋"),
            ("バーベルロー", "背中", "広背筋、僧帽筋、リアデルト"),
            ("プルアップ", "背中", "広背筋、上腕二頭筋"),
            ("ディップス", "胸", "大胸筋下部、上腕三頭筋"),
            ("バーベルカール", "腕", "上腕二頭筋"),
            ("トライセップスエクステンション", "腕", "上腕三頭筋")
        ]
        
        for (name, category, muscleGroups) in defaultExercises {
            let exercise = Exercise(context: context)
            exercise.exerciseID = UUID()
            exercise.name = name
            exercise.category = category
            exercise.muscleGroups = muscleGroups
            exercise.isCustom = false
            exercise.createdAt = Date()
            exercise.updatedAt = Date()
        }
    }
    
    // MARK: - Workout Session Management
    
    func createWorkoutSession() -> WorkoutSession {
        let context = persistenceController.container.viewContext
        
        let session = WorkoutSession(context: context)
        session.sessionID = UUID()
        session.startTime = Date()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.isCompleted = false
        session.syncStatus = "pending"
        session.isSyncedToHealthKit = false
        
        return session
    }
    
    func addWorkoutSet(to session: WorkoutSession, exercise: Exercise, weight: Double, repetitions: Int) {
        let context = persistenceController.container.viewContext
        
        let set = WorkoutSet(context: context)
        set.setID = UUID()
        set.weight = weight
        set.repetitions = Int16(repetitions)
        set.isCompleted = true
        set.createdAt = Date()
        set.updatedAt = Date()
        set.exercise = exercise
        set.workoutSession = session
        
        // セット番号を自動設定
        let existingSets = session.workoutSets?.allObjects as? [WorkoutSet] ?? []
        let maxSetNumber = existingSets.map { $0.setNumber }.max() ?? 0
        set.setNumber = maxSetNumber + 1
        
        session.updatedAt = Date()
        
        persistenceController.save()
        Self.logger.info("Added workout set: \(exercise.name ?? "Unknown") - \(weight)kg x \(repetitions) reps")
    }
    
    func completeWorkoutSession(_ session: WorkoutSession) {
        session.endTime = Date()
        session.isCompleted = true
        session.updatedAt = Date()
        
        persistenceController.save()
        
        // 自動同期を開始
        syncManager.markSessionForSync(session)
        
        Self.logger.info("Completed workout session: \(session.sessionID?.uuidString ?? "unknown")")
    }
    
    // MARK: - Data Management
    
    func performManualSync() {
        syncManager.forceSyncNow()
    }
    
    func exportUserData() async throws -> URL {
        return try await dataRecoveryManager.createBackup()
    }
    
    func importUserData(from url: URL) async throws {
        try await dataRecoveryManager.restoreFromBackup(url)
        
        // データ復元後に再初期化
        Task {
            await initialize()
        }
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        Self.logger.error("App error: \(error)")
        
        // エラーの種類に応じて適切な処理を実行
        if error is HealthKitError {
            // HealthKit関連のエラーは致命的ではない
            Self.logger.warning("HealthKit error handled gracefully")
        } else if error is DataRecoveryError {
            // データ整合性エラーの場合は復旧を試行
            Task {
                do {
                    try await dataRecoveryManager.performDataIntegrityCheck()
                } catch {
                    Self.logger.error("Data recovery failed: \(error)")
                }
            }
        } else {
            // その他のエラーはユーザーに通知
            initializationError = error
        }
    }
    
    // MARK: - App Lifecycle
    
    func handleAppWillResignActive() {
        // アプリがバックグラウンドに入る前に保存
        persistenceController.save()
        Self.logger.info("App will resign active - data saved")
    }
    
    func handleAppDidBecomeActive() {
        // アプリがフォアグラウンドに戻った時の処理
        Task {
            if syncManager.isReachable && syncManager.pendingSyncCount > 0 {
                await syncManager.syncPendingData()
            }
        }
        Self.logger.info("App did become active - sync triggered if needed")
    }
}

// fetchRequestはCore Dataで自動生成されるため、拡張は不要です