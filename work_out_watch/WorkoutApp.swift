import SwiftUI
import CoreData
import WatchConnectivity
import os.log

@MainActor
class WorkoutApp: NSObject, ObservableObject {
    private static let logger = Logger(subsystem: "com.workout.app", category: "App")
    
    // Core managers
    let persistenceController = PersistenceController.shared
    let healthKitManager = HealthKitManagerDisabled() // HealthKit無効化版を使用
    
    // App state
    @Published var isInitialized = false
    @Published var initializationError: Error?
    @Published var isWatchConnected = false
    
    // WatchConnectivity
    private var session: WCSession?
    
    override init() {
        super.init()
        Task { [weak self] in
            await self?.initialize()
        }
    }
    
    // MARK: - Initialization
    
    private func initialize() async {
        Self.logger.info("Starting iOS app initialization")
        
        do {
            // 1. HealthKit機能を一時的に無効化
            Self.logger.info("HealthKit initialization skipped (disabled)")
            
            // 2. WatchConnectivityを設定
            setupWatchConnectivity()
            
            // 3. 初期データを作成（必要に応じて）
            await createInitialDataIfNeeded()
            
            isInitialized = true
            Self.logger.info("iOS app initialization completed successfully")
            
        } catch {
            Self.logger.error("iOS app initialization failed: \(error)")
            initializationError = error
        }
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            Self.logger.warning("WatchConnectivity not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        Self.logger.info("WatchConnectivity session activated")
    }
    
    private func shouldRequestHealthKitAuthorization() async -> Bool {
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
            
            do {
                try self.syncDefaultExercises(in: context)
                if context.hasChanges {
                    try context.save()
                    Self.logger.info("Default exercises synced")
                }
            } catch {
                Self.logger.error("Failed to sync default exercises: \(error.localizedDescription)")
            }
        }
    }
    
    private var defaultExercises: [(name: String, category: String, muscles: String)] {
        [
            ("ベンチプレス", "胸", "大胸筋、三角筋前部、上腕三頭筋"),
            ("インクラインベンチプレス", "胸", "大胸筋上部、三角筋前部"),
            ("スクワット", "脚", "大腿四頭筋、大臀筋、ハムストリング"),
            ("デッドリフト", "背中", "脊柱起立筋、広背筋、僧帽筋、大臀筋"),
            ("ショルダープレス", "肩", "三角筋、上腕三頭筋"),
            ("バーベルロー", "背中", "広背筋、僧帽筋、リアデルト"),
            ("プルアップ", "背中", "広背筋、上腕二頭筋"),
            ("ディップス", "胸", "大胸筋下部、上腕三頭筋"),
            ("バーベルカール", "腕", "上腕二頭筋"),
            ("トライセップスエクステンション", "腕", "上腕三頭筋"),
            ("ランジ", "脚", "大腿四頭筋、ハムストリング、大臀筋"),
            ("レッグプレス", "脚", "大腿四頭筋、大臀筋"),
            ("ラットプルダウン", "背中", "広背筋、上腕二頭筋"),
            ("ケーブルフライ", "胸", "大胸筋"),
            ("サイドレイズ", "肩", "三角筋中部"),
            ("フェイスプル", "肩", "三角筋後部、僧帽筋"),
            ("プランク", "体幹", "腹直筋、腹横筋、背筋群"),
            ("ヒップスラスト", "脚", "大臀筋、ハムストリング")
        ]
    }

    private func syncDefaultExercises(in context: NSManagedObjectContext) throws {
        for data in defaultExercises {
            let request = NSFetchRequest<Exercise>(entityName: "Exercise")
            request.predicate = NSPredicate(format: "name == %@", data.name)
            request.fetchLimit = 1
            let existing = try context.fetch(request).first
            let exercise = existing ?? Exercise(context: context)
            if exercise.exerciseID == nil {
                exercise.exerciseID = UUID()
            }
            exercise.name = data.name
            exercise.category = data.category
            exercise.muscleGroups = data.muscles
            exercise.isCustom = false
            exercise.updatedAt = Date()
            if exercise.createdAt == nil {
                exercise.createdAt = Date()
            }
        }
        try removeDuplicateDefaultExercises(in: context)
    }

