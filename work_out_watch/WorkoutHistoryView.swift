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
        NavigationView {
            List {
                if completedSessions.isEmpty {
                    EmptyStateView()
                } else {
                    ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date, style: .date).font(.headline)) {
                            ForEach(groupedSessions[date] ?? [], id: \.sessionID) { session in
                                WorkoutSessionRow(session: session) {
                                    selectedSession = session
                                    showingSessionDetail = true
                                }
                            }
                        }
                    }
                }
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
                .foregroundColor(.secondary)
            
            Text("ワークアウト履歴がありません")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("記録を開始して、\nトレーニングの進捗を追跡しましょう")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(totalSets) セット")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !exerciseNames.isEmpty {
                    Text(exerciseNames.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // HealthKit同期ステータス
                HStack {
                    Image(systemName: session.isSyncedToHealthKit ? "checkmark.circle.fill" : "clock")
                        .foregroundColor(session.isSyncedToHealthKit ? .green : .orange)
                        .font(.caption)
                    
                    Text(session.isSyncedToHealthKit ? "HealthKit同期済み" : "同期待ち")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .contentShape(Rectangle())
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
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Session Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ワークアウト詳細")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("開始時間")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(session.startTime ?? Date(), style: .time)
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            if let endTime = session.endTime {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("終了時間")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(endTime, style: .time)
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        if let start = session.startTime, let end = session.endTime {
                            let duration = Int(end.timeIntervalSince(start)) / 60
                            Text("継続時間: \(duration)分")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if session.totalCalories > 0 {
                            Text("消費カロリー: \(Int(session.totalCalories))kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Exercise Sets by Exercise
                    ForEach(exerciseGroups.keys.sorted(), id: \.self) { exerciseName in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(exerciseName)
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(exerciseGroups[exerciseName] ?? [], id: \.setID) { set in
                                    SetDetailRow(set: set)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Notes
                    if let notes = session.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("メモ")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Sync Status
                    HStack {
                        Image(systemName: session.isSyncedToHealthKit ? "checkmark.circle.fill" : "clock")
                            .foregroundColor(session.isSyncedToHealthKit ? .green : .orange)
                        
                        Text(session.isSyncedToHealthKit ? "HealthKit同期済み" : "HealthKit同期待ち")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("ワークアウト詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
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
            
            Spacer()
            
            Text("\(set.weight, specifier: "%.1f")kg")
                .font(.subheadline)
            
            Text("×")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(set.repetitions)回")
                .font(.subheadline)
            
            Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(set.isCompleted ? .green : .secondary)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

#Preview {
    WorkoutHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WorkoutApp())
}