import SwiftUI
import SwiftData

struct StartGameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \OpponentEntity.name) private var savedOpponents: [OpponentEntity]
    @Query(sort: \GoalieProfileEntity.name) private var goalies: [GoalieProfileEntity]

    let defaultTeamName: String
    let preselectedGoalieID: UUID?
    var onStart: (GameSessionEntity) -> Void

    @State private var teamName: String
    @State private var opponentName = ""
    @State private var isHome = true
    @State private var sessionType: SessionType = .game
    @State private var periodCount = 3
    @State private var selectedGoalieID: UUID?

    init(defaultTeamName: String, preselectedGoalieID: UUID?, onStart: @escaping (GameSessionEntity) -> Void) {
        self.defaultTeamName = defaultTeamName
        self.preselectedGoalieID = preselectedGoalieID
        self.onStart = onStart
        _teamName = State(initialValue: defaultTeamName)
        _selectedGoalieID = State(initialValue: preselectedGoalieID)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Matchup") {
                    TextField("My Team", text: $teamName)
                    TextField("Opponent", text: $opponentName)
                        .autocorrectionDisabled()
                    if !savedOpponents.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(savedOpponents) { opponent in
                                    Button(opponent.name) { opponentName = opponent.name }
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    Toggle("Home Game", isOn: $isHome)
                }

                Section("Format") {
                    Picker("Type", selection: $sessionType) {
                        ForEach(SessionType.allCases) { Text($0.displayName).tag($0) }
                    }
                    Stepper("Periods: \(periodCount)", value: $periodCount, in: 1...4)
                }

                if goalies.count > 1 {
                    Section("Goalie") {
                        Picker("Goalie", selection: $selectedGoalieID) {
                            ForEach(goalies) { goalie in
                                Text(goalie.name).tag(Optional(goalie.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { start() }
                        .disabled(opponentName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func start() {
        let trimmedOpponent = opponentName.trimmingCharacters(in: .whitespaces)
        if !savedOpponents.contains(where: { $0.name.caseInsensitiveCompare(trimmedOpponent) == .orderedSame }) {
            modelContext.insert(OpponentEntity(name: trimmedOpponent))
        }
        var goalieIDs: [UUID] = []
        if let selectedGoalieID { goalieIDs = [selectedGoalieID] }

        let game = GameSessionEntity(
            sessionTypeRaw: sessionType.rawValue,
            teamName: teamName,
            opponentName: trimmedOpponent,
            isHome: isHome,
            periodCount: periodCount,
            goalieIDs: goalieIDs
        )
        modelContext.insert(game)
        try? modelContext.save()
        onStart(game)
        dismiss()
    }
}
