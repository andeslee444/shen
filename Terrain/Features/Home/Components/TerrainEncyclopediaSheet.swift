//
//  TerrainEncyclopediaSheet.swift
//  Terrain
//
//  Full encyclopedia of all 8 terrain types and modifiers.
//  Opens when the user taps the terrain chips on the Home tab.
//

import SwiftUI

/// A reference-guide sheet showing all 8 terrain types, all modifiers,
/// and a short TCM primer explaining how terrain classification works.
struct TerrainEncyclopediaSheet: View {
    /// The user's current terrain type — pre-expanded on open
    let currentType: TerrainScoringEngine.PrimaryType
    /// The user's current modifier
    let currentModifier: TerrainScoringEngine.Modifier

    @Environment(\.dismiss) private var dismiss
    @Environment(\.terrainTheme) private var theme

    /// Tracks which terrain type rows are expanded (user's type starts expanded)
    @State private var expandedTypes: Set<TerrainScoringEngine.PrimaryType>
    /// Tracks which modifier rows are expanded
    @State private var expandedModifiers: Set<TerrainScoringEngine.Modifier> = []

    private let constitutionService = ConstitutionService()

    init(currentType: TerrainScoringEngine.PrimaryType, currentModifier: TerrainScoringEngine.Modifier) {
        self.currentType = currentType
        self.currentModifier = currentModifier
        // Pre-expand the user's current type
        self._expandedTypes = State(initialValue: [currentType])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.xxl) {
                    // Section 1: The 8 Terrain Types
                    terrainTypesSection

                    divider

                    // Section 2: Modifiers
                    modifiersSection

                    divider

                    // Section 3: How Terrain Works
                    howTerrainWorksSection

                    Spacer(minLength: theme.spacing.xxxl)
                }
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle("Terrain Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(theme.colors.backgroundSecondary)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Divider()
            .padding(.horizontal, theme.spacing.sm)
    }

    // MARK: - Section 1: Terrain Types

    private var terrainTypesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            sectionHeader("The 8 Terrain Types")

