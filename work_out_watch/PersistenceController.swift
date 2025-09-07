import Foundation
import CoreData
import os.log

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    private static let logger = Logger(subsystem: "com.workout.app", category: "CoreData")
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "WorkoutDataModel")
        
        // 一時的にローカルストアを使用（App Groups設定後に変更予定）
        // App Groups設定でWatch版とデータ共有
        // if let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.workout.app")?.appendingPathComponent("WorkoutDataModel.sqlite") {
        //     let description = NSPersistentStoreDescription(url: storeURL)
        //     description.type = NSSQLiteStoreType
        //     description.shouldInferMappingModelAutomatically = true
        //     description.shouldMigrateStoreAutomatically = true
        //     container.persistentStoreDescriptions = [description]
        // }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                Self.logger.error("Core Data error: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            Self.logger.info("Core Data store loaded: \(storeDescription.url?.absoluteString ?? "unknown")")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                Self.logger.info("Context saved successfully")
            } catch {
                Self.logger.error("Save error: \(error)")
            }
        }
    }
    
    func saveContext() async throws {
        let context = container.viewContext
        if context.hasChanges {
            try await context.perform {
                try context.save()
                Self.logger.info("Async context saved successfully")
            }
        }
    }
    
    // プレビュー用
    static var preview: PersistenceController = {
        let result = PersistenceController()
        let context = result.container.viewContext
        
        // プレビュー用のサンプルデータ作成を一時的に無効化
        // （Core Dataモデルの安定化のため）
        
        // let sampleSession = WorkoutSession(context: context)
        // サンプルデータは後で追加予定
        
        return result
    }()
}