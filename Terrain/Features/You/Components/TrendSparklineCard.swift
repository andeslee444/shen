//
//  TrendSparklineCard.swift
//  Terrain
//
//  A compact card showing a trend category with a mini sparkline chart.
//  The sparkline is like a tiny EKG — it shows the shape of your trend
//  over 14 days without needing axes or labels.
//

import SwiftUI

struct TrendSparklineCard: View {
    let trend: TrendResult

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Category icon + name
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: trend.icon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 20, alignment: .center)

                Text(trend.category)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .frame(width: 100, alignment: .leading)

            // Mini sparkline chart
            SparklineView(
                data: trend.dailyRates,
                lineColor: trendColor(trend.direction)
            )
            .frame(height: 24)

            // Direction arrow + label
            HStack(spacing: theme.spacing.xxs) {
                Image(systemName: trend.direction.icon)
                    .font(.system(size: 10, weight: .semibold))

                Text(trend.direction.rawValue.capitalized)
                    .font(theme.typography.labelSmall)
            }
            .foregroundColor(trendColor(trend.direction))
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, theme.spacing.xs)
    }

    private func trendColor(_ direction: TrendDirection) -> Color {
        switch direction {
        case .improving: return theme.colors.success
        case .stable: return theme.colors.textSecondary
        case .declining: return theme.colors.warning
        }
    }
}

// MARK: - Sparkline View

/// Draws a smooth line through data points using SwiftUI Path.
/// No axes, no labels — just the shape of the trend.
struct SparklineView: View {
    let data: [Double]
    let lineColor: Color

    var body: some View {
        GeometryReader { geometry in
            if data.count >= 2 {
                let width = geometry.size.width
                let height = geometry.size.height
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = max(maxVal - minVal, 0.01) // avoid division by zero

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = height - (height * CGFloat((value - minVal) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                // Fill gradient under the line
                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = height - (height * CGFloat((value - minVal) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    // Close the path at the bottom
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.addLine(to: CGPoint(x: 0, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [lineColor.opacity(0.15), lineColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}
