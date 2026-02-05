//
//  EvolutionTrendsView.swift
//  Terrain
//
//  Section F: 14-day rolling trends with sparklines, symptom heatmap,
//  routine effectiveness, streak card, and calendar.
//  Enhanced with terrain-aware prioritization and TerrainPulseCard.
//

import SwiftUI

struct EvolutionTrendsView: View {
    let trends: [TrendResult]
    let annotatedTrends: [AnnotatedTrendResult]
    let routineScores: [(name: String, score: Double)]
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int
    let dailyLogs: [DailyLog]
    let terrainType: TerrainScoringEngine.PrimaryType?
    let modifier: TerrainScoringEngine.Modifier
    let terrainPulse: TerrainPulseInsight?
    let activityMinutes: ActivityMinutesResult?

    @Environment(\.terrainTheme) private var theme

    @AppStorage("hasDismissedTrendsIntro") private var hasDismissedTrendsIntro = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Terrain Pulse — hero insight card (Phase 13)
            if let pulse = terrainPulse, let type = terrainType {
                TerrainPulseCard(
                    insight: pulse,
                    terrainType: type,
                    modifier: modifier
                )
            }

            // Intro card for new users (only show if no pulse)
            if terrainPulse == nil && !hasDismissedTrendsIntro {
                trendsIntroCard
            }

            // Sparkline trends section — now terrain-prioritized
            trendsSection

            // Activity log card (Phase 13 — minutes tracking)
            if let activity = activityMinutes,
               activity.totalRoutineMinutes > 0 || activity.totalMovementMinutes > 0 {
                ActivityLogCard(
                    activityMinutes: activity,
                    terrainType: terrainType,
                    modifier: modifier
                )
            }

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

    private var trendsIntroCard: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(theme.colors.accent)
                    .font(.system(size: 16))
                Text("How Trends Work")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Button {
                    withAnimation(theme.animation.quick) {
                        hasDismissedTrendsIntro = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text("We track patterns from your daily check-ins. After a few days, you'll see trends emerge across sleep, digestion, stress, and more.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)

            HStack(spacing: theme.spacing.md) {
                Label("Green = improving", systemImage: "arrow.up.circle.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.success)
                Label("Orange = watch", systemImage: "arrow.down.circle.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.warning)
                Label("Gray = no data", systemImage: "minus.circle.fill")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("14-Day Trends")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                // Show terrain badge if personalized
                if terrainType != nil && !annotatedTrends.isEmpty {
                    Text("Prioritized for you")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }

            if trends.isEmpty && annotatedTrends.isEmpty {
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
            } else if !annotatedTrends.isEmpty {
                // Use terrain-prioritized annotated trends
                ForEach(annotatedTrends) { trend in
                    AnnotatedTrendCard(trend: trend)
                }
            } else {
                // Fallback to basic trends
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

// MARK: - Streak Card (formerly in ProgressView.swift)

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack {
            VStack {
                Text("\(currentStreak)")
                    .font(theme.typography.displayLarge)
                    .foregroundColor(theme.colors.accent)

                Text("day streak")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 60)

            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(theme.colors.warning)
                    Text("Longest: \(longestStreak) days")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.success)
                    Text("Total: \(totalCompletions) completions")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Calendar View (formerly in ProgressView.swift)

struct CalendarView: View {
    let dailyLogs: [DailyLog]

    @Environment(\.terrainTheme) private var theme
    @State private var selectedMonth = Date()

    private var calendar: Calendar { Calendar.current }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var firstWeekdayOffset: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return 0
        }
        return calendar.component(.weekday, from: firstDay) - 1
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Text(monthTitle)
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: theme.spacing.xs) {
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Text("")
                        .frame(height: 36)
                }

                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        isCompleted: hasCompletion(on: date),
                        isToday: calendar.isDateInToday(date)
                    )
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private func hasCompletion(on date: Date) -> Bool {
        let dayStart = calendar.startOfDay(for: date)
        return dailyLogs.contains { log in
            calendar.startOfDay(for: log.date) == dayStart && log.hasCompletedRoutine
        }
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        ZStack {
            if isCompleted {
                Circle()
                    .fill(theme.colors.success)
                    .frame(width: 32, height: 32)
            } else if isToday {
                Circle()
                    .strokeBorder(theme.colors.accent, lineWidth: 2)
                    .frame(width: 32, height: 32)
            }

            Text("\(Calendar.current.component(.day, from: date))")
                .font(theme.typography.bodySmall)
                .foregroundColor(isCompleted ? .white : (isToday ? theme.colors.accent : theme.colors.textPrimary))
        }
        .frame(height: 36)
    }
}