    private func removeDuplicateDefaultExercises(in context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<Exercise>(entityName: "Exercise")
        request.predicate = NSPredicate(format: "isCustom == NO")
        let exercises = try context.fetch(request)
        var seenNames = Set<String>()
        for exercise in exercises {
            let key = (exercise.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty else { continue }
            if seenNames.insert(key).inserted {
                continue
            }
            context.delete(exercise)
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

        if let exerciseInContext = try? context.existingObject(with: exercise.objectID) as? Exercise {
            set.exercise = exerciseInContext
        } else {
            set.exercise = exercise
        }
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
        
        // HealthKit同期を一時的に無効化
        Self.logger.info("HealthKit sync skipped (disabled mode)")
        
        Self.logger.info("Completed workout session: \(session.sessionID?.uuidString ?? "unknown")")
    }
    
    // MARK: - Data Fetching for UI
    
    func fetchWorkoutSessions() -> [WorkoutSession] {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.startTime, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            Self.logger.error("Failed to fetch workout sessions: \(error)")
            return []
        }
    }
    
    func fetchExercises() -> [Exercise] {
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<Exercise>(entityName: "Exercise")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            Self.logger.error("Failed to fetch exercises: \(error)")
            return []
        }
    }
    
    // MARK: - Manual Sync
    
    func performManualHealthKitSync() {
        // HealthKit同期を一時的に無効化
        Self.logger.info("Manual HealthKit sync skipped (disabled mode)")
    }
}

// MARK: - WCSessionDelegate

extension WorkoutApp: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
        }
        
        if let error = error {
            Self.logger.error("WCSession activation failed: \(error)")
        } else {
            Self.logger.info("WCSession activation completed with state: \(activationState.rawValue)")
        }
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        Self.logger.info("WCSession became inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Self.logger.info("WCSession deactivated")
        session.activate()
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Self.logger.info("Received message from Apple Watch: \(message)")
        
        if let type = message["type"] as? String {
            switch type {
            case "workoutSession":
                // Watchからワークアウトデータを受信
                if let sessionData = message["data"] as? [String: Any] {
                    Task { @MainActor in
                        await self.processWorkoutSessionFromWatch(sessionData)
                        replyHandler(["status": "success"])
                    }
                }
                
            case "syncRequest":
                // Watch側からの同期リクエスト
                replyHandler(["status": "received"])
                
            default:
                replyHandler(["status": "unknown_type"])
            }
        }
    }
    
    private func processWorkoutSessionFromWatch(_ data: [String: Any]) async {
        let context = persistenceController.container.viewContext
        
        await context.perform {
            // Watchからのセッションデータを処理してCore Dataに保存
            let session = WorkoutSession(context: context)
            session.sessionID = UUID(uuidString: data["sessionID"] as? String ?? "") ?? UUID()
            session.startTime = data["startTime"] as? Date
            session.endTime = data["endTime"] as? Date
            session.isCompleted = data["isCompleted"] as? Bool ?? false
            session.notes = data["notes"] as? String
            session.totalCalories = data["totalCalories"] as? Double ?? 0
            session.createdAt = data["createdAt"] as? Date ?? Date()
            session.updatedAt = data["updatedAt"] as? Date ?? Date()
            session.syncStatus = "synced"
            session.isSyncedToHealthKit = false
            
            // WorkoutSetデータも処理
            if let setsData = data["workoutSets"] as? [[String: Any]] {
                for setData in setsData {
                    let set = WorkoutSet(context: context)
                    set.setID = UUID(uuidString: setData["setID"] as? String ?? "") ?? UUID()
                    set.weight = setData["weight"] as? Double ?? 0
                    set.repetitions = Int16(setData["repetitions"] as? Int ?? 0)
                    set.setNumber = Int16(setData["setNumber"] as? Int ?? 1)
                    set.isCompleted = setData["isCompleted"] as? Bool ?? false
                    set.createdAt = setData["createdAt"] as? Date ?? Date()
                    set.updatedAt = setData["updatedAt"] as? Date ?? Date()
                    
                    // Exercise を見つけるか作成
                    let exerciseName = setData["exerciseName"] as? String ?? "Unknown"
                    let exerciseRequest = NSFetchRequest<Exercise>(entityName: "Exercise")
                    exerciseRequest.predicate = NSPredicate(format: "name == %@", exerciseName)
                    
                    let exercise: Exercise
                    if let existingExercise = try? context.fetch(exerciseRequest).first {
                        exercise = existingExercise
                    } else {
                        exercise = Exercise(context: context)
                        exercise.exerciseID = UUID()
                        exercise.name = exerciseName
                        exercise.isCustom = true
                        exercise.createdAt = Date()
                        exercise.updatedAt = Date()
                    }
                    
                    set.exercise = exercise
                    set.workoutSession = session
                }
            }
            
            try? context.save()
            Self.logger.info("Processed workout session from Watch: \(session.sessionID?.uuidString ?? "unknown")")
        }
        
        // HealthKit同期を一時的に無効化
        Self.logger.info("HealthKit sync for Watch data skipped (disabled mode)")
    }
}
