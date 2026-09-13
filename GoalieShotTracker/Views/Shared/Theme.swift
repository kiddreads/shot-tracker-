import SwiftUI

enum Theme {
    static let rinkBackground = Color(red: 0.06, green: 0.08, blue: 0.11)
    static let cardBackground = Color(red: 0.11, green: 0.13, blue: 0.17)
    static let iceBlue = Color(red: 0.29, green: 0.63, blue: 0.94)
    static let saveGreen = Color(red: 0.30, green: 0.78, blue: 0.47)
    static let goalRed = Color(red: 0.92, green: 0.31, blue: 0.31)
    static let warningAmber = Color(red: 0.95, green: 0.71, blue: 0.24)

    /// Maps a save percentage to a color on a red -> amber -> green ramp,
    /// used for zone heatmaps and stat tiles.
    static func savePercentageColor(_ value: Double) -> Color {
        switch value {
        case ..<0.80: return goalRed
        case 0.80..<0.90: return warningAmber
        default: return saveGreen
        }
    }

    static func dangerColor(_ level: DangerLevel) -> Color {
        switch level {
        case .low: return iceBlue
        case .medium: return warningAmber
        case .high: return goalRed
        }
    }
}

extension View {
    /// Standard card container used across dashboard/analytics tiles.
    func cardStyle() -> some View {
        padding(16)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
