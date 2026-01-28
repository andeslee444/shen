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
        // Test a realistic quiz response scenario
        let responses: [(questionId: String, optionId: String)] = [
            ("q1_run_temp", "often_cold"),      // cold_heat: -2
            ("q2_drinks_feel_best", "hot_tea"), // cold_heat: -2 (total: -4)
            ("q3_sweat_night", "hardly_sweat"), // cold_heat: -1, def_excess: -1 (total: -5, -1)
            ("q4_energy_pattern", "low_all_day"), // def_excess: -4 (total: -5)
            ("q5_stress_response", "shuts_down_fatigue"), // def_excess: -2 (total: -7)
            ("q6_after_meals", "light_normal"), // no change
            ("q7_stools_usually", "normal"),    // no change
            ("q8_cravings", "sweet"),           // damp_dry: -0.6 (weighted)
            ("q9_body_tends", "normal"),        // no change
            ("q10_thirst_mouth", "rarely_thirsty"), // cold_heat: -1, damp_dry: -1 (total: -6, -1.6)
            ("q11_mood_flow", "easygoing"),     // no change
            ("q12_sleep", "sleep_good")         // no change
        ]

        let result = engine.calculateTerrain(from: responses)

        // Should be Cold + Deficient based on accumulated scores
        XCTAssertEqual(result.primaryType, .coldDeficient)
    }

    // MARK: - Terrain Profile ID Tests

    func testTerrainProfileIdFormat() {
        let vector = TerrainVector(coldHeat: -5, defExcess: -5)
        let result = engine.calculateTerrain(from: vector)

        XCTAssertEqual(result.terrainProfileId, "cold_deficient_low_flame")
    }
}
