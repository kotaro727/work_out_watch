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
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 20)
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("運動")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(exerciseType)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
                    
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("重量")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("\(Int(weight)) kg")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
                    
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("回数")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("\(repetitions) 回")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("日時")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text("\(Date(), formatter: dateFormatter)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.1, green: 0.1, blue: 0.1))
                    )
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
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .font(.title3)
                            Text("完了")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                        )
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(isSaved)
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