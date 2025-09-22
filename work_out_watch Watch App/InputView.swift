import SwiftUI

struct InputView: View {
    let exerciseType: String
    @State private var weight: Double = 50.0
    @State private var repetitions: Int = 10
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Theme.accentGradient)
                            .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 6)

                        Text(exerciseType)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Theme.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Theme.border)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 18) {
                        Label {
                            Text("重量")
                                .font(.system(size: 15, weight: .semibold))
                        } icon: {
                            Image(systemName: "scalemass")
                        }
                        .foregroundColor(Theme.textPrimary)

                        HStack(spacing: 16) {
                            CircularControlButton(systemName: "minus") {
                                weight = max(0, weight - 1)
                            }

                            VStack(spacing: 4) {
                                Text("\(Int(weight)) kg")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("Digital Crownで微調整")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .frame(minWidth: 95)

                            CircularControlButton(systemName: "plus") {
                                weight += 1
                            }
                        }

                        Divider().overlay(Theme.border)

                        Label {
                            Text("回数")
                                .font(.system(size: 15, weight: .semibold))
                        } icon: {
                            Image(systemName: "number")
                        }
                        .foregroundColor(Theme.textPrimary)

                        HStack(spacing: 16) {
                            CircularControlButton(systemName: "minus") {
                                repetitions = max(1, repetitions - 1)
                            }

                            Text("\(repetitions) 回")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                                .frame(minWidth: 80)

                            CircularControlButton(systemName: "plus") {
                                repetitions += 1
                            }
                        }
                    }
                    .padding()
                    .background(Theme.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Theme.border)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    NavigationLink(
                        destination: CompletionView(
                            exerciseType: exerciseType,
                            weight: weight,
                            repetitions: repetitions
                        )
                    ) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("記録する")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Theme.accentGradient)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Theme.border)
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 8)
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

private struct CircularControlButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(Theme.accentGradient)
                )
                .overlay(
                    Circle().stroke(Theme.border)
                )
                .shadow(color: Theme.accent.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        InputView(exerciseType: "ベンチプレス")
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    .preferredColorScheme(.dark)
}
