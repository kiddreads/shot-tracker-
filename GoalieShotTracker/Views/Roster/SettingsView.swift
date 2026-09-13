import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var games: [GameSessionEntity]
    @Query private var shots: [ShotEventEntity]
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = true

    private var exportURL: URL? {
        guard !shots.isEmpty else { return nil }
        return CSVExporter.writeTempFile(
            csv: CSVExporter.export(shots: shots.map(\.asCoreModel), games: games.map(\.asCoreModel))
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("iCloud Sync", isOn: $cloudSyncEnabled)
            } footer: {
                Text("Requires restarting the app to take effect. When off, your stats stay on this device only.")
            }

            Section("Data") {
                if let exportURL {
                    ShareLink("Export All Shots as CSV", item: exportURL)
                } else {
                    Text("Export All Shots as CSV")
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                LabeledContent("Games Logged", value: "\(games.count)")
                LabeledContent("Shots Logged", value: "\(shots.count)")
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
    }
}
