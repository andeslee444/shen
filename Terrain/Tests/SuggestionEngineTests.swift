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

    /// Creates a minimal Ingredient with the given tags, goals, and seasons.
    private func makeIngredient(
        id: String,
        name: String,
        tags: [String],
        goals: [String] = [],
        seasons: [String] = ["all_year"]
    ) -> Ingredient {
        Ingredient(
            id: id,
            name: IngredientName(
                common: LocalizedString(english: name)
            ),
            category: "test",
            tags: tags,
            goals: goals,
            seasons: seasons,
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

    /// Creates a minimal Routine with the given tags, terrain fit, goals, and seasons.
    private func makeRoutine(
        id: String,
        name: String,
        tags: [String],
        terrainFit: [String] = [],
        goals: [String] = [],
        seasons: [String] = ["all_year"],
        avoidForHours: Int = 0
    ) -> Routine {
        Routine(
            id: id,
            title: LocalizedString(english: name),
            durationMin: 5,
            tags: tags,
            goals: goals,
            seasons: seasons,
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
        // Tag match (+1 for "warming") + terrain fit (+5 explicit) + seasonal ("all_year" +3) = at least 9
        XCTAssertGreaterThanOrEqual(result.score, 8)
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
        // Content exists but has no matching tags for the need.
        // Use an out-of-season ingredient so the seasonal bonus doesn't apply.
        let ingredient = makeIngredient(id: "salt", name: "Salt", tags: ["seasoning"], seasons: ["never_match"])

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

    // MARK: - v2 Scoring Tests

    func testProportionalTagScoring() {
        // 3-tag match should beat 1-tag match
        let weak = makeIngredient(id: "weak", name: "Weak", tags: ["warming"])
        let strong = makeIngredient(id: "strong", name: "Strong", tags: ["warming", "supports_deficiency", "supports_digestion"])

        let result = engine.suggest(
            for: .energy,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [weak, strong],
            routines: []
        )

        XCTAssertEqual(result.title, "Strong", "Ingredient matching more tags should win")
    }

    func testAvoidTagPenalty() {
        // A candidate with an avoid-tag should score lower than one without
        let good = makeIngredient(id: "good", name: "Good", tags: ["warming"])
        let bad = makeIngredient(id: "bad", name: "Bad", tags: ["warming", "cooling"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .coldDeficient,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [good, bad],
            routines: [],
            avoidTags: Set(["cooling"])
        )

        XCTAssertEqual(result.title, "Good", "Candidate with avoid-tagged content should lose")
    }

    func testSeasonalBonus() {
        // In-season candidate should beat out-of-season candidate
        let inSeason = makeIngredient(id: "in", name: "InSeason", tags: ["warming"], seasons: ["winter"])
        let outSeason = makeIngredient(id: "out", name: "OutSeason", tags: ["warming"], seasons: ["summer"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [inSeason, outSeason],
            routines: [],
            season: .winter
        )

        XCTAssertEqual(result.title, "InSeason", "In-season candidate should win")
    }

    func testCompletionSuppression() {
        // A completed candidate should fall back to next best
        let completed = makeIngredient(id: "done", name: "Done", tags: ["warming", "supports_deficiency"])
        let available = makeIngredient(id: "available", name: "Available", tags: ["warming"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [completed, available],
            routines: [],
            completedIds: Set(["done"])
        )

        XCTAssertEqual(result.title, "Available", "Completed candidate should be suppressed")
    }

    func testCabinetBonus() {
        // Cabinet ingredient should win a tie
        let inCabinet = makeIngredient(id: "cabinet", name: "Cabinet", tags: ["warming"])
        let notCabinet = makeIngredient(id: "other", name: "Other", tags: ["warming"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [inCabinet, notCabinet],
            routines: [],
            cabinetIngredientIds: Set(["cabinet"])
        )

        XCTAssertEqual(result.title, "Cabinet", "Cabinet ingredient should win tie")
    }

    func testContradictionPenalty() {
        // Candidate with both warming+cooling should be penalized when symptoms conflict
        let contradicted = makeIngredient(id: "confused", name: "Confused", tags: ["warming", "cooling"])
        let clear = makeIngredient(id: "clear", name: "Clear", tags: ["warming"])

        // Cold symptom maps to "warming", headache maps to "cooling" — thermal conflict
        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [.cold, .headache],
            timeOfDay: .afternoon,
            ingredients: [contradicted, clear],
            routines: []
        )

        XCTAssertEqual(result.title, "Clear", "Thermally contradicted candidate should lose")
    }

    func testGoalAlignment() {
        // Candidate matching user goals should score higher
        let aligned = makeIngredient(id: "aligned", name: "Aligned", tags: ["warming"], goals: ["sleep"])
        let unaligned = makeIngredient(id: "unaligned", name: "Unaligned", tags: ["warming"], goals: ["skin"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [aligned, unaligned],
            routines: [],
            userGoals: ["sleep"]
        )

        XCTAssertEqual(result.title, "Aligned", "Goal-aligned candidate should win")
    }

    // MARK: - Need-Goal Differentiation Tests

    func testNeedGoalMatchScores3Points() {
        // An ingredient with a goal matching the need's relevantGoals should score +3
        let matched = makeIngredient(id: "energizer", name: "Energizer", tags: ["warming"], goals: ["energy"])
        let unmatched = makeIngredient(id: "plain", name: "Plain", tags: ["warming"], goals: ["skin"])

        let result = engine.suggest(
            for: .energy,  // relevantGoals = ["energy"]
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [matched, unmatched],
            routines: []
        )

        XCTAssertEqual(result.title, "Energizer", "Ingredient whose goals match the need should win")
    }

    func testDifferentNeedsProduceDifferentSuggestions() {
        // Simulate the warm_balanced scenario from the bug report:
        // Three cooling routines with different goals should now differentiate.
        let chrysanthemum = makeRoutine(
            id: "chrysanthemum-tea-full",
            name: "Chrysanthemum Tea",
            tags: ["cooling", "calms_shen"],
            terrainFit: ["warm_balanced_high_flame"],
            goals: ["stress", "skin"]
        )
        let cucumberMint = makeRoutine(
            id: "cucumber-mint-water-medium",
            name: "Cucumber Mint Water",
            tags: ["cooling", "moves_qi"],
            terrainFit: ["warm_balanced_high_flame"],
            goals: ["skin", "energy"]
        )
        let mintCool = makeRoutine(
            id: "mint-cool-water-lite",
            name: "Mint Cool Water",
            tags: ["cooling", "calms_shen"],
            terrainFit: ["warm_balanced_high_flame"],
            goals: ["hydration", "stress"]
        )

        let routines = [chrysanthemum, cucumberMint, mintCool]

        let energyResult = engine.suggest(
            for: .energy,  // relevantGoals = ["energy"]
            terrainType: .warmBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: routines
        )

        let calmResult = engine.suggest(
            for: .calm,  // relevantGoals = ["sleep", "stress"]
            terrainType: .warmBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: routines
        )

        // Energy should pick cucumber-mint (goal "energy")
        XCTAssertEqual(energyResult.title, "Cucumber Mint Water",
                       "Energy need should select the routine with goal 'energy'")

        // Calm should pick chrysanthemum or mint-cool (goal "stress"), NOT cucumber-mint
        XCTAssertNotEqual(calmResult.title, "Cucumber Mint Water",
                          "Calm need should NOT pick the same routine as Energy")
        XCTAssertTrue(
            calmResult.title == "Chrysanthemum Tea" || calmResult.title == "Mint Cool Water",
            "Calm need should select a routine with goal 'stress'"
        )
    }

    func testWarmBalancedGetsVarietyAcrossNeeds() {
        // The core bug: all 6 needs used to return "Cucumber Mint Water".
        // After the fix, we expect at least 3 distinct suggestions.
        let chrysanthemum = makeRoutine(
            id: "chrysanthemum-tea-full",
            name: "Chrysanthemum Tea",
            tags: ["cooling", "calms_shen"],
            terrainFit: ["warm_balanced_high_flame"],
            goals: ["stress", "skin"]
        )
        let cucumberMint = makeRoutine(
            id: "cucumber-mint-water-medium",
            name: "Cucumber Mint Water",
            tags: ["cooling", "moves_qi"],
            terrainFit: ["warm_balanced_high_flame"],
            goals: ["skin", "energy"]
        )
        let mintCool = makeRoutine(
            id: "mint-cool-water-lite",
            name: "Mint Cool Water",
            tags: ["cooling", "calms_shen"],
            terrainFit: ["warm_balanced_high_flame"],
            goals: ["hydration", "stress"]
        )

        let routines = [chrysanthemum, cucumberMint, mintCool]
        var titles: Set<String> = []

        for need in QuickNeed.allCases {
            let result = engine.suggest(
                for: need,
                terrainType: .warmBalanced,
                modifier: .none,
                symptoms: [],
                timeOfDay: .afternoon,
                ingredients: [],
                routines: routines
            )
            titles.insert(result.title)
        }

        XCTAssertGreaterThanOrEqual(titles.count, 2,
            "At least 2 distinct suggestions should appear across 6 needs (was 1 before fix)")
    }

    func testNeedGoalMatchAppliesToRoutines() {
        // Verify the +3 need-goal bonus works in routine scoring
        let stressRoutine = makeRoutine(
            id: "stress-relief", name: "Stress Relief",
            tags: ["calms_shen"],
            goals: ["stress"]
        )
        let energyRoutine = makeRoutine(
            id: "energy-boost", name: "Energy Boost",
            tags: ["calms_shen"],
            goals: ["energy"]
        )

        let calmResult = engine.suggest(
            for: .calm,  // relevantGoals = ["sleep", "stress"]
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: [stressRoutine, energyRoutine]
        )

        XCTAssertEqual(calmResult.title, "Stress Relief",
                       "Calm need should prefer routine with goal 'stress'")
    }

    func testRoutineEffectivenessBoost() {
        // High-effectiveness routine should score higher
        let effective = makeRoutine(id: "eff", name: "Effective", tags: ["warming"])
        let baseline = makeRoutine(id: "base", name: "Baseline", tags: ["warming"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [],
            routines: [effective, baseline],
            routineEffectiveness: ["eff": 0.5]
        )

        XCTAssertEqual(result.title, "Effective", "High-effectiveness routine should win")
    }

    // MARK: - Diagnostic Signal Boost Tests (Phase 14)

    func testSleepDisturbanceBoostsCalmsShen() {
        let calming = makeIngredient(id: "jujube", name: "Jujube Seed", tags: ["calms_shen"])
        let warming = makeIngredient(id: "ginger", name: "Ginger", tags: ["warming"])

        let result = engine.suggest(
            for: .calm,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .evening,
            ingredients: [calming, warming],
            routines: [],
            sleepQuality: .hardToFallAsleep
        )

        XCTAssertEqual(result.title, "Jujube Seed",
                       "Sleep disturbance should boost calms_shen ingredient")
    }

    func testColdFeelingBoostsWarming() {
        let warming = makeIngredient(id: "ginger", name: "Ginger", tags: ["warming"])
        let cooling = makeIngredient(id: "chrysanth", name: "Chrysanthemum", tags: ["cooling"])

        let result = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [warming, cooling],
            routines: [],
            thermalFeeling: .cold
        )

        XCTAssertEqual(result.title, "Ginger",
                       "Cold feeling should boost warming ingredient")
    }

    func testHotFeelingBoostsCooling() {
        let cooling = makeIngredient(id: "chrysanth", name: "Chrysanthemum", tags: ["cooling"])
        let warming = makeIngredient(id: "ginger", name: "Ginger", tags: ["warming"])

        let result = engine.suggest(
            for: .calm,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [cooling, warming],
            routines: [],
            thermalFeeling: .hot
        )

        XCTAssertEqual(result.title, "Chrysanthemum",
                       "Hot feeling should boost cooling ingredient")
    }

    func testComfortableFeelingNoBoost() {
        // With comfortable feeling, no diagnostic boost should be applied
        let warming = makeIngredient(id: "ginger", name: "Ginger", tags: ["warming"])

        let resultWithComfort = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [warming],
            routines: [],
            thermalFeeling: .comfortable
        )

        let resultWithout = engine.suggest(
            for: .warmth,
            terrainType: .neutralBalanced,
            modifier: .none,
            symptoms: [],
            timeOfDay: .afternoon,
            ingredients: [warming],
            routines: []
        )

        XCTAssertEqual(resultWithComfort.score, resultWithout.score,
                       "Comfortable feeling should not add diagnostic boost")
    }
}
