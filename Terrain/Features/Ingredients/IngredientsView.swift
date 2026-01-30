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
    @State private var selectedIngredient: Ingredient?

    // MARK: - Computed Properties

    /// Whether the user has an active search/category filter.
    /// Think of this as asking "is the user narrowing their view?"
    private var hasActiveFilter: Bool {
        !searchText.isEmpty || selectedCategory != nil
    }

    /// Single source of truth for "does this ingredient pass the current filter?"
    /// Every section on the page runs through this same gate.
    private func matchesFilter(_ ingredient: Ingredient) -> Bool {
        let matchesSearch = searchText.isEmpty ||
            ingredient.displayName.localizedCaseInsensitiveContains(searchText)
        let matchesCategory = selectedCategory == nil ||
            IngredientCategory(rawValue: ingredient.category) == selectedCategory
        return matchesSearch && matchesCategory
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

    /// Current season based on calendar month
    private var currentSeason: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }

    /// Display name for the current season
    private var seasonDisplayName: String {
        currentSeason.capitalized
    }

    /// Seasonal ingredients that also pass the current filter
    private var filteredSeasonalIngredients: [Ingredient] {
        allIngredients.filter { ingredient in
            matchesFilter(ingredient) &&
            (ingredient.seasons.contains(currentSeason) ||
             ingredient.seasons.contains("all_year"))
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Search
                    searchBar

                    // Category filters
                    categoryFilters

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

                    // In Season section
                    if !filteredSeasonalIngredients.isEmpty {
                        seasonalSection
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
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.medium)
        .padding(.horizontal, theme.spacing.lg)
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
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
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }

    private var cabinetSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "cabinet.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)
                    .accessibilityHidden(true)

                Text("My Cabinet")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
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
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)

                Text("Recommended for You")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
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
                                isInCabinet: isInCabinet(ingredient.id)
                            )
                            .frame(width: 160)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }
        }
    }

    private var seasonalSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: seasonIcon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)

                Text("In Season (\(seasonDisplayName))")
                    .font(theme.typography.labelLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .padding(.horizontal, theme.spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.md) {
                    ForEach(filteredSeasonalIngredients.prefix(8)) { ingredient in
                        Button {
                            selectedIngredient = ingredient
                            HapticManager.light()
                        } label: {
                            IngredientCard(
                                ingredient: ingredient,
                                isInCabinet: isInCabinet(ingredient.id)
                            )
                            .frame(width: 160)
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
            Text("All Ingredients")
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.textPrimary)
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
                                isInCabinet: isInCabinet(ingredient.id)
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
            print("Failed to save cabinet item: \(error)")
        }
    }

    private func removeFromCabinet(_ item: UserCabinet) {
        modelContext.delete(item)
        do {
            try modelContext.save()
            HapticManager.light()
        } catch {
            print("Failed to remove cabinet item: \(error)")
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

    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Circle()
                .fill(theme.colors.accent.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .foregroundColor(theme.colors.accent)
                )

            Text(ingredientName)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(1)
        }
    }
}

// MARK: - Ingredient Card

struct IngredientCard: View {
    let ingredient: Ingredient
    var isInCabinet: Bool = false

    @Environment(\.terrainTheme) private var theme

    /// Formats tags for display (converts snake_case to human-readable)
    private var displayTags: [String] {
        ingredient.tags.prefix(3).map { tag in
            tag.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Image placeholder
            RoundedRectangle(cornerRadius: theme.cornerRadius.medium)
                .fill(theme.colors.backgroundSecondary)
                .frame(height: 100)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 32))
                        .foregroundColor(theme.colors.accent.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(ingredient.displayName)
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)

                    if isInCabinet {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.success)
                    }
                }

                if let category = IngredientCategory(rawValue: ingredient.category) {
                    Text(category.displayName)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }

                FlowLayout(spacing: 4) {
                    ForEach(displayTags, id: \.self) { tag in
                        Text(tag)
                            .font(theme.typography.caption)
                            .foregroundColor(theme.colors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.colors.accent.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

#Preview {
    IngredientsView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
