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
        case .digestion: return "fork.knife"
        case .warmth: return "flame.fill"
        case .cooling: return "snowflake"
        case .focus: return "eye"
        }
    }

    /// Content-pack goals that relate to this need (used for need-goal scoring).
    /// While `relevantTags` maps to TCM-level tags (e.g. "warming", "calms_shen"),
    /// this maps to user-facing goals (e.g. "energy", "stress") so the engine
    /// can differentiate what the user is actually asking for.
    var relevantGoals: [String] {
        switch self {
        case .energy:    return ["energy"]
        case .calm:      return ["sleep", "stress"]
        case .digestion: return ["digestion"]
        case .warmth:    return ["energy"]
        case .cooling:   return ["skin"]
        case .focus:     return ["stress"]
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

// MARK: - Compact Quick Need Card (2-column grid)

struct QuickNeedCompactCard: View {
    let need: QuickNeed
    let isSelected: Bool
    var isCompleted: Bool = false
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: need.icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)

                Text(need.displayName)
                    .font(theme.typography.labelSmall)
                    .foregroundColor(isSelected ? theme.colors.accent : theme.colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(backgroundColor)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    private var iconColor: Color {
        if isCompleted {
            return theme.colors.success
        } else if isSelected {
            return theme.colors.accent
        }
        return theme.colors.accent
    }

    private var backgroundColor: Color {
        if isCompleted {
            return theme.colors.success.opacity(0.12)
        } else if isSelected {
            return theme.colors.accent.opacity(0.12)
        }
        return theme.colors.surface
    }

    private var borderColor: Color {
        if isCompleted {
            return theme.colors.success.opacity(0.3)
        } else if isSelected {
            return theme.colors.accent.opacity(0.4)
        }
        return theme.colors.backgroundSecondary
    }
}

// MARK: - Quick Need Card (legacy full-width)

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
    var whyForYou: String? = nil
    let onDoThis: () -> Void
    let onUndo: () -> Void

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

            // Terrain "why" callout — matches RoutineDetailSheet pattern
            if let why = whyForYou {
                HStack(alignment: .top, spacing: theme.spacing.xs) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.accent)
                        .padding(.top, 2)

                    Text(why)
                        .font(theme.typography.bodySmall)
                        .italic()
                        .foregroundColor(theme.colors.accent)
                }
                .padding(theme.spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.colors.accent.opacity(0.06))
                .cornerRadius(theme.cornerRadius.medium)
            }

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

            if isCompleted {
                Button(action: onUndo) {
                    HStack(spacing: theme.spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(theme.colors.success)
                        Text("Completed Today")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.success)
                        Spacer()
                        Text("Undo")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.md)
                .padding(.horizontal, theme.spacing.md)
                .background(theme.colors.success.opacity(0.1))
                .cornerRadius(theme.cornerRadius.large)
                .accessibilityLabel("Completed today. Tap to undo.")
            } else {
                TerrainPrimaryButton(title: "Do This", action: onDoThis)
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}
