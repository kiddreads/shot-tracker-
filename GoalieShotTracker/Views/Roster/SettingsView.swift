import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var games: [GameSessionEntity]
    @Query private var shots: [ShotEventEntity]
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled = true
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section {
                Toggle("iCloud Sync", isOn: $cloudSyncEnabled)
            } footer: {
                Text("Requires restarting the app to take effect. When off, your stats stay on this device only.")
            }

            Section("Data") {
                Button("Export All Shots as CSV") {
                    exportURL = CSVExporter.writeTempFile(
                        csv: CSVExporter.export(shots: shots.map(\.asCoreModel), games: games.map(\.asCoreModel))
                    )
                    showingShareSheet = exportURL != nil
                }
            }

            Section("About") {
                LabeledContent("Games Logged", value: "\(games.count)")
                LabeledContent("Shots Logged", value: "\(shots.count)")
                LabeledContent("Version", value: "1.0")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingShareSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }
}
