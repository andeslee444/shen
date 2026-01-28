//
//  IngredientsView.swift
//  Terrain
//
//  Ingredients tab with cabinet and discovery
//

import SwiftUI
import SwiftData

struct IngredientsView: View {
    @Environment(\.terrainTheme) private var theme
    @Query private var cabinetItems: [UserCabinet]

    @State private var searchText = ""
    @State private var selectedCategory: IngredientCategory?
    @State private var selectedGoal: Goal?

    // Mock ingredients for now
    private let mockIngredients: [(name: String, category: IngredientCategory, tags: [String])] = [
        ("Ginger", .root, ["Warming", "Digestion"]),
        ("Red Dates", .fruit, ["Nourishing", "Blood"]),
        ("Goji Berries", .fruit, ["Moistening", "Eyes"]),
        ("Cinnamon", .spice, ["Warming", "Circulation"]),
        ("Green Tea", .tea, ["Cooling", "Alertness"]),
        ("Rice", .grain, ["Nourishing", "Digestion"]),
        ("Mung Bean", .legume, ["Cooling", "Detox"]),
        ("Shiitake", .fungus, ["Immune", "Qi"]),
        ("Honey", .other, ["Moistening", "Soothing"]),
        ("Sesame", .other, ["Moistening", "Nourishing"])
    ]

    var filteredIngredients: [(name: String, category: IngredientCategory, tags: [String])] {
        mockIngredients.filter { ingredient in
            let matchesSearch = searchText.isEmpty ||
                ingredient.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil ||
                ingredient.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Search
                    HStack(spacing: theme.spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(theme.colors.textTertiary)

                        TextField("Search ingredients", text: $searchText)
                            .font(theme.typography.bodyMedium)
                    }
                    .padding(theme.spacing.sm)
                    .background(theme.colors.surface)
                    .cornerRadius(theme.cornerRadius.medium)
                    .padding(.horizontal, theme.spacing.lg)

                    // Category filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: theme.spacing.xs) {
                            TerrainChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )

                            ForEach(IngredientCategory.allCases) { category in
                                TerrainChip(
                                    title: category.displayName,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                    }

                    // My Cabinet section
                    if !cabinetItems.isEmpty {
                        VStack(alignment: .leading, spacing: theme.spacing.sm) {
                            Text("My Cabinet")
                                .font(theme.typography.labelLarge)
                                .foregroundColor(theme.colors.textPrimary)
                                .padding(.horizontal, theme.spacing.lg)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: theme.spacing.sm) {
                                    ForEach(cabinetItems) { item in
                                        CabinetIngredientCard(ingredientId: item.ingredientId)
                                    }
                                }
                                .padding(.horizontal, theme.spacing.lg)
                            }
                        }
                    }

                    // All ingredients
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("All Ingredients")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.horizontal, theme.spacing.lg)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: theme.spacing.md) {
                            ForEach(filteredIngredients, id: \.name) { ingredient in
                                IngredientCard(
                                    name: ingredient.name,
                                    category: ingredient.category,
                                    tags: ingredient.tags,
                                    isInCabinet: cabinetItems.contains { $0.ingredientId == ingredient.name.lowercased() }
                                )
                            }
                        }
                        .padding(.horizontal, theme.spacing.lg)
                    }

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .navigationTitle("Ingredients")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CabinetIngredientCard: View {
    let ingredientId: String

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.xs) {
            Circle()
                .fill(theme.colors.accent.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "leaf.fill")
                        .foregroundColor(theme.colors.accent)
                )

            Text(ingredientId.capitalized)
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textPrimary)
        }
    }
}

struct IngredientCard: View {
    let name: String
    let category: IngredientCategory
    let tags: [String]
    var isInCabinet: Bool = false

    @Environment(\.terrainTheme) private var theme

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
                    Text(name)
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    if isInCabinet {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.colors.success)
                    }
                }

                Text(category.displayName)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)

                FlowLayout(spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
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
