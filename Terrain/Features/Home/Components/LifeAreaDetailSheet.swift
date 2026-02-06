//
//  LifeAreaDetailSheet.swift
//  Terrain
//
//  Expanded detail view for a life area reading (Co-Star style).
//  Shows personalized reading, balance advice, accuracy buttons, and reasons.
//

import SwiftUI

/// Detail sheet for a life area with full reading and accuracy feedback
struct LifeAreaDetailSheet: View {
    let reading: LifeAreaReading
    var onAccuracyFeedback: ((Bool) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.terrainTheme) private var theme
    @State private var feedbackGiven: Bool? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                // Header with close button
                header

                // Focus dot and title
                titleSection

                // Main reading paragraph
                readingSection

                // Balance advice
                adviceSection

                // Accuracy feedback
                accuracySection

                // Why this reading (reasons)
                if !reading.reasons.isEmpty {
                    reasonsSection
                }

                Spacer(minLength: theme.spacing.xxxl)
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.background)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(theme.colors.backgroundSecondary)
                    .clipShape(Circle())
            }
        }
    }

    private var titleSection: some View {
        HStack(spacing: theme.spacing.md) {
            // Focus level dot (larger in detail)
            focusDot
                .frame(width: 16, height: 16)

            Text(reading.type.displayName)
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    @ViewBuilder
    private var focusDot: some View {
        switch reading.focusLevel {
        case .neutral:
            Circle()
                .stroke(theme.colors.textTertiary, lineWidth: 2)
        case .moderate:
            ZStack {
                Circle()
                    .stroke(theme.colors.textPrimary, lineWidth: 2)
                HalfFilledCircle()
                    .fill(theme.colors.textPrimary)
            }
        case .priority:
            Circle()
                .fill(theme.colors.textPrimary)
        }
    }

    private var readingSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text(reading.reading)
                .font(theme.typography.bodyLarge)
                .foregroundColor(theme.colors.textPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var adviceSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("To balance")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(reading.balanceAdvice)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.cornerRadius.medium)
    }

    private var accuracySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Does this feel accurate?")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textTertiary)

            HStack(spacing: theme.spacing.md) {
                accuracyButton(isAccurate: true)
                accuracyButton(isAccurate: false)
            }

            if feedbackGiven != nil {
                Text("Thanks for the feedback")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: feedbackGiven)
    }

    private func accuracyButton(isAccurate: Bool) -> some View {
        let isSelected = feedbackGiven == isAccurate

        return Button {
            HapticManager.light()
            withAnimation {
                feedbackGiven = isAccurate
            }
            onAccuracyFeedback?(isAccurate)
        } label: {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: isAccurate ? "hand.thumbsup" : "hand.thumbsdown")
                Text(isAccurate ? "Yes" : "Not quite")
            }
            .font(theme.typography.labelMedium)
            .foregroundColor(isSelected ? theme.colors.background : theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(isSelected ? theme.colors.textPrimary : theme.colors.backgroundSecondary)
            .cornerRadius(theme.cornerRadius.large)
        }
        .disabled(feedbackGiven != nil)
        .opacity(feedbackGiven != nil && !isSelected ? 0.5 : 1)
    }

    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text("Why this reading")
                .font(theme.typography.labelMedium)
                .foregroundColor(theme.colors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            ForEach(reading.reasons) { reason in
                HStack(alignment: .top, spacing: theme.spacing.sm) {
                    reasonIcon(for: reason.source)
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.textTertiary)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reason.source)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textTertiary)

                        Text(reason.detail)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
        }
    }

    private func reasonIcon(for source: String) -> some View {
        let icon: String
        switch source {
        case "Quiz":
            icon = "doc.text"
        case "Weather":
            icon = "cloud.sun"
        case "Symptoms":
            icon = "heart"
        case "Patterns":
            icon = "chart.line.uptrend.xyaxis"
        case "Activity":
            icon = "figure.walk"
        default:
            icon = "info.circle"
        }
        return Image(systemName: icon)
    }
}

// MARK: - Modifier Area Detail Sheet

/// Detail sheet for a modifier area (Inner Climate, Fluid Balance, Qi Movement).
/// Similar to LifeAreaDetailSheet but uses a condition icon instead of a focus dot.
struct ModifierAreaDetailSheet: View {
    let reading: ModifierAreaReading
    var onAccuracyFeedback: ((Bool) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.terrainTheme) private var theme
    @State private var feedbackGiven: Bool? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                // Header with close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                }

