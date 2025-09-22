import SwiftUI

struct WorkoutCompletionView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @Binding var tabSelection: Int

    private var totalSets: Int {
        session.workoutSets?.count ?? 0
    }

    private var groupedSets: [(exercise: String, sets: [WorkoutSet])] {
        guard let sets = session.workoutSets?.allObjects as? [WorkoutSet] else { return [] }

        let grouped = Dictionary(grouping: sets) { set in
            set.exercise?.name ?? "不明な種目"
        }

        return grouped
            .map { key, value in
                let sortedSets = value.sorted { lhs, rhs in
                    if lhs.setNumber == rhs.setNumber {
                        return (lhs.createdAt ?? .distantPast) < (rhs.createdAt ?? .distantPast)
                    }
                    return lhs.setNumber < rhs.setNumber
                }
                return (exercise: key, sets: sortedSets)
            }
            .sorted { $0.exercise < $1.exercise }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 完了アイコン
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Theme.accentGradient)
                            .frame(width: 120, height: 120)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 20, y: 10)

                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 8) {
                        Text("ワークアウト完了！")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)

                        Text("お疲れ様でした")
                            .font(.headline)
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                // セッション情報
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("合計セット")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Text("\(totalSets)セット")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                        }

                        Spacer()
                    }

                    if groupedSets.isEmpty {
                        Text("記録されたセットがありません")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(alignment: .leading, spacing: 18) {
                            ForEach(groupedSets, id: \.exercise) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(group.exercise)
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)

                                    VStack(spacing: 8) {
                                        ForEach(group.sets, id: \.objectID) { set in
                                            HStack {
                                                Text("セット \(set.setNumber)")
                                                    .font(.caption)
                                                    .foregroundColor(Theme.textSecondary)

                                                Spacer()

                                                Text("\(set.weight, specifier: "%.1f")kg × \(set.repetitions)回")
                                                    .font(.subheadline)
                                                    .foregroundColor(Theme.textPrimary)
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(Theme.background.opacity(0.4))
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                    }
                                }
                                if group.exercise != groupedSets.last?.exercise {
                                    Divider()
                                        .overlay(Theme.border)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Theme.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.border)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Spacer()

                // アクションボタン
                VStack(spacing: 16) {
                    Button {
                        tabSelection = 0  // 履歴タブに遷移
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("履歴を見る")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
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

                    Button {
                        dismiss()
                    } label: {
                        Text("続ける")
                            .font(.headline)
                            .foregroundColor(Theme.accentSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Theme.border)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .navigationTitle("完了")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") {
                    dismiss()
                }
                .foregroundColor(Theme.accentSecondary)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let session = WorkoutSession(context: context)
    session.sessionID = UUID()
    session.isCompleted = true

    let bench = Exercise(context: context)
    bench.exerciseID = UUID()
    bench.name = "ベンチプレス"

    let squat = Exercise(context: context)
    squat.exerciseID = UUID()
    squat.name = "スクワット"

    let benchSet1 = WorkoutSet(context: context)
    benchSet1.setID = UUID()
    benchSet1.setNumber = 1
    benchSet1.weight = 60
    benchSet1.repetitions = 8
    benchSet1.exercise = bench
    benchSet1.workoutSession = session

    let benchSet2 = WorkoutSet(context: context)
    benchSet2.setID = UUID()
    benchSet2.setNumber = 2
    benchSet2.weight = 62.5
    benchSet2.repetitions = 6
    benchSet2.exercise = bench
    benchSet2.workoutSession = session

    let squatSet1 = WorkoutSet(context: context)
    squatSet1.setID = UUID()
    squatSet1.setNumber = 1
    squatSet1.weight = 80
    squatSet1.repetitions = 10
    squatSet1.exercise = squat
    squatSet1.workoutSession = session

    return NavigationStack {
        WorkoutCompletionView(session: session, tabSelection: .constant(0))
    }
    .environment(\.managedObjectContext, context)
}