            ForEach(TerrainScoringEngine.PrimaryType.allCases, id: \.rawValue) { type in
                terrainTypeRow(type)
            }
        }
    }

    private func terrainTypeRow(_ type: TerrainScoringEngine.PrimaryType) -> some View {
        let isExpanded = expandedTypes.contains(type)
        let isCurrent = type == currentType
        let components = TypeBlockComponents.from(terrainType: type, modifier: .none)

        return VStack(alignment: .leading, spacing: 0) {
            // Row header: tappable to expand/collapse
            Button {
                HapticManager.light()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedTypes.remove(type)
                    } else {
                        expandedTypes.insert(type)
                    }
                }
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    TypeChip(
                        label: type.nickname,
                        color: nicknameColor(for: components.temperature)
                    )

                    Text(type.label)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textTertiary)

                    Spacer()

                    if isCurrent {
                        Text("You")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, theme.spacing.xs)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent.opacity(0.12))
                            .cornerRadius(theme.cornerRadius.full)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textTertiary)
                }
                .padding(.vertical, theme.spacing.sm)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                terrainTypeDetail(type)
                    .padding(.top, theme.spacing.xs)
                    .padding(.bottom, theme.spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(isCurrent ? theme.colors.accent.opacity(0.04) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(isCurrent ? theme.colors.accent.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }

    private func terrainTypeDetail(_ type: TerrainScoringEngine.PrimaryType) -> some View {
        let copy = TerrainCopy.forType(type, modifier: .none)
        let defaults = constitutionService.generateDefaults(type: type, modifier: .none)
        let watchFors = constitutionService.generateWatchFors(type: type, modifier: .none)

        return VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // Superpower
            detailBlock(label: "Superpower", text: copy.superpower, icon: "bolt.fill")

            // Trap
            detailBlock(label: "Trap", text: copy.trap, icon: "exclamationmark.triangle")

            // Signature Ritual
            detailBlock(label: "Signature Ritual", text: copy.signatureRitual, icon: "sparkles")

            // Truths
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                detailLabel("Truths")
                ForEach(Array(copy.truths.enumerated()), id: \.offset) { _, truth in
                    HStack(alignment: .top, spacing: theme.spacing.xs) {
                        Text("\u{2022}")
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textTertiary)
                        Text(truth)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Best Defaults
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                detailLabel("Best Defaults")
                ForEach(Array(defaults.bestDefaults.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: theme.spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.colors.success)
                            .frame(width: 16)
                        Text(item)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Avoid
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                detailLabel("Avoid")
                ForEach(Array(defaults.avoidDefaults.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: theme.spacing.xs) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.colors.warning)
                            .frame(width: 16)
                        Text(item)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Watch-Fors
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                detailLabel("Watch-Fors")
                ForEach(Array(watchFors.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: theme.spacing.xs) {
                        Image(systemName: item.icon)
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.textTertiary)
                            .frame(width: 16)
                        Text(item.text)
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            // Key Ingredients
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                detailLabel("Key Ingredients")
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: theme.spacing.xs)
                ], alignment: .leading, spacing: theme.spacing.xs) {
                    ForEach(copy.recommendedIngredients, id: \.self) { ingredient in
                        Text(ingredient)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.textSecondary)
                            .padding(.horizontal, theme.spacing.xs)
                            .padding(.vertical, 4)
                            .background(theme.colors.backgroundSecondary)
                            .cornerRadius(theme.cornerRadius.small)
                    }
                }
            }
        }
        .padding(.leading, theme.spacing.xs)
    }

    // MARK: - Section 2: Modifiers

    /// Only the 4 active modifiers (excludes .none)
    private var activeModifiers: [TerrainScoringEngine.Modifier] {
        [.shen, .stagnation, .damp, .dry]
    }

    private var modifiersSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            sectionHeader("Modifiers")

            Text("Modifiers overlay your base type, adding a secondary pattern that shifts your daily guidance.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, theme.spacing.xs)

            ForEach(activeModifiers, id: \.rawValue) { modifier in
                modifierRow(modifier)
            }
        }
    }

    private func modifierRow(_ modifier: TerrainScoringEngine.Modifier) -> some View {
        let isExpanded = expandedModifiers.contains(modifier)
        let isCurrent = modifier == currentModifier
        let content = ModifierEncyclopediaContent.forModifier(modifier)

        return VStack(alignment: .leading, spacing: 0) {
            // Row header
            Button {
                HapticManager.light()
                withAnimation(.easeInOut(duration: 0.25)) {
                    if isExpanded {
                        expandedModifiers.remove(modifier)
                    } else {
                        expandedModifiers.insert(modifier)
                    }
                }
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    TypeChip(
                        label: modifier.displayName,
                        color: modifierChipColor(modifier)
                    )

                    Spacer()

                    if isCurrent {
                        Text("You")
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, theme.spacing.xs)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent.opacity(0.12))
                            .cornerRadius(theme.cornerRadius.full)
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.colors.textTertiary)
                }
                .padding(.vertical, theme.spacing.sm)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                modifierDetail(content)
                    .padding(.top, theme.spacing.xs)
                    .padding(.bottom, theme.spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(isCurrent ? theme.colors.accent.opacity(0.04) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .stroke(isCurrent ? theme.colors.accent.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }

    private func modifierDetail(_ content: ModifierEncyclopediaContent) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            // TCM Explanation
            detailBlock(label: "What it means", text: content.explanation, icon: "book")

            // Organ system
            detailBlock(label: "Organ system", text: content.organ, icon: "heart.circle")

            // Common triggers
            detailBlock(label: "Common triggers", text: content.triggers, icon: "exclamationmark.triangle")
        }
        .padding(.leading, theme.spacing.xs)
    }

    // MARK: - Section 3: How Terrain Works

    private var howTerrainWorksSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            sectionHeader("How Terrain Works")

            // The 5 axes
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                detailLabel("The 5 Axes")

                axisRow(name: "Temperature", description: "Cold to warm — your body's thermal tendency")
                axisRow(name: "Energy Reserve", description: "Deficient to excess — how much energy you store")
                axisRow(name: "Fluid Balance", description: "Damp to dry — how your body handles moisture")
                axisRow(name: "Flow", description: "Smooth to stagnant — how freely energy moves")
                axisRow(name: "Mind & Sleep", description: "Settled to restless — how easily your spirit calms")
            }

            // How types are determined
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                detailLabel("How types are determined")
                Text("Your terrain type comes from crossing two axes: Temperature (cold / neutral / warm) and Energy Reserve (deficient / balanced / excess). This creates 8 primary types — like coordinates on a map.")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }

            // How modifiers work
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                detailLabel("How modifiers work")
                Text("If one of the other three axes — Flow, Fluid Balance, or Mind & Sleep — scores above a threshold, it becomes a modifier that overlays your base type. Think of it as a weather pattern on top of your landscape.")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
            }

            // Disclaimer
            Text("This is not a diagnosis — it's a pattern map to guide daily rituals.")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .italic()
                .padding(.top, theme.spacing.sm)
        }
    }

    private func axisRow(name: String, description: String) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.sm) {
            Text(name)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textPrimary)
                .frame(width: 100, alignment: .leading)
            Text(description)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Shared Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.headlineMedium)
            .foregroundColor(theme.colors.textPrimary)
    }

    private func detailLabel(_ title: String) -> some View {
        Text(title)
            .font(theme.typography.labelSmall)
            .foregroundColor(theme.colors.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func detailBlock(label: String, text: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(theme.colors.textTertiary)
                detailLabel(label)
            }
            Text(text)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }

    private func nicknameColor(for temperature: TypeBlockComponents.TemperatureChip) -> Color {
        switch temperature {
        case .cold: return theme.colors.terrainCool
        case .neutral: return theme.colors.terrainNeutral
        case .warm: return theme.colors.terrainWarm
        }
    }

    private func modifierChipColor(_ modifier: TerrainScoringEngine.Modifier) -> Color {
        switch modifier {
        case .damp: return theme.colors.terrainCool
        case .dry: return theme.colors.terrainWarm
        case .stagnation: return theme.colors.warning
        case .shen: return theme.colors.info
        case .none: return theme.colors.textTertiary
        }
    }
}

