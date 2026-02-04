//
//  IngredientsView.swift
//  Terrain
//
//  Ingredients tab with cabinet, discovery, and terrain-aware recommendations
//

import SwiftUI
import SwiftData

struct IngredientsView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query private var cabinetItems: [UserCabinet]
    @Query(sort: \Ingredient.id) private var allIngredients: [Ingredient]
    @Query private var userProfiles: [UserProfile]
    @Query private var terrainProfiles: [TerrainProfile]

    @State private var searchText = ""
    @State private var selectedCategory: IngredientCategory?
    @State private var selectedBenefit: IngredientBenefit?
    @State private var selectedIngredient: Ingredient?
    @State private var inSeasonOnly = false

    /// Which filter dimension is showing: category chips or benefit chips
    enum FilterMode: String, CaseIterable {
        case category = "Category"
        case benefit = "Benefit"
    }
    @State private var filterMode: FilterMode = .category

    // MARK: - Computed Properties

    /// Whether the user has an active search/category filter.
    /// Think of this as asking "is the user narrowing their view?"
    private var hasActiveFilter: Bool {
        !searchText.isEmpty || selectedCategory != nil || selectedBenefit != nil || inSeasonOnly
    }

    /// Single source of truth for "does this ingredient pass the current filter?"
    /// Every section on the page runs through this same gate.
    private func matchesFilter(_ ingredient: Ingredient) -> Bool {
        let matchesSearch = searchText.isEmpty ||
            ingredient.displayName.localizedCaseInsensitiveContains(searchText)
        let matchesCategory = selectedCategory == nil ||
            IngredientCategory(rawValue: ingredient.category) == selectedCategory
        let matchesBenefit = selectedBenefit == nil ||
            selectedBenefit!.matches(ingredient)
        let matchesSeason = !inSeasonOnly ||
            ingredient.seasons.contains(currentSeason)
        return matchesSearch && matchesCategory && matchesBenefit && matchesSeason
    }

    /// All ingredients that pass the current search + category filter
    private var filteredIngredients: [Ingredient] {
        allIngredients.filter { matchesFilter($0) }
    }

    /// Cabinet ingredients that pass the current filter
    private var filteredCabinetItems: [(cabinet: UserCabinet, ingredient: Ingredient)] {
        cabinetItems.compactMap { item in
            guard let ingredient = allIngredients.first(where: { $0.id == item.ingredientId }),
                  matchesFilter(ingredient) else { return nil }
            return (cabinet: item, ingredient: ingredient)
        }
    }

    /// Tags recommended for the user's terrain profile
    private var recommendedTags: [String] {
        guard let profileId = userProfiles.first?.terrainProfileId,
              let profile = terrainProfiles.first(where: { $0.id == profileId }) else {
            return []
        }
        return profile.recommendedTags
    }

    /// Recommended ingredients that also pass the current filter
    private var filteredRecommendedIngredients: [Ingredient] {
        guard !recommendedTags.isEmpty else { return [] }
        return allIngredients.filter { ingredient in
            matchesFilter(ingredient) &&
            ingredient.tags.contains { recommendedTags.contains($0) }
        }
    }

    /// Current season using TCM's five-season model (五季).
    /// Late summer (长夏) is the Earth-element transition period (August–September)
    /// when dampness peaks and damp-draining foods are most relevant.
    private var currentSeason: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...7: return "summer"
        case 8, 9: return "late_summer"
        case 10, 11: return "autumn"
        default: return "winter"
        }
    }

    /// Display name for the current season
    private var seasonDisplayName: String {
        currentSeason == "late_summer" ? "Late Summer" : currentSeason.capitalized
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Search
                    searchBar

                    // Consolidated filter row
                    filterRow

                    // My Cabinet section
                    if cabinetItems.isEmpty {
                        if !allIngredients.isEmpty && !hasActiveFilter {
                            TerrainEmptyState.emptyCabinet(onAddIngredients: {
                                searchText = ""
                                selectedCategory = nil
                            })
                        }
                    } else if !filteredCabinetItems.isEmpty {
                        cabinetSection
                    }

                    // Recommended for you section (terrain-aware)
                    if !filteredRecommendedIngredients.isEmpty {
                        recommendedSection
                    }

                    // All ingredients
                    allIngredientsSection

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle("Ingredients")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedIngredient) { ingredient in
                IngredientDetailSheet(
                    ingredient: ingredient,
                    isInCabinet: isInCabinet(ingredient.id),
                    onToggleCabinet: {
                        toggleCabinet(ingredient.id)
                    }
                )
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.colors.textTertiary)
                .accessibilityHidden(true)

            TextField("Search ingredients", text: $searchText)
                .font(theme.typography.bodyMedium)
                .accessibilityLabel("Search ingredients")
                .accessibilityHint("Search by ingredient name")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    HapticManager.light()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
        .padding(.horizontal, theme.spacing.lg)
    }

    /// Consolidated filter: Category ↔ Benefit chip toggle + In Season toggle
    private var filterRow: some View {
        VStack(spacing: theme.spacing.xs) {
            // Toggle header + In Season + clear button
            HStack(spacing: theme.spacing.xs) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(theme.animation.quick) {
                            filterMode = mode
                        }
                        HapticManager.selection()
                    } label: {
                        Text(mode.rawValue)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(filterMode == mode ? theme.colors.accent : theme.colors.textTertiary)
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xxs)
                    }
                }

                // In Season — independent toggle that layers on top of category/benefit
                Button {
                    withAnimation(theme.animation.quick) {
                        inSeasonOnly.toggle()
                    }
                    HapticManager.selection()
                } label: {
                    HStack(spacing: theme.spacing.xxs) {
                        Image(systemName: seasonIcon)
                            .font(.system(size: 10))
                        Text("In Season")
                            .font(theme.typography.labelSmall)
                    }
                    .foregroundColor(inSeasonOnly ? theme.colors.accent : theme.colors.textTertiary)
                    .padding(.horizontal, theme.spacing.sm)
                    .padding(.vertical, theme.spacing.xxs)
                    .background(inSeasonOnly ? theme.colors.accent.opacity(0.12) : Color.clear)
                    .cornerRadius(theme.cornerRadius.full)
                }

                Spacer()

                // Clear button — only visible when a filter is active
                if selectedCategory != nil || selectedBenefit != nil || inSeasonOnly {
                    Button {
                        withAnimation(theme.animation.quick) {
                            selectedCategory = nil
                            selectedBenefit = nil
                            inSeasonOnly = false
                        }
                        HapticManager.light()
                    } label: {
                        Text("Clear")
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.accent)
                    }
                }
            }
            .padding(.horizontal, theme.spacing.lg)

            // Active chip row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.xs) {
                    switch filterMode {
                    case .category:
                        TerrainChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: {
                                selectedCategory = nil
                                HapticManager.selection()
                            }
                        )

                        ForEach(IngredientCategory.allCases) { category in
                            TerrainChip(
                                title: category.displayName,
                                isSelected: selectedCategory == category,
                                action: {
                                    selectedCategory = category
                                    HapticManager.selection()
                                }
                            )
                        }

                    case .benefit:
                        ForEach(IngredientBenefit.allCases) { benefit in
                            TerrainChip(
                                title: benefit.displayName,
                                icon: benefit.icon,
                                isSelected: selectedBenefit == benefit,
                                action: {
                                    selectedBenefit = selectedBenefit == benefit ? nil : benefit
                                    HapticManager.selection()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    private var cabinetSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "cabinet.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.accent)
                        .accessibilityHidden(true)

                    Text("My Cabinet")
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Text("\(filteredCabinetItems.count) ingredient\(filteredCabinetItems.count == 1 ? "" : "s") saved")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .accessibilityAddTraits(.isHeader)
            .padding(.horizontal, theme.spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.sm) {
                    ForEach(filteredCabinetItems, id: \.cabinet.id) { pair in
                        Button {
                            selectedIngredient = pair.ingredient
                            HapticManager.light()
                        } label: {
                            CabinetIngredientCard(
                                ingredientId: pair.ingredient.id,
                                ingredients: allIngredients
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(theme.colors.accent)

                    Text("Recommended for You")
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)
                }

                Text("Based on your terrain profile")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(.horizontal, theme.spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.md) {
                    ForEach(filteredRecommendedIngredients.prefix(8)) { ingredient in
                        Button {
                            selectedIngredient = ingredient
                            HapticManager.light()
                        } label: {
                            IngredientCard(
                                ingredient: ingredient,
                                isInCabinet: isInCabinet(ingredient.id),
                                activeBenefit: selectedBenefit
                            )
                            .frame(width: gridCardWidth)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    private var allIngredientsSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Text("All Ingredients")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)

                Spacer()

                Text("\(filteredIngredients.count)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
                    .padding(.horizontal, theme.spacing.xs)
                    .padding(.vertical, theme.spacing.xxs)
                    .background(theme.colors.backgroundSecondary)
                    .cornerRadius(theme.cornerRadius.small)
            }
            .padding(.horizontal, theme.spacing.lg)

            if filteredIngredients.isEmpty && !allIngredients.isEmpty {
                Text("No ingredients match your search")
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.xl)
            } else if allIngredients.isEmpty {
                VStack(spacing: theme.spacing.md) {
                    ProgressView()
                    Text("Loading ingredients...")
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.xl)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: theme.spacing.md) {
                    ForEach(filteredIngredients) { ingredient in
                        Button {
                            selectedIngredient = ingredient
                            HapticManager.light()
                        } label: {
                            IngredientCard(
                                ingredient: ingredient,
                                isInCabinet: isInCabinet(ingredient.id),
                                activeBenefit: selectedBenefit
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    // MARK: - Helpers

    /// Card width that matches the 2-column grid in All Ingredients.
    /// Formula mirrors LazyVGrid: (screen - left padding - right padding - column gap) / 2
    private var gridCardWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let horizontalPadding = theme.spacing.lg * 2
        let columnSpacing = theme.spacing.md
        return floor((screenWidth - horizontalPadding - columnSpacing) / 2)
    }

    private var seasonIcon: String {
        switch currentSeason {
        case "spring": return "leaf.fill"
        case "summer": return "sun.max.fill"
        case "autumn": return "leaf.fill"
        case "winter": return "snowflake"
        default: return "calendar"
        }
    }

    private func isInCabinet(_ ingredientId: String) -> Bool {
        cabinetItems.contains { $0.ingredientId == ingredientId }
    }

    private func toggleCabinet(_ ingredientId: String) {
        if let existingItem = cabinetItems.first(where: { $0.ingredientId == ingredientId }) {
            removeFromCabinet(existingItem)
        } else {
            addToCabinet(ingredientId)
        }
    }

    private func addToCabinet(_ ingredientId: String) {
        guard !isInCabinet(ingredientId) else { return }
        let item = UserCabinet(ingredientId: ingredientId)
        modelContext.insert(item)
        do {
            try modelContext.save()
            HapticManager.success()
        } catch {
            TerrainLogger.persistence.error("Failed to save cabinet item: \(error)")
        }
    }

    private func removeFromCabinet(_ item: UserCabinet) {
        modelContext.delete(item)
        do {
            try modelContext.save()
            HapticManager.light()
        } catch {
            TerrainLogger.persistence.error("Failed to remove cabinet item: \(error)")
        }
    }
}

// MARK: - Cabinet Ingredient Card

struct CabinetIngredientCard: View {
    let ingredientId: String
    let ingredients: [Ingredient]

    @Environment(\.terrainTheme) private var theme

    /// Looks up the actual ingredient by ID to get the proper display name
    private var ingredientName: String {
        ingredients.first { $0.id == ingredientId }?.displayName ?? ingredientId.capitalized
    }

    /// Looks up the ingredient's emoji via the IngredientEmoji extension
    private var ingredientEmoji: String {
        ingredients.first { $0.id == ingredientId }?.emoji ?? "🌿"
    }

    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Circle()
                .fill(theme.colors.accent.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(ingredientEmoji)
                        .font(.system(size: 28))
                )

            Text(ingredientName)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
        }
    }
}

// MARK: - Ingredient Card (Compact)

struct IngredientCard: View {
    let ingredient: Ingredient
    var isInCabinet: Bool = false
    /// When a benefit filter is active, this ensures the filtered benefit
    /// is the one displayed on the card (not buried in the "+N" count).
    var activeBenefit: IngredientBenefit? = nil

    @Environment(\.terrainTheme) private var theme

    /// All benefits that match this ingredient
    private var allBenefits: [IngredientBenefit] {
        IngredientBenefit.allCases.filter { $0.matches(ingredient) }
    }

    /// The benefit to display on the card. If the user is filtering by a
    /// benefit, that one gets priority so the card explains *why* it appeared.
    private var displayedBenefit: IngredientBenefit? {
        if let active = activeBenefit, active.matches(ingredient) {
            return active
        }
        return allBenefits.first
    }

    /// How many additional benefits exist beyond the one shown.
    /// e.g. 4 total - 1 shown = "+3"
    private var additionalBenefitCount: Int {
        max(allBenefits.count - 1, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Emoji + name row
            HStack(spacing: theme.spacing.sm) {
                Circle()
                    .fill(theme.colors.accent.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(ingredient.emoji)
                            .font(.system(size: 22))
                    )

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: theme.spacing.xxs) {
                        Text(ingredient.displayName)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        if isInCabinet {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(theme.colors.success)
                        }
                    }

                    // Benefit label + additional count
                    if let benefit = displayedBenefit {
                        HStack(spacing: theme.spacing.xxs) {
                            Text(benefit.displayName)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)

                            if additionalBenefitCount > 0 {
                                Text("+\(additionalBenefitCount)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(theme.colors.accent)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(theme.colors.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // 2-line description teaser
            Text(ingredient.whyItHelps.plain.localized)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    IngredientsView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
