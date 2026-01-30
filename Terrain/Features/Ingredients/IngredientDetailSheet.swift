//
//  IngredientDetailSheet.swift
//  Terrain
//
//  Full ingredient detail modal with TCM information and cabinet actions
//

import SwiftUI
import SwiftData

/// Displays comprehensive information about a single ingredient.
/// Think of this as a detailed "recipe card" that shows everything you need to know:
/// what it does, how to use it, and when to be careful.
struct IngredientDetailSheet: View {
    let ingredient: Ingredient
    let isInCabinet: Bool
    let onToggleCabinet: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @Query private var userProfiles: [UserProfile]

    @State private var showTCMExplanation = false

    private let insightEngine = InsightEngine()

    private var terrainType: TerrainScoringEngine.PrimaryType {
        guard let profile = userProfiles.first,
              let terrainId = profile.terrainProfileId,
              let type = TerrainScoringEngine.PrimaryType(rawValue: terrainId) else {
            return .neutralBalanced
        }
        return type
    }

    private var terrainModifier: TerrainScoringEngine.Modifier {
        userProfiles.first?.resolvedModifier ?? .none
    }

    /// Terrain-specific explanation for why this ingredient matters for the user
    private var whyForYourTerrain: String? {
        insightEngine.generateWhyForYou(
            ingredientTags: ingredient.tags,
            terrainType: terrainType,
            modifier: terrainModifier
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.lg) {
                    // Header with image and names
                    headerSection

                    // Category and tags
                    categoryTagsSection

                    // Why It Helps
                    whyItHelpsSection

                    // How To Use
                    howToUseSection

                    // Cautions (if any)
                    if !ingredient.cautions.flags.isEmpty || !ingredient.cautions.text.localized.isEmpty {
                        cautionsSection
                    }

                    // Cultural context
                    if !ingredient.culturalContext.blurb.localized.isEmpty {
                        culturalContextSection
                    }

                    // Cabinet action button
                    cabinetActionButton

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: theme.spacing.md) {
            // Image placeholder
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .fill(theme.colors.backgroundSecondary)
                .frame(height: 180)
                .overlay(
                    Image(systemName: categoryIcon)
                        .font(.system(size: 56))
                        .foregroundColor(theme.colors.accent.opacity(0.5))
                )

            // Names
            VStack(spacing: theme.spacing.xs) {
                Text(ingredient.displayName)
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.textPrimary)

                if let pinyin = ingredient.name.pinyin, let hanzi = ingredient.name.hanzi {
                    Text("\(pinyin) \(hanzi)")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Category & Tags Section

    private var categoryTagsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Category chip
            if let category = IngredientCategory(rawValue: ingredient.category) {
                TerrainChip(title: category.displayName, isSelected: true)
            }

            // Tags
            if !ingredient.tags.isEmpty {
                FlowLayout(spacing: theme.spacing.xs) {
                    ForEach(ingredient.tags, id: \.self) { tag in
                        Text(formatTag(tag))
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(.horizontal, theme.spacing.xs)
                            .padding(.vertical, theme.spacing.xxs)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius.small)
                    }
                }
            }
        }
    }

    // MARK: - Why It Helps Section

