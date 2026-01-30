//
//  EvolutionTrendsView.swift
//  Terrain
//
//  Section F: 14-day rolling trends with sparklines, symptom heatmap,
//  routine effectiveness, streak card, and calendar.
//

import SwiftUI

struct EvolutionTrendsView: View {
    let trends: [TrendResult]
    let routineScores: [(name: String, score: Double)]
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int
    let dailyLogs: [DailyLog]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Sparkline trends section
            trendsSection

            // Symptom heatmap
            SymptomHeatmapView(dailyLogs: dailyLogs)

            // Routine effectiveness (only show if there's data)
            if !routineScores.isEmpty {
                RoutineEffectivenessCard(routineScores: routineScores)
            }

            // Streak card
            StreakCard(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                totalCompletions: totalCompletions
            )

            // Calendar
            CalendarView(dailyLogs: dailyLogs)
        }
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("14-Day Trends")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if trends.isEmpty {
                // Empty state
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.textTertiary)

                    Text("Check in for a few more days to see your trends")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.lg)
            } else {
                ForEach(Array(trends.enumerated()), id: \.offset) { _, trend in
                    TrendSparklineCard(trend: trend)
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
