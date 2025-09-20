import SwiftUI
import CoreData

struct WorkoutHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var workoutApp: WorkoutApp
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkoutSession.startTime, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == YES")
    ) private var completedSessions: FetchedResults<WorkoutSession>
    
    @State private var selectedSession: WorkoutSession?
    @State private var showingSessionDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    if completedSessions.isEmpty {
                        EmptyStateView()
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                            Section(header: Text(date, style: .date)
                                .font(.headline)
                                .foregroundColor(Theme.textSecondary)) {
                                ForEach(groupedSessions[date] ?? [], id: \.sessionID) { session in
                                    WorkoutSessionRow(session: session) {
                                        selectedSession = session
                                        showingSessionDetail = true
                                    }
                                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("ワークアウト履歴")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        workoutApp.performManualHealthKitSync()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundColor(Theme.accentSecondary)
                }
            }
            .sheet(isPresented: $showingSessionDetail) {
                if let session = selectedSession {
                    WorkoutSessionDetailView(session: session)
                }
            }
        }
    }
    
    private var groupedSessions: [Date: [WorkoutSession]] {
        Dictionary(grouping: completedSessions) { session in
            Calendar.current.startOfDay(for: session.startTime ?? Date())
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundColor(Theme.accentSecondary)
            
            Text("ワークアウト履歴がありません")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Theme.textPrimary)
            
            Text("記録を開始して、\nトレーニングの進捗を追跡しましょう")
                .font(.body)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSession
    let onTap: () -> Void
    
    private var exerciseNames: [String] {
        guard let sets = session.workoutSets?.allObjects as? [WorkoutSet] else { return [] }
        let names = sets.compactMap { $0.exercise?.name }
        return Array(Set(names))
    }
    
    private var totalSets: Int {
        session.workoutSets?.count ?? 0
    }
    
    private var duration: String {
        guard let start = session.startTime, let end = session.endTime else {
            return "不明"
        }
        let minutes = Int(end.timeIntervalSince(start)) / 60
        return "\(minutes)分"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(session.startTime ?? Date(), style: .time)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text("\(totalSets) セット")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                
                if !exerciseNames.isEmpty {
                    Text(exerciseNames.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }
                
                // HealthKit同期ステータス
                HStack {
                    Image(systemName: session.isSyncedToHealthKit ? "checkmark.circle.fill" : "clock")
                        .foregroundColor(session.isSyncedToHealthKit ? Theme.success : Theme.accent)
                        .font(.caption)
                    
                    Text(session.isSyncedToHealthKit ? "HealthKit同期済み" : "同期待ち")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.backgroundElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.border)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    
    private var workoutSets: [WorkoutSet] {
        guard let sets = session.workoutSets?.allObjects as? [WorkoutSet] else { return [] }
        return sets.sorted { $0.setNumber < $1.setNumber }
    }
    
    private var exerciseGroups: [String: [WorkoutSet]] {
        Dictionary(grouping: workoutSets) { set in
            set.exercise?.name ?? "Unknown Exercise"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Session Header
                        VStack(alignment: .leading, spacing: 8) {
                        Text("ワークアウト詳細")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("開始時間")
                                    .font(.caption)
                                    .foregroundColor(Theme.textSecondary)
                                Text(session.startTime ?? Date(), style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.textPrimary)
                            }
                            
                            Spacer()
                            
                            if let endTime = session.endTime {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("終了時間")
                                        .font(.caption)
                                        .foregroundColor(Theme.textSecondary)
                                    Text(endTime, style: .time)
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textPrimary)
                                }
                            }
                        }
                        
                        if let start = session.startTime, let end = session.endTime {
                            let duration = Int(end.timeIntervalSince(start)) / 60
                            Text("継続時間: \(duration)分")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                        
                        if session.totalCalories > 0 {
                            Text("消費カロリー: \(Int(session.totalCalories))kcal")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    .padding()
                    .background(Theme.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Theme.border)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    // Exercise Sets by Exercise
                    ForEach(exerciseGroups.keys.sorted(), id: \.self) { exerciseName in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exerciseName)
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(exerciseGroups[exerciseName] ?? [], id: \.setID) { set in
                                    SetDetailRow(set: set)
                                }
                            }
                            .padding()
                            .background(Theme.backgroundElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Theme.border)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    
                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メモ")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            Text(notes)
                                .font(.body)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding()
                        .background(Theme.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    
                    // Sync Status
                    HStack {
                        Image(systemName: session.isSyncedToHealthKit ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(session.isSyncedToHealthKit ? Theme.success : Theme.accent)
                        
                        Text(session.isSyncedToHealthKit ? "HealthKit同期済み" : "HealthKit同期待ち")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Theme.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.border)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                    .padding()
                }
            }
            .navigationTitle("ワークアウト詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accentSecondary)
                }
            }
        }
    }
}

struct SetDetailRow: View {
    let set: WorkoutSet
    
    var body: some View {
        HStack {
            Text("セット \(set.setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.textPrimary)
            
            Spacer()
            
            Text("\(set.weight, specifier: "%.1f")kg")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Text("×")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
            
            Text("\(set.repetitions)回")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.isCompleted ? Theme.success : Theme.textTertiary)
                .font(.caption)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    WorkoutHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WorkoutApp())
}
