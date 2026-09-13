import SwiftUI

struct StatTileView: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }
}

struct BadgeChipView: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "shield.fill")
                .font(.title2)
                .foregroundStyle(Theme.iceBlue)
            Text(badge.title)
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(width: 96, height: 84)
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(badge.title). \(badge.detail)"))
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
