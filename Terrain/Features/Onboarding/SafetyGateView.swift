//
//  SafetyGateView.swift
//  Terrain
//
//  Safety preferences screen for onboarding
//

import SwiftUI

struct SafetyGateView: View {
    @Binding var preferences: SafetyPreferences
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Back + Skip
            HStack {
                Button(action: onBack) {
                    HStack(spacing: theme.spacing.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("Back")
                            .font(theme.typography.labelMedium)
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
                Spacer()
                TerrainTextButton(title: "Skip", action: onSkip)
            }
            .padding(.horizontal, theme.spacing.md)

            // Title — warm and reassuring
            VStack(spacing: theme.spacing.sm) {
                Text("Help us keep things safe")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("We'll adjust recommendations if any of these apply.")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("This is optional — you can always update in Settings.")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)

            // Options — grouped by category
            ScrollView {
                VStack(spacing: theme.spacing.md) {
                    // Pregnancy & nursing
                    SafetySectionLabel(title: "Pregnancy & Nursing")

                    SafetyOptionRow(
                        title: "Pregnant",
                        isSelected: preferences.isPregnant,
                        onToggle: { preferences.isPregnant.toggle() }
                    )

                    SafetyOptionRow(
                        title: "Breastfeeding",
                        isSelected: preferences.isBreastfeeding,
                        onToggle: { preferences.isBreastfeeding.toggle() }
                    )

                    // Medications
                    SafetySectionLabel(title: "Medications")

                    SafetyOptionRow(
                        title: "Taking blood thinners",
                        isSelected: preferences.takesBloodThinners,
                        onToggle: { preferences.takesBloodThinners.toggle() }
                    )

                    SafetyOptionRow(
                        title: "Taking blood pressure meds",
                        isSelected: preferences.takesBpMeds,
                        onToggle: { preferences.takesBpMeds.toggle() }
                    )

                    SafetyOptionRow(
                        title: "Taking thyroid meds",
                        isSelected: preferences.takesThyroidMeds,
                        onToggle: { preferences.takesThyroidMeds.toggle() }
                    )

                    SafetyOptionRow(
                        title: "Taking diabetes meds",
                        isSelected: preferences.takesDiabetesMeds,
                        onToggle: { preferences.takesDiabetesMeds.toggle() }
                    )

                    // Dietary
                    SafetySectionLabel(title: "Dietary")

                    SafetyOptionRow(
                        title: "Acid reflux / GERD",
                        isSelected: preferences.hasGerd,
                        onToggle: { preferences.hasGerd.toggle() }
                    )

                    SafetyOptionRow(
                        title: "Avoiding caffeine",
                        isSelected: preferences.avoidsCaffeine,
                        onToggle: { preferences.avoidsCaffeine.toggle() }
                    )

                    SafetyOptionRow(
                        title: "Histamine sensitivity",
                        isSelected: preferences.hasHistamineIntolerance,
                        onToggle: { preferences.hasHistamineIntolerance.toggle() }
                    )
                }
                .padding(.horizontal, theme.spacing.lg)
            }
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.1), value: showContent)

            // Disclaimer
            Text("This is not medical advice. Always consult your healthcare provider.")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.lg)

            // Continue button
            TerrainPrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.md)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.standard.delay(0.2), value: showContent)
        }
        .onAppear {
            withAnimation(theme.animation.standard) {
                showContent = true
            }
        }
    }
}

struct SafetyOptionRow: View {
    let title: String
    let isSelected: Bool
    let onToggle: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(title)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                    .strokeBorder(isSelected ? theme.colors.accent : theme.colors.textTertiary, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: theme.cornerRadius.small)
                            .fill(isSelected ? theme.colors.accent : Color.clear)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.colors.textInverted)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .frame(width: 24, height: 24)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SafetySectionLabel: View {
    let title: String

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Text(title)
            .font(theme.typography.labelSmall)
            .foregroundColor(theme.colors.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, theme.spacing.xs)
    }
}

#Preview {
    SafetyGateView(
        preferences: .constant(SafetyPreferences()),
        onContinue: {},
        onSkip: {},
        onBack: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
