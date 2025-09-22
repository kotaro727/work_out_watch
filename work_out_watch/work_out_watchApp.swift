//
//  work_out_watchApp.swift
//  work_out_watch
//
//  Created by 鈴木光太郎 on 2025/09/06.
//

import SwiftUI
import CoreData

@main
struct work_out_watchApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var workoutApp = WorkoutApp()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(workoutApp)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
