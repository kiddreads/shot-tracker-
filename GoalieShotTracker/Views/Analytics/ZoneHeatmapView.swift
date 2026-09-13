import SwiftUI

/// Read-only 3x3 heatmap, the analytics counterpart to the interactive
/// `NetDiagramView` used while logging live.
struct ZoneHeatmapView: View {
    let zoneStats: [NetZone: ShotStats]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 4) {
            ForEach(NetZone.allCases) { zone in
                let stats = zoneStats[zone] ?? .zero
                VStack(spacing: 2) {
                    Text(zone.displayName)
                        .font(.caption2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    if stats.shotsFaced > 0 {
                        Text(String(format: "%.2f", stats.savePercentage))
                            .font(.caption.weight(.bold))
                        Text("\(stats.shotsFaced) shots")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 68)
                .background(
                    (stats.shotsFaced > 0 ? Theme.savePercentageColor(stats.savePercentage) : Color.gray)
                        .opacity(stats.shotsFaced > 0 ? 0.5 : 0.12)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

#Preview {
    ZoneHeatmapView(zoneStats: [
        .fiveHole: ShotStats(shotsFaced: 12, saves: 9, goals: 3, savePercentage: 0.75)
    ])
    .padding()
    .background(Theme.rinkBackground)
}
