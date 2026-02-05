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
    @State private var showingTerms = false
    @State private var showingPrivacy = false

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            // Top spacer — roughly 1/5 of screen so content sits
            // in the upper-center, not dead-center or pushed down.
            Spacer()
                .frame(maxHeight: 120)

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

            // Value prop — names the mechanism and the outputs
            Text("Not every body needs the same thing.\nSome run cold and need warmth.\nSome run hot and need cooling.\nSome hold tension and need release.")
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                .animation(theme.animation.reveal.delay(0.2), value: showContent)

            // What you'll get — specific outputs
            VStack(spacing: theme.spacing.md) {
                featureRow(emoji: "\u{1F321}\u{FE0F}", text: "Learn if you run cold, warm, or neutral")
                featureRow(emoji: "\u{1F375}", text: "Get food and drink combos matched to you")
                featureRow(emoji: "\u{1F9D8}", text: "Follow movements and rituals for your type")
            }
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(theme.animation.reveal.delay(0.4), value: showContent)

            // Flexible gap — absorbs remaining space between content and button
            Spacer()

            // Continue button + terms pinned near bottom
            VStack(spacing: theme.spacing.sm) {
                TerrainPrimaryButton(title: "Begin", action: onContinue)
                    .padding(.horizontal, theme.spacing.lg)

                HStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                    Text("Terms")
                        .underline()
                        .onTapGesture {
                            showingTerms = true
                            HapticManager.light()
                        }
                    Text("and")
                    Text("Privacy Policy")
                        .underline()
                        .onTapGesture {
                            showingPrivacy = true
                            HapticManager.light()
                        }
                }
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
            }
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.reveal.delay(0.6), value: showContent)
        }
        .sheet(isPresented: $showingTerms) {
            SafariView(url: LegalURLs.termsOfService)
        }
        .sheet(isPresented: $showingPrivacy) {
            SafariView(url: LegalURLs.privacyPolicy)
        }
        .padding(.horizontal, theme.spacing.lg)
        .padding(.bottom, theme.spacing.lg)
        .onAppear {
            withAnimation(theme.animation.reveal) {
                showContent = true
            }
        }
    }
    private func featureRow(emoji: String, text: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Text(emoji)
                .font(.title3)
                .frame(width: 28)
            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    WelcomeView(onContinue: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
