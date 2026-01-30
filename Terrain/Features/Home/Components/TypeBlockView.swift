//
//  TypeBlockView.swift
//  Terrain
//
//  Displays user's terrain type as a single-line identity stripe
//

import SwiftUI

/// Shows the user's terrain type as a compact single-line stripe:
/// "Your terrain · [warm] [balanced] [shen]"
/// Pill-shaped badges differentiate from the rectangular symptom chips in check-in.
struct TypeBlockView: View {
    let components: TypeBlockComponents

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Text("Your terrain")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)

            Text("·")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)

            // Temperature badge
            TypeChip(
                label: components.temperature.rawValue.lowercased(),
                color: temperatureColor
            )

            // Reserve badge
            TypeChip(
                label: components.reserve.rawValue.lowercased(),
                color: reserveColor
            )

            // Modifier badge (if present)
            if let modifier = components.modifier {
                TypeChip(
                    label: modifier.rawValue.lowercased(),
                    color: modifierColor
                )
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

/// Individual pill badge for type display — pill shape (cornerRadius.full) to differentiate
/// from the rectangular symptom chips in InlineCheckInView.
struct TypeChip: View {
    let label: String
    let color: Color

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Text(label)
            .font(theme.typography.caption)
            .foregroundColor(color)
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, 2)
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
