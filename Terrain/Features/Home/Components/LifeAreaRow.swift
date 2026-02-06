//
//  LifeAreaRow.swift
//  Terrain
//
//  Row component for Co-Star style life areas with dot focus indicators.
//

import SwiftUI

/// A tappable row displaying a life area with its focus level dot indicator.
/// Tap to expand into the detail sheet.
struct LifeAreaRow: View {
    let reading: LifeAreaReading
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                // Focus level dot indicator
                focusDot
                    .frame(width: 12, height: 12)
                    .padding(.top, 4) // Align with first line of text

                // Life area name and description
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(reading.type.displayName)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    if !reading.reading.isEmpty {
                        Text(reading.reading)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                // Chevron for expansion
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.top, 4) // Align with title
            }
            .padding(.vertical, theme.spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var focusDot: some View {
        switch reading.focusLevel {
        case .neutral:
            // Empty circle
            Circle()
                .stroke(theme.colors.textTertiary, lineWidth: 1.5)
        case .moderate:
            // Half-filled circle
            ZStack {
                Circle()
                    .stroke(theme.colors.textPrimary, lineWidth: 1.5)
                HalfFilledCircle()
                    .fill(theme.colors.textPrimary)
            }
        case .priority:
            // Fully filled circle
            Circle()
                .fill(theme.colors.textPrimary)
        }
    }
}

/// Custom shape for the half-filled circle (bottom half filled)
struct HalfFilledCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // Start from left middle, arc to right middle (bottom half)
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: true
        )

        return path
    }
}

/// Section displaying all life areas with their focus indicators
struct LifeAreasSection: View {
    let readings: [LifeAreaReading]
    @Binding var selectedReading: LifeAreaReading?

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(readings) { reading in
                LifeAreaRow(reading: reading) {
                    selectedReading = reading
                }

                if reading.id != readings.last?.id {
                    Divider()
                        .padding(.leading, theme.spacing.lg + 12) // Align with text after dot
                }
            }
        }
        .padding(.horizontal, theme.spacing.lg)
    }
}

#Preview("Life Areas Section") {
    let sampleReadings: [LifeAreaReading] = [
        LifeAreaReading(
            type: .energy,
            focusLevel: .priority,
            reading: "Your energy reserves run low.",
            balanceAdvice: "Warm starts, cooked foods, and paced activity.",
            reasons: [ReadingReason(source: "Quiz", detail: "Deficient patterns")]
        ),
        LifeAreaReading(
            type: .digestion,
            focusLevel: .moderate,
            reading: "Your digestive fire needs protection.",
            balanceAdvice: "Cooked foods, warm drinks, and ginger.",
            reasons: [ReadingReason(source: "Quiz", detail: "Cold patterns")]
        ),
        LifeAreaReading(
            type: .sleep,
            focusLevel: .neutral,
            reading: "Sleep rebuilds what day depletes.",
            balanceAdvice: "Warm feet before bed, earlier bedtimes.",
            reasons: []
        ),
        LifeAreaReading(
            type: .mood,
            focusLevel: .moderate,
            reading: "Mood follows energy.",
            balanceAdvice: "Warmth and nourishment lift spirits.",
            reasons: [ReadingReason(source: "Symptoms", detail: "Stressed")]
        ),
        LifeAreaReading(
            type: .seasonality,
            focusLevel: .priority,
            reading: "Winter amplifies your cold pattern.",
            balanceAdvice: "Extra warming practices are essential.",
            reasons: [ReadingReason(source: "Weather", detail: "Cold today")]
        )
    ]

    return ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your day")
                .font(.headline)
                .padding(.horizontal, 16)

            LifeAreasSection(readings: sampleReadings, selectedReading: .constant(nil))
        }
        .padding(.vertical, 24)
    }
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

// MARK: - Modifier Area Row

/// A tappable row for modifier-specific conditions (Inner Climate, Fluid Balance, Qi Movement).
/// Uses a condition-indicator icon instead of a focus dot.
struct ModifierAreaRow: View {
    let reading: ModifierAreaReading
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: theme.spacing.md) {
                // Condition icon
                Image(systemName: iconName)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textPrimary)
                    .frame(width: 12, height: 12)
                    .padding(.top, 4)

                // Area name and reading
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(reading.type.displayName)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    if !reading.reading.isEmpty {
                        Text(reading.reading)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.top, 4)
            }
            .padding(.vertical, theme.spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch reading.type {
        case .innerClimate: return "thermometer.medium"
        case .fluidBalance: return "drop"
        case .qiMovement: return "wind"
        case .spiritRest: return "moon.stars"
        }
    }
}

/// Section displaying modifier areas with a "Conditions in play" header
struct ModifierAreasSection: View {
    let readings: [ModifierAreaReading]
    @Binding var selectedReading: ModifierAreaReading?

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        if !readings.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("Conditions in play")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, theme.spacing.lg)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(readings) { reading in
                        ModifierAreaRow(reading: reading) {
                            selectedReading = reading
                        }

                        if reading.id != readings.last?.id {
                            Divider()
                                .padding(.leading, theme.spacing.lg + 12)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }
}

#Preview("Individual Rows") {
    VStack(spacing: 16) {
        LifeAreaRow(
            reading: LifeAreaReading(
                type: .energy,
                focusLevel: .neutral,
                reading: "",
                balanceAdvice: ""
            ),
            onTap: {}
        )
        LifeAreaRow(
            reading: LifeAreaReading(
                type: .digestion,
                focusLevel: .moderate,
                reading: "",
                balanceAdvice: ""
            ),
            onTap: {}
        )
        LifeAreaRow(
            reading: LifeAreaReading(
                type: .sleep,
                focusLevel: .priority,
                reading: "",
                balanceAdvice: ""
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
