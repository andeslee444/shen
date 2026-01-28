//
//  RightNowView.swift
//  Terrain
//
//  Right Now tab for quick fixes
//

import SwiftUI

struct RightNowView: View {
    @Environment(\.terrainTheme) private var theme
    @State private var selectedNeed: QuickNeed?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Header
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

                    // Quick needs
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(QuickNeed.allCases) { need in
                            QuickNeedCard(
                                need: need,
                                isSelected: selectedNeed == need,
                                onTap: { selectedNeed = need }
                            )
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Selected suggestion
                    if let need = selectedNeed {
                        VStack(alignment: .leading, spacing: theme.spacing.md) {
                            Text("Suggestion")
                                .font(theme.typography.labelLarge)
                                .foregroundColor(theme.colors.textPrimary)

                            QuickSuggestionCard(need: need)
                        }
                        .padding(.horizontal, theme.spacing.lg)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Right Now")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

enum QuickNeed: String, CaseIterable, Identifiable {
    case energy
    case calm
    case digestion
    case warmth
    case cooling
    case focus

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .calm: return "leaf.fill"
        case .digestion: return "stomach"
        case .warmth: return "flame.fill"
        case .cooling: return "snowflake"
        case .focus: return "brain.head.profile"
        }
    }

    var suggestion: (title: String, description: String, avoidHours: Int?) {
        switch self {
        case .energy:
            return ("Ginger Honey Tea", "A quick warm drink to gently boost your energy without the crash.", nil)
        case .calm:
            return ("5 Deep Breaths", "Box breathing: inhale 4, hold 4, exhale 4, hold 4. Repeat 5 times.", nil)
        case .digestion:
            return ("Post-Meal Walk", "A gentle 10-minute walk aids digestion and prevents sluggishness.", nil)
        case .warmth:
            return ("Warm Ginger Tea", "Fresh ginger steeped in hot water warms from the inside.", 2)
        case .cooling:
            return ("Cucumber Water", "Cool (not ice-cold) cucumber-infused water to gently cool.", nil)
        case .focus:
            return ("Peppermint Inhale", "Crush fresh mint between fingers and inhale deeply 3 times.", nil)
        }
    }
}

struct QuickNeedCard: View {
    let need: QuickNeed
    let isSelected: Bool
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: need.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textSecondary)
                    .frame(width: 40)

                Text(need.displayName)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.accent)
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
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickSuggestionCard: View {
    let need: QuickNeed

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(need.suggestion.title)
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)

            Text(need.suggestion.description)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)

            if let hours = need.suggestion.avoidHours {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))

                    Text("Avoid cold drinks for \(hours) hours after")
                        .font(theme.typography.caption)
                }
                .foregroundColor(theme.colors.warning)
            }

            HStack(spacing: theme.spacing.md) {
                TerrainPrimaryButton(title: "Do This", action: {})
                TerrainTextButton(title: "Save as go-to", action: {})
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

#Preview {
    RightNowView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
