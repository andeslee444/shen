//
//  OnboardingDataConsistencyTests.swift
//  TerrainTests
//
//  Cross-references the hardcoded onboarding data in TutorialPreviewView
//  against the real content pack. Think of this as a "contract test" —
//  if someone updates the content pack but forgets the tutorial, these tests catch it.
//

import XCTest
@testable import Terrain

final class OnboardingDataConsistencyTests: XCTestCase {

    var pack: ContentPackDTO!

    /// All ingredient common names in the content pack (lowercased for matching).
    private lazy var contentPackIngredientNames: Set<String> = {
        Set(pack.ingredients.map { $0.name.common.enUS.lowercased() })
    }()

    /// Ingredient tags indexed by lowercased common name.
    private lazy var ingredientTagsByName: [String: [String]] = {
        var map: [String: [String]] = [:]
        for ingredient in pack.ingredients {
            map[ingredient.name.common.enUS.lowercased()] = ingredient.tags
        }
        return map
    }()

    /// Known display-name aliases that map to actual content pack names.
    /// The onboarding uses friendly short names; the content pack sometimes uses
    /// formal names (e.g., "White Rice" not "Rice"). This avoids false failures.
    private let nameAliases: [String: String] = [
        "rice": "white rice",
        "sesame": "black sesame",
        "almond": "sweet almond",
        "dates": "red dates",
        "longan": "dried longan",
        "citrus peel": "dried citrus peel",
        "barley": "job's tears"   // TCM "barley" typically means Job's Tears (薏苡仁)
    ]

    /// Non-ingredient items that appear in combos but aren't standalone ingredients.
    /// These are preparation mediums, not things you'd look up in an ingredient database.
    /// Non-ingredient items that appear in combos but aren't standalone TCM ingredients.
    /// These are preparation mediums or common cooking items, not things you'd look up
    /// in the TCM ingredient database.
    private let nonIngredients: Set<String> = [
        "hot water", "warm milk", "cool water", "water", "broth",
        "rock sugar", "scallion", "vegetables", "sweet potato"
    ]

    override func setUp() {
        super.setUp()
        do {
            let url = try XCTUnwrap(
                Bundle(for: type(of: self)).url(forResource: "base-content-pack", withExtension: "json", subdirectory: "ContentPacks")
                ?? Bundle(for: type(of: self)).url(forResource: "base-content-pack", withExtension: "json")
                ?? Bundle.main.url(forResource: "base-content-pack", withExtension: "json", subdirectory: "ContentPacks")
                ?? Bundle.main.url(forResource: "base-content-pack", withExtension: "json"),
                "base-content-pack.json not found in test bundle"
            )
            let data = try Data(contentsOf: url)
            pack = try JSONDecoder().decode(ContentPackDTO.self, from: data)
        } catch {
            XCTFail("Failed to load content pack: \(error)")
        }
    }

    override func tearDown() {
        pack = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Find the terrain profile DTO matching a PrimaryType's rawValue (terrain profile ID).
    private func profile(for type: TerrainScoringEngine.PrimaryType) -> TerrainProfileDTO? {
        pack.terrain_profiles.first { $0.id == type.terrainProfileId }
    }

    /// Resolve a display name to a content pack name, checking aliases.
    private func resolvedName(_ displayName: String) -> String {
        let lower = displayName.lowercased()
        return nameAliases[lower] ?? lower
    }

    /// Extract individual ingredient names from a combo string like "Ginger + Honey + Hot Water".
    private func ingredientNames(from combo: String) -> [String] {
        combo.components(separatedBy: " + ").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Check if a display name corresponds to a real content pack ingredient.
    private func isKnownIngredient(_ displayName: String) -> Bool {
        let lower = displayName.lowercased()
        if nonIngredients.contains(lower) { return true }  // not an ingredient, skip
        let resolved = resolvedName(displayName)
        return contentPackIngredientNames.contains(resolved)
    }

    // MARK: - TerrainTagInfo Tests

    /// Every terrain type's recommended tags in TutorialPreviewView must match
    /// the content pack's recommended_tags (order-independent).
    func testAllTerrainRecommendedTagsMatchContentPack() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let tutorialInfo = TerrainTagInfo.forType(type)
            guard let contentProfile = profile(for: type) else {
                XCTFail("No content pack profile found for \(type) (id: \(type.terrainProfileId))")
                continue
            }

            let tutorialSet = Set(tutorialInfo.recommendedTags)
            let contentSet = Set(contentProfile.recommended_tags)

            XCTAssertEqual(
                tutorialSet, contentSet,
                "Recommended tags mismatch for \(type): tutorial=\(tutorialInfo.recommendedTags) vs content_pack=\(contentProfile.recommended_tags)"
            )
        }
    }

