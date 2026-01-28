//
//  GoalsView.swift
//  Terrain
//
//  Goal selection screen for onboarding
//

import SwiftUI

struct GoalsView: View {
    let selectedGoals: Set<Goal>
    let onSelectGoal: (Goal) -> Void
    let onContinue: () -> Void
    let onBack: () -> Void

    @Environment(\.terrainTheme) private var theme
    @State private var showContent = false

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Back button
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
            }
            .padding(.horizontal, theme.spacing.md)

            // Title
            VStack(spacing: theme.spacing.sm) {
                Text("What would you like to focus on?")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Choose up to 2 goals")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.lg)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 10)

            // Goal options
            ScrollView {
                VStack(spacing: theme.spacing.sm) {
                    ForEach(Goal.allCases) { goal in
                        GoalOptionCard(
                            goal: goal,
                            isSelected: selectedGoals.contains(goal),
                            isDisabled: selectedGoals.count >= 2 && !selectedGoals.contains(goal),
                            onTap: { onSelectGoal(goal) }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.1), value: showContent)

            Spacer()

            // Continue button
            TerrainPrimaryButton(
                title: "Continue",
                action: onContinue,
                isEnabled: !selectedGoals.isEmpty
            )
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.md)
            .opacity(showContent ? 1 : 0)
            .animation(theme.animation.standard.delay(0.2), value: showContent)
        }
        .onAppear {
            withAnimation(theme.animation.standard) {
                showContent = true
            }
        }
    }
}

struct GoalOptionCard: View {
    let goal: Goal
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: goal.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.displayName)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(isDisabled ? theme.colors.textTertiary : theme.colors.textPrimary)

                    Text(goalDescription(goal))
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.colors.accent)
                } else {
                    Circle()
                        .strokeBorder(theme.colors.textTertiary.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(theme.spacing.md)
            .background(isSelected ? theme.colors.accent.opacity(0.08) : theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isSelected ? theme.colors.accent : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }

    private func goalDescription(_ goal: Goal) -> String {
        switch goal {
        case .sleep: return "Better rest, easier mornings"
        case .digestion: return "Comfortable gut, less bloating"
        case .energy: return "Steady energy throughout the day"
        case .stress: return "Calmer mind, easier days"
        case .skin: return "Clearer, more balanced skin"
        case .menstrualComfort: return "Smoother cycles, less discomfort"
        }
    }
}

#Preview {
    GoalsView(
        selectedGoals: [.sleep],
        onSelectGoal: { _ in },
        onContinue: {},
        onBack: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
