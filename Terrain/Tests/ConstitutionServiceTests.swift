//
//  ConstitutionServiceTests.swift
//  TerrainTests
//
//  Unit tests for ConstitutionService and TrendEngine.
//

import XCTest
@testable import Terrain

final class ConstitutionServiceTests: XCTestCase {
    var service: ConstitutionService!

    override func setUp() {
        super.setUp()
        service = ConstitutionService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Readout Tests

    func testReadoutAlwaysReturns5Axes() {
        let vector = TerrainVector(coldHeat: 3, defExcess: -2, dampDry: 5, qiStagnation: 6, shenUnsettled: 2)
        let readout = service.generateReadout(vector: vector, modifier: .stagnation)

        XCTAssertEqual(readout.axes.count, 5)
    }

    func testReadoutLabelsForWarmVector() {
        let vector = TerrainVector(coldHeat: 5)
        let readout = service.generateReadout(vector: vector, modifier: .none)

        let temperatureAxis = readout.axes.first { $0.label == "Temperature" }
        XCTAssertNotNil(temperatureAxis)
        XCTAssertTrue(temperatureAxis!.value.contains("Warm"))
    }

    func testReadoutLabelsForColdVector() {
        let vector = TerrainVector(coldHeat: -5)
        let readout = service.generateReadout(vector: vector, modifier: .none)

        let temperatureAxis = readout.axes.first { $0.label == "Temperature" }
        XCTAssertNotNil(temperatureAxis)
        XCTAssertTrue(temperatureAxis!.value.contains("Cool"))
    }

    func testReadoutLabelsForNeutralVector() {
        let vector = TerrainVector()
        let readout = service.generateReadout(vector: vector, modifier: .none)

        let temperatureAxis = readout.axes.first { $0.label == "Temperature" }
        XCTAssertNotNil(temperatureAxis)
        XCTAssertTrue(temperatureAxis!.value.contains("Neutral"))
    }

    func testReadoutLabelsForStagnantVector() {
        let vector = TerrainVector(qiStagnation: 7)
        let readout = service.generateReadout(vector: vector, modifier: .stagnation)

        let flowAxis = readout.axes.first { $0.label == "Flow" }
        XCTAssertNotNil(flowAxis)
        XCTAssertTrue(flowAxis!.value.contains("Stagnant"))
    }

    func testReadoutTooltipsPresent() {
        let vector = TerrainVector()
        let readout = service.generateReadout(vector: vector, modifier: .none)

        for axis in readout.axes {
            XCTAssertFalse(axis.tooltip.isEmpty, "Tooltip for \(axis.label) should not be empty")
        }
    }

    func testReadoutAllEightTerrainTypes() {
        let types: [(Int, Int)] = [
            (-5, -5), (-5, 0), (0, -5), (0, 0),
            (0, 5), (5, 0), (5, 5), (5, -5)
        ]
        for (ch, de) in types {
            let vector = TerrainVector(coldHeat: ch, defExcess: de)
            let readout = service.generateReadout(vector: vector, modifier: .none)
            XCTAssertEqual(readout.axes.count, 5, "Readout for (\(ch), \(de)) should have 5 axes")
        }
    }

    // MARK: - Signal Tests

    func testSignalsNilForNilResponses() {
        let signals = service.generateSignals(responses: nil)
        XCTAssertNil(signals)
    }

    func testSignalsNilForEmptyResponses() {
        let signals = service.generateSignals(responses: [])
        XCTAssertNil(signals)
    }

    func testSignalsReturnMax3() {
        // All 13 base questions with strong deltas
        let responses: [QuizResponse] = [
            QuizResponse(questionId: "q1_run_temp", optionId: "always_cold"),
            QuizResponse(questionId: "q2_drinks_feel_best", optionId: "hot_tea"),
            QuizResponse(questionId: "q3_sweat_night", optionId: "wake_hot_thirsty"),
            QuizResponse(questionId: "q4_energy_pattern", optionId: "wired_but_tired"),
            QuizResponse(questionId: "q5_after_meals", optionId: "bloated_gassy"),
            QuizResponse(questionId: "q7_stress_response", optionId: "runs_hot"),
        ]

        let signals = service.generateSignals(responses: responses)
        XCTAssertNotNil(signals)
        XCTAssertLessThanOrEqual(signals!.count, 3)
    }

    func testSignalsSkipNeutralAnswers() {
        // "easygoing" mood has zero delta — should be excluded
        let responses: [QuizResponse] = [
            QuizResponse(questionId: "q12_mood_flow", optionId: "easygoing"),
            QuizResponse(questionId: "q1_run_temp", optionId: "always_cold")
        ]

        let signals = service.generateSignals(responses: responses)
        XCTAssertNotNil(signals)
        // Should only have 1 signal (the non-neutral one)
        XCTAssertEqual(signals!.count, 1)
    }

    // MARK: - Defaults Tests

    func testDefaultsForEachType() {
        let types: [TerrainScoringEngine.PrimaryType] = TerrainScoringEngine.PrimaryType.allCases

        for type in types {
            let defaults = service.generateDefaults(type: type, modifier: .none)
            XCTAssertFalse(defaults.bestDefaults.isEmpty, "Best defaults for \(type) should not be empty")
            XCTAssertFalse(defaults.avoidDefaults.isEmpty, "Avoid defaults for \(type) should not be empty")
        }
    }

    func testDefaultsModifierOverlay() {
        let baseDefaults = service.generateDefaults(type: .neutralBalanced, modifier: .none)
        let dampDefaults = service.generateDefaults(type: .neutralBalanced, modifier: .damp)

        // Damp modifier should add an item at the front
        XCTAssertNotEqual(baseDefaults.bestDefaults.first, dampDefaults.bestDefaults.first)
    }

    // MARK: - Watch-Fors Tests

    func testWatchForsForEachType() {
        let types: [TerrainScoringEngine.PrimaryType] = TerrainScoringEngine.PrimaryType.allCases

        for type in types {
            let items = service.generateWatchFors(type: type, modifier: .none)
            XCTAssertFalse(items.isEmpty, "Watch-fors for \(type) should not be empty")
            XCTAssertGreaterThanOrEqual(items.count, 3, "Should have at least 3 watch-fors for \(type)")
        }
    }

    func testWatchForsModifierAddsItem() {
        let baseItems = service.generateWatchFors(type: .neutralBalanced, modifier: .none)
        let shenItems = service.generateWatchFors(type: .neutralBalanced, modifier: .shen)

        XCTAssertEqual(shenItems.count, baseItems.count + 1)
    }
}

// MARK: - TrendEngine Tests

final class TrendEngineTests: XCTestCase {
    var engine: TrendEngine!
    let calendar = Calendar.current

