//
//  TerrainScoringEngineTests.swift
//  TerrainTests
//
//  Unit tests for the Terrain Scoring Engine
//

import XCTest
@testable import Terrain

final class TerrainScoringEngineTests: XCTestCase {
    var engine: TerrainScoringEngine!

    override func setUp() {
        super.setUp()
        engine = TerrainScoringEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Primary Type Tests

    func testColdDeficientType() {
        let vector = TerrainVector(coldHeat: -5, defExcess: -5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .coldDeficient)
        XCTAssertEqual(result.primaryType.nickname, "Low Flame")
    }

    func testColdBalancedType() {
        let vector = TerrainVector(coldHeat: -4, defExcess: 0)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .coldBalanced)
        XCTAssertEqual(result.primaryType.nickname, "Cool Core")
    }

    func testNeutralDeficientType() {
        let vector = TerrainVector(coldHeat: 0, defExcess: -5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .neutralDeficient)
        XCTAssertEqual(result.primaryType.nickname, "Low Battery")
    }

    func testNeutralBalancedType() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 0)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .neutralBalanced)
        XCTAssertEqual(result.primaryType.nickname, "Steady Core")
    }

    func testNeutralExcessType() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .neutralExcess)
        XCTAssertEqual(result.primaryType.nickname, "Busy Mind")
    }

    func testWarmBalancedType() {
        let vector = TerrainVector(coldHeat: 5, defExcess: 0)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .warmBalanced)
        XCTAssertEqual(result.primaryType.nickname, "High Flame")
    }

    func testWarmExcessType() {
        let vector = TerrainVector(coldHeat: 5, defExcess: 5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .warmExcess)
        XCTAssertEqual(result.primaryType.nickname, "Overclocked")
    }

    func testWarmDeficientType() {
        let vector = TerrainVector(coldHeat: 5, defExcess: -5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .warmDeficient)
        XCTAssertEqual(result.primaryType.nickname, "Bright but Thin")
    }

    // MARK: - Modifier Tests

    func testDampModifier() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, dampDry: -5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, TerrainScoringEngine.Modifier.damp)
    }

    func testDryModifier() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, dampDry: 5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, .dry)
    }

    func testStagnationModifier() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, qiStagnation: 6)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, .stagnation)
    }

    func testShenModifier() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, shenUnsettled: 6)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, .shen)
    }

    func testNoModifier() {
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, dampDry: 0, qiStagnation: 2, shenUnsettled: 2)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, .none)
    }

    // MARK: - Modifier Priority Tests

    func testShenTakesPriorityOverStagnation() {
        // When both shen and stagnation are high but equal, shen wins
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, qiStagnation: 5, shenUnsettled: 5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, .shen)
    }

    func testHigherMagnitudeWins() {
        // When stagnation is higher magnitude, it wins over shen
        let vector = TerrainVector(coldHeat: 0, defExcess: 0, qiStagnation: 8, shenUnsettled: 4)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.modifier, .stagnation)
    }

    // MARK: - Threshold Edge Cases

    func testColdThresholdExact() {
        // Exactly at -3 should be cold
        let vector = TerrainVector(coldHeat: -3, defExcess: 0)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .coldBalanced)
    }

    func testNeutralAtMinusTwoHeat() {
        // -2 should still be neutral
        let vector = TerrainVector(coldHeat: -2, defExcess: 0)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .neutralBalanced)
    }

    func testWarmThresholdExact() {
        // Exactly at 3 should be warm
        let vector = TerrainVector(coldHeat: 3, defExcess: 0)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.primaryType, .warmBalanced)
    }

    // MARK: - Vector Clamping Tests

    func testVectorClampingMax() {
        let vector = TerrainVector(coldHeat: 15, defExcess: 15, dampDry: 15, qiStagnation: 15, shenUnsettled: 15)

        XCTAssertEqual(vector.coldHeat, 10)
        XCTAssertEqual(vector.defExcess, 10)
        XCTAssertEqual(vector.dampDry, 10)
        XCTAssertEqual(vector.qiStagnation, 10)
        XCTAssertEqual(vector.shenUnsettled, 10)
    }

    func testVectorClampingMin() {
        let vector = TerrainVector(coldHeat: -15, defExcess: -15, dampDry: -15, qiStagnation: -5, shenUnsettled: -5)

        XCTAssertEqual(vector.coldHeat, -10)
        XCTAssertEqual(vector.defExcess, -10)
        XCTAssertEqual(vector.dampDry, -10)
        XCTAssertEqual(vector.qiStagnation, 0) // qi_stagnation min is 0
        XCTAssertEqual(vector.shenUnsettled, 0) // shen_unsettled min is 0
    }

    // MARK: - Quiz Response Tests

    func testQuizResponseCalculation() {
        // Test a realistic cold-deficient quiz response scenario using v2 question IDs
        let responses: [(questionId: String, optionId: String)] = [
            ("q1_run_temp", "often_cold"),           // cold_heat: -2
            ("q2_drinks_feel_best", "hot_tea"),      // cold_heat: -2 (total: -4)
            ("q3_sweat_night", "rarely_sweat"),      // cold_heat: -2, def_excess: -1
            ("q4_energy_pattern", "low_all_day"),    // def_excess: -4
            ("q5_after_meals", "sleepy_heavy"),      // def_excess: -2, damp_dry: -2
            ("q6_environmental", "cold_weather"),    // cold_heat: -2
            ("q7_stress_response", "shuts_down"),    // def_excess: -2
            ("q8_stools_usually", "normal"),         // no change
            ("q9_cravings", "sweet"),                // damp_dry: -0.6 (weighted)
            ("q10_body_tends", "normal"),            // no change
            ("q11_thirst_mouth", "rarely_thirsty"),  // cold_heat: -1, damp_dry: -2
            ("q12_mood_flow", "easygoing"),          // no change
            ("q13_sleep", "sleep_good")              // no change
        ]

        let result = engine.calculateTerrain(from: responses)

        // Should be Cold + Deficient based on accumulated scores
        XCTAssertEqual(result.primaryType, .coldDeficient)
    }

    // MARK: - Modified Question Delta Tests

    func testQ5AfterMealsSleepyHeavyDelta() {
        // "Sleepy and heavy" should push dampDry negative and defExcess negative
        let responses: [(questionId: String, optionId: String)] = [
            ("q5_after_meals", "sleepy_heavy")
        ]
        let result = engine.calculateTerrain(from: responses)

        // dampDry should be -2, defExcess should be -2
        XCTAssertEqual(result.vector.dampDry, -2)
        XCTAssertEqual(result.vector.defExcess, -2)
    }

    func testQ5AfterMealsBloatedDelta() {
        // "Bloated" should push dampDry negative and qiStagnation positive
        let responses: [(questionId: String, optionId: String)] = [
            ("q5_after_meals", "bloated_gassy")
        ]
        let result = engine.calculateTerrain(from: responses)

        XCTAssertEqual(result.vector.dampDry, -2)
        XCTAssertEqual(result.vector.qiStagnation, 2)
    }

    func testQ5AfterMealsAcidRefluxDelta() {
        // "Acid reflux" should push coldHeat positive and set reflux flag
        let responses: [(questionId: String, optionId: String)] = [
            ("q5_after_meals", "acid_reflux")
        ]
        let result = engine.calculateTerrain(from: responses)

        XCTAssertEqual(result.vector.coldHeat, 2)
        XCTAssertTrue(result.flags.contains(.reflux))
    }

    func testQ3BroadenedSweatRarelyDelta() {
        // "Rarely sweat" should push cold and deficient
        let responses: [(questionId: String, optionId: String)] = [
            ("q3_sweat_night", "rarely_sweat")
        ]
        let result = engine.calculateTerrain(from: responses)

        XCTAssertEqual(result.vector.coldHeat, -2)
        XCTAssertEqual(result.vector.defExcess, -1)
    }

    func testQ3WakeHotThirstyDelta() {
        // "Wake hot and thirsty" should push strong heat + dry and set flags
        let responses: [(questionId: String, optionId: String)] = [
            ("q3_sweat_night", "wake_hot_thirsty")
        ]
        let result = engine.calculateTerrain(from: responses)

        XCTAssertEqual(result.vector.coldHeat, 3)
        XCTAssertEqual(result.vector.dampDry, 2)
        XCTAssertTrue(result.flags.contains(.nightSweats))
        XCTAssertTrue(result.flags.contains(.wakeThirstyHot))
    }

    func testQ11RefinedThirstVeryThirstyColdDelta() {
        // "Very thirsty, prefer cold" should push heat + dry strongly
        let responses: [(questionId: String, optionId: String)] = [
            ("q11_thirst_mouth", "very_thirsty_cold")
        ]
        let result = engine.calculateTerrain(from: responses)

        XCTAssertEqual(result.vector.coldHeat, 2)
        XCTAssertEqual(result.vector.dampDry, 3)
    }

    func testQ11RefinedDryMouthNightDelta() {
        // "Dry mouth at night" — separates yin deficiency from pure heat
        let responses: [(questionId: String, optionId: String)] = [
            ("q11_thirst_mouth", "dry_mouth_night")
        ]
        let result = engine.calculateTerrain(from: responses)

        XCTAssertEqual(result.vector.coldHeat, 1)
        XCTAssertEqual(result.vector.dampDry, 3)
        XCTAssertEqual(result.vector.shenUnsettled, 1)
    }

    // MARK: - Q14 Conditional Inclusion Tests

    func testQ14IncludedWhenMenstrualComfortGoal() {
        let goals: Set<Goal> = [.menstrualComfort]
        let filtered = QuizQuestions.questions(for: goals)

        XCTAssertTrue(filtered.contains(where: { $0.id == "q14_menstrual" }))
        XCTAssertEqual(filtered.count, 14) // 13 base + 1 conditional
    }

    func testQ14ExcludedWhenNoMenstrualGoal() {
        let goals: Set<Goal> = [.sleep, .digestion]
        let filtered = QuizQuestions.questions(for: goals)

        XCTAssertFalse(filtered.contains(where: { $0.id == "q14_menstrual" }))
        XCTAssertEqual(filtered.count, 13) // 13 base only
    }

    func testQ14EmptyGoalsExcludesMenstrual() {
        let goals: Set<Goal> = []
        let filtered = QuizQuestions.questions(for: goals)

        XCTAssertFalse(filtered.contains(where: { $0.id == "q14_menstrual" }))
        XCTAssertEqual(filtered.count, 13)
    }

    // MARK: - Existing Types Still Pass

    func testAllPrimaryTypesStillDeterminable() {
        // Verify all 8 types can still be reached
        let testCases: [(TerrainVector, TerrainScoringEngine.PrimaryType)] = [
            (TerrainVector(coldHeat: -5, defExcess: -5), .coldDeficient),
            (TerrainVector(coldHeat: -4, defExcess: 0), .coldBalanced),
            (TerrainVector(coldHeat: 0, defExcess: -5), .neutralDeficient),
            (TerrainVector(coldHeat: 0, defExcess: 0), .neutralBalanced),
            (TerrainVector(coldHeat: 0, defExcess: 5), .neutralExcess),
            (TerrainVector(coldHeat: 5, defExcess: 0), .warmBalanced),
            (TerrainVector(coldHeat: 5, defExcess: 5), .warmExcess),
            (TerrainVector(coldHeat: 5, defExcess: -5), .warmDeficient)
        ]

        for (vector, expectedType) in testCases {
            let result = engine.calculateTerrain(from: vector)
            XCTAssertEqual(result.primaryType, expectedType, "Vector \(vector) should produce \(expectedType)")
        }
    }

    // MARK: - Terrain Profile ID Tests

    func testTerrainProfileIdFormat() {
        let vector = TerrainVector(coldHeat: -5, defExcess: -5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.terrainProfileId, "cold_deficient_low_flame")
    }
}
