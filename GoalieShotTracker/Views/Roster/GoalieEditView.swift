import SwiftUI
import SwiftData

struct GoalieEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existing: GoalieProfileEntity?
    var onSave: ((GoalieProfileEntity) -> Void)?

    @State private var name: String
    @State private var jerseyNumberText: String
    @State private var catchHand: CatchHand
    @State private var teamName: String

    init(existing: GoalieProfileEntity? = nil, onSave: ((GoalieProfileEntity) -> Void)? = nil) {
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: existing?.name ?? "")
        _jerseyNumberText = State(initialValue: existing?.jerseyNumber.map(String.init) ?? "")
        _catchHand = State(initialValue: existing.flatMap { CatchHand(rawValue: $0.catchHandRaw) } ?? .left)
        _teamName = State(initialValue: existing?.teamName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goalie") {
                    TextField("Name", text: $name)
                    TextField("Jersey Number", text: $jerseyNumberText)
                        .keyboardType(.numberPad)
                    Picker("Catch Hand", selection: $catchHand) {
                        ForEach(CatchHand.allCases) { Text($0.displayName).tag($0) }
                    }
                    TextField("Team", text: $teamName)
                }
            }
            .navigationTitle(existing == nil ? "New Goalie" : "Edit Goalie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let profile = GoalieProfile(
            id: existing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            jerseyNumber: Int(jerseyNumberText),
            catchHand: catchHand,
            teamName: teamName.isEmpty ? nil : teamName
        )
        let entity: GoalieProfileEntity
        if let existing {
            existing.update(from: profile)
            entity = existing
        } else {
            entity = GoalieProfileEntity(from: profile)
            modelContext.insert(entity)
        }
        try? modelContext.save()
        onSave?(entity)
        dismiss()
    }
}
