import SwiftUI

struct ShotDraft {
    var shotType: ShotType
    var outcome: ShotOutcome
    var strengthState: StrengthState
    var isRushOrOddMan: Bool
}

/// Appears the instant a zone is tapped. The two big buttons cover the
/// overwhelming majority of taps (save or goal, in real time); everything
/// else is a secondary refinement so a goalie's bench-side scorer never
/// falls behind play.
struct LogShotSheet: View {
    let zone: NetZone
    var onCommit: (ShotDraft) -> Void

    @State private var shotType: ShotType = .wristShot
    @State private var strength: StrengthState = .evenStrength
    @State private var isRush = false
    @State private var reboundGiven = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    section("Shot Type") {
                        ChipRow(items: ShotType.allCases, selection: $shotType) { $0.displayName }
                    }

                    section("Strength") {
                        ChipRow(items: StrengthState.allCases, selection: $strength) { $0.shortLabel }
                    }

                    Toggle("Rush / Odd-Man", isOn: $isRush)
                        .toggleStyle(.switch)

                    Toggle("Rebound Given", isOn: $reboundGiven)
                        .toggleStyle(.switch)

                    primaryButtons

                    section("Other Outcomes") {
                        HStack(spacing: 8) {
                            outcomeChip("Missed Net", outcome: .missedNet)
                            outcomeChip("Blocked", outcome: .blockedShot)
                            outcomeChip("Post/Bar", outcome: .postOrCrossbar)
                        }
                    }
                }
                .padding()
            }
            .background(Theme.rinkBackground)
            .navigationTitle(zone.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        Text("Logging a shot to \(zone.displayName.lowercased())")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private var primaryButtons: some View {
        HStack(spacing: 12) {
            Button {
                HapticsManager.save()
                commit(outcome: reboundGiven ? .savedRebound : .savedFrozen)
            } label: {
                Label("SAVE", systemImage: "hand.raised.fill")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.saveGreen)

            Button {
                HapticsManager.goal()
                commit(outcome: reboundGiven ? .goalOnRebound : .goal)
            } label: {
                Label("GOAL", systemImage: "xmark.circle.fill")
                    .font(.title3.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.goalRed)
        }
    }

    private func outcomeChip(_ title: String, outcome: ShotOutcome) -> some View {
        Button(title) { commit(outcome: outcome) }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
    }

    private func commit(outcome: ShotOutcome) {
        onCommit(
            ShotDraft(
                shotType: shotType,
                outcome: outcome,
                strengthState: strength,
                isRushOrOddMan: isRush
            )
        )
        dismiss()
    }
}

#Preview {
    LogShotSheet(zone: .fiveHole) { _ in }
}
