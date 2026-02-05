//
//  StepJourneyConnector.swift
//  Terrain
//
//  Visual step progress indicator that creates a journey/path metaphor.
//  Shows connected dots representing each step with visual distinction
//  for completed, current, and future steps.
//

import SwiftUI

/// A horizontal progress indicator showing the user's journey through routine steps.
///
/// Visual states:
/// - Completed: Filled dot with checkmark (success color)
/// - Current: Larger highlighted dot (accent color)
/// - Future: Hollow dot (muted)
///
/// Dots are connected by lines that fill in as steps complete,
/// creating a path/journey metaphor.
struct StepJourneyConnector: View {
    let totalSteps: Int
    let currentStep: Int
    let compact: Bool

    @Environment(\.terrainTheme) private var theme

    init(totalSteps: Int, currentStep: Int, compact: Bool = false) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalSteps, id: \.self) { step in
                // Step dot
                stepDot(for: step)

                // Connector line (except after last step)
                if step < totalSteps - 1 {
                    connectorLine(afterStep: step)
                }
            }
        }
        .animation(theme.animation.standard, value: currentStep)
    }

    // MARK: - Step Dot

    @ViewBuilder
    private func stepDot(for step: Int) -> some View {
        let isCompleted = step < currentStep
        let isCurrent = step == currentStep

        ZStack {
            Circle()
                .fill(dotFillColor(isCompleted: isCompleted, isCurrent: isCurrent))
                .frame(
                    width: isCurrent ? (compact ? 14 : 16) : (compact ? 10 : 12),
                    height: isCurrent ? (compact ? 14 : 16) : (compact ? 10 : 12)
                )

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: compact ? 6 : 7, weight: .bold))
                    .foregroundColor(.white)
            } else if isCurrent {
                Circle()
                    .fill(Color.white)
                    .frame(width: compact ? 4 : 5, height: compact ? 4 : 5)
            }
        }
        .shadow(
            color: isCurrent ? theme.colors.accent.opacity(0.3) : .clear,
            radius: 4,
            x: 0,
            y: 2
        )
    }

    private func dotFillColor(isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCompleted {
            return theme.colors.success
        } else if isCurrent {
            return theme.colors.accent
        } else {
            return theme.colors.textTertiary.opacity(0.3)
        }
    }

    // MARK: - Connector Line

    @ViewBuilder
    private func connectorLine(afterStep step: Int) -> some View {
        let isCompleted = step < currentStep

        Rectangle()
            .fill(isCompleted ? theme.colors.success : theme.colors.textTertiary.opacity(0.2))
            .frame(height: compact ? 2 : 3)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Vertical Journey Connector

/// A vertical variant for use alongside step list items.
/// Shows a continuous line connecting step indicators.
struct VerticalStepConnector: View {
    let isCompleted: Bool
    let isLast: Bool

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        if !isLast {
            Rectangle()
                .fill(isCompleted ? theme.colors.success : theme.colors.textTertiary.opacity(0.2))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
        }
    }
}

// MARK: - Preview

#Preview("Journey Connector") {
    VStack(spacing: 40) {
        VStack(alignment: .leading) {
            Text("Step 1 of 5")
                .font(.caption)
            StepJourneyConnector(totalSteps: 5, currentStep: 0)
        }

        VStack(alignment: .leading) {
            Text("Step 3 of 5")
                .font(.caption)
            StepJourneyConnector(totalSteps: 5, currentStep: 2)
        }

        VStack(alignment: .leading) {
            Text("Step 5 of 5 (last)")
                .font(.caption)
            StepJourneyConnector(totalSteps: 5, currentStep: 4)
        }

        VStack(alignment: .leading) {
            Text("Compact variant")
                .font(.caption)
            StepJourneyConnector(totalSteps: 8, currentStep: 3, compact: true)
        }
    }
    .padding()
    .environment(\.terrainTheme, TerrainTheme.default)
}
