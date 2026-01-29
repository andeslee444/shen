//
//  ProgressView.swift
//  Terrain
//
//  Progress tab with streaks and calendar
//

import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.terrainTheme) private var theme
    @Query private var progressRecords: [ProgressRecord]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]
    @Query private var userProfiles: [UserProfile]

    private var progress: ProgressRecord? {
        progressRecords.first
    }

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    // Streak card
                    StreakCard(
                        currentStreak: progress?.currentStreak ?? 0,
                        longestStreak: progress?.longestStreak ?? 0,
                        totalCompletions: progress?.totalCompletions ?? 0
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                    // Calendar
                    CalendarView(dailyLogs: dailyLogs)
                        .padding(.horizontal, theme.spacing.lg)

                    // Terrain profile
                    if let profile = userProfile,
                       let terrainId = profile.terrainProfileId {
                        if let type = TerrainScoringEngine.PrimaryType(rawValue: terrainId) {
                            TerrainProfileCard(type: type)
                                .padding(.horizontal, theme.spacing.lg)
                        }
                    }

                    // Recent activity
                    RecentActivitySection(logs: Array(dailyLogs.prefix(7)))
                        .padding(.horizontal, theme.spacing.lg)

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack {
            // Current streak (large)
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

            // Stats
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
    }
}

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

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Month navigation
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

            // Day headers
            HStack {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: theme.spacing.xs) {
                // Leading empty cells
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Text("")
                        .frame(height: 36)
                }

                // Days
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
    }

    private var firstWeekdayOffset: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return 0
        }
        return calendar.component(.weekday, from: firstDay) - 1
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

struct CalendarDayCell: View {
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

struct TerrainProfileCard: View {
    let type: TerrainScoringEngine.PrimaryType

    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showRetakeConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Your Terrain")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.label)
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(type.nickname)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.accent)
                }

                Spacer()

                Button("Retake Quiz") {
                    showRetakeConfirmation = true
                }
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.accent)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .confirmationDialog(
            "Retake Quiz?",
            isPresented: $showRetakeConfirmation,
            titleVisibility: .visible
        ) {
            Button("Retake Quiz", role: .destructive) {
                retakeQuiz()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your terrain profile. Your progress and logged data will be preserved.")
        }
    }

    private func retakeQuiz() {
        // Delete the current user profile so a new one is created during onboarding
        let fetchDescriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? modelContext.fetch(fetchDescriptor) {
            for profile in profiles {
                modelContext.delete(profile)
            }
            try? modelContext.save()
        }

        // Reset onboarding flag to trigger the onboarding flow
        hasCompletedOnboarding = false
    }
}

struct RecentActivitySection: View {
    let logs: [DailyLog]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Recent Activity")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if logs.isEmpty {
                Text("No recent activity")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, theme.spacing.lg)
            } else {
                ForEach(logs) { log in
                    ActivityRow(log: log)
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

struct ActivityRow: View {
    let log: DailyLog

    @Environment(\.terrainTheme) private var theme

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: log.date)
    }

    var body: some View {
        HStack {
            Image(systemName: log.hasCompletedRoutine ? "checkmark.circle.fill" : "circle")
                .foregroundColor(log.hasCompletedRoutine ? theme.colors.success : theme.colors.textTertiary)

            Text(dateString)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)

            Spacer()

            if let level = log.routineLevel {
                TerrainChip(title: level.displayName, isSelected: false)
            }
        }
    }
}

#Preview {
    ProgressTabView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
