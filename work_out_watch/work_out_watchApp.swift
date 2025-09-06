//
//  work_out_watchApp.swift
//  work_out_watch
//
//  Created by 鈴木光太郎 on 2025/09/06.
//

import SwiftUI
import CoreData

// PersistenceControllerの簡易版をiPhoneアプリ用に作成
struct SimplePersistenceController {
    static let shared = SimplePersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "WorkoutDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
    }
}

@main
struct work_out_watchApp: App {
    let persistenceController = SimplePersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
