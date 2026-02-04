//
//  PermissionsView.swift
//  Terrain
//
//  Explains what location and health permissions enable, reassures about
//  privacy, then triggers system dialogs sequentially. Shown during
//  onboarding after notifications and before account creation.
//

import SwiftUI
import CoreLocation
import HealthKit

struct PermissionsView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onBack: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var isRequesting = false

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

            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Title
                    VStack(spacing: theme.spacing.sm) {
                        Text("Personalize with\nreal-world data")
                            .font(theme.typography.headlineLarge)
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Two optional signals make your daily guidance more accurate.")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .opacity(showContent ? 1 : 0)

                    // Weather card
                    PermissionBenefitCard(
                        emoji: "☁️",
                        label: "LOCAL WEATHER",
                        benefit: "Hot & humid? Cooling foods and lighter movement. Cold & dry? Warming rituals and nourishing meals.",
                        privacy: "Uses location for weather only. Never tracks where you go."
                    )
                    .opacity(showContent ? 1 : 0)
                    .animation(reduceMotion ? .none : theme.animation.standard.delay(0.1), value: showContent)

                    // Activity card
                    PermissionBenefitCard(
                        emoji: "👟",
                        label: "DAILY ACTIVITY",
                        benefit: "Big walk yesterday? Lighter movement today. Rest day? More stretching and active routines.",
                        privacy: "Reads step count only. No other health data."
                    )
                    .opacity(showContent ? 1 : 0)
                    .animation(reduceMotion ? .none : theme.animation.standard.delay(0.2), value: showContent)

                    // Settings note
                    Text("You can change these anytime in Settings.")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .animation(reduceMotion ? .none : theme.animation.standard.delay(0.3), value: showContent)
                }
            }

            // Buttons
            VStack(spacing: theme.spacing.sm) {
                TerrainPrimaryButton(
                    title: "Allow Access",
                    action: {
                        Task { await requestPermissions() }
                    },
                    isEnabled: !isRequesting
                )

                TerrainTextButton(title: "Not now", action: onSkip)
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
            .opacity(showContent ? 1 : 0)
            .animation(reduceMotion ? .none : theme.animation.standard.delay(0.3), value: showContent)
        }
        .onAppear {
            if reduceMotion {
                showContent = true
            } else {
                withAnimation(theme.animation.standard) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Permission Requests

    /// Requests location first, then health, sequentially.
    /// Advances to the next onboarding step regardless of allow/deny.
    private func requestPermissions() async {
        isRequesting = true
        defer { isRequesting = false }

        // 1. Location
        await LocationPermissionHelper.shared.requestPermission()

        // 2. Health (step count only)
        if HKHealthStore.isHealthDataAvailable() {
            let stepType = HKQuantityType(.stepCount)
            try? await HKHealthStore().requestAuthorization(toShare: [], read: [stepType])
        }

        onContinue()
    }
}

// MARK: - Benefit Card

private struct PermissionBenefitCard: View {
    let emoji: String
    let label: String
    let benefit: String
    let privacy: String

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Header
            HStack(spacing: theme.spacing.xs) {
                Text(emoji)
                    .font(.system(size: 18))

                Text(label)
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            // Benefit description
            Text(benefit)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Privacy note
            Text(privacy)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, theme.spacing.lg)
    }
}

// MARK: - Location Permission Helper

/// Wraps CLLocationManager authorization into an async call.
/// Uses the same `nonisolated` delegate + `Task { @MainActor }` pattern
/// as WeatherService (WeatherService.swift:186) for thread safety.
@MainActor
private final class LocationPermissionHelper: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionHelper()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Requests when-in-use authorization if not yet determined.
    /// Returns immediately if already authorized or denied.
    func requestPermission() async {
        guard manager.authorizationStatus == .notDetermined else { return }

        await withCheckedContinuation { cont in
            self.continuation = cont
            manager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            // Only resume if we have a pending continuation and the status
            // is no longer .notDetermined (user responded to the dialog).
            guard manager.authorizationStatus != .notDetermined else { return }
            continuation?.resume()
            continuation = nil
        }
    }
}

// MARK: - Preview

#Preview {
    PermissionsView(
        onContinue: {},
        onSkip: {},
        onBack: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
