//
//  AreasOfLifeView.swift
//  Terrain
//
//  Expandable life area rows with terrain-specific tips
//

import SwiftUI

/// Displays expandable areas of life (Energy, Digestion, Sleep, Mood) with tips.
/// Each row expands to show personalized guidance based on terrain type.
struct AreasOfLifeView: View {
    let areas: [AreaOfLifeContent]

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            ForEach(areas) { area in
                AreaOfLifeRow(area: area)
            }
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

/// Individual expandable row for an area of life
struct AreaOfLifeRow: View {
    let area: AreaOfLifeContent

    @Environment(\.terrainTheme) private var theme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: {
                withAnimation(theme.animation.standard) {
                    isExpanded.toggle()
                }
                HapticManager.light()
            }) {
                HStack {
                    // Icon
                    Image(systemName: area.type.icon)
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.accent)
                        .frame(width: 24)

                    // Title
                    Text(area.type.displayName)
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    // Tips
                    ForEach(area.tips.prefix(3), id: \.self) { tip in
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundColor(theme.colors.accent)
                                .padding(.top, 6)

                            Text(tip)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }

                    // TCM note (if present)
                    if let tcmNote = area.tcmNote {
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 10))
                                .foregroundColor(theme.colors.success)
                                .padding(.top, 2)

                            Text(tcmNote)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                                .italic()
                        }
                        .padding(.top, theme.spacing.xs)
                    }
                }
                .padding(.top, theme.spacing.sm)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

#Preview {
    AreasOfLifeView(
        areas: [
            AreaOfLifeContent(
                type: .energyFocus,
                tips: [
                    "Start with warm water before anything else",
                    "Eat breakfast within an hour of waking",
                    "Short walks, not intense cardio"
                ],
                tcmNote: "Qi and Yang need building. Gentle support over pushing."
            ),
            AreaOfLifeContent(
                type: .digestion,
                tips: [
                    "Cooked and warm foods digest best",
                    "Avoid cold drinks with meals",
                    "Ginger aids your digestion"
                ],
                tcmNote: "The Spleen transforms food into energy. Support it with appropriate temperature and texture."
            ),
            AreaOfLifeContent(
                type: .sleepWindDown,
                tips: [
                    "Warm feet before bed helps sleep",
                    "Earlier bedtime replenishes",
                    "Keep bedroom cozy but ventilated"
                ],
                tcmNote: nil
            ),
            AreaOfLifeContent(
                type: .moodStress,
                tips: [
                    "Low mood often follows low energy",
                    "Warmth and nourishment lift spirits",
                    "Be gentle with yourself today"
                ],
                tcmNote: nil
            )
        ]
    )
    .padding(.vertical, 40)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
