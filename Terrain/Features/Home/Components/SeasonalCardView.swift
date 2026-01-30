//
//  SeasonalCardView.swift
//  Terrain
//
//  Seasonal guidance card for the Home tab.
//  Shows a terrain-specific note about the current TCM season
//  with expandable tips.
//

import SwiftUI

/// Displays a seasonal awareness card with an icon, note, and expandable tips.
/// Content is personalized to the user's terrain type and current season.
struct SeasonalCardView: View {
    let content: SeasonalNoteContent

    @Environment(\.terrainTheme) private var theme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Header row: icon + season label
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: content.icon)
                    .font(.system(size: 20))
                    .foregroundColor(theme.colors.accent)

                Text("\(content.season) note")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textSecondary)

                Spacer()

                // Expand/collapse chevron
                if !content.tips.isEmpty {
                    Button(action: {
                        withAnimation(theme.animation.standard) {
                            isExpanded.toggle()
                        }
                        HapticManager.light()
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Note body
            Text(content.note)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineSpacing(4)

            // Expandable tips
            if isExpanded && !content.tips.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(content.tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Text("·")
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.accent)
                            Text(tip)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                }
                .padding(.top, theme.spacing.xxs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .padding(.horizontal, theme.spacing.lg)
    }
}

#Preview {
    VStack(spacing: 24) {
        SeasonalCardView(
            content: SeasonalNoteContent(
                season: "Winter",
                icon: "snowflake",
                note: "Winter amplifies your cold pattern. Your body works harder to stay warm. Favor soups, stews, and root vegetables. This is your most important season for warm starts.",
                tips: [
                    "Choose cooked breakfasts over cold cereals",
                    "Warm your core with ginger tea in the afternoon",
                    "Layer clothing — your extremities lose heat quickly"
                ]
            )
        )

        SeasonalCardView(
            content: SeasonalNoteContent(
                season: "Summer",
                icon: "sun.max",
                note: "Summer naturally balances your cool tendency. Enjoy moderate warmth but don't overcorrect with too much spice.",
                tips: [
                    "Room temperature water is fine in summer",
                    "Light soups replace heavy stews"
                ]
            )
        )
    }
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
