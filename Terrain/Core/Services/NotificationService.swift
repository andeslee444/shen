//
//  NotificationService.swift
//  Terrain
//
//  Centralized notification scheduling, terrain-personalized content,
//  micro-action delivery, and deep-link handling via UNUserNotificationCenter.
//
//  Architecture note: this service is intentionally static + a companion delegate
//  class. The delegate must be retained at the app level (stored in TerrainApp)
//  because UNUserNotificationCenter holds only a weak reference to its delegate.
//

import Foundation
import SwiftData
import UserNotifications
import os.log

// MARK: - Micro-Action Model

/// A single micro-action: something the user can do in ~10 seconds
/// without opening the app (e.g., "Drink a glass of warm water").
struct MicroAction {
    let text: String
    let duration: String
}

// MARK: - Terrain Group

/// Groups the 8 terrain profile IDs into 3 thermal groups for micro-action selection.
/// Think of this like sorting winter coats vs. summer shirts vs. all-season jackets —
/// the advice changes based on whether your body runs cold, warm, or neutral.
private enum TerrainGroup {
    case cold
    case warm
    case neutral

    init(profileId: String) {
        if profileId.hasPrefix("cold_") {
            self = .cold
        } else if profileId.hasPrefix("warm_") {
            self = .warm
        } else {
            self = .neutral
        }
    }
}

// MARK: - Notification Service

enum NotificationService {

    /// Notification category identifier — all terrain ritual notifications use this.
    static let categoryIdentifier = "TERRAIN_RITUAL"

    /// Action identifiers for the notification buttons.
    private enum ActionID {
        static let didThis = "DID_THIS"
        static let startRitual = "START_RITUAL"
    }

    // MARK: - Category Registration

    /// Registers the notification category with iOS. Must be called once on app launch
    /// (before any notifications fire) so the system knows what buttons to show.
    static func registerCategories() {
        let didThis = UNNotificationAction(
            identifier: ActionID.didThis,
            title: "Did This \u{2713}",
            options: []  // background — no app launch
        )
        let startRitual = UNNotificationAction(
            identifier: ActionID.startRitual,
            title: "Start Ritual \u{2192}",
            options: [.foreground]  // opens app
        )
        let category = UNNotificationCategory(
            identifier: categoryIdentifier,
            actions: [didThis, startRitual],
            intentIdentifiers: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        TerrainLogger.notifications.info("Registered notification categories")
    }

    // MARK: - Content Generation

    /// Builds the notification content for a specific day and phase.
    ///
    /// - Parameters:
    ///   - terrainProfileId: e.g., "cold_deficient_low_flame"
    ///   - terrainNickname: e.g., "Low Flame"
    ///   - phase: morning or evening
    ///   - streakCount: current routine completion streak
    ///   - dayOffset: days from today (0 = today, 1 = tomorrow, etc.) for action rotation
    /// - Returns: A tuple of the notification content and the micro-action used.
    static func buildContent(
        terrainProfileId: String,
        terrainNickname: String,
        phase: DayPhase,
        streakCount: Int,
        dayOffset: Int = 0
    ) -> (UNMutableNotificationContent, MicroAction) {
        let group = TerrainGroup(profileId: terrainProfileId)
        let pool = microActionPool(for: group, phase: phase)

        // Rotate through the pool based on day of year + offset
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear + dayOffset) % pool.count
        let action = pool[index]

        let content = UNMutableNotificationContent()
        content.title = buildTitle(
            nickname: terrainNickname,
            group: group,
            phase: phase,
            streakCount: streakCount
        )
        content.body = "\(action.text) (\(action.duration))"
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier

        return (content, action)
    }

    /// Generates a terrain-aware notification title.
    private static func buildTitle(
        nickname: String,
        group: TerrainGroup,
        phase: DayPhase,
        streakCount: Int
    ) -> String {
        switch phase {
        case .morning:
            if streakCount > 3 {
                return "Day \(streakCount) — your \(nickname) rhythm"
            }
            let principle: String
            switch group {
            case .cold: principle = "warmth"
            case .warm: principle = "calm"
            case .neutral: principle = "balance"
            }
            return "Your \(nickname) body thrives with \(principle)"

        case .evening:
            if streakCount > 3 {
                return "Day \(streakCount) — wind-down time"
            }
            return "Time to settle your \(nickname) pattern"
        }
    }

