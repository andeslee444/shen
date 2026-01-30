//
//  CapsuleStartCTA.swift
//  Terrain
//
//  Level picker and CTA button to start the daily capsule
//

import SwiftUI

/// Bottom CTA that bridges Home tab to Do tab.
struct CapsuleStartCTA: View {
    let onStart: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: {
            HapticManager.light()
            onStart()
        }) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))

                Text("Start Your Capsule")
                    .font(theme.typography.labelLarge)
            }
            .foregroundColor(theme.colors.textInverted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(theme.colors.accent)
            .cornerRadius(theme.cornerRadius.large)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, theme.spacing.md)
    }
}

/// Scale animation button style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    CapsuleStartCTA(
        onStart: { print("Starting capsule") }
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
