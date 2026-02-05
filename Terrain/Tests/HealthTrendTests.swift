//
//  HealthTrendTests.swift
//  TerrainTests
//
//  Tests for TrendEngine's HealthKit-sourced sleep duration and resting heart
//  rate trend computation. These trends are the "biometric layer" on top of the
//  subjective check-in data — like adding an objective thermometer reading to
//  confirm what the user already feels about their sleep and stress patterns.
//

import XCTest
@testable import Terrain

final class HealthTrendTests: XCTestCase {

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

    /// Creates a DailyLog at the given daysAgo offset with optional HealthKit data.
    private func mockLog(
        daysAgo: Int,
        sleepDurationMinutes: Double? = nil,
        restingHeartRate: Int? = nil,
        moodRating: Int? = 6
    ) -> DailyLog {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

        let log = DailyLog(date: date, moodRating: moodRating)
        log.sleepDurationMinutes = sleepDurationMinutes
        log.restingHeartRate = restingHeartRate
        log.energyLevel = .normal
        return log
    }

    /// Creates 14 days of logs with specified first-half and second-half sleep durations.
    private func mockSleepLogs(
        firstHalfMinutes: Double,
        secondHalfMinutes: Double
    ) -> [DailyLog] {
        return (0..<14).map { daysAgo in
            // daysAgo 0..6 = recent (second half), 7..13 = older (first half)
            let minutes = daysAgo < 7 ? secondHalfMinutes : firstHalfMinutes
            return mockLog(daysAgo: daysAgo, sleepDurationMinutes: minutes)
        }
    }

    /// Creates 14 days of logs with specified first-half and second-half resting HR.
    private func mockHeartRateLogs(
        firstHalfBPM: Int,
        secondHalfBPM: Int
    ) -> [DailyLog] {
        return (0..<14).map { daysAgo in
            let bpm = daysAgo < 7 ? secondHalfBPM : firstHalfBPM
            return mockLog(daysAgo: daysAgo, restingHeartRate: bpm)
        }
    }

    // MARK: - Sleep Duration Trend Tests

    func testSleepDurationTrendImproving() {
        // First half ~6.5h (390 min), second half ~8h (480 min) → improving
        let logs = mockSleepLogs(firstHalfMinutes: 390, secondHalfMinutes: 480)
        let trends = engine.computeTrends(logs: logs)

        let sleepDurationTrend = trends.first(where: { $0.category == "Sleep Duration" })
        XCTAssertNotNil(sleepDurationTrend, "Should have a Sleep Duration trend")
        XCTAssertEqual(sleepDurationTrend?.direction, .improving,
                       "More sleep in second half should be improving (390→480 min)")
    }

    func testSleepDurationTrendDeclining() {
        // First half ~8h (480 min), second half ~6h (360 min) → declining
        let logs = mockSleepLogs(firstHalfMinutes: 480, secondHalfMinutes: 360)
        let trends = engine.computeTrends(logs: logs)

        let sleepDurationTrend = trends.first(where: { $0.category == "Sleep Duration" })
        XCTAssertNotNil(sleepDurationTrend, "Should have a Sleep Duration trend")
        XCTAssertEqual(sleepDurationTrend?.direction, .declining,
                       "Less sleep in second half should be declining (480→360 min)")
    }

    func testSleepDurationTrendStable() {
        // All ~7.5h (450 min) → stable
        let logs = mockSleepLogs(firstHalfMinutes: 450, secondHalfMinutes: 450)
        let trends = engine.computeTrends(logs: logs)

        let sleepDurationTrend = trends.first(where: { $0.category == "Sleep Duration" })
        XCTAssertNotNil(sleepDurationTrend, "Should have a Sleep Duration trend")
        XCTAssertEqual(sleepDurationTrend?.direction, .stable,
                       "Same sleep duration should be stable")
    }

    // MARK: - Resting Heart Rate Trend Tests

    func testRestingHeartRateTrendImproving() {
        // First half ~75 BPM, second half ~62 BPM → improving (lower is better)
        let logs = mockHeartRateLogs(firstHalfBPM: 75, secondHalfBPM: 62)
        let trends = engine.computeTrends(logs: logs)

        let hrTrend = trends.first(where: { $0.category == "Resting HR" })
        XCTAssertNotNil(hrTrend, "Should have a Resting HR trend")
        XCTAssertEqual(hrTrend?.direction, .improving,
                       "Lower HR in second half should be improving (75→62 BPM)")
    }

    func testRestingHeartRateTrendDeclining() {
        // First half ~60 BPM, second half ~78 BPM → declining (higher is worse)
        let logs = mockHeartRateLogs(firstHalfBPM: 60, secondHalfBPM: 78)
        let trends = engine.computeTrends(logs: logs)

        let hrTrend = trends.first(where: { $0.category == "Resting HR" })
        XCTAssertNotNil(hrTrend, "Should have a Resting HR trend")
        XCTAssertEqual(hrTrend?.direction, .declining,
                       "Higher HR in second half should be declining (60→78 BPM)")
    }

    // MARK: - Nil Data Handling

