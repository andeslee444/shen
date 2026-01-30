//
//  TerrainButton.swift
//  Terrain
//
//  Button styles for Terrain app with micro-animations and haptic feedback
//

import SwiftUI

// MARK: - Primary Button

struct TerrainPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textInverted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .background(isEnabled ? theme.colors.accent : theme.colors.textTertiary)
                .cornerRadius(theme.cornerRadius.large)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Double tap to \(title.lowercased())" : "Button disabled")
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Secondary Button

struct TerrainSecondaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
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
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Double tap to \(title.lowercased())" : "Button disabled")
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Text Button

struct TerrainTextButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Text(title)
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.accent)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .opacity(isPressed ? 0.8 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Chip Button

struct TerrainChip: View {
    let title: String
    var isSelected: Bool = false
    var action: (() -> Void)? = nil

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Group {
            if let action = action {
                Button {
                    HapticManager.selection()
                    action()
                } label: {
                    chipContent
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(theme.animation.quick, value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
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
            .accessibilityLabel(title)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Icon Button

struct TerrainIconButton: View {
    let systemName: String
    let action: () -> Void
    var size: CGFloat = 24

    @Environment(\.terrainTheme) private var theme
    @State private var isPressed = false

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size * 0.6))
                .foregroundColor(theme.colors.textSecondary)
                .frame(width: size, height: size)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(theme.animation.quick, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
