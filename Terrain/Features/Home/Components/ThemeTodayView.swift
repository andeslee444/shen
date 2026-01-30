//
//  ThemeTodayView.swift
//  Terrain
//
//  Concluding theme/message for the day on Home tab
//

import SwiftUI

/// Displays the concluding theme for the day - a reflective paragraph
/// that ties together the day's guidance into a cohesive message.
struct ThemeTodayView: View {
    let content: ThemeTodayContent

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(content.title)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textSecondary)

            Text(content.body)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineSpacing(4)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .padding(.horizontal, theme.spacing.lg)
    }
}

#Preview {
    VStack(spacing: 24) {
        ThemeTodayView(
            content: ThemeTodayContent(
                body: "Warmth is your foundation. Every warm drink, every cooked meal, every gentle movement is building something. Trust the slow accumulation."
            )
        )

        ThemeTodayView(
            content: ThemeTodayContent(
                title: "Your theme today",
                body: "Today is about restoration, not achievement. Your body is asking for gentleness. Trust that rest is productive, and pace yourself with compassion."
            )
        )
    }
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