    /// Every terrain type's avoid tags in TutorialPreviewView must match
    /// the content pack's avoid_tags (order-independent).
    func testAllTerrainAvoidTagsMatchContentPack() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let tutorialInfo = TerrainTagInfo.forType(type)
            guard let contentProfile = profile(for: type) else {
                XCTFail("No content pack profile found for \(type) (id: \(type.terrainProfileId))")
                continue
            }

            let tutorialSet = Set(tutorialInfo.avoidTags)
            let contentSet = Set(contentProfile.avoid_tags)

            XCTAssertEqual(
                tutorialSet, contentSet,
                "Avoid tags mismatch for \(type): tutorial=\(tutorialInfo.avoidTags) vs content_pack=\(contentProfile.avoid_tags)"
            )
        }
    }

    /// TerrainTagInfo.forType() must not crash for any of the 8 terrain types.
    func testEveryTerrainTypeHasTagInfo() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let info = TerrainTagInfo.forType(type)
            XCTAssertFalse(
                info.recommendedTags.isEmpty,
                "\(type) should have at least one recommended tag"
            )
        }
    }

    // MARK: - TerrainDailyPractice Tests

    /// Every terrain type's daily practice references ingredients that exist in the content pack.
    func testDailyPracticeIngredientsExistInContentPack() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let practice = TerrainDailyPractice.forType(type)

            for combo in [practice.morning.ingredientCombo, practice.evening.ingredientCombo] {
                for name in ingredientNames(from: combo) {
                    XCTAssertTrue(
                        isKnownIngredient(name),
                        "\(type) daily practice references '\(name)' which is not in the content pack (combo: \(combo))"
                    )
                }
            }
        }
    }

    /// Cold terrain types should reference warming ingredients, not cooling ones.
    /// Warm terrain types should reference cooling ingredients, not warming ones.
    func testDailyPracticeTCMAlignment() {
        let coldTypes: [TerrainScoringEngine.PrimaryType] = [.coldDeficient, .coldBalanced]
        let warmTypes: [TerrainScoringEngine.PrimaryType] = [.warmExcess, .warmBalanced, .warmDeficient]

        for type in coldTypes {
            let practice = TerrainDailyPractice.forType(type)
            let allCombos = [practice.morning.ingredientCombo, practice.evening.ingredientCombo]
            for combo in allCombos {
                for name in ingredientNames(from: combo) {
                    let resolved = resolvedName(name)
                    if let tags = ingredientTagsByName[resolved] {
                        XCTAssertFalse(
                            tags.contains("cooling"),
                            "\(type) morning/evening practice uses cooling ingredient '\(name)' — contradicts cold terrain"
                        )
                    }
                }
            }
        }

        for type in warmTypes {
            let practice = TerrainDailyPractice.forType(type)
            let allCombos = [practice.morning.ingredientCombo, practice.evening.ingredientCombo]
            for combo in allCombos {
                for name in ingredientNames(from: combo) {
                    let resolved = resolvedName(name)
                    if let tags = ingredientTagsByName[resolved] {
                        XCTAssertFalse(
                            tags.contains("warming"),
                            "\(type) morning/evening practice uses warming ingredient '\(name)' — contradicts warm terrain"
                        )
                    }
                }
            }
        }
    }

    /// Duration values should be reasonable: 1–30 minutes for routines, 1–30 for movements.
    func testDailyPracticeDurationsReasonable() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let practice = TerrainDailyPractice.forType(type)

            for (label, block) in [("morning", practice.morning), ("evening", practice.evening)] {
                XCTAssertGreaterThan(block.routineMinutes, 0,
                                      "\(type) \(label) routine duration must be positive")
                XCTAssertLessThanOrEqual(block.routineMinutes, 30,
                                          "\(type) \(label) routine duration seems too long: \(block.routineMinutes) min")
                XCTAssertGreaterThan(block.movementMinutes, 0,
                                      "\(type) \(label) movement duration must be positive")
                XCTAssertLessThanOrEqual(block.movementMinutes, 30,
                                          "\(type) \(label) movement duration seems too long: \(block.movementMinutes) min")
            }
        }
    }

    /// Every terrain type produces non-empty daily practice data.
    func testEveryTerrainTypeHasDailyPractice() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let practice = TerrainDailyPractice.forType(type)
            XCTAssertFalse(practice.morning.routineName.isEmpty,
                            "\(type) morning routine name should not be empty")
            XCTAssertFalse(practice.evening.routineName.isEmpty,
                            "\(type) evening routine name should not be empty")
            XCTAssertFalse(practice.morning.movementName.isEmpty,
                            "\(type) morning movement name should not be empty")
            XCTAssertFalse(practice.evening.movementName.isEmpty,
                            "\(type) evening movement name should not be empty")
        }
    }

    // MARK: - TerrainQuickFixInfo Tests

    /// Every terrain type produces exactly 4 quick fixes.
    func testQuickFixReturns4PerType() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let fixes = TerrainQuickFixInfo.forType(type)
            XCTAssertEqual(fixes.count, 4,
                            "\(type) should have exactly 4 quick fixes, got \(fixes.count)")
        }
    }

    /// Quick fixes should have non-empty fields.
    func testQuickFixFieldsNonEmpty() {
        for type in TerrainScoringEngine.PrimaryType.allCases {
            let fixes = TerrainQuickFixInfo.forType(type)
            for (index, fix) in fixes.enumerated() {
                XCTAssertFalse(fix.emoji.isEmpty,
                                "\(type) quick fix \(index) has empty emoji")
                XCTAssertFalse(fix.need.isEmpty,
                                "\(type) quick fix \(index) has empty need")
                XCTAssertFalse(fix.suggestion.isEmpty,
                                "\(type) quick fix \(index) has empty suggestion")
                XCTAssertFalse(fix.duration.isEmpty,
                                "\(type) quick fix \(index) has empty duration")
            }
        }
    }

    /// Cold types should not suggest cooling ingredients in quick fixes.
    /// Warm types should not suggest warming ingredients in quick fixes.
    func testQuickFixTCMAlignment() {
        let coldTypes: [TerrainScoringEngine.PrimaryType] = [.coldDeficient, .coldBalanced]
        let warmTypes: [TerrainScoringEngine.PrimaryType] = [.warmExcess, .warmBalanced]

        // Cold types: quick fix suggestions should not reference cooling ingredients
        for type in coldTypes {
            let fixes = TerrainQuickFixInfo.forType(type)
            let coolingIngredientNames = pack.ingredients
                .filter { $0.tags.contains("cooling") }
                .map { $0.name.common.enUS.lowercased() }
            for fix in fixes {
                let suggestionLower = fix.suggestion.lowercased()
                for coolingName in coolingIngredientNames {
                    XCTAssertFalse(
                        suggestionLower.contains(coolingName),
                        "\(type) quick fix '\(fix.suggestion)' references cooling ingredient '\(coolingName)'"
                    )
                }
            }
        }

        // Warm types: quick fix suggestions should not reference warming ingredients
        for type in warmTypes {
            let fixes = TerrainQuickFixInfo.forType(type)
            let warmingIngredientNames = pack.ingredients
                .filter { $0.tags.contains("warming") }
                .map { $0.name.common.enUS.lowercased() }
            for fix in fixes {
                let suggestionLower = fix.suggestion.lowercased()
                for warmingName in warmingIngredientNames {
                    XCTAssertFalse(
                        suggestionLower.contains(warmingName),
                        "\(type) quick fix '\(fix.suggestion)' references warming ingredient '\(warmingName)'"
                    )
                }
            }
        }
    }
}
