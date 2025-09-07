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
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("筋トレ記録")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
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
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.0)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ExerciseSelectionView()
}
