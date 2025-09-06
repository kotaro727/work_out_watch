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
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Simple Home Tab for testing
            SimpleHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            // History Tab (simplified)
            SimpleHistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("履歴")
                }
                .tag(1)
            
            // Settings Tab (basic)
            SimpleSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                }
                .tag(2)
        }
    }
}

struct SimpleHomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("ワークアウトアプリ")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("開発中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("ホーム")
        }
    }
}

struct SimpleHistoryView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("履歴機能は開発中です")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("履歴")
        }
    }
}

struct SimpleSettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("アプリ情報") {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

// 複雑なViewは一時的に削除（WorkoutAppクラス依存を避けるため）

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
