//
//  TerrainCard.swift
//  Terrain
//
//  Card components for Terrain app
//

import SwiftUI

// MARK: - Basic Card

struct TerrainCard<Content: View>: View {
    let content: Content

    @Environment(\.terrainTheme) private var theme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Elevated Card

struct TerrainElevatedCard<Content: View>: View {
    let content: Content

    @Environment(\.terrainTheme) private var theme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(theme.spacing.lg)
            .background(theme.colors.surfaceElevated)
            .cornerRadius(theme.cornerRadius.xl)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 4)
    }
}

// MARK: - Routine Capsule Card

struct RoutineCapsuleCard: View {
    let title: String
    let subtitle: String?
    let duration: String
    let level: RoutineLevel
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    Text(title)
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    TerrainChip(title: level.displayName, isSelected: true)
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }

                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textTertiary)

                    Text(duration)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Ingredient Chip

struct IngredientChip: View {
    let name: String
    var isInCabinet: Bool = false
    var onTap: (() -> Void)? = nil

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: onTap) {
                    chipContent
                }
            } else {
                chipContent
            }
        }
    }

    private var chipContent: some View {
        HStack(spacing: theme.spacing.xxs) {
            Text(name)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textPrimary)

            if isInCabinet {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.success)
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xxs)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.cornerRadius.full)
    }
}

// MARK: - Progress Card

struct ProgressCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        TerrainCard {
            HStack(spacing: theme.spacing.lg) {
                VStack {
                    Text("\(currentStreak)")
                        .font(theme.typography.displayMedium)
                        .foregroundColor(theme.colors.accent)
                    Text("Current")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(longestStreak)")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Longest")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(totalCompletions)")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Total")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Previews

#Preview("Cards") {
    ScrollView {
        VStack(spacing: 16) {
            TerrainCard {
                Text("Basic Card Content")
            }

            RoutineCapsuleCard(
                title: "Warm Start Congee",
                subtitle: "Gentle warmth for your morning",
                duration: "10 min",
                level: .full,
                onTap: {}
            )

            HStack {
                IngredientChip(name: "Ginger", isInCabinet: true)
                IngredientChip(name: "Red Dates")
                IngredientChip(name: "Goji Berries")
            }

            ProgressCard(
                currentStreak: 7,
                longestStreak: 14,
                totalCompletions: 42
            )
        }
        .padding()
    }
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
