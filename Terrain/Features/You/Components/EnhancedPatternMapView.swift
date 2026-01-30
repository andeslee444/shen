//
//  EnhancedPatternMapView.swift
//  Terrain
//
//  Merged constitution readout + pattern map — shows each axis
//  with its label, value text, slider bar, and expandable tooltip.
//  Replaces both ConstitutionCardView and PatternMapView.
//

import SwiftUI

struct EnhancedPatternMapView: View {
    let readout: ConstitutionReadout
    let vector: TerrainVector

    @Environment(\.terrainTheme) private var theme
    @State private var activeTooltipIndex: Int?
    @State private var appeared = false

    private struct AxisConfig {
        let leftLabel: String
        let rightLabel: String
        let value: Int
        let minVal: Int
        let maxVal: Int
    }

    private var axisConfigs: [AxisConfig] {
        [
            AxisConfig(leftLabel: "Cold", rightLabel: "Hot", value: vector.coldHeat, minVal: -10, maxVal: 10),
            AxisConfig(leftLabel: "Deficient", rightLabel: "Excess", value: vector.defExcess, minVal: -10, maxVal: 10),
            AxisConfig(leftLabel: "Damp", rightLabel: "Dry", value: vector.dampDry, minVal: -10, maxVal: 10),
            AxisConfig(leftLabel: "Stagnant", rightLabel: "Smooth", value: 10 - vector.qiStagnation, minVal: 0, maxVal: 10),
            AxisConfig(leftLabel: "Restless", rightLabel: "Settled", value: 10 - vector.shenUnsettled, minVal: 0, maxVal: 10)
        ]
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(Array(readout.axes.enumerated()), id: \.offset) { index, axis in
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    // Axis label + tooltip button
                    HStack {
                        Text(axis.label)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textTertiary)

                        Spacer()

                        Button {
                            withAnimation(theme.animation.quick) {
                                activeTooltipIndex = activeTooltipIndex == index ? nil : index
                            }
                            HapticManager.light()
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textTertiary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Value text from ConstitutionReadout
                    Text(axis.value)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    // Slider bar
                    if index < axisConfigs.count {
                        axisBar(axisConfigs[index])
                    }

                    // Expandable tooltip
                    if activeTooltipIndex == index {
                        Text(axis.tooltip)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(theme.spacing.sm)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius.medium)
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }

                if index < readout.axes.count - 1 {
                    Divider()
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .onAppear {
            withAnimation(theme.animation.standard) {
                appeared = true
            }
        }
    }

    // MARK: - Slider Bar

    private func axisBar(_ config: AxisConfig) -> some View {
        HStack {
            Text(config.leftLabel)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .frame(width: 64, alignment: .leading)

            GeometryReader { geo in
                let range = Double(config.maxVal - config.minVal)
                let normalized = range > 0
                    ? (Double(config.value - config.minVal) / range)
                    : 0.5
                let dotX = normalized * geo.size.width

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(theme.colors.backgroundSecondary)
                        .frame(height: 4)

                    // Center mark for bipolar axes
                    if config.minVal < 0 {
                        Rectangle()
                            .fill(theme.colors.textTertiary.opacity(0.3))
                            .frame(width: 1, height: 8)
                            .position(x: geo.size.width / 2, y: 4)
                    }

                    // Dot
                    Circle()
                        .fill(theme.colors.accent)
                        .frame(width: 10, height: 10)
                        .offset(x: appeared ? dotX - CGFloat(5) : (config.minVal < 0 ? geo.size.width / 2 - CGFloat(5) : CGFloat(-5)))
                        .animation(theme.animation.standard, value: appeared)
                }
                .frame(height: 10)
            }
            .frame(height: 10)

            Text(config.rightLabel)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .frame(width: 64, alignment: .trailing)
        }
    }
}
