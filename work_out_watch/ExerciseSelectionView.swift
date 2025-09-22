import CoreData
import SwiftUI

struct ExerciseSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext: NSManagedObjectContext
    @EnvironmentObject var workoutApp: WorkoutApp
    @Environment(\.dismiss) private var dismiss

    @Binding var tabSelection: Int

    @State private var currentSession: WorkoutSession?
    @State private var completedSession: WorkoutSession?
    @State private var showingInputView: Bool = false
    @State private var selectedExercise: Exercise?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var allExercises: FetchedResults<Exercise>

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    ForEach(exerciseGroups, id: \.name) { group in
                        NavigationLink {
                            ExerciseGroupDetailView(
                                groupName: group.name,
                                exercises: group.exercises,
                                onSelect: { exercise in
                                    selectedExercise = exercise
                                    startWorkoutSession()
                                }
                            )
                        } label: {
                            ExerciseGroupRow(
                                groupName: group.name,
                                exerciseCount: group.exercises.count
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .tint(Theme.accent)
            }
            .navigationTitle("エクササイズ選択")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.background.opacity(0.95), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accentSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        completeCurrentSession()
                    }
                    .disabled(currentSession == nil)
                    .foregroundColor(
                        currentSession == nil ? Theme.textTertiary : Theme.accentSecondary)
                }
            }
            .sheet(isPresented: $showingInputView) {
                if let exercise = selectedExercise, let session = currentSession {
                    InputView(
                        exercise: exercise,
                        session: session,
                        onSave: { weight, reps in
                            addSetToCurrentSession(exercise: exercise, weight: weight, reps: reps)
                        },
                        onComplete: {
                            completeCurrentSession()
                        }
                    )
                    .environmentObject(workoutApp)
                }
            }
            .sheet(item: $completedSession) { session in
                NavigationStack {
                    WorkoutCompletionView(session: session, tabSelection: $tabSelection)
                }
            }
        }
    }

    private var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: allExercises) { exercise in
            exercise.category ?? "その他"
        }
    }

    private var exerciseGroups: [(name: String, exercises: [Exercise])] {
        groupedExercises
            .map { (key: String, value: [Exercise]) in
                (name: key, exercises: value.sorted { ($0.name ?? "") < ($1.name ?? "") })
            }
            .sorted { $0.name < $1.name }
    }

    private func startWorkoutSession() {
        if currentSession == nil {
            currentSession = workoutApp.createWorkoutSession()
        }
        showingInputView = true
    }

    private func addSetToCurrentSession(exercise: Exercise, weight: Double, reps: Int) {
        guard let session = currentSession else { return }
        workoutApp.addWorkoutSet(to: session, exercise: exercise, weight: weight, repetitions: reps)
    }

    private func completeCurrentSession() {
        guard let session = currentSession else {
            return
        }

        // セッションを完了状態に更新
        session.endTime = Date()
        session.isCompleted = true
        session.updatedAt = Date()

        // データを保存
        workoutApp.completeWorkoutSession(session)

        // 完了したセッションを保存してから画面遷移
        showingInputView = false
        completedSession = session
        currentSession = nil
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    if let muscleGroups = exercise.muscleGroups {
                        Text(muscleGroups)
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
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

struct ExerciseGroupRow: View {
    let groupName: String
    let exerciseCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(groupName)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("\(exerciseCount)種目")
                    .font(.caption)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Theme.textTertiary)
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
}

struct ExerciseGroupDetailView: View {
    let groupName: String
    let exercises: [Exercise]
    let onSelect: (Exercise) -> Void

    @State private var searchText = ""

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else {
            return exercises
        }
        return exercises.filter { exercise in
            exercise.name?.localizedCaseInsensitiveContains(searchText) == true
                || exercise.muscleGroups?.localizedCaseInsensitiveContains(searchText) == true
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                if filteredExercises.isEmpty {
                    Text("該当する種目がありません")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredExercises, id: \.exerciseID) { exercise in
                        ExerciseRow(
                            exercise: exercise,
                            onTap: {
                                onSelect(exercise)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .searchable(text: $searchText, prompt: "種目を検索")
        .navigationTitle(groupName)
        .navigationBarTitleDisplayMode(.large)
        .tint(Theme.accent)
    }
}

#Preview {
    ExerciseSelectionView(tabSelection: .constant(0))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WorkoutApp())
}
