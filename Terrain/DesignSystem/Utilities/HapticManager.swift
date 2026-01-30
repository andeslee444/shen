//
//  HapticManager.swift
//  Terrain
//
//  Haptic feedback utilities for tactile UI responses
//

import UIKit

/// Provides haptic feedback for user interactions.
/// Think of this as adding a subtle "click" or "buzz" feeling when users tap buttons,
/// complete actions, or toggle settings - making the app feel more responsive and alive.
enum HapticManager {

    // MARK: - Impact Feedback

    /// Light tap - use for button taps, card selections, chip toggles
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Medium tap - use for more significant actions like confirming selections
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Heavy tap - use sparingly for major confirmations
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success - use when completing a routine, saving to cabinet, marking done
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    /// Warning - use for cautions or alerts
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    /// Error - use when something goes wrong
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection changed - use for toggles, segment changes, picker scrolling
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
