//
//  OnboardingCompleteView.swift
//  Terrain
//
//  "You're all set" completion screen at the end of onboarding.
//  Echoes the user's terrain nickname and provides a clear first action.
//

import SwiftUI

struct OnboardingCompleteView: View {
    let displayName: String?
    let terrainNickname: String
    let onStart: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.xxl) {
            Spacer()

            // Celebratory icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(theme.colors.success)
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)

            // Welcome message
            VStack(spacing: theme.spacing.md) {
                Text("You're all set")
                    .font(theme.typography.displayMedium)
                    .foregroundColor(theme.colors.textPrimary)

                Text(displayName != nil ? "Welcome, \(displayName!)" : "Welcome to Terrain")
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.colors.accent)

                Text("Your terrain: \(terrainNickname)")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 15)

            // Guidance
            Text("Your daily practice is ready \u{2014}\nfood, movement, and guidance,\npersonalized to your terrain.")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xl)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.2), value: showContent)

            Spacer()

            // Primary CTA
            TerrainPrimaryButton(title: "Start Today", action: onStart)
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.4), value: showContent)

            Spacer(minLength: theme.spacing.xl)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

#Preview {
    OnboardingCompleteView(
        displayName: "Andes",
        terrainNickname: "Low Flame",
        onStart: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
