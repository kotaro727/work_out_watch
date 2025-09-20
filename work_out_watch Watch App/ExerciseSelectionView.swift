import SwiftUI

struct ExerciseSelectionView: View {
    let exercises = [
        ("ベンチプレス", "figure.strengthtraining.traditional"),
        ("スクワット", "figure.strengthtraining.functional"), 
        ("デッドリフト", "dumbbell.fill"),
        ("ショルダープレス", "figure.arms.open"),
        ("バーベルロー", "figure.strengthtraining.traditional"),
        ("インクラインベンチプレス", "figure.strengthtraining.traditional")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("筋トレ記録")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                            .padding(.top, 8)
                        
                        ForEach(exercises, id: \.0) { exercise in
                            ExerciseRowView(exercise: exercise)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ExerciseRowView: View {
    let exercise: (String, String)
    
    var body: some View {
        NavigationLink(destination: InputView(exerciseType: exercise.0)) {
            HStack {
                Image(systemName: exercise.1)
                    .font(.title2)
                    .foregroundStyle(Theme.accentGradient)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.0)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.backgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.border)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseSelectionView()
        .preferredColorScheme(.dark)
}
