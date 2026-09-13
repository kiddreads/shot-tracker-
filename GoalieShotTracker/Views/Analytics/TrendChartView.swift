import SwiftUI
import Charts

struct TrendChartView: View {
    let points: [TrendPoint]

    var body: some View {
        if points.isEmpty {
            EmptyStateView(systemImage: "chart.line.uptrend.xyaxis", title: "No Trend Yet", message: "Log a few games to see your save percentage over time.")
        } else {
            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Save %", point.savePercentage)
                )
                .foregroundStyle(Theme.iceBlue)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Save %", point.savePercentage)
                )
                .foregroundStyle(Theme.savePercentageColor(point.savePercentage))
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.2f", doubleValue))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }
}

struct ShotTypeBarChartView: View {
    let stats: [ShotTypeStat]

    var body: some View {
        let nonEmpty = stats.filter { $0.stats.shotsFaced > 0 }
        if nonEmpty.isEmpty {
            EmptyStateView(systemImage: "chart.bar", title: "No Shots Yet", message: "Shot-type breakdown appears once you log some shots.")
        } else {
            Chart(nonEmpty) { stat in
                BarMark(
                    x: .value("Shots", stat.stats.shotsFaced),
                    y: .value("Type", stat.shotType.displayName)
                )
                .foregroundStyle(Theme.iceBlue)
                .annotation(position: .trailing) {
                    Text(String(format: "%.2f", stat.stats.savePercentage))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: CGFloat(nonEmpty.count) * 32 + 20)
        }
    }
}
