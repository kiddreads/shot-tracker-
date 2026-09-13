import Foundation
import SwiftData

/// Builds the app's `ModelContainer`. iCloud sync is opt-in via
/// `CloudSyncSettings` (stored in `UserDefaults`, surfaced in Settings) so a
/// goalie who doesn't want their stats leaving the device never has to.
enum PersistenceController {

    static var schema: Schema {
        Schema([
            GoalieProfileEntity.self,
            TeamEntity.self,
            OpponentEntity.self,
            GameSessionEntity.self,
            ShotEventEntity.self
        ])
    }

    static func makeContainer(cloudSyncEnabled: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudSyncEnabled ? .automatic : .none
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Falling back to an in-memory store keeps the app usable (and
            // avoids a hard launch crash) if the on-disk store is somehow
            // corrupt or schema-incompatible after an update.
            assertionFailure("Failed to create persistent ModelContainer: \(error)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }

    /// In-memory container pre-populated with sample data, for SwiftUI previews.
    @MainActor
    static func previewContainer() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        SampleData.populate(container.mainContext)
        return container
    }
}

enum CloudSyncSettings {
    private static let key = "cloudSyncEnabled"

    static var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
