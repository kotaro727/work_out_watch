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
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("筋トレ記録")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    ForEach(exercises, id: \.0) { exercise in
                        NavigationLink(destination: InputView(exerciseType: exercise.0)) {
                            HStack {
                                Image(systemName: exercise.1)
                                    .font(.title2)
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.0)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()

                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.2, green: 0.4, blue: 0.2))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ExerciseSelectionView()
}
