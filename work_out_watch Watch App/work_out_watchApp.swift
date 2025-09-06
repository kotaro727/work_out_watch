//
//  work_out_watchApp.swift
//  work_out_watch Watch App
//
//  Created by 鈴木光太郎 on 2025/09/06.
//

import SwiftUI

@main
struct work_out_watch_Watch_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ExerciseSelectionView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
