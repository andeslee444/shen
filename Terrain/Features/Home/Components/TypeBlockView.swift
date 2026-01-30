//
//  TypeBlockView.swift
//  Terrain
//
//  Displays user's terrain type as identity chips
//

import SwiftUI

/// Shows the user's terrain type broken into Temperature, Reserve, and optional Modifier chips.
/// Example: [Neutral] [Low] [Damp]
struct TypeBlockView: View {
    let components: TypeBlockComponents

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Your Type")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textSecondary)

            HStack(spacing: theme.spacing.xs) {
                // Temperature chip
                TypeChip(
                    label: components.temperature.rawValue,
                    color: temperatureColor
                )

                // Reserve chip
                TypeChip(
                    label: components.reserve.rawValue,
                    color: reserveColor
                )

                // Modifier chip (if present)
                if let modifier = components.modifier {
                    TypeChip(
                        label: modifier.rawValue,
                        color: modifierColor
                    )
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
    }

    private var temperatureColor: Color {
        switch components.temperature {
        case .cold:
            return theme.colors.terrainCool
        case .neutral:
            return theme.colors.terrainNeutral
        case .warm:
            return theme.colors.terrainWarm
        }
    }

    private var reserveColor: Color {
        switch components.reserve {
        case .low:
            return theme.colors.warning
        case .balanced:
            return theme.colors.success
        case .high:
            return theme.colors.info
        }
    }

    private var modifierColor: Color {
        guard let modifier = components.modifier else { return theme.colors.textTertiary }
        switch modifier {
        case .damp:
            return theme.colors.terrainCool
        case .dry:
            return theme.colors.terrainWarm
        case .stagnation:
            return theme.colors.warning
        case .shen:
            return theme.colors.info
        }
    }
}

/// Individual chip for type display
struct TypeChip: View {
    let label: String
    let color: Color

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Text(label)
            .font(theme.typography.labelSmall)
            .foregroundColor(color)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xxs)
            .background(color.opacity(0.12))
            .cornerRadius(theme.cornerRadius.full)
    }
}

#Preview {
    VStack(spacing: 24) {
        TypeBlockView(
            components: TypeBlockComponents(
                temperature: .neutral,
                reserve: .low,
                modifier: .damp
            )
        )

        TypeBlockView(
            components: TypeBlockComponents(
                temperature: .cold,
                reserve: .balanced,
                modifier: nil
            )
        )

        TypeBlockView(
            components: TypeBlockComponents(
                temperature: .warm,
                reserve: .high,
                modifier: .shen
            )
        )
    }
    .padding(.vertical, 40)
    .frame(maxWidth: .infinity)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
