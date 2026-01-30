//
//  PreferencesSafetyView.swift
//  Terrain
//
//  Section G: Safety flags, notifications, retake quiz, and about section.
//  Consolidates settings from the previous YouView into a single component.
//

import SwiftUI
import SwiftData

struct PreferencesSafetyView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(SupabaseSyncService.self) private var syncService

    @Binding var showRetakeQuizConfirmation: Bool
    @State private var showAuthSheet = false
    @State private var showSignOutConfirmation = false
    @State private var signOutError: String?

    let userProfile: UserProfile?

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Safety flags
            safetySection

            // Notifications
            notificationsSection

            // Account
            accountSection

            // Profile actions
            profileActionsSection

            // About
            aboutSection
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView(syncService: syncService)
        }
        .confirmationDialog(
            "Sign Out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    do {
                        try await syncService.signOut()
                    } catch {
                        signOutError = "Could not sign out. Please try again."
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your data will remain on this device. You can sign back in anytime to resume syncing.")
        }
    }

    // MARK: - Safety Section

    private var safetySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Safety")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 0) {
                safetyToggle("Pregnant", binding: pregnantBinding, icon: "heart")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("Breastfeeding", binding: breastfeedingBinding, icon: "heart")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("GERD / Acid Reflux", binding: gerdBinding, icon: "stomach")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("Blood Thinners", binding: bloodThinnersBinding, icon: "drop")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("BP Medication", binding: bpMedsBinding, icon: "waveform.path.ecg")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("Thyroid Medication", binding: thyroidMedsBinding, icon: "pills")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("Diabetes Medication", binding: diabetesMedsBinding, icon: "pills")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("Avoids Caffeine", binding: caffeineBinding, icon: "cup.and.saucer")
                Divider().padding(.leading, theme.spacing.md)
                safetyToggle("Histamine Intolerance", binding: histamineBinding, icon: "allergens")
            }
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    private func safetyToggle(_ label: String, binding: Binding<Bool>, icon: String) -> some View {
        Toggle(isOn: binding) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(theme.colors.accent)
                Text(label)
                    .font(theme.typography.bodyMedium)
            }
        }
        .tint(theme.colors.accent)
        .padding(theme.spacing.md)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Notifications")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 0) {
                Toggle(isOn: notificationsBinding) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .foregroundColor(theme.colors.accent)
                        Text("Daily Reminders")
                            .font(theme.typography.bodyMedium)
                    }
                }
                .tint(theme.colors.accent)
                .padding(theme.spacing.md)

                if userProfile?.notificationsEnabled == true {
                    Divider().padding(.leading, theme.spacing.md)

                    DatePicker(
                        selection: morningTimeBinding,
                        displayedComponents: .hourAndMinute
                    ) {
                        HStack {
                            Image(systemName: "sunrise")
                                .foregroundColor(theme.colors.warning)
                            Text("Morning")
                                .font(theme.typography.bodyMedium)
                        }
                    }
                    .padding(theme.spacing.md)

                    Divider().padding(.leading, theme.spacing.md)

                    DatePicker(
                        selection: eveningTimeBinding,
                        displayedComponents: .hourAndMinute
                    ) {
                        HStack {
                            Image(systemName: "sunset")
                                .foregroundColor(theme.colors.accent)
                            Text("Evening")
                                .font(theme.typography.bodyMedium)
                        }
                    }
                    .padding(theme.spacing.md)
                }
            }
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Account")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 0) {
                if syncService.isAuthenticated {
                    // Signed in — show email
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(theme.colors.accent)
                        Text(syncService.currentUserEmail ?? "Signed In")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(theme.colors.success)
                            .font(.system(size: 14))
                    }
                    .padding(theme.spacing.md)

                    Divider().padding(.leading, theme.spacing.md)

                    // Sync status
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(theme.colors.textSecondary)
                        Text(syncService.isSyncing ? "Syncing..." : "Sync Active")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                        Spacer()
                        if syncService.isSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(theme.spacing.md)

                    Divider().padding(.leading, theme.spacing.md)

                    // Sign out button
                    Button {
                        showSignOutConfirmation = true
                        HapticManager.light()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(theme.colors.error)
                            Text("Sign Out")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.error)
                            Spacer()
                        }
                        .padding(theme.spacing.md)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Signed out — show sign in button
                    Button {
                        showAuthSheet = true
                        HapticManager.light()
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(theme.colors.accent)
                            Text("Sign In / Create Account")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.textTertiary)
                        }
                        .padding(theme.spacing.md)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Hint text
                    Text("Sign in to sync your data across devices")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.bottom, theme.spacing.sm)
                }

                // Sign out error
                if let signOutError {
                    Text(signOutError)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.error)
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.bottom, theme.spacing.sm)
                }
            }
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    // MARK: - Profile Actions Section

    private var profileActionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Profile")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 0) {
                Button {
                    showRetakeQuizConfirmation = true
                    HapticManager.light()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(theme.colors.accent)
                        Text("Retake Terrain Quiz")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                    .padding(theme.spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("About")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            VStack(spacing: 0) {
                // Version
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(theme.colors.textSecondary)
                    Text("Version")
                        .font(theme.typography.bodyMedium)
                    Spacer()
                    Text(appVersion)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(theme.spacing.md)

                Divider().padding(.leading, theme.spacing.md)

                aboutLink("Privacy Policy", icon: "hand.raised", url: "https://terrain.app/privacy")

                Divider().padding(.leading, theme.spacing.md)

                aboutLink("Terms of Service", icon: "doc.text", url: "https://terrain.app/terms")

                Divider().padding(.leading, theme.spacing.md)

                aboutLink("Contact Support", icon: "envelope", url: "mailto:support@terrain.app")
            }
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
    }

    private func aboutLink(_ title: String, icon: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(theme.colors.textSecondary)
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10))
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(theme.spacing.md)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Safety Bindings

    private func makeSafetyBinding(_ keyPath: WritableKeyPath<SafetyPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { userProfile?.safetyPreferences[keyPath: keyPath] ?? false },
            set: { newValue in
                if let profile = userProfile {
                    profile.safetyPreferences[keyPath: keyPath] = newValue
                    profile.updatedAt = Date()
                    try? modelContext.save()
                }
                HapticManager.selection()
            }
        )
    }

    private var pregnantBinding: Binding<Bool> { makeSafetyBinding(\.isPregnant) }
    private var breastfeedingBinding: Binding<Bool> { makeSafetyBinding(\.isBreastfeeding) }
    private var gerdBinding: Binding<Bool> { makeSafetyBinding(\.hasGerd) }
    private var bloodThinnersBinding: Binding<Bool> { makeSafetyBinding(\.takesBloodThinners) }
    private var bpMedsBinding: Binding<Bool> { makeSafetyBinding(\.takesBpMeds) }
    private var thyroidMedsBinding: Binding<Bool> { makeSafetyBinding(\.takesThyroidMeds) }
    private var diabetesMedsBinding: Binding<Bool> { makeSafetyBinding(\.takesDiabetesMeds) }
    private var caffeineBinding: Binding<Bool> { makeSafetyBinding(\.avoidsCaffeine) }
    private var histamineBinding: Binding<Bool> { makeSafetyBinding(\.hasHistamineIntolerance) }

    // MARK: - Notification Bindings

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { userProfile?.notificationsEnabled ?? false },
            set: { newValue in
                if let profile = userProfile {
                    profile.notificationsEnabled = newValue
                    profile.updatedAt = Date()
                    try? modelContext.save()
                }
                HapticManager.selection()
            }
        )
    }

    private var morningTimeBinding: Binding<Date> {
        Binding(
            get: { userProfile?.morningNotificationTime ?? defaultMorningTime },
            set: { newValue in
                if let profile = userProfile {
                    profile.morningNotificationTime = newValue
                    profile.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        )
    }

    private var eveningTimeBinding: Binding<Date> {
        Binding(
            get: { userProfile?.eveningNotificationTime ?? defaultEveningTime },
            set: { newValue in
                if let profile = userProfile {
                    profile.eveningNotificationTime = newValue
                    profile.updatedAt = Date()
                    try? modelContext.save()
                }
            }
        )
    }

    private var defaultMorningTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private var defaultEveningTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}