                // Icon and title
                HStack(spacing: theme.spacing.md) {
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundColor(theme.colors.textPrimary)

                    Text(reading.type.displayName)
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.colors.textPrimary)
                }

                // Reading
                Text(reading.reading)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                // Balance advice
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("To balance")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textTertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(reading.balanceAdvice)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(theme.spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.colors.backgroundSecondary)
                .cornerRadius(theme.cornerRadius.medium)

                // Accuracy feedback
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Does this feel accurate?")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textTertiary)

                    HStack(spacing: theme.spacing.md) {
                        modifierAccuracyButton(isAccurate: true)
                        modifierAccuracyButton(isAccurate: false)
                    }

                    if feedbackGiven != nil {
                        Text("Thanks for the feedback")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: feedbackGiven)

                // Reasons
                if !reading.reasons.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.md) {
                        Text("Why this reading")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)

                        ForEach(reading.reasons) { reason in
                            HStack(alignment: .top, spacing: theme.spacing.sm) {
                                reasonIcon(for: reason.source)
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.colors.textTertiary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reason.source)
                                        .font(theme.typography.labelSmall)
                                        .foregroundColor(theme.colors.textTertiary)

                                    Text(reason.detail)
                                        .font(theme.typography.bodySmall)
                                        .foregroundColor(theme.colors.textSecondary)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: theme.spacing.xxxl)
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.background)
    }

    private var iconName: String {
        switch reading.type {
        case .innerClimate: return "thermometer.medium"
        case .fluidBalance: return "drop"
        case .qiMovement: return "wind"
        case .spiritRest: return "moon.stars"
        }
    }

    private func modifierAccuracyButton(isAccurate: Bool) -> some View {
        let isSelected = feedbackGiven == isAccurate

        return Button {
            HapticManager.light()
            withAnimation {
                feedbackGiven = isAccurate
            }
            onAccuracyFeedback?(isAccurate)
        } label: {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: isAccurate ? "hand.thumbsup" : "hand.thumbsdown")
                Text(isAccurate ? "Yes" : "Not quite")
            }
            .font(theme.typography.labelMedium)
            .foregroundColor(isSelected ? theme.colors.background : theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(isSelected ? theme.colors.textPrimary : theme.colors.backgroundSecondary)
            .cornerRadius(theme.cornerRadius.large)
        }
        .disabled(feedbackGiven != nil)
        .opacity(feedbackGiven != nil && !isSelected ? 0.5 : 1)
    }

    private func reasonIcon(for source: String) -> some View {
        let icon: String
        switch source {
        case "Quiz": icon = "doc.text"
        case "Weather": icon = "cloud.sun"
        case "Symptoms": icon = "heart"
        case "Patterns": icon = "chart.line.uptrend.xyaxis"
        case "Activity": icon = "figure.walk"
        default: icon = "info.circle"
        }
        return Image(systemName: icon)
    }
}

#Preview("Energy - Priority") {
    LifeAreaDetailSheet(
        reading: LifeAreaReading(
            type: .energy,
            focusLevel: .priority,
            reading: "Your energy reserves run low. The fire that powers you burns small—gentle, not roaring. You build strength through accumulation, not intensity.",
            balanceAdvice: "Warm starts, cooked foods, and paced activity. Rest when tired rather than pushing through.",
            reasons: [
                ReadingReason(source: "Quiz", detail: "Your terrain shows deficient patterns"),
                ReadingReason(source: "Symptoms", detail: "You checked 'tired' today"),
                ReadingReason(source: "Activity", detail: "Low movement today (1,200 steps)")
            ]
        )
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Sleep - Moderate") {
    LifeAreaDetailSheet(
        reading: LifeAreaReading(
            type: .sleep,
            focusLevel: .moderate,
            reading: "Heat rises at night. Your body holds warmth that can disturb sleep if not released through deliberate cool-down.",
            balanceAdvice: "Cool room, light evening meals, and a wind-down routine help heat dissipate for rest.",
            reasons: [
                ReadingReason(source: "Quiz", detail: "Warm constitutions need to cool before sleep")
            ]
        )
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Seasonality - Neutral") {
    LifeAreaDetailSheet(
        reading: LifeAreaReading(
            type: .seasonality,
            focusLevel: .neutral,
            reading: "Spring is here. Your body naturally responds to the season—tuning in helps you ride rather than fight the rhythm.",
            balanceAdvice: "Eat seasonally, adjust routines to daylight, and listen to what your body asks for.",
            reasons: [
                ReadingReason(source: "Patterns", detail: "Seasonal awareness supports balance")
            ]
        )
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
