//
//  PulseCheckInView.swift
//  Terrain
//
//  A lightweight 5-step pulse check-in that detects terrain drift.
//  Presented as a full-screen sheet from the You tab.
//

import SwiftUI

struct PulseCheckInView: View {
    let currentTerrainId: String
    let currentModifier: String?
    var onRequestRetake: (() -> Void)?
    var onComplete: ((Date) -> Void)?

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var currentStep = 0
    @State private var answers: [Int: Int] = [:]
    @State private var driftResult: TerrainDriftResult?
    @State private var showingResult = false

    private let questions = PulseCheckInQuestions.all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingResult, let result = driftResult {
                    resultView(result)
                } else {
                    questionView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Question View

    private var questionView: some View {
        let question = questions[currentStep]
        let selectedValue = answers[question.id]

        return VStack(spacing: theme.spacing.xl) {
            Spacer()
                .frame(height: theme.spacing.lg)

            // Progress indicator
            progressIndicator

            // Question text
            Text(question.text)
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.lg)

            // Options
            VStack(spacing: theme.spacing.sm) {
                ForEach(question.options) { option in
                    optionRow(
                        option: option,
                        isSelected: selectedValue == option.value,
                        questionId: question.id
                    )
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            Spacer()

            // Next button
            TerrainPrimaryButton(
                title: currentStep < questions.count - 1 ? "Next" : "See Results",
                action: advanceOrFinish,
                isEnabled: selectedValue != nil
            )
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .animation(theme.animation.standard, value: currentStep)
    }

    private var progressIndicator: some View {
        HStack(spacing: theme.spacing.xs) {
            Text("\(currentStep + 1) of \(questions.count)")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)

            Spacer()

            // Dot indicators
            HStack(spacing: theme.spacing.xxs) {
                ForEach(0..<questions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? theme.colors.accent : theme.colors.backgroundSecondary)
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
    }

    private func optionRow(
        option: PulseCheckInOption,
        isSelected: Bool,
        questionId: Int
    ) -> some View {
        Button {
            HapticManager.selection()
            withAnimation(theme.animation.quick) {
                answers[questionId] = option.value
            }
        } label: {
            HStack {
                Text(option.text)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(isSelected ? theme.colors.textPrimary : theme.colors.textSecondary)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Radio indicator
                Circle()
                    .strokeBorder(
                        isSelected ? theme.colors.accent : theme.colors.textTertiary,
                        lineWidth: isSelected ? 0 : 1.5
                    )
                    .background(
                        Circle()
                            .fill(isSelected ? theme.colors.accent : Color.clear)
                    )
                    .frame(width: 20, height: 20)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(theme.colors.textInverted)
                                .frame(width: 8, height: 8)
                        }
                    }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .fill(isSelected ? theme.colors.accent.opacity(0.06) : theme.colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(
                        isSelected ? theme.colors.accent.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        }
        .accessibilityLabel(option.text)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Result View

    private func resultView(_ result: TerrainDriftResult) -> some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()

            // Icon
            Image(systemName: resultIcon(for: result.recommendation))
                .font(.system(size: 48, weight: .light))
                .foregroundColor(resultColor(for: result.recommendation))
                .padding(.bottom, theme.spacing.sm)

            // Title
            Text(resultTitle(for: result.recommendation))
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.lg)

            // Summary
            Text(result.driftSummary)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xl)

            Spacer()

            // Action buttons
            VStack(spacing: theme.spacing.sm) {
                if result.recommendation == .significantDrift {
                    TerrainPrimaryButton(title: "Retake Full Quiz") {
                        HapticManager.medium()
                        onComplete?(Date())
                        dismiss()
                        // Small delay to let the sheet dismiss before triggering retake
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onRequestRetake?()
                        }
                    }

                    TerrainTextButton(title: "Not Now") {
                        onComplete?(Date())
                        dismiss()
                    }
                } else {
                    TerrainPrimaryButton(title: "Done") {
                        onComplete?(Date())
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .animation(theme.animation.reveal, value: showingResult)
    }

    // MARK: - Helpers

    private func advanceOrFinish() {
        HapticManager.light()
        if currentStep < questions.count - 1 {
            currentStep += 1
        } else {
            computeDrift()
        }
    }

    private func computeDrift() {
        let detector = TerrainDriftDetector()
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: currentTerrainId,
            currentModifier: currentModifier
        )
        driftResult = result
        withAnimation(theme.animation.reveal) {
            showingResult = true
        }
    }

    private func resultIcon(for recommendation: DriftRecommendation) -> String {
        switch recommendation {
        case .noChange: return "checkmark.circle"
        case .minorShift: return "arrow.triangle.2.circlepath"
        case .significantDrift: return "exclamationmark.triangle"
        }
    }

    private func resultColor(for recommendation: DriftRecommendation) -> Color {
        switch recommendation {
        case .noChange: return theme.colors.success
        case .minorShift: return theme.colors.warning
        case .significantDrift: return theme.colors.accent
        }
    }

    private func resultTitle(for recommendation: DriftRecommendation) -> String {
        switch recommendation {
        case .noChange: return "Your terrain is holding steady."
        case .minorShift: return "A small shift detected."
        case .significantDrift: return "Your body seems to be in a different place."
        }
    }
}

// MARK: - Preview

#Preview("Pulse Check-In") {
    PulseCheckInView(
        currentTerrainId: "neutral_balanced_steady_core",
        currentModifier: nil
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
