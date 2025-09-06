//
//  ContentView.swift
//  work_out_watch
//
//  Created by 鈴木光太郎 on 2025/09/06.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // 一時的にWorkoutRecordの代わりに基本的な表示を実装
    // @FetchRequest(
    //     entity: WorkoutRecord.entity(),
    //     sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutRecord.date, ascending: false)],
    //     animation: .default)
    // private var workoutRecords: FetchedResults<WorkoutRecord>
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("ワークアウト履歴")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Apple Watchからワークアウトデータが\n同期されます")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("ワークアウト")
        }
    }
}

#Preview {
    ContentView()
}
