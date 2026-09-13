import SwiftUI
import SwiftData

struct RosterView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GoalieProfileEntity.name) private var goalies: [GoalieProfileEntity]
    @State private var showingAddGoalie = false
    @State private var editingGoalie: GoalieProfileEntity?

    var body: some View {
        NavigationStack {
            List {
                Section("Goalies") {
                    if goalies.isEmpty {
                        Text("No goalies yet. Add one to start tracking.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(goalies) { goalie in
                        Button {
                            appState.selectedGoalieID = goalie.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(goalie.name)
                                        .foregroundStyle(.primary)
                                    if let jersey = goalie.jerseyNumber {
                                        Text("#\(jersey)" + (goalie.teamName.map { " · \($0)" } ?? ""))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if appState.selectedGoalieID == goalie.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.iceBlue)
                                }
                            }
                        }
                        .swipeActions {
                            Button("Edit") { editingGoalie = goalie }
                                .tint(Theme.iceBlue)
                            Button("Delete", role: .destructive) { delete(goalie) }
                        }
                    }
                }

                Section {
                    NavigationLink("Settings") { SettingsView() }
                }
            }
            .navigationTitle("Roster")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddGoalie = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoalie) {
                GoalieEditView { newGoalie in
                    if appState.selectedGoalieID == nil {
                        appState.selectedGoalieID = newGoalie.id
                    }
                }
            }
            .sheet(item: $editingGoalie) { goalie in
                GoalieEditView(existing: goalie)
            }
        }
    }

    private func delete(_ goalie: GoalieProfileEntity) {
        modelContext.delete(goalie)
        try? modelContext.save()
        if appState.selectedGoalieID == goalie.id {
            appState.selectedGoalieID = goalies.first(where: { $0.id != goalie.id })?.id
        }
    }
}
