//
//  SettingsView.swift
//  Terrain
//
//  App settings for notifications, profile, and about
//

import SwiftUI
import SwiftData

/// Settings screen for managing notifications, profile, and app information.
/// Think of this as the "control panel" for the app where users can customize
/// their experience and access important links.
struct SettingsView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var userProfiles: [UserProfile]

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @State private var showRetakeQuizConfirmation = false

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    var body: some View {
        NavigationStack {
            List {
                // Notifications Section
                notificationsSection

                // Profile Section
                profileSection

                // About Section
                aboutSection
            }
            .listStyle(.insetGrouped)
            .background(theme.colors.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.accent)
                }
            }
            .confirmationDialog(
                "Retake Terrain Quiz?",
                isPresented: $showRetakeQuizConfirmation,
                titleVisibility: .visible
            ) {
                Button("Retake Quiz", role: .destructive) {
                    retakeQuiz()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restart the onboarding process to determine your new terrain profile. Your progress history will be preserved.")
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        Section {
            // Notifications toggle
            Toggle(isOn: notificationsBinding) {
                Label("Daily Reminders", systemImage: "bell.badge")
            }
            .tint(theme.colors.accent)

            if userProfile?.notificationsEnabled == true {
                // Morning time picker
                DatePicker(
                    selection: morningTimeBinding,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("Morning", systemImage: "sunrise")
                }

                // Evening time picker
                DatePicker(
                    selection: eveningTimeBinding,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("Evening", systemImage: "sunset")
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Get gentle reminders to check in and complete your daily rituals.")
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        Section {
            // Terrain type display
            if let profile = userProfile,
               let terrainId = profile.terrainProfileId,
               let type = TerrainScoringEngine.PrimaryType(rawValue: terrainId) {
                HStack {
                    Label("Your Terrain", systemImage: "person.circle")
                    Spacer()
                    Text(type.label)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }

            // Retake quiz button
            Button {
                showRetakeQuizConfirmation = true
                HapticManager.light()
            } label: {
                Label("Retake Terrain Quiz", systemImage: "arrow.counterclockwise")
                    .foregroundColor(theme.colors.accent)
            }
        } header: {
            Text("Profile")
        } footer: {
            if let profile = userProfile,
               let lastQuizDate = profile.lastQuizCompletedAt {
                Text("Quiz last completed \(lastQuizDate.formatted(date: .abbreviated, time: .omitted))")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            // Version
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersion)
                    .foregroundColor(theme.colors.textSecondary)
            }

            // Privacy Policy
            Link(destination: URL(string: "https://terrain.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            .foregroundColor(theme.colors.textPrimary)

            // Terms of Service
            Link(destination: URL(string: "https://terrain.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            .foregroundColor(theme.colors.textPrimary)

            // Support
            Link(destination: URL(string: "mailto:support@terrain.app")!) {
                Label("Contact Support", systemImage: "envelope")
            }
            .foregroundColor(theme.colors.textPrimary)
        } header: {
            Text("About")
        }
    }

    // MARK: - Bindings

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { userProfile?.notificationsEnabled ?? false },
            set: { newValue in
                if let profile = userProfile {
                    profile.notificationsEnabled = newValue
                    profile.updatedAt = Date()
                    saveProfile()
                }
                HapticManager.selection()
            }
        )
    }

    private var morningTimeBinding: Binding<Date> {
        Binding(
            get: {
                userProfile?.morningNotificationTime ?? defaultMorningTime
            },
            set: { newValue in
                if let profile = userProfile {
                    profile.morningNotificationTime = newValue
                    profile.updatedAt = Date()
                    saveProfile()
                }
            }
        )
    }

    private var eveningTimeBinding: Binding<Date> {
        Binding(
            get: {
                userProfile?.eveningNotificationTime ?? defaultEveningTime
            },
            set: { newValue in
                if let profile = userProfile {
                    profile.eveningNotificationTime = newValue
                    profile.updatedAt = Date()
                    saveProfile()
                }
            }
        )
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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

    private func saveProfile() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }

    private func retakeQuiz() {
        // Delete the current user profile so a new one is created during onboarding
        if let profiles = try? modelContext.fetch(FetchDescriptor<UserProfile>()) {
            for profile in profiles {
                modelContext.delete(profile)
            }
            try? modelContext.save()
        }

        // Reset onboarding flag to trigger the onboarding flow
        hasCompletedOnboarding = false
        HapticManager.success()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
