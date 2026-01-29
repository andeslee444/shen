//
//  NotificationsView.swift
//  Terrain
//
//  Notification preferences screen for onboarding
//

import SwiftUI
import UserNotifications

struct NotificationsView: View {
    let coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    let onSkip: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Skip button
            HStack {
                Spacer()
                TerrainTextButton(title: "Skip", action: onSkip)
            }
            .padding(.horizontal, theme.spacing.lg)

            Spacer()

            // Title
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 48))
                    .foregroundColor(theme.colors.accent)

                Text("Stay consistent")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Text("Gentle reminders help you build your daily ritual habit.")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)

            Spacer()

            // Time pickers
            VStack(spacing: theme.spacing.md) {
                NotificationTimeRow(
                    title: "Morning routine",
                    subtitle: "Start your day aligned",
                    icon: "sun.horizon.fill",
                    time: Binding(
                        get: { coordinator.morningNotificationTime },
                        set: { coordinator.morningNotificationTime = $0 }
                    ),
                    isEnabled: Binding(
                        get: { coordinator.enableMorningNotification },
                        set: { coordinator.enableMorningNotification = $0 }
                    )
                )

                NotificationTimeRow(
                    title: "Evening wind-down",
                    subtitle: "Prepare for rest",
                    icon: "moon.fill",
                    time: Binding(
                        get: { coordinator.eveningNotificationTime },
                        set: { coordinator.eveningNotificationTime = $0 }
                    ),
                    isEnabled: Binding(
                        get: { coordinator.enableEveningNotification },
                        set: { coordinator.enableEveningNotification = $0 }
                    )
                )
            }
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.1), value: showContent)

            Spacer()

            // Enable button
            TerrainPrimaryButton(
                title: "Enable Notifications",
                action: requestNotifications
            )
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.2), value: showContent)

            // Not now
            TerrainTextButton(title: "Not now", action: onSkip)
                .opacity(showContent ? 1 : 0)
                .animation(theme.animation.standard.delay(0.2), value: showContent)

            Spacer(minLength: theme.spacing.lg)
        }
        .onAppear {
            withAnimation(theme.animation.standard) {
                showContent = true
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                coordinator.notificationsEnabled = granted
                if granted {
                    scheduleNotifications()
                }
                onContinue()
            }
        }
    }

    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()

        if coordinator.enableMorningNotification {
            let content = UNMutableNotificationContent()
            content.title = "Good morning"
            content.body = "Your daily routine is ready."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: coordinator.morningNotificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "morning-routine", content: content, trigger: trigger)

            center.add(request)
        }

        if coordinator.enableEveningNotification {
            let content = UNMutableNotificationContent()
            content.title = "Wind down"
            content.body = "Time for your evening ritual."
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: coordinator.eveningNotificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "evening-routine", content: content, trigger: trigger)

            center.add(request)
        }
    }
}

struct NotificationTimeRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var time: Date
    @Binding var isEnabled: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(theme.colors.accent)

            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isEnabled ? theme.colors.accent : theme.colors.textTertiary)
                .frame(width: 32)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(isEnabled ? theme.colors.textPrimary : theme.colors.textTertiary)

                Text(subtitle)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()

            // Time picker
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1 : 0.5)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

#Preview {
    NotificationsView(coordinator: OnboardingCoordinator(), onContinue: {}, onSkip: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