// MARK: - Modifier Encyclopedia Content

/// Hardcoded TCM content for each modifier's encyclopedia entry
private struct ModifierEncyclopediaContent {
    let explanation: String
    let organ: String
    let triggers: String

    static func forModifier(_ modifier: TerrainScoringEngine.Modifier) -> ModifierEncyclopediaContent {
        switch modifier {
        case .shen:
            return ModifierEncyclopediaContent(
                explanation: "Your spirit (Shen) doesn't settle easily. The Heart houses the mind in TCM — when disturbed, sleep fractures and thoughts race.",
                organ: "Heart",
                triggers: "Overstimulation, irregular sleep, unresolved emotions"
            )
        case .stagnation:
            return ModifierEncyclopediaContent(
                explanation: "Qi should flow like a river. Yours gets blocked — often in the Liver channel — creating tension, irritability, and tightness.",
                organ: "Liver",
                triggers: "Emotional suppression, prolonged sitting, frustration"
            )
        case .damp:
            return ModifierEncyclopediaContent(
                explanation: "Your body accumulates fluid and heaviness. The Spleen — TCM's digestive center — struggles to transform and transport.",
                organ: "Spleen",
                triggers: "Heavy or greasy foods, excess dairy, humid environments"
            )
        case .dry:
            return ModifierEncyclopediaContent(
                explanation: "Your body runs low on nourishing fluids. Yin — the cool, moistening force — is depleted, leaving tissues dry.",
                organ: "Lung / Kidney",
                triggers: "Overwork, dehydration, excess heat exposure"
            )
        case .none:
            return ModifierEncyclopediaContent(
                explanation: "",
                organ: "",
                triggers: ""
            )
        }
    }
}

// MARK: - Preview

#Preview {
    TerrainEncyclopediaSheet(
        currentType: .warmDeficient,
        currentModifier: .shen
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
