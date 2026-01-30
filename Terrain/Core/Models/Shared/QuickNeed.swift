//
//  QuickNeed.swift
//  Terrain
//
//  Quick fix needs and suggestion cards, extracted from RightNowView.
//  Used by DoView for the "Quick Fixes" section.
//

import SwiftUI

// MARK: - Quick Need Enum

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

    /// Tags in the content pack that relate to this need (used for dynamic lookup)
    var relevantTags: [String] {
        switch self {
        case .energy:
            return ["supports_deficiency", "warming"]
        case .calm:
            return ["calms_shen", "moves_qi"]
        case .digestion:
            return ["supports_digestion"]
        case .warmth:
            return ["warming"]
        case .cooling:
            return ["cooling", "moistens_dryness"]
        case .focus:
            return ["moves_qi", "calms_shen"]
        }
    }

    /// Hardcoded fallback suggestion (used when no matching content is found)
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

// MARK: - Quick Need Card

struct QuickNeedCard: View {
    let need: QuickNeed
    let isSelected: Bool
    var isCompleted: Bool = false
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: need.icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 40)

                Text(need.displayName)
                    .font(theme.typography.bodyLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(theme.colors.success)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.accent)
                }
            }
            .padding(theme.spacing.md)
            .background(backgroundColor)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var iconColor: Color {
        if isCompleted {
            return theme.colors.success
        } else if isSelected {
            return theme.colors.accent
        }
        return theme.colors.textSecondary
    }

    private var backgroundColor: Color {
        if isCompleted {
            return theme.colors.success.opacity(0.08)
        } else if isSelected {
            return theme.colors.accent.opacity(0.08)
        }
        return theme.colors.surface
    }

    private var borderColor: Color {
        if isCompleted {
            return theme.colors.success
        } else if isSelected {
            return theme.colors.accent
        }
        return Color.clear
    }
}

// MARK: - Quick Suggestion Card

struct QuickSuggestionCard: View {
    let need: QuickNeed
    let suggestion: (title: String, description: String, avoidHours: Int?)
    var isCompleted: Bool = false
    var avoidTimeText: String? = nil
    let onDoThis: () -> Void
    let onSaveGoTo: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text(suggestion.title)
                    .font(theme.typography.headlineSmall)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                if isCompleted {
                    HStack(spacing: theme.spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Done")
                            .font(theme.typography.labelSmall)
                    }
                    .foregroundColor(theme.colors.success)
                }
            }

            Text(suggestion.description)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)

            // Avoid guidance: show live countdown if available, else static text
            if let avoidText = avoidTimeText, isCompleted {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                    Text(avoidText)
                        .font(theme.typography.caption)
                }
                .foregroundColor(theme.colors.warning)
            } else if let hours = suggestion.avoidHours {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Avoid cold drinks for \(hours) hours after")
                        .font(theme.typography.caption)
                }
                .foregroundColor(theme.colors.warning)
            }

            HStack(spacing: theme.spacing.md) {
                if isCompleted {
                    HStack(spacing: theme.spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(theme.colors.success)
                        Text("Completed Today")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.success)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.md)
                    .background(theme.colors.success.opacity(0.1))
                    .cornerRadius(theme.cornerRadius.large)
                } else {
                    TerrainPrimaryButton(title: "Do This", action: onDoThis)
                    TerrainTextButton(title: "Save as go-to", action: onSaveGoTo)
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}
