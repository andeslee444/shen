//
//  HowItWorksView.swift
//  Terrain
//
//  Explains the 5-axis assessment before the user takes the quiz.
//  Each "sensor" maps to one axis of the TerrainScoringEngine vector.
//

import SwiftUI

struct HowItWorksView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var visibleSensors: Int = 0

    private let sensors: [Sensor] = [
        Sensor(
            emoji: "\u{1F321}\u{FE0F}",
            label: "Thermostat",
            leftLabel: "Cold",
            rightLabel: "Hot",
            question: "Do you tend to run cold or hot?",
            leftColor: Color(hex: "7A8E9E"),
            rightColor: Color(hex: "C9956E")
        ),
        Sensor(
            emoji: "\u{1F50B}",
            label: "Energy Reserves",
            leftLabel: "Depleted",
            rightLabel: "Full",
            question: "Does your body deplete easily or overflow?",
            leftColor: Color(hex: "9E9E8E"),
            rightColor: Color(hex: "7A9E7E")
        ),
        Sensor(
            emoji: "\u{1F4A7}",
            label: "Moisture",
            leftLabel: "Waterlogged",
            rightLabel: "Dry",
            question: "Does your body hold fluid or run dry?",
            leftColor: Color(hex: "6B8FA3"),
            rightColor: Color(hex: "C9A96E")
        ),
        Sensor(
            emoji: "\u{1F30A}",
            label: "Flow",
            leftLabel: "Free",
            rightLabel: "Stuck",
            question: "Does your energy move freely or get stuck?",
            leftColor: Color(hex: "7A9E7E"),
            rightColor: Color(hex: "A07A7A")
        ),
        Sensor(
            emoji: "\u{1F9E0}",
            label: "Mind",
            leftLabel: "Settled",
            rightLabel: "Restless",
            question: "Is your mind calm or restless?",
            leftColor: Color(hex: "7A8E9E"),
            rightColor: Color(hex: "B08EA0")
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
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
            .opacity(showContent ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: showContent)

            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    Spacer(minLength: theme.spacing.md)

                    // Title
                    Text("How Terrain reads your body")
                        .font(theme.typography.headlineLarge)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(reduceMotion ? .none : theme.animation.reveal, value: showContent)

                    // Subtitle
                    Text("A short assessment reads five\nsignals inside your body.")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(reduceMotion ? .none : theme.animation.reveal.delay(0.1), value: showContent)

                    // Sensor cards
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(Array(sensors.enumerated()), id: \.element.label) { index, sensor in
                            sensorRow(sensor: sensor)
                                .opacity(visibleSensors > index ? 1 : 0)
                                .offset(y: visibleSensors > index ? 0 : 12)
                                .animation(
                                    reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.15),
                                    value: visibleSensors
                                )
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Footer
                    Text("From these signals, Terrain maps you to 1 of 8 body types \u{2014} then personalizes your food, drink, movement, and daily guidance.")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.xl)
                        .opacity(visibleSensors >= sensors.count ? 1 : 0)
                        .animation(reduceMotion ? .none : theme.animation.standard.delay(0.2), value: visibleSensors)

                    Spacer(minLength: theme.spacing.lg)
                }
            }

            // Continue button pinned to bottom
            TerrainPrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.lg)
                .opacity(visibleSensors >= sensors.count ? 1 : 0)
                .animation(reduceMotion ? .none : theme.animation.standard.delay(0.3), value: visibleSensors)
        }
        .onAppear {
            if reduceMotion {
                showContent = true
                visibleSensors = sensors.count
            } else {
                withAnimation(theme.animation.reveal) {
                    showContent = true
                }
                // Stagger sensor appearances
                for i in 0..<sensors.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.15) {
                        withAnimation {
                            visibleSensors = i + 1
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sensor Row

    private func sensorRow(sensor: Sensor) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Emoji + label
            HStack(spacing: theme.spacing.xs) {
                Text(sensor.emoji)
                    .font(.system(size: 18))
                Text(sensor.label)
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            // Gradient bar with labels
            VStack(spacing: theme.spacing.xxs) {
                // The decorative gradient bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [sensor.leftColor.opacity(0.5), sensor.rightColor.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)

                // Axis labels
                HStack {
                    Text(sensor.leftLabel)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                    Spacer()
                    Text(sensor.rightLabel)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }

            // Question
            Text(sensor.question)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Sensor Model

private struct Sensor {
    let emoji: String
    let label: String
    let leftLabel: String
    let rightLabel: String
    let question: String
    let leftColor: Color
    let rightColor: Color
}

// MARK: - Preview

#Preview {
    HowItWorksView(onContinue: {}, onBack: {})
        .environment(\.terrainTheme, TerrainTheme.default)
}
