//
//  PostRoutineFeedbackSheet.swift
//  Terrain
//
//  Simple 3-button post-completion feedback sheet.
//  Appears after a routine or movement is completed.
//

import SwiftUI

/// Post-completion feedback sheet: "How do you feel?"
/// Three options: Better / Same / Not sure
/// Auto-dismisses after selection with a brief "Thanks!" animation.
struct PostRoutineFeedbackSheet: View {
    let routineOrMovementId: String
    let onFeedback: (PostRoutineFeedback) -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFeedback: PostRoutineFeedback?
    @State private var showThanks = false

    var body: some View {
        VStack(spacing: theme.spacing.xl) {
            if showThanks {
                // Thanks animation
                VStack(spacing: theme.spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(theme.colors.success)

                    Text("Thanks!")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("Your feedback helps us personalize your experience.")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Question
                VStack(spacing: theme.spacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 28))
                        .foregroundColor(theme.colors.accent)

                    Text("How do you feel?")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("After completing your practice")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                // Feedback buttons
                HStack(spacing: theme.spacing.md) {
                    ForEach(PostRoutineFeedback.allCases, id: \.self) { feedback in
                        FeedbackOptionButton(
                            feedback: feedback,
                            isSelected: selectedFeedback == feedback,
                            onTap: {
                                selectFeedback(feedback)
                            }
                        )
                    }
                }
            }
        }
        .padding(theme.spacing.xl)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }

    private func selectFeedback(_ feedback: PostRoutineFeedback) {
        selectedFeedback = feedback
        HapticManager.success()
        onFeedback(feedback)

        // Show thanks briefly, then dismiss
        withAnimation(theme.animation.spring) {
            showThanks = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

/// Individual feedback option button
struct FeedbackOptionButton: View {
    let feedback: PostRoutineFeedback
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.sm) {
                Image(systemName: feedback.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.accent)

                Text(feedback.displayName)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(isSelected ? theme.colors.textInverted : theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(isSelected ? theme.colors.accent : theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(theme.colors.accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PostRoutineFeedbackSheet(
        routineOrMovementId: "warm-start-congee-full",
        onFeedback: { feedback in print("Feedback: \(feedback)") }
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
