import SwiftUI

struct InputView: View {
    let exerciseType: String
    @State private var weight: Double = 50.0
    @State private var repetitions: Int = 10
    @State private var isWeightFocused = true
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(exerciseType)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(isWeightFocused ? "重量を調整" : "回数を調整")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                VStack(spacing: 12) {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "scalemass")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("重量")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("\(Int(weight)) kg")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(isWeightFocused ? .green : .white)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isWeightFocused ? Color(red: 0.15, green: 0.3, blue: 0.15) : Color(red: 0.1, green: 0.1, blue: 0.1))
                                .stroke(isWeightFocused ? Color.green : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            isWeightFocused = true
                        }
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "number")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("回数")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("\(repetitions) 回")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(!isWeightFocused ? .green : .white)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(!isWeightFocused ? Color(red: 0.15, green: 0.3, blue: 0.15) : Color(red: 0.1, green: 0.1, blue: 0.1))
                                .stroke(!isWeightFocused ? Color.green : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            isWeightFocused = false
                        }
                    }
                }
                .padding(.horizontal, 8)
                
                HStack(spacing: 20) {
                    Button {
                        if isWeightFocused {
                            weight = max(0, weight - 1)
                        } else {
                            repetitions = max(1, repetitions - 1)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color(red: 0.2, green: 0.2, blue: 0.2)))
                    }
                    
                    Button {
                        if isWeightFocused {
                            weight += 1
                        } else {
                            repetitions += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Color(red: 0.2, green: 0.2, blue: 0.2)))
                    }
                }
                
                NavigationLink(destination: CompletionView(
                    exerciseType: exerciseType,
                    weight: weight,
                    repetitions: repetitions
                )) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("記録する")
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
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
        }
        .focusable(true)
        .digitalCrownRotation(
            isWeightFocused ? $weight : Binding(
                get: { Double(repetitions) },
                set: { repetitions = Int($0) }
            ),
            from: isWeightFocused ? 0 : 1,
            through: isWeightFocused ? 200 : 50,
            by: isWeightFocused ? 5 : 1,
            sensitivity: .medium
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        InputView(exerciseType: "ベンチプレス")
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
