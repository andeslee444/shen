//
//  SuggestionEngineTests.swift
//  TerrainTests
//
//  Tests for SuggestionEngine scoring algorithm.
//

import XCTest
@testable import Terrain

final class SuggestionEngineTests: XCTestCase {

    private let engine = SuggestionEngine()

    // MARK: - Helper Factories

    /// Creates a minimal Ingredient with the given tags.
    private func makeIngredient(id: String, name: String, tags: [String]) -> Ingredient {
        Ingredient(
            id: id,
            name: IngredientName(
                common: LocalizedString(english: name)
            ),
            category: "test",
            tags: tags,
            whyItHelps: WhyItHelps(
                plain: LocalizedString(english: "Test ingredient"),
                tcm: LocalizedString(english: "Test TCM")
            ),
            howToUse: HowToUse(
                quickUses: [QuickUse(text: LocalizedString(english: "Use it"))],
                typicalAmount: LocalizedString(english: "1 cup")
            ),
            culturalContext: CulturalContext(
                blurb: LocalizedString(english: "Test")
            )
        )
    }

    /// Creates a minimal Routine with the given tags and terrain fit.
    private func makeRoutine(
        id: String,
        name: String,
        tags: [String],
        terrainFit: [String] = [],
        avoidForHours: Int = 0
    ) -> Routine {
        Routine(
            id: id,
            title: LocalizedString(english: name),
            durationMin: 5,
            tags: tags,
            terrainFit: terrainFit,
            why: RoutineWhy(oneLine: LocalizedString(english: "Test routine")),
            avoidForHours: avoidForHours
        )
    }

    // MARK: - Scoring Tests

    func testTagMatchToNeedScores3Points() {
        // Energy need looks for "supports_deficiency" and "warming" tags
        let ingredient = makeIngredient(id: "ginger", name: "Ginger", tags: ["warming"])

        let result = engine.suggest(
            for: .energy,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [ingredient],
            routines: []
        )

        // Should find the ingredient (score > 0 means it was selected over fallback)
        XCTAssertEqual(result.title, "Ginger")
        XCTAssertGreaterThan(result.score, 0)
    }

    func testTerrainFitScores4Points() {
        // Create a routine with explicit terrain fit for cold_deficient
        let routine = makeRoutine(
            id: "warm-tea",
            name: "Warm Tea",
            tags: ["warming"],
            terrainFit: ["cold_deficient_low_flame"]
        )

        let result = engine.suggest(
            for: .warmth,
            terrainType: .coldDeficient,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: [routine]
        )

        XCTAssertEqual(result.title, "Warm Tea")
        // Tag match (+3) + terrain fit (+4) = at least 7
        XCTAssertGreaterThanOrEqual(result.score, 7)
    }

    func testModifierBoostScores2Points() {
        // Shen modifier should boost "calms_shen" tagged content
        let ingredient = makeIngredient(id: "chamomile", name: "Chamomile", tags: ["calms_shen"])

        let result = engine.suggest(
            for: .calm,
            terrainType: .neutralBalanced,
            modifier: .shen,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [ingredient],
            routines: []
        )

        XCTAssertEqual(result.title, "Chamomile")
        // Tag match (+3) + modifier boost (+2) = at least 5
        XCTAssertGreaterThanOrEqual(result.score, 5)
    }

    func testSymptomAlignmentScores3Points() {
        // Stressed symptom maps to "calms_shen" and "moves_qi"
        let ingredient = makeIngredient(id: "mint", name: "Mint", tags: ["moves_qi"])

        let result = engine.suggest(
            for: .focus,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [.stressed],
            timeOfDay: .afternoon,
            ingredients: [ingredient],
            routines: []
        )

        XCTAssertEqual(result.title, "Mint")
        // Tag match (+3 for focus) + symptom alignment (+3) = at least 6
        XCTAssertGreaterThanOrEqual(result.score, 6)
    }

    func testTimeOfDayBoostScores2Points() {
        // Morning favors "warming" and "supports_deficiency"
        let ingredient = makeIngredient(id: "ginger", name: "Ginger", tags: ["warming"])

        let morningResult = engine.suggest(
            for: .energy,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .morning,
            ingredients: [ingredient],
            routines: []
        )

        let nightResult = engine.suggest(
            for: .energy,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .night,
            ingredients: [ingredient],
            routines: []
        )

        // Morning should score higher for warming content
        XCTAssertGreaterThan(morningResult.score, nightResult.score)
    }

    func testAvoidGuidanceScores1Point() {
        let withAvoid = makeRoutine(
            id: "warm-tea",
            name: "Warm Tea",
            tags: ["warming"],
            terrainFit: [],
            avoidForHours: 2
        )
        let withoutAvoid = makeRoutine(
            id: "warm-tea-2",
            name: "Warm Tea 2",
            tags: ["warming"],
            terrainFit: [],
            avoidForHours: 0
        )

        let resultWith = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: [withAvoid]
        )

