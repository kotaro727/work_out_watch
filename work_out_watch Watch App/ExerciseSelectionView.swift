import SwiftUI

struct ExerciseGroup: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
    let exercises: [ExerciseItem]
}

struct ExerciseItem: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
}

struct ExerciseSelectionView: View {
    private let exerciseGroups: [ExerciseGroup] = [
        ExerciseGroup(
            name: "胸",
            icon: "figure.strengthtraining.traditional",
            exercises: [
                ExerciseItem(name: "ベンチプレス", icon: "figure.strengthtraining.traditional"),
                ExerciseItem(name: "インクラインベンチプレス", icon: "figure.strengthtraining.traditional"),
                ExerciseItem(name: "ダンベルフライ", icon: "dumbbell.fill")
            ]
        ),
        ExerciseGroup(
            name: "背中",
            icon: "figure.pullup.gen1",
            exercises: [
                ExerciseItem(name: "チンニング", icon: "figure.pullup.gen1"),
                ExerciseItem(name: "バーベルロー", icon: "figure.strengthtraining.functional"),
                ExerciseItem(name: "デッドリフト", icon: "dumbbell.fill")
            ]
        ),
        ExerciseGroup(
            name: "肩",
            icon: "figure.arms.open",
            exercises: [
                ExerciseItem(name: "ショルダープレス", icon: "figure.arms.open"),
                ExerciseItem(name: "サイドレイズ", icon: "figure.arms.open"),
                ExerciseItem(name: "リアレイズ", icon: "dumbbell.fill")
            ]
        ),
        ExerciseGroup(
            name: "脚",
            icon: "figure.strengthtraining.functional",
            exercises: [
                ExerciseItem(name: "スクワット", icon: "figure.strengthtraining.functional"),
                ExerciseItem(name: "ランジ", icon: "figure.walk"),
                ExerciseItem(name: "レッグプレス", icon: "figure.strengthtraining.traditional")
            ]
        )
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
                        
                        ForEach(exerciseGroups) { group in
                            NavigationLink(destination: ExerciseGroupDetailView(group: group)) {
                                ExerciseGroupRowView(group: group)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ExerciseGroupRowView: View {
    let group: ExerciseGroup

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: group.icon)
                .font(.title2)
                .foregroundStyle(Theme.accentGradient)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Text("\(group.exercises.count)種目")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
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
}

struct ExerciseRowView: View {
    let exercise: ExerciseItem

    var body: some View {
        NavigationLink(destination: InputView(exerciseType: exercise.name)) {
            HStack(spacing: 12) {
                Image(systemName: exercise.icon)
                    .font(.title2)
                    .foregroundStyle(Theme.accentGradient)
                    .frame(width: 28)

                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textPrimary)

                Spacer(minLength: 0)
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

struct ExerciseGroupDetailView: View {
    let group: ExerciseGroup

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                ForEach(group.exercises) { exercise in
                    ExerciseRowView(exercise: exercise)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.carousel)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(group.name)
    }
}

#Preview {
    ExerciseSelectionView()
        .preferredColorScheme(.dark)
}