    func testNilSleepDataHandling() {
        // No sleep data at all — should return neutral midpoint rates
        let logs = (0..<14).map { mockLog(daysAgo: $0) }
        let trends = engine.computeTrends(logs: logs)

        let sleepDurationTrend = trends.first(where: { $0.category == "Sleep Duration" })
        XCTAssertNotNil(sleepDurationTrend, "Should have a Sleep Duration trend even without data")

        // With no data, both halves average to 450 (midpoint) → stable
        XCTAssertEqual(sleepDurationTrend?.direction, .stable,
                       "No sleep data should result in stable trend (neutral midpoint)")

        // Daily rates should all be 0.5 (neutral)
        if let rates = sleepDurationTrend?.dailyRates {
            XCTAssertEqual(rates.count, 14, "Should have 14 daily rates")
            for rate in rates {
                XCTAssertEqual(rate, 0.5, accuracy: 0.01,
                               "No-data days should have 0.5 neutral rate")
            }
        }
    }

    func testNilHeartRateDataHandling() {
        // No HR data at all — should return neutral midpoint rates
        let logs = (0..<14).map { mockLog(daysAgo: $0) }
        let trends = engine.computeTrends(logs: logs)

        let hrTrend = trends.first(where: { $0.category == "Resting HR" })
        XCTAssertNotNil(hrTrend, "Should have a Resting HR trend even without data")

        // With no data, both halves average to 70 (midpoint) → stable
        XCTAssertEqual(hrTrend?.direction, .stable,
                       "No HR data should result in stable trend (neutral midpoint)")

        // Daily rates should all be 0.5 (neutral)
        if let rates = hrTrend?.dailyRates {
            XCTAssertEqual(rates.count, 14, "Should have 14 daily rates")
            for rate in rates {
                XCTAssertEqual(rate, 0.5, accuracy: 0.01,
                               "No-data days should have 0.5 neutral rate")
            }
        }
    }

    // MARK: - Priority and Healthy Zone Tests

    func testPriorityOrderingIncludesNewCategories() {
        // Create logs with HealthKit data so trends are non-empty
        let logs = (0..<14).map {
            mockLog(daysAgo: $0, sleepDurationMinutes: 420, restingHeartRate: 68)
        }

        let annotated = engine.prioritizeTrends(
            logs: logs,
            terrainType: .coldDeficient,
            modifier: .none
        )

        let categories = Set(annotated.map { $0.category })
        XCTAssertTrue(categories.contains("Sleep Duration"),
                      "prioritizeTrends should include Sleep Duration category")
        XCTAssertTrue(categories.contains("Resting HR"),
                      "prioritizeTrends should include Resting HR category")

        // Verify they have the expected priority values
        if let sleepDurationTrend = annotated.first(where: { $0.category == "Sleep Duration" }) {
            XCTAssertEqual(sleepDurationTrend.priority, 9,
                           "Sleep Duration should have priority 9 for Cold Deficient")
        }
        if let hrTrend = annotated.first(where: { $0.category == "Resting HR" }) {
            XCTAssertEqual(hrTrend.priority, 10,
                           "Resting HR should have priority 10 for Cold Deficient")
        }
    }

    func testHealthyZonesForNewCategories() {
        // Sleep Duration zones
        let sleepDeficientZone = engine.healthyZone(
            for: "Sleep Duration",
            terrainType: .coldDeficient
        )
        XCTAssertGreaterThan(sleepDeficientZone.range.lowerBound, 0,
                             "Sleep Duration zone should have a positive lower bound")
        XCTAssertLessThanOrEqual(sleepDeficientZone.range.upperBound, 1.0,
                                 "Sleep Duration zone should not exceed 1.0")
        XCTAssertTrue(sleepDeficientZone.terrainContext.lowercased().contains("deficient") ||
                      sleepDeficientZone.terrainContext.lowercased().contains("recovery"),
                      "Deficient sleep zone context should mention deficiency or recovery")

        let sleepExcessZone = engine.healthyZone(
            for: "Sleep Duration",
            terrainType: .warmExcess
        )
        // Excess types need less sleep, so their lower bound should be lower or equal
        XCTAssertLessThanOrEqual(
            sleepExcessZone.range.upperBound,
            sleepDeficientZone.range.upperBound,
            "Excess types should have same or lower upper sleep bound vs deficient"
        )

        // Resting HR zones
        let hrWarmZone = engine.healthyZone(
            for: "Resting HR",
            terrainType: .warmExcess
        )
        XCTAssertGreaterThan(hrWarmZone.range.lowerBound, 0,
                             "Resting HR zone should have a positive lower bound")
        XCTAssertTrue(hrWarmZone.terrainContext.lowercased().contains("warm") ||
                      hrWarmZone.terrainContext.lowercased().contains("heat"),
                      "Warm type HR zone should mention warm or heat")

        let hrDefaultZone = engine.healthyZone(
            for: "Resting HR",
            terrainType: .neutralBalanced
        )
        XCTAssertTrue(hrDefaultZone.terrainContext.lowercased().contains("heart") ||
                      hrDefaultZone.terrainContext.lowercased().contains("cardiovascular"),
                      "Default HR zone should mention heart or cardiovascular health")
    }
}
