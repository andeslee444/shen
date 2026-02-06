//
//  TypeBlockView.swift
//  Terrain
//
//  Displays user's terrain type as a friendly identity stripe with nickname
//

import SwiftUI

/// Shows the user's terrain type as a compact identity stripe:
/// "Your terrain · Low Flame" with optional modifier like "· Restless"
/// Uses nickname for emotional resonance rather than raw axis labels.
struct TypeBlockView: View {
    let components: TypeBlockComponents
    var onTap: () -> Void = {}

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button {
            HapticManager.light()
            onTap()
        } label: {
            HStack(spacing: theme.spacing.xs) {
                Text("Your terrain")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)

                Text("·")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)

                // Nickname badge (primary identity)
                TypeChip(
                    label: components.nickname,
                    color: nicknameColor
                )

                // Modifier badge (if present) — friendly name
                if let modifier = components.modifier {
                    TypeChip(
                        label: modifier.friendlyName,
                        color: modifierColor
                    )
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var nicknameColor: Color {
        switch components.temperature {
        case .cold:
            return theme.colors.terrainCool
        case .neutral:
            return theme.colors.terrainNeutral
        case .warm:
            return theme.colors.terrainWarm
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
                modifier: .damp,
                nickname: "Low Battery"
            )
        )

        TypeBlockView(
            components: TypeBlockComponents(
                temperature: .cold,
                reserve: .balanced,
                modifier: nil,
                nickname: "Cool Core"
            )
        )

        TypeBlockView(
            components: TypeBlockComponents(
                temperature: .warm,
                reserve: .high,
                modifier: .shen,
                nickname: "Overclocked"
            )
        )
    }
    .padding(.vertical, 40)
    .frame(maxWidth: .infinity)
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
