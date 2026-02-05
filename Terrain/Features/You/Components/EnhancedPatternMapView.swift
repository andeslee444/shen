//
//  EnhancedPatternMapView.swift
//  Terrain
//
//  Colorful pattern map matching the onboarding "How It Works" style.
//  Shows each axis with emoji, gradient bar, and user's position.
//

import SwiftUI

struct EnhancedPatternMapView: View {
    let readout: ConstitutionReadout
    let vector: TerrainVector

    @Environment(\.terrainTheme) private var theme
    @State private var appeared = false

    // MARK: - Axis Configuration

    private struct AxisDisplay {
        let emoji: String
        let label: String
        let leftLabel: String
        let rightLabel: String
        let leftColor: Color
        let rightColor: Color
        let value: Int
        let minVal: Int
        let maxVal: Int
    }

    private var axes: [AxisDisplay] {
        [
            AxisDisplay(
                emoji: "🌡️",
                label: "Temperature",
                leftLabel: "Cold",
                rightLabel: "Hot",
                leftColor: Color(hex: "7A8E9E"),
                rightColor: Color(hex: "C9956E"),
                value: vector.coldHeat,
                minVal: -10,
                maxVal: 10
            ),
            AxisDisplay(
                emoji: "🔋",
                label: "Energy",
                leftLabel: "Depleted",
                rightLabel: "Full",
                leftColor: Color(hex: "9E9E8E"),
                rightColor: Color(hex: "7A9E7E"),
                value: vector.defExcess,
                minVal: -10,
                maxVal: 10
            ),
            AxisDisplay(
                emoji: "💧",
                label: "Moisture",
                leftLabel: "Damp",
                rightLabel: "Dry",
                leftColor: Color(hex: "6B8FA3"),
                rightColor: Color(hex: "C9A96E"),
                value: vector.dampDry,
                minVal: -10,
                maxVal: 10
            ),
            AxisDisplay(
                emoji: "🌊",
                label: "Flow",
                leftLabel: "Stuck",
                rightLabel: "Free",
                leftColor: Color(hex: "A07A7A"),
                rightColor: Color(hex: "7A9E7E"),
                value: 10 - vector.qiStagnation,
                minVal: 0,
                maxVal: 10
            ),
            AxisDisplay(
                emoji: "🧠",
                label: "Mind",
                leftLabel: "Restless",
                rightLabel: "Settled",
                leftColor: Color(hex: "B08EA0"),
                rightColor: Color(hex: "7A8E9E"),
                value: 10 - vector.shenUnsettled,
                minVal: 0,
                maxVal: 10
            )
        ]
    }

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(Array(axes.enumerated()), id: \.offset) { index, axis in
                axisRow(axis)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(theme.animation.standard.delay(0.2)) {
                appeared = true
            }
        }
    }

    // MARK: - Axis Row

    private func axisRow(_ axis: AxisDisplay) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Emoji + label
            HStack(spacing: theme.spacing.xs) {
                Text(axis.emoji)
                    .font(.system(size: 18))
                Text(axis.label)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textPrimary)
            }

            // Gradient bar with position indicator
            GeometryReader { geo in
                let range = Double(axis.maxVal - axis.minVal)
                let normalized = range > 0
                    ? (Double(axis.value - axis.minVal) / range)
                    : 0.5
                let clampedNormalized = min(max(normalized, 0), 1)
                let dotX = clampedNormalized * geo.size.width

                ZStack(alignment: .leading) {
                    // Gradient track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [axis.leftColor, axis.rightColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)

                    // Position indicator (white dot with shadow)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: appeared ? dotX - CGFloat(8) : (axis.minVal < 0 ? geo.size.width / 2 - CGFloat(8) : CGFloat(-8)))
                        .animation(theme.animation.spring, value: appeared)
                }
                .frame(height: 16)
            }
            .frame(height: 16)

            // Axis labels
            HStack {
                Text(axis.leftLabel)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                Spacer()
                Text(axis.rightLabel)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}
