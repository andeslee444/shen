//
//  RoutineDetailSheet.swift
//  Terrain
//
//  Detailed view of a routine with steps
//

import SwiftUI

struct RoutineDetailSheet: View {
    let level: RoutineLevel
    let onComplete: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var isTimerRunning = false
    @State private var timeRemaining = 0

    private var routine: RoutineData {
        RoutineData.forLevel(level)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                ProgressView(value: Double(currentStep) / Double(routine.steps.count))
                    .tint(theme.colors.accent)
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // Header
                        VStack(spacing: theme.spacing.sm) {
                            Text(routine.title)
                                .font(theme.typography.headlineLarge)
                                .foregroundColor(theme.colors.textPrimary)

                            Text(routine.subtitle)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)

                            HStack(spacing: theme.spacing.md) {
                                Label(routine.duration, systemImage: "clock")
                                Label(routine.difficulty, systemImage: "speedometer")
                            }
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.md)

                        // Ingredients
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Ingredients")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textTertiary)

                            FlowLayout(spacing: theme.spacing.xs) {
                                ForEach(routine.ingredients, id: \.self) { ingredient in
                                    IngredientChip(name: ingredient)
                                }
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        // Current step
                        if currentStep < routine.steps.count {
                            StepCard(
                                stepNumber: currentStep + 1,
                                totalSteps: routine.steps.count,
                                step: routine.steps[currentStep],
                                isTimerRunning: isTimerRunning,
                                timeRemaining: timeRemaining,
                                onStartTimer: startTimer
                            )
                            .padding(.horizontal, theme.spacing.lg)
                        }

                        // All steps overview
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("All steps")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textTertiary)

                            ForEach(Array(routine.steps.enumerated()), id: \.offset) { index, step in
                                StepRow(
                                    number: index + 1,
                                    text: step.text,
                                    isCompleted: index < currentStep,
                                    isCurrent: index == currentStep
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        // Why section
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("Why this helps")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.textTertiary)

                            Text(routine.whyText)
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                        .padding(.horizontal, theme.spacing.lg)

                        Spacer(minLength: theme.spacing.xxl)
                    }
                }

                // Bottom buttons
                HStack(spacing: theme.spacing.md) {
                    if currentStep > 0 {
                        TerrainSecondaryButton(title: "Previous") {
                            currentStep -= 1
                        }
                    }

                    if currentStep < routine.steps.count - 1 {
                        TerrainPrimaryButton(title: "Next Step") {
                            currentStep += 1
                        }
                    } else {
                        TerrainPrimaryButton(title: "Complete") {
                            onComplete()
                            dismiss()
                        }
                    }
                }
                .padding(theme.spacing.lg)
                .background(theme.colors.background)
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }

    private func startTimer(seconds: Int) {
        timeRemaining = seconds
        isTimerRunning = true

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                isTimerRunning = false
            }
        }
    }
}

struct StepCard: View {
    let stepNumber: Int
    let totalSteps: Int
    let step: RoutineStepData
    let isTimerRunning: Bool
    let timeRemaining: Int
    let onStartTimer: (Int) -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                Text("Step \(stepNumber) of \(totalSteps)")
                    .font(theme.typography.labelSmall)
                    .foregroundColor(theme.colors.textTertiary)

                Spacer()

                if step.timerSeconds > 0 {
                    if isTimerRunning {
                        Text(timeString(from: timeRemaining))
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(theme.colors.accent)
                    } else {
                        Button(action: { onStartTimer(step.timerSeconds) }) {
                            Label(timeString(from: step.timerSeconds), systemImage: "timer")
                                .font(theme.typography.labelMedium)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }

            Text(step.text)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.accent.opacity(0.08))
        .cornerRadius(theme.cornerRadius.large)
    }

    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(secs)s"
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    let isCompleted: Bool
    let isCurrent: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            ZStack {
                Circle()
                    .fill(isCompleted ? theme.colors.success : (isCurrent ? theme.colors.accent : theme.colors.backgroundSecondary))
                    .frame(width: 24, height: 24)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(isCurrent ? .white : theme.colors.textTertiary)
                }
            }

            Text(text)
                .font(theme.typography.bodyMedium)
                .foregroundColor(isCompleted ? theme.colors.textTertiary : theme.colors.textPrimary)
                .strikethrough(isCompleted)
        }
    }
}

// MARK: - Mock Data

struct RoutineData {
    let title: String
    let subtitle: String
    let duration: String
    let difficulty: String
    let ingredients: [String]
    let steps: [RoutineStepData]
    let whyText: String

    static func forLevel(_ level: RoutineLevel) -> RoutineData {
        switch level {
        case .full:
            return RoutineData(
                title: "Warm Start Congee",
                subtitle: "Nourishing breakfast to warm your center",
                duration: "10-15 min",
                difficulty: "Easy",
                ingredients: ["Rice", "Ginger", "Scallion", "Chicken (optional)"],
                steps: [
                    RoutineStepData(text: "Bring 4 cups water to a boil", timerSeconds: 0),
                    RoutineStepData(text: "Add 1/2 cup rice and 2 slices fresh ginger", timerSeconds: 0),
                    RoutineStepData(text: "Reduce heat and simmer, stirring occasionally", timerSeconds: 600),
                    RoutineStepData(text: "Add salt to taste and top with scallions", timerSeconds: 0),
                    RoutineStepData(text: "Eat slowly, savoring the warmth", timerSeconds: 0)
                ],
                whyText: "Congee is easily digestible and warming to the center. The long cooking breaks down the rice, making nutrients readily available. Ginger adds warming properties that support digestion."
            )

        case .lite:
            return RoutineData(
                title: "Ginger Honey Tea",
                subtitle: "Quick warming drink",
                duration: "5 min",
                difficulty: "Easy",
                ingredients: ["Fresh Ginger", "Honey", "Hot Water"],
                steps: [
                    RoutineStepData(text: "Slice 3-4 thin pieces of fresh ginger", timerSeconds: 0),
                    RoutineStepData(text: "Place in a mug and pour hot water over", timerSeconds: 0),
                    RoutineStepData(text: "Let steep for 3-5 minutes", timerSeconds: 180),
                    RoutineStepData(text: "Add honey to taste and sip slowly", timerSeconds: 0)
                ],
                whyText: "Fresh ginger tea warms the stomach and supports digestion. The honey adds gentle sweetness and has soothing properties. Best consumed warm, not hot."
            )

        case .minimum:
            return RoutineData(
                title: "Warm Water Ritual",
                subtitle: "Simple hydration ritual",
                duration: "90 sec",
                difficulty: "Easy",
                ingredients: ["Warm Water"],
                steps: [
                    RoutineStepData(text: "Heat water to a comfortable drinking temperature", timerSeconds: 0),
                    RoutineStepData(text: "Take 3 slow, deep breaths", timerSeconds: 15),
                    RoutineStepData(text: "Sip the warm water slowly, feeling it warm your center", timerSeconds: 60)
                ],
                whyText: "Simple warm water first thing helps wake up the digestive system gently. The temperature matters—too hot can irritate, too cold can shock the system. Room temperature to warm is ideal."
            )
        }
    }
}

struct RoutineStepData {
    let text: String
    let timerSeconds: Int
}

#Preview {
    RoutineDetailSheet(level: .full, onComplete: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
