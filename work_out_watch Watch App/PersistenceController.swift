import CoreData
import Foundation
import os.log

struct PersistenceController {
    private static let logger = Logger(subsystem: "com.workout.app", category: "CoreData")
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let sampleRecord = WorkoutRecord(context: viewContext)
        sampleRecord.exerciseType = "ベンチプレス"
        sampleRecord.weight = 80.0
        sampleRecord.repetitions = 10
        sampleRecord.date = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WorkoutDataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // ローカルストレージを使用（App Groupは後で実装）
            let storeURL = getStoreURL()
            container.persistentStoreDescriptions.first!.url = storeURL
            Self.logger.info("Core Data store URL: \(storeURL)")
        }
        
        // Core Data設定を最適化
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                Self.logger.error("Core Data error: \(error), \(error.userInfo)")
                // 開発中はfatalErrorではなくログ出力に変更
                #if DEBUG
                print("Core Data loading failed: \(error)")
                #else
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #endif
            } else {
                Self.logger.info("Core Data loaded successfully")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private func getStoreURL() -> URL {
        // アプリのDocumentsディレクトリを使用
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("WorkoutData.sqlite")
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                Self.logger.info("Context saved successfully")
            } catch {
                let nsError = error as NSError
                Self.logger.error("Save error: \(nsError), \(nsError.userInfo)")
                #if DEBUG
                print("Context save failed: \(nsError)")
                #else
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                #endif
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
}