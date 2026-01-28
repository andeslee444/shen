//
//  WelcomeView.swift
//  Terrain
//
//  Welcome screen for onboarding
//

import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.xxl) {
            Spacer()

            // Logo/Title
            VStack(spacing: theme.spacing.md) {
                Text("Terrain")
                    .font(theme.typography.displayLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Your body has a climate.")
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            // Subtitle
            VStack(spacing: theme.spacing.sm) {
                Text("Discover your terrain and get")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textSecondary)

                Text("personalized daily rituals")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textSecondary)

                Text("rooted in Traditional Chinese Medicine.")
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .multilineTextAlignment(.center)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(theme.animation.reveal.delay(0.2), value: showContent)

            Spacer()

            // Features
            VStack(spacing: theme.spacing.md) {
                FeatureRow(
                    icon: "person.fill.viewfinder",
                    title: "Know your terrain",
                    description: "3-minute assessment"
                )

                FeatureRow(
                    icon: "sun.horizon.fill",
                    title: "Daily rituals",
                    description: "Personalized eat, drink, move"
                )

                FeatureRow(
                    icon: "leaf.fill",
                    title: "Build your cabinet",
                    description: "Simple, accessible ingredients"
                )
            }
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.reveal.delay(0.4), value: showContent)

            Spacer()

            // Continue button
            TerrainPrimaryButton(title: "Begin", action: onContinue)
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.6), value: showContent)

            // Terms
            Text("By continuing, you agree to our Terms of Service")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.reveal.delay(0.6), value: showContent)
        }
        .padding(theme.spacing.lg)
        .onAppear {
            withAnimation(theme.animation.reveal) {
                showContent = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.colors.accent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Text(description)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, theme.spacing.md)
    }
}

#Preview {
    WelcomeView(onContinue: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
