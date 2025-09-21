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
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 30) {
                        // Exercise Info
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.accentGradient)
                                .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 6)

                            Text(exercise.name ?? "Unknown Exercise")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                        .background(Theme.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        
                        // Weight Input
                        VStack(spacing: 20) {
                            Label {
                                Text("重量")
                                    .font(.headline)
                            } icon: {
                                Image(systemName: "scalemass")
                            }
                            .foregroundColor(Theme.textPrimary)
                            
                            HStack(spacing: 20) {
                                CircularControlButton(systemName: "minus") {
                                    weight = max(0, weight - 2.5)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("\(weight, specifier: "%.1f")")
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("kg")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(minWidth: 120)
                                
                                CircularControlButton(systemName: "plus") {
                                    weight += 2.5
                                }
                            }
                            
                            // Weight Slider for fine adjustment
                            Slider(value: $weight, in: 0...200, step: 0.5)
                                .tint(Theme.accent)
                                .padding(.horizontal)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        
                        // Reps Input
                        VStack(spacing: 20) {
                            Label {
                                Text("回数")
                                    .font(.headline)
                            } icon: {
                                Image(systemName: "number")
                            }
                            .foregroundColor(Theme.textPrimary)
                            
                            HStack(spacing: 20) {
                                CircularControlButton(systemName: "minus") {
                                    reps = max(1, reps - 1)
                                }
                                
                                VStack(spacing: 4) {
                                    Text("\(reps)")
                                        .font(.system(size: 38, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text("reps")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(minWidth: 120)
                                
                                CircularControlButton(systemName: "plus") {
                                    reps += 1
                                }
                            }
                            
                            // Reps Stepper for fine adjustment
                            Stepper("", value: $reps, in: 1...100)
                                .labelsHidden()
                                .tint(Theme.accentSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.border)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        
                        // Current Session Info
                        if let sets = session.workoutSets?.allObjects as? [WorkoutSet], !sets.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("今回のセット")
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                
                                ForEach(sets.sorted { $0.setNumber < $1.setNumber }, id: \.setID) { set in
                                    if set.exercise?.exerciseID == exercise.exerciseID {
                                        HStack {
                                            Text("セット \(set.setNumber)")
                                                .font(.subheadline)
                                                .foregroundColor(Theme.textSecondary)
                                            Spacer()
                                            Text("\(set.weight, specifier: "%.1f")kg × \(set.repetitions)回")
                                                .font(.subheadline)
                                                .foregroundColor(Theme.textTertiary)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.backgroundElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Theme.border)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        
                        // Save Button
                        Button {
                            saveSet()
                        } label: {
                            Text("セットを記録")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Theme.accentGradient)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Theme.border)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Spacer(minLength: 12)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("重量・回数入力")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .foregroundColor(Theme.accentSecondary)
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

private struct CircularControlButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 54, height: 54)
                .background(
                    Circle()
                        .fill(Theme.accentGradient)
                )
                .overlay(
                    Circle()
                        .stroke(Theme.border)
                )
                .shadow(color: Theme.accent.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
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
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 32) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 90))
                        .foregroundStyle(Theme.accentGradient)
                        .shadow(color: Theme.accent.opacity(0.45), radius: 16, x: 0, y: 10)
                    
                    VStack(spacing: 12) {
                        Text("セット完了！")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(exercise.name ?? "Unknown Exercise")
                            .font(.headline)
                            .foregroundColor(Theme.textSecondary)
                        
                        Text("\(weight, specifier: "%.1f")kg × \(reps)回")
                            .font(.title2)
                            .foregroundColor(Theme.textPrimary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Theme.border)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    
                    VStack(spacing: 16) {
                        Button {
                            onNextSet()
                        } label: {
                            Text("次のセットへ")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Theme.accentGradient)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Theme.border)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            onFinish()
                        } label: {
                            Text("完了")
                                .font(.headline)
                                .foregroundColor(Theme.accentSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(Theme.backgroundElevated)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Theme.border)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding()
            }
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