    private var whyItHelpsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("Why It Helps")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            Text(ingredient.whyItHelps.plain.localized)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Expandable TCM explanation
            Button {
                withAnimation(theme.animation.standard) {
                    showTCMExplanation.toggle()
                }
                HapticManager.selection()
            } label: {
                HStack(spacing: theme.spacing.xs) {
                    Text("TCM Explanation")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.accent)

                    Image(systemName: showTCMExplanation ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.colors.accent)
                }
            }

            if showTCMExplanation {
                Text(ingredient.whyItHelps.tcm.localized)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(theme.spacing.sm)
                    .background(theme.colors.accent.opacity(0.08))
                    .cornerRadius(theme.cornerRadius.medium)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Terrain-specific "why" section
            if let terrainWhy = whyForYourTerrain {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("For your terrain")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.accent)

                    Text(terrainWhy)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .italic()
                }
                .padding(theme.spacing.sm)
                .background(theme.colors.accent.opacity(0.06))
                .cornerRadius(theme.cornerRadius.medium)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }

    // MARK: - How To Use Section

    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Text("How To Use")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)

            if !ingredient.howToUse.quickUses.isEmpty {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    ForEach(Array(ingredient.howToUse.quickUses.enumerated()), id: \.offset) { index, quickUse in
                        HStack(alignment: .top, spacing: theme.spacing.sm) {
                            Circle()
                                .fill(theme.colors.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                                Text(quickUse.text.localized)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundColor(theme.colors.textSecondary)

                                if quickUse.prepTimeMin > 0 {
                                    HStack(spacing: theme.spacing.xxs) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 10))
                                        Text("\(quickUse.prepTimeMin) min")
                                            .font(theme.typography.caption)
                                    }
                                    .foregroundColor(theme.colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }

            // Typical amount
            if !ingredient.howToUse.typicalAmount.localized.isEmpty {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "scalemass")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textTertiary)

                    Text(ingredient.howToUse.typicalAmount.localized)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
                .padding(.top, theme.spacing.xs)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }

    // MARK: - Cautions Section

    private var cautionsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.warning)

                Text("Cautions")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            // Safety flags
            if !ingredient.cautions.flags.isEmpty {
                FlowLayout(spacing: theme.spacing.xs) {
                    ForEach(ingredient.cautions.flags, id: \.self) { flag in
                        HStack(spacing: theme.spacing.xxs) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.system(size: 10))
                            Text(flag.displayName)
                                .font(theme.typography.caption)
                        }
                        .foregroundColor(theme.colors.warning)
                        .padding(.horizontal, theme.spacing.xs)
                        .padding(.vertical, theme.spacing.xxs)
                        .background(theme.colors.warning.opacity(0.1))
                        .cornerRadius(theme.cornerRadius.small)
                    }
                }
            }

            // Caution text
            if !ingredient.cautions.text.localized.isEmpty {
                Text(ingredient.cautions.text.localized)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.warning.opacity(0.05))
        .cornerRadius(theme.cornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                .stroke(theme.colors.warning.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Cultural Context Section

    private var culturalContextSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "globe.asia.australia")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)

                Text("Cultural Context")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }

            Text(ingredient.culturalContext.blurb.localized)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }

    // MARK: - Cabinet Action Button

    private var cabinetActionButton: some View {
        Button {
            onToggleCabinet()
            HapticManager.success()
        } label: {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: isInCabinet ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 20))

                Text(isInCabinet ? "In My Cabinet" : "Add to Cabinet")
                    .font(theme.typography.labelLarge)
            }
            .foregroundColor(isInCabinet ? theme.colors.success : theme.colors.textInverted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacing.md)
            .background(isInCabinet ? theme.colors.success.opacity(0.1) : theme.colors.accent)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isInCabinet ? theme.colors.success : Color.clear, lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private var categoryIcon: String {
        switch IngredientCategory(rawValue: ingredient.category) {
        case .spice: return "leaf.fill"
        case .root: return "carrot.fill"
        case .fruit: return "apple.logo"
        case .grain: return "circle.grid.3x3.fill"
        case .legume: return "oval.fill"
        case .fungus: return "laurel.leading"
        case .tea: return "cup.and.saucer.fill"
        case .protein: return "fish.fill"
        case .aromatic: return "wind"
        case .other, .none: return "leaf.fill"
        }
    }

    private func formatTag(_ tag: String) -> String {
        tag.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Preview

#Preview {
    IngredientDetailSheet(
        ingredient: Ingredient(
            id: "ginger",
            name: IngredientName(
                common: "Ginger",
                pinyin: "sheng jiang",
                hanzi: "生姜"
            ),
            category: "spice",
            tags: ["warming", "supports_digestion", "moves_qi"],
            goals: ["digestion", "warmth"],
            seasons: ["winter", "autumn"],
            whyItHelps: WhyItHelps(
                plain: "Ginger warms from within and helps settle the stomach. Great when you feel cold or sluggish.",
                tcm: "Warms the middle burner, disperses cold, stops nausea, and promotes sweating to release exterior cold patterns."
            ),
            howToUse: HowToUse(
                quickUses: [
                    QuickUse(text: "Slice fresh ginger and steep in hot water for 5 minutes", prepTimeMin: 5, methodTags: ["steep"]),
                    QuickUse(text: "Add to stir-fries or soups at the start of cooking", prepTimeMin: 2, methodTags: ["stir_in"])
                ],
                typicalAmount: "3-5 thin slices or 1 tsp grated"
            ),
            cautions: Cautions(
                flags: [.pregnancyCaution],
                text: "Use moderately if you tend to run warm or have acid reflux."
            ),
            culturalContext: CulturalContext(
                blurb: "A cornerstone of Chinese cooking and medicine for millennia. Every Chinese kitchen keeps fresh ginger on hand.",
                commonIn: ["chinese", "east_asian"]
            )
        ),
        isInCabinet: false,
        onToggleCabinet: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
