//
//  TerrainHeroHeaderView.swift
//  Terrain
//
//  Colorful hero header for the You tab — gradient background,
//  type label, nickname with glow, and modifier chip.
//

import SwiftUI

struct TerrainHeroHeaderView: View {
    let terrainType: TerrainScoringEngine.PrimaryType
    let modifier: TerrainScoringEngine.Modifier

    @Environment(\.terrainTheme) private var theme

    /// Terrain-specific glow color
    private var terrainGlowColor: Color {
        switch terrainType {
        case .coldDeficient, .coldBalanced:
            return theme.colors.terrainCool
        case .warmDeficient, .warmBalanced, .warmExcess:
            return theme.colors.terrainWarm
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            return theme.colors.terrainNeutral
        }
    }

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Text("YOUR TERRAIN")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .tracking(3)

            Text(terrainType.label)
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.textPrimary)

            Text(terrainType.nickname)
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.accent)
                .shadow(color: terrainGlowColor.opacity(0.4), radius: 8)

            if modifier != .none {
                TerrainChip(title: modifier.displayName, isSelected: true)
            }

            Text(CommunityStats.normalizationText(for: terrainType.terrainProfileId))
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .padding(.top, theme.spacing.xxs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, theme.spacing.xl)
        .background(
            RadialGradient(
                gradient: Gradient(colors: [
                    terrainGlowColor.opacity(0.15),
                    Color.clear
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
        )
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.xl)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}
