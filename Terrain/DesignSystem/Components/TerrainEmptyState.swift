//
//  TerrainEmptyState.swift
//  Terrain
//
//  Illustrated empty state component for when content is unavailable
//

import SwiftUI

/// A consistent empty state view used throughout the app.
/// Think of this as a friendly "nothing here yet" message with an illustration,
/// title, and optional action button to help users move forward.
struct TerrainEmptyState: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Illustration
            Circle()
                .fill(theme.colors.backgroundSecondary)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 40))
                        .foregroundColor(theme.colors.textTertiary)
                )

            // Text
            VStack(spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Action button (if provided)
            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                    HapticManager.light()
                } label: {
                    Text(actionTitle)
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.accent)
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.vertical, theme.spacing.sm)
                        .background(theme.colors.accent.opacity(0.1))
                        .cornerRadius(theme.cornerRadius.large)
                }
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preset Empty States

extension TerrainEmptyState {
    /// Empty cabinet state
    static func emptyCabinet(onAddIngredients: @escaping () -> Void) -> TerrainEmptyState {
        TerrainEmptyState(
            systemImage: "cabinet",
            title: "Your cabinet is empty",
            subtitle: "Save ingredients you want to remember for later",
            actionTitle: "Browse Ingredients",
            action: onAddIngredients
        )
    }

    /// Empty progress state
    static func emptyProgress(onStartRoutine: @escaping () -> Void) -> TerrainEmptyState {
        TerrainEmptyState(
            systemImage: "chart.line.uptrend.xyaxis",
            title: "No activity yet",
            subtitle: "Complete routines to start tracking your progress",
            actionTitle: "Start Today's Routine",
            action: onStartRoutine
        )
    }

    /// Empty lessons state
    static var emptyLessons: TerrainEmptyState {
        TerrainEmptyState(
            systemImage: "book",
            title: "No lessons available",
            subtitle: "Lessons will appear here when content is loaded"
        )
    }

    /// No search results state
    static func noSearchResults(query: String) -> TerrainEmptyState {
        TerrainEmptyState(
            systemImage: "magnifyingglass",
            title: "No results found",
            subtitle: "Try a different search term for \"\(query)\""
        )
    }

    /// Offline state
    static func offline(onRetry: @escaping () -> Void) -> TerrainEmptyState {
        TerrainEmptyState(
            systemImage: "wifi.slash",
            title: "You're offline",
            subtitle: "Connect to the internet to sync your data",
            actionTitle: "Retry",
            action: onRetry
        )
    }

    /// Error state
    static func error(message: String, onRetry: @escaping () -> Void) -> TerrainEmptyState {
        TerrainEmptyState(
            systemImage: "exclamationmark.triangle",
            title: "Something went wrong",
            subtitle: message,
            actionTitle: "Try Again",
            action: onRetry
        )
    }
}

// MARK: - Preview

#Preview("Empty Cabinet") {
    TerrainEmptyState.emptyCabinet(onAddIngredients: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Empty Progress") {
    TerrainEmptyState.emptyProgress(onStartRoutine: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("No Search Results") {
    TerrainEmptyState.noSearchResults(query: "turmeric")
        .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Custom Empty State") {
    TerrainEmptyState(
        systemImage: "leaf.fill",
        title: "Custom Title",
        subtitle: "This is a custom empty state with an action button",
        actionTitle: "Take Action",
        action: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