    // MARK: - Scheduling

    /// Schedules terrain-personalized notifications with unique, rotating micro-actions.
    /// Removes all pending notifications first, then rebuilds.
    ///
    /// **Scheduling window depends on user configuration:**
    /// - If the user has set explicit morning/evening times → schedules 7 days ahead
    ///   (up to 14 notifications: 7 mornings + 7 evenings).
    /// - If times are nil (never customized) → schedules only **today's** notifications
    ///   using the 8:00 AM / 8:00 PM defaults. Future days are skipped because we
    ///   re-call this method on every foreground resume, so tomorrow's notifications
    ///   get scheduled when the user next opens the app. This avoids filling the
    ///   system queue with default-time notifications for users who haven't opted in.
    ///
    /// Call this:
    /// - On app foreground (refills the window)
    /// - After settings changes (time or enable/disable)
    /// - After quiz completion (terrain now known)
    static func scheduleUpcoming(profile: UserProfile, modelContainer: ModelContainer) {
        let center = UNUserNotificationCenter.current()

        // Wipe the slate — we always rebuild the full window
        center.removeAllPendingNotificationRequests()

        guard profile.notificationsEnabled else {
            TerrainLogger.notifications.info("Notifications disabled — cleared all pending")
            return
        }

        guard let terrainId = profile.terrainProfileId, !terrainId.isEmpty else {
            TerrainLogger.notifications.info("No terrain profile yet — skipping personalized scheduling")
            return
        }

        // Fetch the terrain nickname from SwiftData
        let nickname = fetchNickname(terrainId: terrainId, modelContainer: modelContainer)

        // Fetch streak count
        let streakCount = fetchStreakCount(modelContainer: modelContainer)

        let calendar = Calendar.current
        let morningTime = profile.morningNotificationTime ?? defaultMorningTime()
        let eveningTime = profile.eveningNotificationTime ?? defaultEveningTime()

        var scheduledCount = 0

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
                continue
            }

