import SwiftUI

struct WorkoutCompletionView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) private var dismiss
    @Binding var tabSelection: Int

    private var totalSets: Int {
        session.workoutSets?.count ?? 0
    }

    private var duration: String {
        guard let start = session.startTime, let end = session.endTime else {
            return "不明"
        }
        let minutes = Int(end.timeIntervalSince(start)) / 60
        return "\(minutes)分"
    }

    private var exerciseNames: [String] {
        guard let sets = session.workoutSets?.allObjects as? [WorkoutSet] else { return [] }
        let names = sets.compactMap { $0.exercise?.name }
        return Array(Set(names))
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
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("継続時間")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Text(duration)
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("セット数")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                            Text("\(totalSets)セット")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }

                    if !exerciseNames.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("実施種目")
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)

                            Text(exerciseNames.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    session.startTime = Date().addingTimeInterval(-3600)  // 1時間前
    session.endTime = Date()
    session.isCompleted = true

    return NavigationStack {
        WorkoutCompletionView(session: session, tabSelection: .constant(0))
    }
    .environment(\.managedObjectContext, context)
}
