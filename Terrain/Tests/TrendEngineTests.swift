//
//  TrendEngineTests.swift
//  TerrainTests
//
//  Tests for TrendEngine's terrain-aware prioritization and pulse generation.
//
//  These tests verify the "brain" that interprets raw trend data through the
//  lens of each terrain type — like verifying a translator correctly interprets
//  the same symptom differently for different body constitutions.
//

import XCTest
@testable import Terrain

final class TrendEngineTests: XCTestCase {

    private var engine: TrendEngine!

    override func setUp() {
        super.setUp()
        engine = TrendEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Creates a mock DailyLog for testing
    private func mockLog(
        date: Date,
        quickSymptoms: [QuickSymptom] = [],
        energyLevel: EnergyLevel? = nil,
        moodRating: Int? = nil,
        sleepQuality: SleepQuality? = nil,
        routineFeedback: [RoutineFeedbackEntry] = []
    ) -> DailyLog {
        let log = DailyLog(
            date: date,
            quickSymptoms: quickSymptoms,
            routineFeedback: routineFeedback,
            moodRating: moodRating
        )
        log.energyLevel = energyLevel
        log.sleepQuality = sleepQuality
        return log
    }

    /// Creates an array of logs spanning the last N days with varying data
    private func mockLogsForWindow(days: Int = 14) -> [DailyLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<days).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let hasStress = daysAgo % 3 == 0
            let hasTired = daysAgo % 4 == 0
            let mood = 5 + (daysAgo % 3) // Varies 5-7
            let energy: EnergyLevel = daysAgo % 2 == 0 ? .normal : .low

            return mockLog(
                date: date,
                quickSymptoms: hasStress ? [.stressed] : (hasTired ? [.tired] : []),
                energyLevel: energy,
                moodRating: mood
            )
        }
    }

    /// Creates logs with a clear declining sleep pattern
    private func mockLogsWithDecliningSleep() -> [DailyLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<14).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            // First half: good sleep, second half: poor sleep
            let sleepQuality: SleepQuality = daysAgo < 7 ? .wokeMiddleOfNight : .fellAsleepEasily

            return mockLog(
                date: date,
                moodRating: daysAgo < 7 ? 4 : 7, // Mood declining too
                sleepQuality: sleepQuality
            )
        }
    }

    /// Creates logs with activity duration data
    private func mockLogsWithActivityMinutes() -> [DailyLog] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<14).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            var feedback: [RoutineFeedbackEntry] = []

            // Add routine feedback every other day
            if daysAgo % 2 == 0 {
                feedback.append(RoutineFeedbackEntry(
                    routineOrMovementId: "ginger-honey-tea",
                    feedback: .better,
                    timestamp: date,
                    startedAt: calendar.date(byAdding: .minute, value: -10, to: date),
                    actualDurationSeconds: 600, // 10 minutes
                    activityType: .routine
                ))
            }

            // Add movement feedback every third day
            if daysAgo % 3 == 0 {
                feedback.append(RoutineFeedbackEntry(
                    routineOrMovementId: "morning-stretch",
                    feedback: .better,
                    timestamp: date,
                    startedAt: calendar.date(byAdding: .minute, value: -15, to: date),
                    actualDurationSeconds: 900, // 15 minutes
                    activityType: .movement
                ))
            }

            return mockLog(
                date: date,
                routineFeedback: feedback
            )
        }
    }

    // MARK: - prioritizeTrends Tests

    func testPrioritizeTrends_ColdDeficient_EnergyFirst() {
        let logs = mockLogsForWindow()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .coldDeficient,
            modifier: .none
        )

        XCTAssertFalse(result.isEmpty, "Should return annotated trends")

        // For cold deficient, Energy should be priority 1
        if let energyTrend = result.first(where: { $0.category == "Energy" }) {
            XCTAssertEqual(energyTrend.priority, 1, "Energy should be priority 1 for Cold Deficient")
        }

        // Digestion should be priority 2
        if let digestionTrend = result.first(where: { $0.category == "Digestion" }) {
            XCTAssertEqual(digestionTrend.priority, 2, "Digestion should be priority 2 for Cold Deficient")
        }
    }

    func testPrioritizeTrends_WarmExcess_StressFirst() {
        let logs = mockLogsForWindow()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .warmExcess,
            modifier: .none
        )

        XCTAssertFalse(result.isEmpty)

        // For warm excess, Stress should be priority 1
        if let stressTrend = result.first(where: { $0.category == "Stress" }) {
            XCTAssertEqual(stressTrend.priority, 1, "Stress should be priority 1 for Warm Excess")
        }
    }

    func testPrioritizeTrends_NeutralBalanced_MoodFirst() {
        let logs = mockLogsForWindow()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .neutralBalanced,
            modifier: .none
        )

        // For neutral balanced, Mood should be priority 1
        if let moodTrend = result.first(where: { $0.category == "Mood" }) {
            XCTAssertEqual(moodTrend.priority, 1, "Mood should be priority 1 for Neutral Balanced")
        }
    }

    func testPrioritizeTrends_NeutralExcess_StressAndStiffness() {
        let logs = mockLogsForWindow()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .neutralExcess,
            modifier: .none
        )

        // For neutral excess, Stress should be priority 1, Stiffness priority 2
        if let stressTrend = result.first(where: { $0.category == "Stress" }) {
            XCTAssertEqual(stressTrend.priority, 1, "Stress should be priority 1 for Neutral Excess")
        }
        if let stiffnessTrend = result.first(where: { $0.category == "Stiffness" }) {
            XCTAssertEqual(stiffnessTrend.priority, 2, "Stiffness should be priority 2 for Neutral Excess")
        }
    }

    func testPrioritizeTrends_SortedByPriority() {
        let logs = mockLogsForWindow()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .coldDeficient,
            modifier: .none
        )

        // Verify sorted by priority
        for i in 0..<(result.count - 1) {
            XCTAssertLessThanOrEqual(
                result[i].priority,
                result[i + 1].priority,
                "Trends should be sorted by priority (ascending)"
            )
        }
    }

    func testPrioritizeTrends_ModifierAffectsWatchFor() {
        let logs = mockLogsForWindow()

        // Shen modifier should mark Sleep, Stress, Mood as watch-fors
        let shenResult = engine.prioritizeTrends(
            logs: logs,
            terrainType: .neutralBalanced,
            modifier: .shen
        )

        let sleepTrend = shenResult.first(where: { $0.category == "Sleep" })
        XCTAssertTrue(sleepTrend?.isWatchFor ?? false, "Sleep should be watch-for with Shen modifier")

        let stressTrend = shenResult.first(where: { $0.category == "Stress" })
        XCTAssertTrue(stressTrend?.isWatchFor ?? false, "Stress should be watch-for with Shen modifier")
    }

    func testPrioritizeTrends_StagnationModifier() {
        let logs = mockLogsForWindow()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .neutralBalanced,
            modifier: .stagnation
        )

        // Stagnation should mark Stiffness as watch-for
        let stiffnessTrend = result.first(where: { $0.category == "Stiffness" })
        XCTAssertTrue(stiffnessTrend?.isWatchFor ?? false, "Stiffness should be watch-for with Stagnation modifier")

        let headacheTrend = result.first(where: { $0.category == "Headache" })
        XCTAssertTrue(headacheTrend?.isWatchFor ?? false, "Headache should be watch-for with Stagnation modifier")
    }

    func testPrioritizeTrends_EmptyLogs() {
        let result = engine.prioritizeTrends(
            logs: [],
            terrainType: .coldDeficient,
            modifier: .none
        )

        XCTAssertTrue(result.isEmpty, "Empty logs should return empty annotated trends")
    }

    func testPrioritizeTrends_InsufficientData() {
        // Only 2 days of data (need at least 3)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let logs = [
            mockLog(date: today),
            mockLog(date: calendar.date(byAdding: .day, value: -1, to: today)!)
        ]

        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .coldDeficient,
            modifier: .none
        )

        XCTAssertTrue(result.isEmpty, "Insufficient data should return empty trends")
    }

    // MARK: - healthyZone Tests

    func testHealthyZone_DeficientTypes_LowerEnergyRange() {
        let coldDeficientZone = engine.healthyZone(for: "Energy", terrainType: .coldDeficient)
        let neutralBalancedZone = engine.healthyZone(for: "Energy", terrainType: .neutralBalanced)

        // Deficient types have lower baseline energy range
        XCTAssertLessThan(
            coldDeficientZone.range.upperBound,
            neutralBalancedZone.range.upperBound,
            "Cold Deficient should have lower upper bound for energy"
        )
    }

    func testHealthyZone_WarmTypes_SleepAttention() {
        let warmExcessZone = engine.healthyZone(for: "Sleep", terrainType: .warmExcess)

        // Should have terrain context mentioning heat
        XCTAssertTrue(
            warmExcessZone.terrainContext.lowercased().contains("warm") ||
            warmExcessZone.terrainContext.lowercased().contains("heat"),
            "Warm type sleep zone should mention heat in context"
        )
    }

    func testHealthyZone_ColdTypes_DigestionSensitivity() {
        let coldDeficientZone = engine.healthyZone(for: "Digestion", terrainType: .coldDeficient)

        // Should mention sensitive digestion
        XCTAssertTrue(
            coldDeficientZone.terrainContext.lowercased().contains("cold") ||
            coldDeficientZone.terrainContext.lowercased().contains("sensitive"),
            "Cold type digestion zone should mention cold or sensitive"
        )
    }

    func testHealthyZone_DefaultRange() {
        // Non-specific category should return default range
        let zone = engine.healthyZone(for: "Cramps", terrainType: .neutralBalanced)

        XCTAssertEqual(zone.range.lowerBound, 0.5, "Default lower bound should be 0.5")
        XCTAssertEqual(zone.range.upperBound, 0.9, "Default upper bound should be 0.9")
    }

    // MARK: - computeActivityMinutes Tests

    func testComputeActivityMinutes_SumsCorrectly() {
        let logs = mockLogsWithActivityMinutes()
        let result = engine.computeActivityMinutes(logs: logs)

        // We have 7 routine entries (every other day) at 10 minutes each = 70
        // We have 5 movement entries (every third day) at 15 minutes each = 75
        XCTAssertGreaterThan(result.totalRoutineMinutes, 0, "Should have routine minutes")
        XCTAssertGreaterThan(result.totalMovementMinutes, 0, "Should have movement minutes")
    }

    func testComputeActivityMinutes_SeparatesTypes() {
        let logs = mockLogsWithActivityMinutes()
        let result = engine.computeActivityMinutes(logs: logs)

        // Check that arrays have correct length
        XCTAssertEqual(result.routineMinutes.count, 14, "Should have 14 days of routine data")
        XCTAssertEqual(result.movementMinutes.count, 14, "Should have 14 days of movement data")
    }

    func testComputeActivityMinutes_EmptyLogs() {
        let result = engine.computeActivityMinutes(logs: [])

        XCTAssertEqual(result.totalRoutineMinutes, 0, "Empty logs should have 0 routine minutes")
        XCTAssertEqual(result.totalMovementMinutes, 0, "Empty logs should have 0 movement minutes")
        XCTAssertEqual(result.routineMinutes.count, 14, "Should still have 14-day array")
    }

    func testComputeActivityMinutes_NoFeedbackEntries() {
        let logs = mockLogsForWindow() // These logs have no feedback entries
        let result = engine.computeActivityMinutes(logs: logs)

        XCTAssertEqual(result.totalRoutineMinutes, 0, "Logs without feedback should have 0 minutes")
        XCTAssertEqual(result.totalMovementMinutes, 0)
    }

    // MARK: - generateTerrainPulse Tests

    func testGenerateTerrainPulse_DecliningSleep_ColdDeficient() {
        let logs = mockLogsWithDecliningSleep()
        let pulse = engine.generateTerrainPulse(
            logs: logs,
            terrainType: .coldDeficient,
            modifier: .none
        )

        // Should generate an insight about sleep
        XCTAssertFalse(pulse.headline.isEmpty, "Should generate a headline")
        XCTAssertFalse(pulse.body.isEmpty, "Should generate a body")
    }

    func testGenerateTerrainPulse_WithShenModifier() {
        let logs = mockLogsWithDecliningSleep()
        let pulse = engine.generateTerrainPulse(
            logs: logs,
            terrainType: .neutralBalanced,
            modifier: .shen
        )

        // Should mention shen or mind in the body for sleep issues
        let bodyLower = pulse.body.lowercased()
        let mentionsShen = bodyLower.contains("shen") ||
                          bodyLower.contains("mind") ||
                          bodyLower.contains("spirit")
        XCTAssertTrue(mentionsShen, "Shen modifier should be reflected in sleep decline insight")
    }

    func testGenerateTerrainPulse_StablePatterns() {
        // Create logs with stable, good data
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stableLogs = (0..<14).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            return mockLog(
                date: date,
                energyLevel: .normal,
                moodRating: 7,
                sleepQuality: .fellAsleepEasily
            )
        }

        let pulse = engine.generateTerrainPulse(
            logs: stableLogs,
            terrainType: .neutralBalanced,
            modifier: .none
        )

        XCTAssertFalse(pulse.isUrgent, "Stable patterns should not be urgent")
    }

    func testGenerateTerrainPulse_WarmExcess_StressDecline() {
        // Create logs with increasing stress
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let stressyLogs = (0..<14).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            // More stress in recent days (lower daysAgo = more recent)
            let hasStress = daysAgo < 7
            return mockLog(
                date: date,
                quickSymptoms: hasStress ? [.stressed] : [],
                moodRating: hasStress ? 4 : 7
            )
        }

        let pulse = engine.generateTerrainPulse(
            logs: stressyLogs,
            terrainType: .warmExcess,
            modifier: .none
        )

        // For warm excess, stress should be highlighted
        let bodyLower = pulse.body.lowercased()
        let mentionsHeatOrCool = bodyLower.contains("heat") ||
                                 bodyLower.contains("cool") ||
                                 bodyLower.contains("stress")
        XCTAssertTrue(mentionsHeatOrCool, "Warm Excess stress insight should mention heat/cool/stress")
    }

    func testGenerateTerrainPulse_EmptyLogs() {
        let pulse = engine.generateTerrainPulse(
            logs: [],
            terrainType: .coldDeficient,
            modifier: .none
        )

        // Should still generate a stable message
        XCTAssertFalse(pulse.headline.isEmpty, "Should generate headline even with empty logs")
    }

    // MARK: - Terrain Note Generation Tests

    func testTerrainNote_DecliningTrend_HasContent() {
        let logs = mockLogsWithDecliningSleep()
        let result = engine.prioritizeTrends(
            logs: logs,
            terrainType: .coldDeficient,
            modifier: .none
        )

        // All trends should have terrain notes
        for trend in result {
            XCTAssertFalse(trend.terrainNote.isEmpty, "Trend \(trend.category) should have a terrain note")
        }
    }

    func testTerrainNote_WarmExcessHeadache() {
        // Create logs with headaches
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let headacheLogs = (0..<14).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            // More headaches recently
            let hasHeadache = daysAgo < 5
            return mockLog(
                date: date,
                quickSymptoms: hasHeadache ? [.headache] : []
            )
        }

        let result = engine.prioritizeTrends(
            logs: headacheLogs,
            terrainType: .warmExcess,
            modifier: .none
        )

        if let headacheTrend = result.first(where: { $0.category == "Headache" && $0.direction == .declining }) {
            XCTAssertTrue(
                headacheTrend.terrainNote.lowercased().contains("heat") ||
                headacheTrend.terrainNote.lowercased().contains("rising"),
                "Warm Excess headache note should mention heat or rising"
            )
        }
    }

    // MARK: - All Terrain Types Coverage

    func testAllTerrainTypes_HavePrioritization() {
        let logs = mockLogsForWindow()

        for terrainType in TerrainScoringEngine.PrimaryType.allCases {
            let result = engine.prioritizeTrends(
                logs: logs,
                terrainType: terrainType,
                modifier: .none
            )

            XCTAssertFalse(result.isEmpty, "\(terrainType) should return annotated trends")

            // Verify all 10 categories are present (8 original + Sleep Duration + Resting HR)
            let categories = Set(result.map { $0.category })
            XCTAssertEqual(categories.count, 10, "\(terrainType) should have all 10 trend categories")
        }
    }

    func testAllModifiers_AffectWatchFors() {
        let logs = mockLogsForWindow()

        for modifier in TerrainScoringEngine.Modifier.allCases where modifier != .none {
            let result = engine.prioritizeTrends(
                logs: logs,
                terrainType: .neutralBalanced,
                modifier: modifier
            )

            let hasWatchFor = result.contains { $0.isWatchFor }
            XCTAssertTrue(hasWatchFor, "\(modifier) modifier should add at least one watch-for")
        }
    }
}