            // Morning notification
            if profile.morningNotificationTime != nil || dayOffset == 0 {
                // Always schedule morning if we have a time (or default)
                let morningComponents = buildTriggerComponents(
                    from: morningTime,
                    targetDate: targetDate,
                    calendar: calendar
                )

                // Skip if this time is already in the past today
                if let triggerDate = calendar.date(from: morningComponents),
                   triggerDate > Date() {
                    let (content, _) = buildContent(
                        terrainProfileId: terrainId,
                        terrainNickname: nickname,
                        phase: .morning,
                        streakCount: streakCount,
                        dayOffset: dayOffset
                    )
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: morningComponents,
                        repeats: false
                    )
                    let request = UNNotificationRequest(
                        identifier: "terrain-morning-\(dayOffset)",
                        content: content,
                        trigger: trigger
                    )
                    center.add(request) { error in
                        if let error {
                            TerrainLogger.notifications.error("Failed to schedule morning-\(dayOffset): \(error.localizedDescription)")
                        }
                    }
                    scheduledCount += 1
                }
            }

            // Evening notification
            if profile.eveningNotificationTime != nil || dayOffset == 0 {
                let eveningComponents = buildTriggerComponents(
                    from: eveningTime,
                    targetDate: targetDate,
                    calendar: calendar
                )

                if let triggerDate = calendar.date(from: eveningComponents),
                   triggerDate > Date() {
                    let (content, _) = buildContent(
                        terrainProfileId: terrainId,
                        terrainNickname: nickname,
                        phase: .evening,
                        streakCount: streakCount,
                        dayOffset: dayOffset
                    )
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: eveningComponents,
                        repeats: false
                    )
                    let request = UNNotificationRequest(
                        identifier: "terrain-evening-\(dayOffset)",
                        content: content,
                        trigger: trigger
                    )
                    center.add(request) { error in
                        if let error {
                            TerrainLogger.notifications.error("Failed to schedule evening-\(dayOffset): \(error.localizedDescription)")
                        }
                    }
                    scheduledCount += 1
                }
            }
        }

        TerrainLogger.notifications.info("Scheduled \(scheduledCount) notifications for terrain: \(terrainId)")
    }

    // MARK: - Helpers

    /// Combines a time-of-day (from the user's preference) with a target calendar date.
    private static func buildTriggerComponents(
        from time: Date,
        targetDate: Date,
        calendar: Calendar
    ) -> DateComponents {
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        dateComponents.second = 0
        return dateComponents
    }

    /// Fetches the terrain nickname from SwiftData. Falls back to a generic label.
    private static func fetchNickname(terrainId: String, modelContainer: ModelContainer) -> String {
        do {
            let context = ModelContext(modelContainer)
            var descriptor = FetchDescriptor<TerrainProfile>(
                predicate: #Predicate { $0.id == terrainId }
            )
            descriptor.fetchLimit = 1
            if let profile = try context.fetch(descriptor).first {
                return profile.nickname.localized
            }
        } catch {
            TerrainLogger.notifications.error("Failed to fetch terrain profile: \(error.localizedDescription)")
        }
        return "Terrain"
    }

    /// Fetches the current streak count from the most recent ProgressRecord.
    private static func fetchStreakCount(modelContainer: ModelContainer) -> Int {
        do {
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<ProgressRecord>()
            if let record = try context.fetch(descriptor).first {
                return record.currentStreak
            }
        } catch {
            TerrainLogger.notifications.error("Failed to fetch streak: \(error.localizedDescription)")
        }
        return 0
    }

    private static func defaultMorningTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    private static func defaultEveningTime() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Micro-Action Pools

    /// Returns the micro-action pool for a terrain group and day phase.
    /// 7 actions per pool x 6 pools = 42 total actions.
    /// Each pool is intentionally sized to 7 so users see a different action
    /// each day of the week before repeating.
    private static func microActionPool(for group: TerrainGroup, phase: DayPhase) -> [MicroAction] {
        switch (group, phase) {
        case (.cold, .morning):
            return [
                MicroAction(text: "Drink a glass of warm water", duration: "10 sec"),
                MicroAction(text: "Rub your palms together briskly for 10 seconds", duration: "10 sec"),
                MicroAction(text: "Place your warm palms over your lower back", duration: "15 sec"),
                MicroAction(text: "Stretch your arms overhead and take 3 deep breaths", duration: "15 sec"),
                MicroAction(text: "Roll your ankles slowly — 5 circles each direction", duration: "20 sec"),
                MicroAction(text: "Press your thumb into the center of your palm for 5 seconds", duration: "10 sec"),
                MicroAction(text: "Gently massage your earlobes for 10 seconds", duration: "10 sec"),
            ]
        case (.cold, .evening):
            return [
                MicroAction(text: "Place your hands on your lower belly and breathe deeply", duration: "15 sec"),
                MicroAction(text: "Sip warm water before bed", duration: "10 sec"),
                MicroAction(text: "Rub the soles of your feet gently for 15 seconds", duration: "15 sec"),
                MicroAction(text: "Take 3 slow breaths, imagining warmth spreading inward", duration: "15 sec"),
                MicroAction(text: "Gently press the space between your eyebrows for 5 seconds", duration: "10 sec"),
                MicroAction(text: "Roll your shoulders backward slowly 5 times", duration: "15 sec"),
                MicroAction(text: "Cup your palms over your closed eyes and relax your jaw", duration: "15 sec"),
            ]
        case (.warm, .morning):
            return [
                MicroAction(text: "Drink room-temperature water with a slow exhale", duration: "10 sec"),
                MicroAction(text: "Splash cool water on your wrists and inner elbows", duration: "10 sec"),
                MicroAction(text: "Take 3 breaths — inhale 4 counts, exhale 6 counts", duration: "20 sec"),
                MicroAction(text: "Gently press your temples with your fingertips for 5 seconds", duration: "10 sec"),
                MicroAction(text: "Open a window and take 3 deep breaths of fresh air", duration: "15 sec"),
                MicroAction(text: "Close your eyes and unclench your jaw for 10 seconds", duration: "10 sec"),
                MicroAction(text: "Roll your neck slowly — 3 circles each direction", duration: "20 sec"),
            ]
        case (.warm, .evening):
            return [
                MicroAction(text: "Take 3 slow exhales through your mouth", duration: "15 sec"),
                MicroAction(text: "Press your thumbs into your temples gently for 10 seconds", duration: "10 sec"),
                MicroAction(text: "Place a cool cloth on the back of your neck", duration: "15 sec"),
                MicroAction(text: "Close your eyes and count 5 slow breaths", duration: "20 sec"),
                MicroAction(text: "Gently shake out your hands for 10 seconds to release tension", duration: "10 sec"),
                MicroAction(text: "Rest your palms face-up on your knees and breathe", duration: "15 sec"),
                MicroAction(text: "Soften your forehead and relax your tongue from the roof of your mouth", duration: "10 sec"),
            ]
        case (.neutral, .morning):
            return [
                MicroAction(text: "Take 3 deep breaths by a window", duration: "15 sec"),
                MicroAction(text: "Roll your shoulders back 5 times", duration: "15 sec"),
                MicroAction(text: "Stand tall and press your feet into the floor for 10 seconds", duration: "10 sec"),
                MicroAction(text: "Tap the top of your head lightly with your fingertips", duration: "10 sec"),
                MicroAction(text: "Stretch your arms wide and take one big breath", duration: "10 sec"),
                MicroAction(text: "Rub your hands together and place them over your eyes", duration: "15 sec"),
                MicroAction(text: "Interlace your fingers overhead and lean gently to each side", duration: "15 sec"),
            ]
        case (.neutral, .evening):
            return [
                MicroAction(text: "Drop your shoulders away from your ears", duration: "10 sec"),
                MicroAction(text: "Close your eyes and count 5 breaths", duration: "20 sec"),
                MicroAction(text: "Place one hand on your chest and one on your belly — breathe slowly", duration: "15 sec"),
                MicroAction(text: "Gently massage the web between your thumb and index finger", duration: "15 sec"),
                MicroAction(text: "Relax your tongue and soften the muscles around your eyes", duration: "10 sec"),
                MicroAction(text: "Take a slow sip of warm water and notice the warmth", duration: "10 sec"),
                MicroAction(text: "Rock gently from your heels to your toes 5 times", duration: "15 sec"),
            ]
        }
    }
}

