import SwiftUI

struct ContentView: View {
    @State private var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            WorkoutHistoryView()
                .tag(0)
                .tabItem {
                    Label("履歴", systemImage: "clock.arrow.circlepath")
                }

            StatisticsView()
                .tag(1)
                .tabItem {
                    Label("統計", systemImage: "chart.bar.xaxis")
                }

            ExerciseSelectionView(tabSelection: $selection)
                .tag(2)
                .tabItem {
                    Label("記録", systemImage: "plus.circle")
                }
        }
        .background(Theme.background.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WorkoutApp())
        .preferredColorScheme(.dark)
}
