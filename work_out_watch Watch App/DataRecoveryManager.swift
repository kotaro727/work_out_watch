import Foundation
import CoreData
import os.log

@MainActor
class DataRecoveryManager: ObservableObject {
    private static let logger = Logger(subsystem: "com.workout.app", category: "DataRecovery")
    
    private let persistenceController: PersistenceController
    @Published var isRecovering = false
    @Published var recoveryProgress: Double = 0.0
    @Published var lastRecoveryDate: Date?
    
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Data Validation & Recovery
    
    func performDataIntegrityCheck() async throws {
        Self.logger.info("Starting data integrity check")
        isRecovering = true
        recoveryProgress = 0.0
        
        let context = persistenceController.container.viewContext
        
        do {
            // 1. Orphaned WorkoutSets の修正
            try await fixOrphanedWorkoutSets()
            recoveryProgress = 0.25
            
            // 2. Missing Exercise 参照の修正
            try await fixMissingExerciseReferences()
            recoveryProgress = 0.50
            
            // 3. 不整合な日付の修正
            try await fixInconsistentDates()
            recoveryProgress = 0.75
            
            // 4. 重複データの除去
            try await removeDuplicateData()
            recoveryProgress = 1.0
            
            lastRecoveryDate = Date()
            Self.logger.info("Data integrity check completed successfully")
            
        } catch {
            Self.logger.error("Data integrity check failed: \(error)")
            throw DataRecoveryError.integrityCheckFailed(error)
        }
        
        isRecovering = false
    }
    
    private func fixOrphanedWorkoutSets() async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            let request = NSFetchRequest<WorkoutSet>(entityName: "WorkoutSet")
            request.predicate = NSPredicate(format: "workoutSession == nil")
            
            let orphanedSets = try context.fetch(request)
            
            for set in orphanedSets {
                // 対応するセッションを作成するか、削除する
                if let exerciseName = set.exercise?.name {
                    let session = WorkoutSession(context: context)
                    session.sessionID = UUID()
                    session.startTime = set.createdAt ?? Date()
                    session.createdAt = set.createdAt ?? Date()
                    session.updatedAt = Date()
                    session.isCompleted = true
                    session.syncStatus = "pending"
                    
                    set.workoutSession = session
                    Self.logger.info("Created recovery session for orphaned set: \(exerciseName)")
                } else {
                    // 参照が完全に壊れている場合は削除
                    context.delete(set)
                    Self.logger.warning("Deleted completely orphaned workout set")
                }
            }
            
