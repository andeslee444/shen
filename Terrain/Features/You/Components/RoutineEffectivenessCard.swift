//
//  RoutineEffectivenessCard.swift
//  Terrain
//
//  Shows completed routines with their effectiveness scores.
//  Each routine gets a horizontal bar extending left (negative) or right (positive)
//  from center — like a balance scale showing whether it helped or not.
//

import SwiftUI

struct RoutineEffectivenessCard: View {
    let routineScores: [(name: String, score: Double)]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Routine Effectiveness")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if routineScores.isEmpty {
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.textTertiary)

                    Text("Complete routines over several days to see effectiveness data")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
            } else {
                ForEach(Array(routineScores.enumerated()), id: \.offset) { _, item in
                    EffectivenessRow(
                        name: item.name,
                        score: item.score
                    )
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Effectiveness Row

struct EffectivenessRow: View {
    let name: String
    let score: Double // -1.0 to +1.0

    @Environment(\.terrainTheme) private var theme

    private var barColor: Color {
        if score > 0.2 {
            return theme.colors.success
        } else if score < -0.2 {
            return theme.colors.warning
        } else {
            return theme.colors.textTertiary
        }
    }

    private var label: String {
        if score > 0.2 {
            return "Positive effect"
        } else if score < -0.2 {
            return "May not be ideal"
        } else {
            return "Neutral"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(name)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textPrimary)

            GeometryReader { geometry in
                let midX = geometry.size.width / 2
                let barWidth = abs(score) * midX

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.colors.backgroundSecondary)
                        .frame(height: 6)

                    // Center line
                    Rectangle()
                        .fill(theme.colors.textTertiary.opacity(0.3))
                        .frame(width: 1, height: 10)
                        .position(x: midX, y: 3)

                    // Score bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: barWidth, height: 6)
                        .offset(x: score >= 0 ? midX : midX - barWidth)
                }
            }
            .frame(height: 10)

            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(.vertical, theme.spacing.xxs)
    }
}
