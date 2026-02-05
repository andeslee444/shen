//
//  ActivityLogCard.swift
//  Terrain
//
//  Shows activity minutes tracking: routine (food/drink) vs movement time.
//  Stacked bar chart with 14-day breakdown and TCM insight.
//

import SwiftUI

struct ActivityLogCard: View {
    let activityMinutes: ActivityMinutesResult
    let terrainType: TerrainScoringEngine.PrimaryType?
    let modifier: TerrainScoringEngine.Modifier

    @Environment(\.terrainTheme) private var theme

    /// Color for routine activities (food/drink) — warm brown
    private var routineColor: Color {
        theme.colors.accent
    }

    /// Color for movement activities — cool blue-grey
    private var movementColor: Color {
        theme.colors.info
    }

    /// Maximum daily minutes for scaling the bars
    private var maxDailyMinutes: Double {
        let dailyTotals = zip(activityMinutes.routineMinutes, activityMinutes.movementMinutes)
            .map { $0 + $1 }
        return max(dailyTotals.max() ?? 30, 30) // Minimum 30 for reasonable scaling
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)
                Text("Activity Time")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
            }

            // Summary stats
            HStack(spacing: theme.spacing.lg) {
                statBadge(
                    value: Int(activityMinutes.totalRoutineMinutes),
                    label: "min routines",
                    color: routineColor
                )
                statBadge(
                    value: Int(activityMinutes.totalMovementMinutes),
                    label: "min movement",
                    color: movementColor
                )
            }

            // Stacked bar chart
            stackedBarChart

            // Legend
            HStack(spacing: theme.spacing.lg) {
                legendItem(color: routineColor, label: "Food & Drink")
                legendItem(color: movementColor, label: "Movement")
            }

            // TCM insight (terrain-specific)
            if let insight = terrainInsight {
                Text(insight)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.top, theme.spacing.xs)
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Subviews

    private func statBadge(value: Int, label: String, color: Color) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text("\(value)")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    private var stackedBarChart: some View {
        GeometryReader { geometry in
            let barWidth = (geometry.size.width - CGFloat(activityMinutes.windowDays - 1) * 2) / CGFloat(activityMinutes.windowDays)
            let maxHeight = geometry.size.height

            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<activityMinutes.windowDays, id: \.self) { day in
                    let routineHeight = minutesToHeight(activityMinutes.routineMinutes[day], maxHeight: maxHeight)
                    let movementHeight = minutesToHeight(activityMinutes.movementMinutes[day], maxHeight: maxHeight)

                    VStack(spacing: 0) {
                        // Movement (top of stack)
                        if movementHeight > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(movementColor)
                                .frame(width: barWidth, height: movementHeight)
                        }

                        // Routine (bottom of stack)
                        if routineHeight > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(routineColor)
                                .frame(width: barWidth, height: routineHeight)
                        }

                        // Empty day placeholder
                        if routineHeight == 0 && movementHeight == 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(theme.colors.textTertiary.opacity(0.2))
                                .frame(width: barWidth, height: 2)
                        }
                    }
                }
            }
        }
        .frame(height: 60)
    }

    private func minutesToHeight(_ minutes: Double, maxHeight: CGFloat) -> CGFloat {
        guard maxDailyMinutes > 0 else { return 0 }
        let ratio = minutes / maxDailyMinutes
        return max(CGFloat(ratio) * maxHeight, minutes > 0 ? 2 : 0) // Minimum 2pt for non-zero
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: theme.spacing.xxs) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
        }
    }

    // MARK: - Terrain Insight

    private var terrainInsight: String? {
        guard let type = terrainType else { return nil }

        let totalMinutes = activityMinutes.totalRoutineMinutes + activityMinutes.totalMovementMinutes
        let routineRatio = activityMinutes.totalRoutineMinutes / max(totalMinutes, 1)

        switch type {
        case .coldDeficient, .coldBalanced:
            if routineRatio > 0.7 {
                return "Warming rituals are your foundation. Good focus on nourishing routines."
            } else if activityMinutes.totalMovementMinutes > activityMinutes.totalRoutineMinutes {
                return "Cold types benefit from warming rituals more than intense movement."
            }
        case .neutralExcess:
            if activityMinutes.totalMovementMinutes < 30 {
                return "Excess energy needs more movement to stay balanced."
            } else {
                return "Movement helps channel your excess energy well."
            }
        case .warmExcess:
            if routineRatio > 0.8 {
                return "Balance warming routines with cooling movement."
            }
        case .warmDeficient:
            if activityMinutes.totalMovementMinutes > activityMinutes.totalRoutineMinutes * 2 {
                return "Your reserves are thin — balance movement with nourishing rest."
            }
        default:
            break
        }

        // Modifier-specific insights
        switch modifier {
        case .stagnation:
            if activityMinutes.totalMovementMinutes < 20 {
                return "Your stagnation pattern needs more movement to keep energy flowing."
            }
        case .damp:
            if activityMinutes.totalMovementMinutes > 30 {
                return "Good movement helps drain dampness from your system."
            }
        default:
            break
        }

        // Generic insight
        if totalMinutes < 30 {
            return "Small daily rituals add up. Even 5 minutes makes a difference."
        }

        return nil
    }
}

// MARK: - Preview

#Preview("With Data") {
    ActivityLogCard(
        activityMinutes: ActivityMinutesResult(
            routineMinutes: [5, 8, 12, 0, 6, 10, 15, 8, 5, 10, 12, 8, 6, 10],
            movementMinutes: [10, 5, 0, 8, 12, 5, 8, 10, 15, 8, 5, 10, 8, 12],
            totalRoutineMinutes: 115,
            totalMovementMinutes: 116,
            windowDays: 14
        ),
        terrainType: .coldDeficient,
        modifier: .shen
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Sparse Data") {
    ActivityLogCard(
        activityMinutes: ActivityMinutesResult(
            routineMinutes: [0, 0, 5, 0, 0, 8, 0, 0, 0, 10, 0, 0, 5, 0],
            movementMinutes: [0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 8, 0, 0],
            totalRoutineMinutes: 28,
            totalMovementMinutes: 18,
            windowDays: 14
        ),
        terrainType: .neutralExcess,
        modifier: .stagnation
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
