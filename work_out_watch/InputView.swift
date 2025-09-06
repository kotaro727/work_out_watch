import SwiftUI

struct InputView: View {
    let exercise: Exercise
    let session: WorkoutSession
    let onSave: (Double, Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var workoutApp: WorkoutApp
    
    @State private var weight: Double = 40.0
    @State private var reps: Int = 10
    @State private var showingCompletion = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Exercise Info
                    VStack(spacing: 8) {
                        Text(exercise.name ?? "Unknown Exercise")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let category = exercise.category {
                            Text(category)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let muscleGroups = exercise.muscleGroups {
                            Text(muscleGroups)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Weight Input
                    VStack(spacing: 16) {
                        Text("重量")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Button {
                                weight = max(0, weight - 2.5)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.green))
                            }
                            
                            VStack {
                                Text("\(weight, specifier: "%.1f")")
                                    .font(.system(size: 32, weight: .bold))
                                Text("kg")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(minWidth: 100)
                            
                            Button {
                                weight += 2.5
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.green))
                            }
                        }
                        
                        // Weight Slider for fine adjustment
                        Slider(value: $weight, in: 0...200, step: 0.5)
                            .accentColor(.green)
                            .padding(.horizontal)
                    }
                    
                    // Reps Input
                    VStack(spacing: 16) {
                        Text("回数")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Button {
                                reps = max(1, reps - 1)
                            } label: {
                                Image(systemName: "minus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.green))
                            }
                            
                            VStack {
                                Text("\(reps)")
                                    .font(.system(size: 32, weight: .bold))
                                Text("reps")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(minWidth: 100)
                            
                            Button {
                                reps += 1
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Circle().fill(Color.green))
                            }
                        }
                        
                        // Reps Stepper for fine adjustment
                        Stepper("", value: $reps, in: 1...100)
                            .labelsHidden()
                    }
                    
                    // Current Session Info
                    if let sets = session.workoutSets?.allObjects as? [WorkoutSet], !sets.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("今回のセット")
                                .font(.headline)
                            
                            ForEach(sets.sorted { $0.setNumber < $1.setNumber }, id: \.setID) { set in
                                if set.exercise?.exerciseID == exercise.exerciseID {
                                    HStack {
                                        Text("セット \(set.setNumber)")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(set.weight, specifier: "%.1f")kg × \(set.repetitions)回")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Save Button
                    Button {
                        saveSet()
                    } label: {
                        Text("セットを記録")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("重量・回数入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCompletion) {
                SetCompletionView(
                    exercise: exercise,
                    weight: weight,
                    reps: reps,
                    onNextSet: {
                        // Reset for next set
                        showingCompletion = false
                    },
                    onFinish: {
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func saveSet() {
        onSave(weight, reps)
        showingCompletion = true
    }
}

struct SetCompletionView: View {
    let exercise: Exercise
    let weight: Double
    let reps: Int
    let onNextSet: () -> Void
    let onFinish: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("セット完了！")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 8) {
                    Text(exercise.name ?? "Unknown Exercise")
                        .font(.headline)
                    Text("\(weight, specifier: "%.1f")kg × \(reps)回")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(spacing: 16) {
                    Button {
                        onNextSet()
                    } label: {
                        Text("次のセットへ")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        onFinish()
                    } label: {
                        Text("完了")
                            .font(.headline)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("記録完了")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let exercise = Exercise(context: context)
    exercise.exerciseID = UUID()
    exercise.name = "ベンチプレス"
    exercise.category = "胸"
    exercise.muscleGroups = "大胸筋、三角筋前部、上腕三頭筋"
    
    let session = WorkoutSession(context: context)
    session.sessionID = UUID()
    session.startTime = Date()
    
    return InputView(
        exercise: exercise,
        session: session,
        onSave: { _, _ in }
    )
    .environmentObject(WorkoutApp())
}