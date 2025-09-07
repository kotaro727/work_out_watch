import SwiftUI

struct InputView: View {
    let exerciseType: String
    @State private var weight: Double = 50.0
    @State private var repetitions: Int = 10
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text(exerciseType)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .padding(.top)
                    
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("重量")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 20) {
                                Button {
                                    weight = max(0, weight - 1)
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.green))
                                }
                                
                                Text("\(Int(weight)) kg")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(minWidth: 80)
                                
                                Button {
                                    weight += 1
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.green))
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text("回数")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 20) {
                                Button {
                                    repetitions = max(1, repetitions - 1)
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.green))
                                }
                                
                                Text("\(repetitions) 回")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(minWidth: 80)
                                
                                Button {
                                    repetitions += 1
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color.green))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    NavigationLink(destination: CompletionView(
                        exerciseType: exerciseType,
                        weight: weight,
                        repetitions: repetitions
                    )) {
                        HStack(spacing:0) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                            Text("記録する")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.green)
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
            }
        }
        .focusable(true)
        .digitalCrownRotation(
            $weight,
            from: 0,
            through: 200,
            by: 1,
            sensitivity: .medium
        )

        .navigationBarHidden(false)
        .navigationBarBackButtonHidden(false)
    }
}

#Preview {
    NavigationView {
        InputView(exerciseType: "ベンチプレス")
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
