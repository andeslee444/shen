//
//  TerrainDriftDetectorTests.swift
//  TerrainTests
//
//  Unit tests for the TerrainDriftDetector pulse check-in drift detection.
//

import XCTest
@testable import Terrain

final class TerrainDriftDetectorTests: XCTestCase {
    var detector: TerrainDriftDetector!

    override func setUp() {
        super.setUp()
        detector = TerrainDriftDetector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Build an answer dictionary from the 5 axis values in question order.
    private func makeAnswers(
        coldHeat: Int = 0,
        defExcess: Int = 0,
        dampDry: Int = 0,
        qiStagnation: Int = 0,
        shenUnsettled: Int = 0
    ) -> [Int: Int] {
        return [
            1: coldHeat,       // cold_heat axis
            2: defExcess,      // def_excess axis
            3: dampDry,        // damp_dry axis
            4: qiStagnation,   // qi_stagnation axis
            5: shenUnsettled   // shen_unsettled axis
        ]
    }

    // MARK: - No Change

    func testSameTypeAndModifier_noChange() {
        // Neutral Balanced + no modifier → answers that also produce Neutral Balanced + none
        let answers = makeAnswers()
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.neutralBalanced.rawValue,
            currentModifier: TerrainScoringEngine.Modifier.none.rawValue
        )

        XCTAssertEqual(result.recommendation, .noChange)
        XCTAssertFalse(result.hasDrifted)
        XCTAssertEqual(result.pulseType, .neutralBalanced)
        XCTAssertEqual(result.pulseModifier, .none)
        XCTAssertEqual(result.driftSummary, "Your terrain profile is stable.")
    }

    // MARK: - Minor Shift

    func testSameTypeDifferentModifier_minorShift() {
        // Current: Neutral Balanced + none
        // Pulse answers: all neutral except shen = 4 → same type, but shen modifier
        let answers = makeAnswers(shenUnsettled: 4)
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.neutralBalanced.rawValue,
            currentModifier: TerrainScoringEngine.Modifier.none.rawValue
        )

        XCTAssertEqual(result.recommendation, .minorShift)
        XCTAssertTrue(result.hasDrifted)
        XCTAssertEqual(result.pulseType, .neutralBalanced)
        XCTAssertEqual(result.pulseModifier, .shen)
    }

    // MARK: - Significant Drift

    func testDifferentType_significantDrift() {
        // Current: Neutral Balanced
        // Pulse answers: cold + deficient → should classify as Cold Deficient
        let answers = makeAnswers(coldHeat: -3, defExcess: -3)
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.neutralBalanced.rawValue,
            currentModifier: nil
        )

        XCTAssertEqual(result.recommendation, .significantDrift)
        XCTAssertTrue(result.hasDrifted)
        XCTAssertEqual(result.pulseType, .coldDeficient)
        XCTAssertEqual(result.driftSummary, "Your body may have shifted. Consider retaking the full assessment.")
    }

    // MARK: - Neutral Scores Default

    func testNeutralScores_defaultsCorrectly() {
        // All zeros → Neutral Balanced, no modifier
        let answers = makeAnswers()
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.neutralBalanced.rawValue,
            currentModifier: nil
        )

        XCTAssertEqual(result.pulseType, .neutralBalanced)
        XCTAssertEqual(result.pulseModifier, .none)
        XCTAssertEqual(result.recommendation, .noChange)
    }

    // MARK: - Cold Type Detection

    func testAllColdAnswers_detectsColdType() {
        // coldHeat = -3, defExcess = -3 → Cold Deficient
        let answers = makeAnswers(coldHeat: -3, defExcess: -3, dampDry: -3)
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.coldDeficient.rawValue,
            currentModifier: TerrainScoringEngine.Modifier.damp.rawValue
        )

        XCTAssertEqual(result.pulseType, .coldDeficient)
        // The damp_dry = -3 triggers Damp modifier
        XCTAssertEqual(result.pulseModifier, .damp)
    }

    // MARK: - Warm Type Detection

    func testAllWarmAnswers_detectsWarmType() {
        // coldHeat = 3, defExcess = 3 → Warm Excess
        let answers = makeAnswers(coldHeat: 3, defExcess: 3, dampDry: 3)
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.warmExcess.rawValue,
            currentModifier: TerrainScoringEngine.Modifier.dry.rawValue
        )

        XCTAssertEqual(result.pulseType, .warmExcess)
        // dampDry = 3 triggers Dry modifier
        XCTAssertEqual(result.pulseModifier, .dry)
    }

    // MARK: - Shen Modifier Detection

    func testHighShenScore_detectsShenModifier() {
        // shen_unsettled = 4 triggers Shen modifier (threshold is 4)
        let answers = makeAnswers(shenUnsettled: 4)
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.neutralBalanced.rawValue,
            currentModifier: TerrainScoringEngine.Modifier.shen.rawValue
        )

        XCTAssertEqual(result.pulseModifier, .shen)
        // Same type and modifier → no change
        XCTAssertEqual(result.recommendation, .noChange)
    }

    // MARK: - Stagnation Modifier Detection

    func testHighQiStagnation_detectsStagnationModifier() {
        // qi_stagnation = 4 triggers Stagnation modifier (threshold is 4)
        let answers = makeAnswers(qiStagnation: 4)
        let result = detector.detectDrift(
            answers: answers,
            currentTerrainId: TerrainScoringEngine.PrimaryType.neutralBalanced.rawValue,
            currentModifier: TerrainScoringEngine.Modifier.stagnation.rawValue
        )

        XCTAssertEqual(result.pulseModifier, .stagnation)
        // Same type and modifier → no change
        XCTAssertEqual(result.recommendation, .noChange)
    }

    // MARK: - Engine Consistency

    func testReusesEngineClassification() {
        // Verify the drift detector produces the same classification as
        // creating a TerrainVector and running it through the engine directly.
        let answers = makeAnswers(coldHeat: 3, defExcess: -3, dampDry: 0, qiStagnation: 4, shenUnsettled: 0)

        // Classify via engine directly
        let engine = TerrainScoringEngine()
        let vector = TerrainVector(coldHeat: 3, defExcess: -3, dampDry: 0, qiStagnation: 4, shenUnsettled: 0)
        let engineResult = engine.calculateTerrain(from: vector)

        // Classify via drift detector
        let driftResult = detector.detectDrift(
            answers: answers,
            currentTerrainId: "neutral_balanced_steady_core",
            currentModifier: nil
        )

        XCTAssertEqual(driftResult.pulseType, engineResult.primaryType,
                        "Drift detector must produce the same primary type as the engine")
        XCTAssertEqual(driftResult.pulseModifier, engineResult.modifier,
                        "Drift detector must produce the same modifier as the engine")
    }
}
