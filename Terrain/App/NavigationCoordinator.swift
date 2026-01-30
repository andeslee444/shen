//
//  NavigationCoordinator.swift
//  Terrain
//
//  Cross-tab navigation coordinator using @Observable
//

import SwiftUI

/// Coordinates navigation across the app's tab structure.
/// Think of this as a "traffic controller" that allows one part of the app
/// to programmatically navigate to another, like a lesson CTA that jumps to the Do tab.
@Observable
final class NavigationCoordinator {

    // MARK: - Tab Selection

    /// The currently selected tab
    var selectedTab: Tab = .home

    /// Available tabs in the app
    enum Tab: Int, CaseIterable {
        case home = 0
        case `do` = 1
        case ingredients = 2
        case learn = 3
        case you = 4

        var title: String {
            switch self {
            case .home: return "Home"
            case .do: return "Do"
            case .ingredients: return "Ingredients"
            case .learn: return "Learn"
            case .you: return "You"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .do: return "play.circle.fill"
            case .ingredients: return "leaf.fill"
            case .learn: return "book.fill"
            case .you: return "person.fill"
            }
        }
    }

    // MARK: - Navigation Actions

    /// Navigate to a specific tab
    func navigate(to tab: Tab) {
        selectedTab = tab
        HapticManager.selection()
    }

    /// Navigate based on a CTA action string (e.g., "open_home", "open_ingredients")
    func handleCTAAction(_ action: String) {
        switch action {
        case "open_home":
            navigate(to: .home)
        case "open_do":
            navigate(to: .do)
        case "open_ingredients":
            navigate(to: .ingredients)
        case "open_learn":
            navigate(to: .learn)
        case "open_you":
            navigate(to: .you)
        case "open_routine", "open_movement":
            // Navigate to Do tab where routines and movements are shown
            navigate(to: .do)
        // Legacy actions for backward compatibility
        case "open_today":
            navigate(to: .home)
        case "open_right_now":
            navigate(to: .do)
        case "open_progress":
            navigate(to: .you)
        default:
            print("Unknown CTA action: \(action)")
        }
    }
}
