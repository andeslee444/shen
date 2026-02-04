//
//  RightNowView.swift
//  Terrain
//
//  DEPRECATED: This view has been replaced by the Quick Fixes section in DoView.
//  QuickNeed, QuickNeedCard, and QuickSuggestionCard have been extracted to
//  Core/Models/Shared/QuickNeed.swift.
//
//  Kept for reference only.
//

import SwiftUI
import SwiftData

// DEPRECATED — see DoView for the active implementation
struct RightNowView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Ingredient.id) private var ingredients: [Ingredient]
    @Query(sort: \Routine.id) private var routines: [Routine]
    @Query(sort: \DailyLog.date, order: .reverse) private var dailyLogs: [DailyLog]

    @State private var selectedNeed: QuickNeed?
    @State private var showCompletionFeedback = false
    @State private var completedNeed: QuickNeed?

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        VStack(spacing: theme.spacing.sm) {
                            Text("What do you need right now?")
                                .font(theme.typography.headlineLarge)
                                .foregroundColor(theme.colors.textPrimary)

                            Text("Quick suggestions for how you're feeling")
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.md)

                        VStack(spacing: theme.spacing.sm) {
                            ForEach(QuickNeed.allCases) { need in
                                QuickNeedCard(
                                    need: need,
                                    isSelected: selectedNeed == need,
                                    isCompleted: isNeedCompletedToday(need),
                                    onTap: {
                                        withAnimation(theme.animation.standard) {
                                            selectedNeed = need
                                        }
                                        HapticManager.selection()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        if let need = selectedNeed {
                            VStack(alignment: .leading, spacing: theme.spacing.md) {
                                Text("Suggestion")
                                    .font(theme.typography.labelLarge)
                                    .foregroundColor(theme.colors.textPrimary)

                                QuickSuggestionCard(
                                    need: need,
                                    suggestion: dynamicSuggestion(for: need),
                                    isCompleted: isNeedCompletedToday(need),
                                    onDoThis: {
                                        markSuggestionComplete(need: need)
                                    },
                                    onUndo: {
                                        undoSuggestionComplete(need: need)
                                    }
                                )
                            }
                            .padding(.horizontal, theme.spacing.lg)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer(minLength: theme.spacing.xxl)
                    }
                }
                .background(theme.colors.background)

                if showCompletionFeedback {
                    completionOverlay
                }
            }
            .navigationTitle("Right Now")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var completionOverlay: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(theme.colors.success)

            Text("Done!")
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)

            if let need = completedNeed {
                Text("You completed \(need.displayName.lowercased())")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.xl)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.xl)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .transition(.scale.combined(with: .opacity))
    }

    private func dynamicSuggestion(for need: QuickNeed) -> (title: String, description: String, avoidHours: Int?) {
        if let ingredient = ingredients.first(where: { ing in
            need.relevantTags.contains { tag in ing.tags.contains(tag) }
        }) {
            let description = ingredient.howToUse.quickUses.first?.text.localized
                ?? ingredient.whyItHelps.plain.localized
            return (ingredient.displayName, description, nil)
        }
        return need.suggestion
    }

    private func isNeedCompletedToday(_ need: QuickNeed) -> Bool {
        let suggestionId = "rightnow-\(need.rawValue)"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyLogs.first { log in
            calendar.startOfDay(for: log.date) == today
        }?.completedRoutineIds.contains(suggestionId) ?? false
    }

    private func markSuggestionComplete(need: QuickNeed) {
        let suggestionId = "rightnow-\(need.rawValue)"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let todayLog = dailyLogs.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            if !todayLog.completedRoutineIds.contains(suggestionId) {
                todayLog.completedRoutineIds.append(suggestionId)
                todayLog.updatedAt = Date()
            }
        } else {
            let newLog = DailyLog()
            newLog.completedRoutineIds.append(suggestionId)
            modelContext.insert(newLog)
        }

        do {
            try modelContext.save()
            completedNeed = need
            withAnimation(theme.animation.spring) {
                showCompletionFeedback = true
            }
            HapticManager.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(theme.animation.standard) {
                    showCompletionFeedback = false
                }
            }
        } catch {
            TerrainLogger.persistence.error("Failed to save completion: \(error)")
            HapticManager.error()
        }
    }

    private func undoSuggestionComplete(need: QuickNeed) {
        let suggestionId = "rightnow-\(need.rawValue)"
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let todayLog = dailyLogs.first(where: { calendar.startOfDay(for: $0.date) == today }) else { return }

        todayLog.completedRoutineIds.removeAll { $0 == suggestionId }
        todayLog.updatedAt = Date()

        do {
            try modelContext.save()
            HapticManager.light()
        } catch {
            TerrainLogger.persistence.error("Failed to undo completion: \(error)")
        }
    }
}

#Preview {
    RightNowView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