    override func setUp() {
        super.setUp()
        engine = TrendEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    func testEmptyLogsReturnsEmpty() {
        let trends = engine.computeTrends(logs: [])
        XCTAssertTrue(trends.isEmpty)
    }

    func testFewerThan3DaysReturnsEmpty() {
        let today = Date()
        let logs = [
            DailyLog(date: today, quickSymptoms: [.poorSleep]),
            DailyLog(date: calendar.date(byAdding: .day, value: -1, to: today)!, quickSymptoms: [.bloating])
        ]

        let trends = engine.computeTrends(logs: logs)
        XCTAssertTrue(trends.isEmpty)
    }

    func testSufficientDataReturns7Trends() {
        let today = Date()
        var logs: [DailyLog] = []
        for i in 0..<7 {
            logs.append(DailyLog(
                date: calendar.date(byAdding: .day, value: -i, to: today)!,
                quickSymptoms: i < 3 ? [.poorSleep] : []
            ))
        }

        let trends = engine.computeTrends(logs: logs)
        XCTAssertEqual(trends.count, 7)

        let categories = Set(trends.map { $0.category })
        XCTAssertTrue(categories.contains("Sleep"))
        XCTAssertTrue(categories.contains("Digestion"))
        XCTAssertTrue(categories.contains("Stress"))
        XCTAssertTrue(categories.contains("Energy"))
        XCTAssertTrue(categories.contains("Headache"))
        XCTAssertTrue(categories.contains("Cramps"))
        XCTAssertTrue(categories.contains("Stiffness"))
    }

    func testImprovingTrendWhenSymptomsDecline() {
        let today = Date()
        var logs: [DailyLog] = []

        // First half (8-14 days ago): lots of poor sleep
        for i in 8..<14 {
            logs.append(DailyLog(
                date: calendar.date(byAdding: .day, value: -i, to: today)!,
                quickSymptoms: [.poorSleep]
            ))
        }
        // Second half (0-7 days ago): no poor sleep
        for i in 0..<7 {
            logs.append(DailyLog(
                date: calendar.date(byAdding: .day, value: -i, to: today)!,
                quickSymptoms: []
            ))
        }

        let trends = engine.computeTrends(logs: logs)
        let sleepTrend = trends.first { $0.category == "Sleep" }
        XCTAssertEqual(sleepTrend?.direction, .improving)
    }
}