        let resultWithout = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: [withoutAvoid]
        )

        // The one with avoid guidance should score exactly 1 point more
        XCTAssertEqual(resultWith.score - resultWithout.score, 1)
    }

    // MARK: - Fallback Tests

    func testFallbackWhenNoCandidatesMatch() {
        // No content at all — should return the hardcoded fallback
        let result = engine.suggest(
            for: .energy,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: []
        )

        XCTAssertEqual(result.score, 0)
        XCTAssertNil(result.sourceId)
        XCTAssertEqual(result.title, "Ginger Honey Tea") // Energy fallback
    }

    func testFallbackWithIrrelevantContent() {
        // Content exists but has no matching tags for the need
        let ingredient = makeIngredient(id: "salt", name: "Salt", tags: ["seasoning"])

        let result = engine.suggest(
            for: .energy,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [ingredient],
            routines: []
        )

        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.title, "Ginger Honey Tea") // Fallback
    }

    // MARK: - Ordering Tests

    func testOrderedNeedsWithNoSymptoms() {
        let ordered = engine.orderedNeeds(for: [])
        // With no symptoms, order matches allCases
        XCTAssertEqual(ordered, QuickNeed.allCases.map { $0 })
    }

    func testOrderedNeedsBumpsRelevantToTop() {
        let ordered = engine.orderedNeeds(for: [.stressed])
        // "Calm" should be boosted to position 0 or 1 since .stressed maps to .calm
        let calmIndex = ordered.firstIndex(of: .calm)!
        XCTAssertLessThanOrEqual(calmIndex, 1, "Calm should be in top 2 when user is stressed")
    }

    func testOrderedNeedsColdBumpsWarmth() {
        let ordered = engine.orderedNeeds(for: [.cold])
        let warmthIndex = ordered.firstIndex(of: .warmth)!
        XCTAssertEqual(warmthIndex, 0, "Warmth should be first when user feels cold")
    }

    func testOrderedNeedsTiredBumpsEnergy() {
        let ordered = engine.orderedNeeds(for: [.tired])
        let energyIndex = ordered.firstIndex(of: .energy)!
        XCTAssertEqual(energyIndex, 0, "Energy should be first when user is tired")
    }

    // MARK: - Terrain Mapping Tests

    func testTerrainRecommendedTagsColdDeficient() {
        let tags = engine.terrainRecommendedTags(for: .coldDeficient, modifier: .none)
        XCTAssertTrue(tags.contains("warming"))
        XCTAssertTrue(tags.contains("supports_deficiency"))
    }

    func testTerrainRecommendedTagsWarmExcessWithShen() {
        let tags = engine.terrainRecommendedTags(for: .warmExcess, modifier: .shen)
        XCTAssertTrue(tags.contains("cooling"))
        XCTAssertTrue(tags.contains("calms_shen"))
    }

    func testTerrainRecommendedTagsDampModifier() {
        let tags = engine.terrainRecommendedTags(for: .neutralBalanced, modifier: .damp)
        XCTAssertTrue(tags.contains("dries_damp"))
    }

    // MARK: - Highest Score Wins

    func testHighestScoringCandidateWins() {
        // Create two ingredients: one with more matching criteria should win
        let weak = makeIngredient(id: "weak", name: "Weak Match", tags: ["warming"])
        let strong = makeIngredient(
            id: "strong",
            name: "Strong Match",
            tags: ["warming", "supports_deficiency", "calms_shen"]
        )

        let result = engine.suggest(
            for: .energy,
            terrainType: .coldDeficient,
            modifier: .shen,
            symptoms: [],
            timeOfDay: .morning,
            ingredients: [weak, strong],
            routines: []
        )

        XCTAssertEqual(result.title, "Strong Match")
    }

    // MARK: - TimeOfDay Tests

    func testTimeOfDayMorning() {
        // 8:00 AM
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        XCTAssertEqual(TimeOfDay.current(for: date), .morning)
    }

    func testTimeOfDayAfternoon() {
        var components = DateComponents()
        components.hour = 14
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        XCTAssertEqual(TimeOfDay.current(for: date), .afternoon)
    }

    func testTimeOfDayEvening() {
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        XCTAssertEqual(TimeOfDay.current(for: date), .evening)
    }

    func testTimeOfDayNight() {
        var components = DateComponents()
        components.hour = 23
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        XCTAssertEqual(TimeOfDay.current(for: date), .night)
    }

    func testTimeOfDayEarlyMorningIsNight() {
        var components = DateComponents()
        components.hour = 3
        components.minute = 0
        let date = Calendar.current.date(from: components)!
        XCTAssertEqual(TimeOfDay.current(for: date), .night)
    }
}
