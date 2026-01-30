//
//  TerrainIdentityView.swift
//  Terrain
//
//  Surfaces the Superpower, Trap, Signature Ritual, and Truths
//  from the terrain reveal — now visible on the You tab.
//  Reuses TerrainRevealCard from TerrainRevealView.
//

import SwiftUI

struct TerrainIdentityView: View {
    let terrainCopy: TerrainCopy

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Identity cards
            TerrainRevealCard(
                icon: "sparkles",
                title: "Your Superpower",
                content: terrainCopy.superpower
            )

            TerrainRevealCard(
                icon: "exclamationmark.triangle",
                title: "Your Trap",
                content: terrainCopy.trap
            )

            TerrainRevealCard(
                icon: "sun.horizon",
                title: "Your Signature Ritual",
                content: terrainCopy.signatureRitual
            )

            // Truths section
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Truths about you")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)

                ForEach(Array(terrainCopy.truths.enumerated()), id: \.offset) { _, truth in
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Circle()
                            .fill(theme.colors.accent)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)

                        Text(truth)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
    }
}
