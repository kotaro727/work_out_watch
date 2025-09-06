import SwiftUI
import CoreData

struct ExerciseSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var workoutApp: WorkoutApp
    @Environment(\.dismiss) private var dismiss
    
    @State private var exercises: [Exercise] = []
    @State private var currentSession: WorkoutSession?
    @State private var showingInputView = false
    @State private var selectedExercise: Exercise?
    @State private var searchText = ""
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
    ) private var allExercises: FetchedResults<Exercise>
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return Array(allExercises)
        } else {
            return allExercises.filter { exercise in
                exercise.name?.localizedCaseInsensitiveContains(searchText) == true ||
                exercise.category?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("エクササイズを検索", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Exercise List
                List {
                    ForEach(groupedExercises.keys.sorted(), id: \.self) { category in
                        Section(category) {
                            ForEach(groupedExercises[category] ?? [], id: \.exerciseID) { exercise in
                                ExerciseRow(exercise: exercise) {
                                    selectedExercise = exercise
                                    startWorkoutSession()
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "エクササイズを検索")
            }
            .navigationTitle("エクササイズ選択")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        completeCurrentSession()
                    }
                    .disabled(currentSession == nil)
                }
            }
            .sheet(isPresented: $showingInputView) {
                if let exercise = selectedExercise, let session = currentSession {
                    InputView(
                        exercise: exercise,
                        session: session,
                        onSave: { weight, reps in
                            addSetToCurrentSession(exercise: exercise, weight: weight, reps: reps)
                        }
                    )
                    .environmentObject(workoutApp)
                }
            }
            .onAppear {
                exercises = workoutApp.fetchExercises()
            }
        }
    }
    
    private var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { exercise in
            exercise.category ?? "その他"
        }
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
        guard let session = currentSession else { return }
        workoutApp.completeWorkoutSession(session)
        currentSession = nil
        dismiss()
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
                        .foregroundColor(.primary)
                    
                    if let muscleGroups = exercise.muscleGroups {
                        Text(muscleGroups)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseSelectionView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(WorkoutApp())
}