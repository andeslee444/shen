//
//  DefaultsView.swift
//  Terrain
//
//  Section D: Stable baseline do/don't guidance for the user's terrain type.
//

import SwiftUI

struct DefaultsView: View {
    let defaults: DefaultsContent

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Your Defaults")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            // Best defaults
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Best defaults for you")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textSecondary)

                ForEach(defaults.bestDefaults, id: \.self) { item in
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Circle()
                            .fill(theme.colors.success)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(item)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
            }

            Divider()

            // Avoid defaults
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Avoid when off-balance")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textSecondary)

                ForEach(defaults.avoidDefaults, id: \.self) { item in
                    HStack(alignment: .top, spacing: theme.spacing.sm) {
                        Circle()
                            .fill(theme.colors.warning)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(item)
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
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
}
