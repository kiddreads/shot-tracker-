import SwiftUI

/// A tap-to-log 3x3 net diagram. Zone cells are colored live by that zone's
/// save percentage so a goalie (or coach) can see weak spots forming
/// mid-game, not just after the fact in Analytics.
struct NetDiagramView: View {
    let zoneStats: [NetZone: ShotStats]
    var onZoneTapped: (NetZone) -> Void

    var body: some View {
        VStack(spacing: 0) {
            crossbar
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
                ForEach(NetZone.allCases) { zone in
                    ZoneCell(zone: zone, stats: zoneStats[zone] ?? .zero) {
                        onZoneTapped(zone)
                    }
                }
            }
            .padding(6)
            .background(Theme.cardBackground)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .aspectRatio(1.15, contentMode: .fit)
    }

    private var crossbar: some View {
        Rectangle()
            .fill(Color.red.opacity(0.85))
            .frame(height: 6)
    }
}

private struct ZoneCell: View {
    let zone: NetZone
    let stats: ShotStats
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.zoneSelected()
            action()
        }) {
            VStack(spacing: 2) {
                Text(zone.displayName)
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if stats.shotsFaced > 0 {
                    Text("\(stats.saves)/\(stats.shotsFaced)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(4)
            .background(cellColor.opacity(stats.shotsFaced > 0 ? 0.55 : 0.18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }

    private var cellColor: Color {
        stats.shotsFaced > 0 ? Theme.savePercentageColor(stats.savePercentage) : Theme.dangerColor(zone.baselineDanger)
    }

    private var accessibilityLabel: String {
        stats.shotsFaced > 0
            ? "\(zone.displayName), \(stats.saves) saves on \(stats.shotsFaced) shots"
            : "\(zone.displayName), no shots yet"
    }
}

#Preview {
    NetDiagramView(zoneStats: [
        .fiveHole: ShotStats(shotsFaced: 4, saves: 3, goals: 1, savePercentage: 0.75),
        .highGlove: ShotStats(shotsFaced: 2, saves: 2, goals: 0, savePercentage: 1.0)
    ]) { _ in }
    .padding()
    .background(Theme.rinkBackground)
}
