import UIKit

/// Centralizes haptic feedback so the live logger can fire distinct, tuned
/// feedback per outcome without every call site constructing its own
/// generator (which also avoids the small warm-up latency on first use).
enum HapticsManager {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        notification.prepare()
    }

    static func save() {
        notification.notificationOccurred(.success)
    }

    static func goal() {
        notification.notificationOccurred(.error)
    }

    static func zoneSelected() {
        impactLight.impactOccurred()
    }

    static func undo() {
        impactMedium.impactOccurred()
    }

    static func milestone() {
        impactHeavy.impactOccurred()
    }
}
