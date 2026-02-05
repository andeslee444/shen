//
//  TerrainPulseCard.swift
//  Terrain
//
//  Hero card showing personalized terrain-aware insight at top of Trends.
//  Uses terrain glow colors and Co-Star editorial tone.
//

import SwiftUI

struct TerrainPulseCard: View {
    let insight: TerrainPulseInsight
    let terrainType: TerrainScoringEngine.PrimaryType
    let modifier: TerrainScoringEngine.Modifier

    @Environment(\.terrainTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var pulseScale: CGFloat = 0.95
    @State private var glowOpacity: Double = 0.3

    /// Color for the terrain type glow effect
    private var terrainGlowColor: Color {
        switch terrainType {
        case .coldDeficient, .coldBalanced:
            return Color(hex: "7A8E9E") // Cool blue-grey
        case .warmDeficient, .warmBalanced, .warmExcess:
            return Color(hex: "C9956E") // Warm amber
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            return Color(hex: "9E9E8E") // Neutral earth
        }
    }

    /// Accent color for urgent insights
    private var urgentAccentColor: Color {
        insight.isUrgent ? theme.colors.warning : terrainGlowColor
    }

    var body: some View {
        ZStack {
            // Radial gradient background (matches TerrainRevealView)
            RadialGradient(
                gradient: Gradient(colors: [
                    terrainGlowColor.opacity(glowOpacity * 0.25),
                    theme.colors.surface.opacity(0)
                ]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 200
            )
            .animation(reduceMotion ? nil : .easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulseScale)

            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Header row with terrain badge and optional category indicator
                HStack(spacing: theme.spacing.sm) {
                    // Terrain type badge
                    HStack(spacing: theme.spacing.xxs) {
                        Circle()
                            .fill(terrainGlowColor)
                            .frame(width: 8, height: 8)
                        Text(terrainType.nickname)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }

                    if let category = insight.accentCategory {
                        Text("•")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)

                        HStack(spacing: theme.spacing.xxs) {
                            Image(systemName: iconForCategory(category))
                                .font(.system(size: 10))
                            Text(category)
                                .font(theme.typography.caption)
                        }
                        .foregroundColor(insight.isUrgent ? theme.colors.warning : theme.colors.textSecondary)
                    }

                    Spacer()

                    // Urgent indicator
                    if insight.isUrgent {
                        HStack(spacing: theme.spacing.xxs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Watch")
                                .font(theme.typography.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(theme.colors.warning)
                    }
                }

                // Headline - editorial style, bold
                Text(insight.headline)
                    .font(theme.typography.headlineMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                // Body - terrain-specific interpretation
                Text(insight.body)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)

                // Modifier badge (if present)
                if modifier != .none {
                    HStack(spacing: theme.spacing.xxs) {
                        Image(systemName: modifierIcon)
                            .font(.system(size: 10))
                        Text(modifierFocusLabel)
                            .font(theme.typography.caption)
                    }
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.top, theme.spacing.xs)
                }
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .stroke(
                    insight.isUrgent
                        ? theme.colors.warning.opacity(0.3)
                        : terrainGlowColor.opacity(0.15),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .opacity(appeared ? 1 : 0)
        .blur(radius: appeared ? 0 : 8)
        .scaleEffect(appeared ? 1 : 0.95)
        .onAppear {
            if reduceMotion {
                appeared = true
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
            // Start subtle pulse animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
                glowOpacity = 0.5
            }
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Sleep": return "moon.zzz"
        case "Energy": return "bolt"
        case "Digestion": return "fork.knife"
        case "Stress": return "brain.head.profile"
        case "Mood": return "face.smiling"
        case "Headache": return "exclamationmark.circle"
        case "Stiffness": return "figure.walk"
        case "Cramps": return "drop.fill"
        default: return "chart.line.uptrend.xyaxis"
        }
    }

    /// Icon for the modifier type
    private var modifierIcon: String {
        switch modifier {
        case .shen: return "brain"
        case .stagnation: return "arrow.triangle.2.circlepath"
        case .damp: return "drop.fill"
        case .dry: return "sun.haze"
        case .none: return "circle"
        }
    }

    /// Short label for the modifier focus area
    private var modifierFocusLabel: String {
        switch modifier {
        case .shen: return "Mind focus"
        case .stagnation: return "Flow focus"
        case .damp: return "Digestion focus"
        case .dry: return "Moisture focus"
        case .none: return ""
        }
    }
}

// MARK: - Preview

#Preview("Declining Sleep - Cold Deficient") {
    TerrainPulseCard(
        insight: TerrainPulseInsight(
            headline: "Your sleep has been declining",
            body: "For Low Flame types, sleep is when your reserves rebuild. This 5-day decline deserves attention — warm feet before bed and earlier wind-down can help restore your pattern.",
            accentCategory: "Sleep",
            isUrgent: true
        ),
        terrainType: .coldDeficient,
        modifier: .shen
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Improving Energy - Neutral Deficient") {
    TerrainPulseCard(
        insight: TerrainPulseInsight(
            headline: "Energy is building",
            body: "Low Battery types can push through fatigue, but it costs you. This upward trend shows your practices are working — keep at it.",
            accentCategory: "Energy",
            isUrgent: false
        ),
        terrainType: .neutralDeficient,
        modifier: .none
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Stable - Warm Excess") {
    TerrainPulseCard(
        insight: TerrainPulseInsight(
            headline: "Well balanced",
            body: "For Overclocked types, stability is an achievement. Your cooling and pacing practices are keeping your heat in check.",
            accentCategory: nil,
            isUrgent: false
        ),
        terrainType: .warmExcess,
        modifier: .stagnation
    )
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