            if !orphanedSets.isEmpty {
                try context.save()
                Self.logger.info("Fixed \(orphanedSets.count) orphaned workout sets")
            }
        }
    }
    
    private func fixMissingExerciseReferences() async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            let request = NSFetchRequest<WorkoutSet>(entityName: "WorkoutSet")
            request.predicate = NSPredicate(format: "exercise == nil")
            
            let setsWithoutExercise = try context.fetch(request)
            
            for set in setsWithoutExercise {
                // デフォルト運動を作成
                let defaultExercise = Exercise(context: context)
                defaultExercise.exerciseID = UUID()
                defaultExercise.name = "不明な運動"
                defaultExercise.category = "その他"
                defaultExercise.isCustom = true
                defaultExercise.createdAt = Date()
                defaultExercise.updatedAt = Date()
                
                set.exercise = defaultExercise
            }
            
            if !setsWithoutExercise.isEmpty {
                try context.save()
                Self.logger.info("Fixed \(setsWithoutExercise.count) sets with missing exercise references")
            }
        }
    }
    
    private func fixInconsistentDates() async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            // createdAt > updatedAt の修正
            let sessionRequest = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
            let sessions = try context.fetch(sessionRequest)
            
            var fixedCount = 0
            
            for session in sessions {
                var needsUpdate = false
                
                if let created = session.createdAt, let updated = session.updatedAt, created > updated {
                    session.updatedAt = created
                    needsUpdate = true
                }
                
                if let start = session.startTime, let end = session.endTime, start > end {
                    session.endTime = start.addingTimeInterval(3600) // デフォルト1時間
                    needsUpdate = true
                }
                
                if needsUpdate {
                    fixedCount += 1
                }
            }
            
            if fixedCount > 0 {
                try context.save()
                Self.logger.info("Fixed \(fixedCount) sessions with inconsistent dates")
            }
        }
    }
    
    private func removeDuplicateData() async throws {
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            // 同じUUIDを持つセッションの重複を除去
            let sessionRequest = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
            sessionRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.createdAt, ascending: true)]
            
            let sessions = try context.fetch(sessionRequest)
            var seenIDs: Set<UUID> = []
            var duplicates: [WorkoutSession] = []
            
            for session in sessions {
                if let sessionID = session.sessionID {
                    if seenIDs.contains(sessionID) {
                        duplicates.append(session)
                    } else {
                        seenIDs.insert(sessionID)
                    }
                }
            }
            
            for duplicate in duplicates {
                context.delete(duplicate)
            }
            
            if !duplicates.isEmpty {
                try context.save()
                Self.logger.info("Removed \(duplicates.count) duplicate sessions")
            }
        }
    }
    
    // MARK: - Backup & Restore
    
    func createBackup() async throws -> URL {
        let context = persistenceController.container.viewContext
        let backupData = try await context.perform {
            var backup: [String: Any] = [:]
            
            // WorkoutSessions をエクスポート
            let sessionRequest = NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
            let sessions = try context.fetch(sessionRequest)
            
            backup["sessions"] = sessions.compactMap { session -> [String: Any]? in
                return [
                    "sessionID": session.sessionID?.uuidString ?? "",
                    "startTime": session.startTime ?? Date(),
                    "endTime": session.endTime,
                    "isCompleted": session.isCompleted,
                    "notes": session.notes,
                    "totalCalories": session.totalCalories as Any,
                    "createdAt": session.createdAt ?? Date(),
                    "updatedAt": session.updatedAt ?? Date()
                ]
            }
            
            // Exercises をエクスポート
            let exerciseRequest = NSFetchRequest<Exercise>(entityName: "Exercise")
            let exercises = try context.fetch(exerciseRequest)
            
            backup["exercises"] = exercises.compactMap { exercise -> [String: Any]? in
                return [
                    "exerciseID": exercise.exerciseID?.uuidString ?? "",
                    "name": exercise.name ?? "",
                    "category": exercise.category,
                    "muscleGroups": exercise.muscleGroups,
                    "instructions": exercise.instructions,
                    "isCustom": exercise.isCustom,
                    "createdAt": exercise.createdAt ?? Date(),
                    "updatedAt": exercise.updatedAt ?? Date()
                ]
            }
            
            backup["version"] = "1.0"
            backup["backupDate"] = Date()
            
            return backup
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsPath.appendingPathComponent("workout_backup_\(Date().timeIntervalSince1970).json")
        
        let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
        try jsonData.write(to: backupURL)
        
        Self.logger.info("Backup created at: \(backupURL)")
        return backupURL
    }
    
    func restoreFromBackup(_ backupURL: URL) async throws {
        let jsonData = try Data(contentsOf: backupURL)
        let backupData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        guard let backup = backupData else {
            throw DataRecoveryError.invalidBackupFormat
        }
        
        let context = persistenceController.container.newBackgroundContext()
        
        try await context.perform {
            // 既存データをクリア（復元モード）
            let sessionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WorkoutSession")
            let sessionDeleteRequest = NSBatchDeleteRequest(fetchRequest: sessionRequest)
            try context.execute(sessionDeleteRequest)
            
            // セッションを復元
            if let sessions = backup["sessions"] as? [[String: Any]] {
                for sessionData in sessions {
                    let session = WorkoutSession(context: context)
                    session.sessionID = UUID(uuidString: sessionData["sessionID"] as? String ?? "") ?? UUID()
                    session.startTime = sessionData["startTime"] as? Date
                    session.endTime = sessionData["endTime"] as? Date
                    session.isCompleted = sessionData["isCompleted"] as? Bool ?? false
                    session.notes = sessionData["notes"] as? String
                    session.totalCalories = sessionData["totalCalories"] as? Double ?? 0
                    session.createdAt = sessionData["createdAt"] as? Date ?? Date()
                    session.updatedAt = sessionData["updatedAt"] as? Date ?? Date()
                    session.syncStatus = "pending"
                    session.isSyncedToHealthKit = false
                }
            }
            
            try context.save()
        }
        
        Self.logger.info("Data restored from backup: \(backupURL)")
    }
    
    // MARK: - Emergency Reset
    
    func performEmergencyReset() async throws {
        Self.logger.warning("Performing emergency reset")
        
        let context = persistenceController.container.viewContext
        
        try await context.perform {
            // すべてのエンティティを削除
            let entities = ["WorkoutSession", "WorkoutSet", "Exercise", "UserPreferences"]
            
            for entityName in entities {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                try context.execute(deleteRequest)
            }
            
            try context.save()
        }
        
        // デフォルトデータを再作成
        await createDefaultExercises()
        
        Self.logger.info("Emergency reset completed")
    }
    
    private func createDefaultExercises() async {
        let context = persistenceController.container.viewContext
        
        let defaultExercises = [
            ("ベンチプレス", "胸", "上半身"),
            ("スクワット", "脚", "下半身"),
            ("デッドリフト", "背中", "全身"),
            ("ショルダープレス", "肩", "上半身"),
            ("バーベルロー", "背中", "上半身")
        ]
        
        await context.perform {
            for (name, category, muscleGroup) in defaultExercises {
                let exercise = Exercise(context: context)
                exercise.exerciseID = UUID()
                exercise.name = name
                exercise.category = category
                exercise.muscleGroups = muscleGroup
                exercise.isCustom = false
                exercise.createdAt = Date()
                exercise.updatedAt = Date()
            }
            
            try? context.save()
        }
        
        Self.logger.info("Default exercises created")
    }
}

// MARK: - Error Types

enum DataRecoveryError: LocalizedError {
    case integrityCheckFailed(Error)
    case invalidBackupFormat
    case restoreFailed(Error)
    case emergencyResetFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .integrityCheckFailed(let error):
            return "データ整合性チェックに失敗しました: \(error.localizedDescription)"
        case .invalidBackupFormat:
            return "バックアップファイルの形式が無効です"
        case .restoreFailed(let error):
            return "データの復元に失敗しました: \(error.localizedDescription)"
        case .emergencyResetFailed(let error):
            return "緊急リセットに失敗しました: \(error.localizedDescription)"
        }
    }
}
