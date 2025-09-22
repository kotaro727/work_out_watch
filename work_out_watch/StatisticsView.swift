import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var workoutApp: WorkoutApp
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.startTime, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES")
    ) private var completedSessions: FetchedResults<WorkoutSession>
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedExercise: String = "全体"
    
    enum TimeRange: String, CaseIterable {
        case week = "週"
        case month = "月"
        case year = "年"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    private var filteredSessions: [WorkoutSession] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return completedSessions.filter { session in
            guard let startTime = session.startTime else { return false }
            return startTime >= cutoffDate
        }
    }
    
    private var exerciseOptions: [String] {
        let allExercises = Set(
            completedSessions.compactMap { session in
                (session.workoutSets?.allObjects as? [WorkoutSet])?.compactMap { $0.exercise?.name }
            }.flatMap { $0 }
        )
        return ["全体"] + Array(allExercises).sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Time Range Selector
                        Picker("期間", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .tint(Theme.accent)
                    
                        // Exercise Filter
                        HStack {
                        Text("エクササイズ:")
                            .font(.headline)
                            .foregroundColor(Theme.textSecondary)
                        
                        Picker("エクササイズ", selection: $selectedExercise) {
                            ForEach(exerciseOptions, id: \.self) { exercise in
                                Text(exercise).tag(exercise)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding(.horizontal)
                    .foregroundColor(Theme.textPrimary)
                    
                        // Statistics Cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "総セッション数",
                                value: "\(filteredSessions.count)",
                                icon: "calendar",
                            color: Theme.accentSecondary
                            )
                        
                            StatCard(
                                title: "総セット数",
                                value: "\(totalSets)",
                                icon: "list.number",
                            color: Theme.success
                            )
                        
                            StatCard(
                                title: "平均継続時間",
                                value: averageDuration,
                                icon: "clock",
                            color: Theme.accent
                            )
                        
                            StatCard(
                                title: "総消費カロリー",
                                value: "\(Int(totalCalories))kcal",
                                icon: "flame",
                            color: Theme.accentMuted
                            )
                        }
                        .padding(.horizontal)
                    
                        // Workout Summary
                        if !filteredSessions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("期間サマリー")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 8) {
                                Text("この期間の合計: \(filteredSessions.count)回")
                                    .foregroundColor(Theme.textSecondary)
                                Text("平均頻度: \(String(format: "%.1f", Double(filteredSessions.count) / Double(selectedTimeRange.days) * 7))回/週")
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.backgroundElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Theme.border)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)
                        }
                    }
                    
                    // Exercise Distribution
                    if selectedExercise == "全体" && !filteredSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("エクササイズ分布")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal)
                            
                            ExerciseDistributionView(sessions: filteredSessions)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Theme.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Theme.border)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal)
                        }
                    }
                    
                    // Progress Tracking for Specific Exercise
                    if selectedExercise != "全体" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(selectedExercise)の進歩")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal)
                            
                            ExerciseProgressSummary(
                                sessions: filteredSessions,
                                exerciseName: selectedExercise
                            )
                            .padding()
                                .frame(maxWidth: .infinity)
                                .background(Theme.backgroundElevated)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Theme.border)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal)
                        }
                    }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
            .foregroundColor(Theme.textPrimary)
        }
    }
    
    private var totalSets: Int {
        filteredSessions.reduce(0) { total, session in
            total + (session.workoutSets?.count ?? 0)
        }
    }
    
    private var averageDuration: String {
        guard !filteredSessions.isEmpty else { return "0分" }
        
        let totalMinutes = filteredSessions.compactMap { session -> Int? in
            guard let start = session.startTime, let end = session.endTime else { return nil }
            return Int(end.timeIntervalSince(start)) / 60
        }.reduce(0, +)
        
        let avgMinutes = totalMinutes / filteredSessions.count
        return "\(avgMinutes)分"
    }
    
    private var totalCalories: Double {
        filteredSessions.reduce(0) { total, session in
            total + (session.totalCalories)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Theme.border)
                    )
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundElevated)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.border)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// Chart関連は一時的に削除（Swift Chartsが利用できない場合のため）

struct ExerciseDistributionView: View {
    let sessions: [WorkoutSession]
    
    private var exerciseCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        
        for session in sessions {
            if let sets = session.workoutSets?.allObjects as? [WorkoutSet] {
                for set in sets {
                    let exerciseName = set.exercise?.name ?? "Unknown"
                    counts[exerciseName, default: 0] += 1
                }
            }
        }
        
        return counts.sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(exerciseCounts.prefix(5)), id: \.0) { exercise in
                HStack {
                    Text(exercise.0)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(exercise.1)セット")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Theme.border)
                )
            }
        }
    }
}

struct ExerciseProgressSummary: View {
    let sessions: [WorkoutSession]
    let exerciseName: String
    
    private var progressData: [(Date, Double, Int)] {
        var data: [(Date, Double, Int)] = []
        
        for session in sessions.sorted(by: { ($0.startTime ?? Date()) < ($1.startTime ?? Date()) }) {
            if let sets = session.workoutSets?.allObjects as? [WorkoutSet] {
                let exerciseSets = sets.filter { $0.exercise?.name == exerciseName }
                if !exerciseSets.isEmpty {
                    let maxWeight = exerciseSets.map { $0.weight }.max() ?? 0
                    let totalReps = exerciseSets.map { Int($0.repetitions) }.reduce(0, +)
                    
                    data.append((session.startTime ?? Date(), maxWeight, totalReps))
                }
            }
        }
        
        return data
    }
    
    var body: some View {
        if progressData.isEmpty {
            Text("データがありません")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                if let latest = progressData.last {
                    Text("最新記録: \(latest.1, specifier: "%.1f")kg")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                }
                
                if let max = progressData.max(by: { $0.1 < $1.1 }) {
                    Text("最大重量: \(max.1, specifier: "%.1f")kg")
                        .font(.subheadline)
                        .foregroundColor(Theme.accentSecondary)
                }
                
                Text("記録回数: \(progressData.count)回")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
            }
        }
    }
}

#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WorkoutApp())
}
