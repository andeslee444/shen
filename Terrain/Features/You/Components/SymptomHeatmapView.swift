//
//  SymptomHeatmapView.swift
//  Terrain
//
//  A 7x14 grid (7 symptom categories x 14 days), like GitHub's contribution chart.
//  Each cell is colored by whether the symptom was reported that day.
//  This gives a bird's-eye view of symptom patterns over the past two weeks.
//

import SwiftUI

struct SymptomHeatmapView: View {
    let dailyLogs: [DailyLog]
    var windowDays: Int = 14

    @Environment(\.terrainTheme) private var theme

    /// The symptom categories we track, in display order
    private let categories: [(label: String, symptom: QuickSymptom, icon: String)] = [
        ("Sleep", .poorSleep, "moon.zzz"),
        ("Digestion", .bloating, "stomach"),
        ("Stress", .stressed, "brain.head.profile"),
        ("Tired", .tired, "battery.25"),
        ("Headache", .headache, "head.profile"),
        ("Cramps", .cramps, "waveform.path"),
        ("Stiff", .stiff, "figure.walk")
    ]

    /// Column headers: abbreviated day labels
    private var dayLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            return String(formatter.string(from: date).prefix(1))
        }
    }

    /// Pre-computed map: (symptom, dayIndex) → had symptom?
    private func hasSymptom(_ symptom: QuickSymptom, onDayIndex dayIndex: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - dayIndex), to: today) else {
            return false
        }
        let dayStart = calendar.startOfDay(for: targetDay)

        return dailyLogs.contains { log in
            calendar.startOfDay(for: log.date) == dayStart && log.quickSymptoms.contains(symptom)
        }
    }

    /// Whether we have any log data for a given day index
    private func hasData(onDayIndex dayIndex: Int) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - dayIndex), to: today) else {
            return false
        }
        let dayStart = calendar.startOfDay(for: targetDay)

        return dailyLogs.contains { calendar.startOfDay(for: $0.date) == dayStart }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Symptom Heatmap")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if dailyLogs.isEmpty {
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.textTertiary)

                    Text("Check in daily to build your symptom pattern map")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
            } else {
                VStack(spacing: 2) {
                    // Day column headers
                    HStack(spacing: 2) {
                        // Spacer for row label column
                        Color.clear
                            .frame(width: 60, height: 12)

                        ForEach(0..<windowDays, id: \.self) { dayIndex in
                            Text(dayLabels[dayIndex])
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(theme.colors.textTertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // Grid rows
                    ForEach(Array(categories.enumerated()), id: \.offset) { _, category in
                        HStack(spacing: 2) {
                            // Row label
                            HStack(spacing: 2) {
                                Image(systemName: category.icon)
                                    .font(.system(size: 8))
                                Text(category.label)
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(theme.colors.textTertiary)
                            .frame(width: 60, alignment: .leading)

                            // Cells
                            ForEach(0..<windowDays, id: \.self) { dayIndex in
                                let hasData = hasData(onDayIndex: dayIndex)
                                let hasSymptom = hasSymptom(category.symptom, onDayIndex: dayIndex)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellColor(hasData: hasData, hasSymptom: hasSymptom))
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    private func cellColor(hasData: Bool, hasSymptom: Bool) -> Color {
        if !hasData {
            return theme.colors.backgroundSecondary.opacity(0.5) // no data = very faint
        }
        if hasSymptom {
            return theme.colors.warning.opacity(0.6) // symptom present = warm highlight
        }
        return theme.colors.success.opacity(0.2) // no symptom = gentle green
    }
}