// MARK: - Notification Delegate

/// Handles notification responses (button taps) and foreground display.
///
/// This is a separate class from NotificationService because:
/// 1. UNUserNotificationCenterDelegate requires NSObject conformance
/// 2. The delegate runs outside the SwiftUI view hierarchy, so it uses
///    ModelContext(modelContainer) directly for background writes
/// 3. Must be retained as a strong reference (stored in TerrainApp) because
///    UNUserNotificationCenter only holds a weak reference to its delegate
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        super.init()
    }

    /// Called when the user taps a notification action button.
    /// - "DID_THIS": Logs the micro-action completion to today's DailyLog (background — no app launch)
    /// - "START_RITUAL": Sets an @AppStorage flag so MainTabView navigates to the Do tab on next render
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionId = response.actionIdentifier

        switch actionId {
        case "DID_THIS":
            TerrainLogger.notifications.info("User tapped 'Did This' — logging micro-action")
            logMicroActionCompletion()

        case "START_RITUAL":
            TerrainLogger.notifications.info("User tapped 'Start Ritual' — setting deep-link")
            UserDefaults.standard.set("open_do", forKey: "pendingNotificationAction")

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification body itself (not an action button) — open Do tab
            TerrainLogger.notifications.info("User tapped notification body — setting deep-link")
            UserDefaults.standard.set("open_do", forKey: "pendingNotificationAction")

        default:
            break
        }

        completionHandler()
    }

    /// Show notifications even when the app is in the foreground.
    /// Without this, iOS silently swallows foreground notifications.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Private

    /// Writes microActionCompletedAt to today's DailyLog.
    /// Creates a new DailyLog if none exists for today.
    private func logMicroActionCompletion() {
        do {
            let context = ModelContext(modelContainer)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            var descriptor = FetchDescriptor<DailyLog>(
                predicate: #Predicate<DailyLog> { log in
                    log.date >= startOfDay && log.date < endOfDay
                }
            )
            descriptor.fetchLimit = 1

            let existingLogs = try context.fetch(descriptor)

            if let todayLog = existingLogs.first {
                todayLog.microActionCompletedAt = Date()
                todayLog.updatedAt = Date()
            } else {
                // Create a new DailyLog for today with the micro-action recorded
                let newLog = DailyLog(date: Date())
                newLog.microActionCompletedAt = Date()
                context.insert(newLog)
            }

            try context.save()
            TerrainLogger.notifications.info("Micro-action completion logged")
        } catch {
            TerrainLogger.notifications.error("Failed to log micro-action: \(error.localizedDescription)")
        }
    }
}
