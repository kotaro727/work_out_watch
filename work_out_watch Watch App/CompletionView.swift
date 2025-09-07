import SwiftUI
import CoreData

struct CompletionView: View {
    let exerciseType: String
    let weight: Double
    let repetitions: Int
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var isSaved = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        if isSaved {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                                .scaleEffect(showConfetti ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showConfetti)
                            
                            Text("記録完了!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("ワークアウト記録")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.top, 20)
                
                VStack(spacing: 12) {
                    InfoRow(icon: "figure.strengthtraining.traditional", label: "運動", value: exerciseType)
                    InfoRow(icon: "scalemass", label: "重量", value: "\(Int(weight)) kg")
                    InfoRow(icon: "number", label: "回数", value: "\(repetitions) 回")
                    InfoRow(icon: "clock", label: "日時", value: dateFormatter.string(from: Date()))
                }
                .padding(.horizontal, 8)
                
                if !isSaved {
                    Button {
                        saveWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title3)
                            Text("保存")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.green)
                        )
                    }
                    .disabled(isSaved)
                    .padding(.horizontal, 8)
                } else {
                    NavigationLink(destination: ExerciseSelectionView()) {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.title3)
                            Text("完了")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.gray.opacity(0.3))
                        )
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(isSaved)
    }
    
    private struct InfoRow: View {
        let icon: String
        let label: String
        let value: String

        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.green)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(value)
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
    }
    
    private func saveWorkout() {
        let newRecord = WorkoutRecord(context: viewContext)
        newRecord.exerciseType = exerciseType
        newRecord.weight = weight
        newRecord.repetitions = Int16(repetitions)
        newRecord.date = Date()
        
        do {
            try viewContext.save()
            withAnimation(.easeInOut(duration: 0.5)) {
                isSaved = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showConfetti = true
            }
            
            WKInterfaceDevice.current().play(.success)
            
        } catch {
            print("保存エラー: \(error)")
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }()
}

#Preview {
    NavigationView {
        CompletionView(
            exerciseType: "ベンチプレス",
            weight: 80.0,
            repetitions: 10
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}