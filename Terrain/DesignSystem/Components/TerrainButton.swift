//
//  TerrainButton.swift
//  Terrain
//
//  Button styles for Terrain app
//

import SwiftUI

// MARK: - Primary Button

struct TerrainPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textInverted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(isEnabled ? theme.colors.accent : theme.colors.textTertiary)
                .cornerRadius(theme.cornerRadius.large)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button

struct TerrainSecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.labelLarge)
                .foregroundColor(isEnabled ? theme.colors.accent : theme.colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                        .stroke(isEnabled ? theme.colors.accent : theme.colors.textTertiary, lineWidth: 1)
                )
                .cornerRadius(theme.cornerRadius.large)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Text Button

struct TerrainTextButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.accent)
        }
    }
}

// MARK: - Chip Button

struct TerrainChip: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    chipContent
                }
            } else {
                chipContent
            }
        }
    }

    private var chipContent: some View {
        Text(title)
            .font(theme.typography.labelSmall)
            .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.textSecondary)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xxs)
            .background(isSelected ? theme.colors.accent : theme.colors.backgroundSecondary)
            .cornerRadius(theme.cornerRadius.full)
    }
}

// MARK: - Icon Button

struct TerrainIconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 24

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.6))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: 16) {
        TerrainPrimaryButton(title: "Continue", action: {})
        TerrainSecondaryButton(title: "Skip", action: {})
        TerrainTextButton(title: "Learn more", action: {})

        HStack {
            TerrainChip(title: "Sleep", isSelected: true)
            TerrainChip(title: "Energy", isSelected: false)
            TerrainChip(title: "Digestion", isSelected: false)
        }
    }
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
