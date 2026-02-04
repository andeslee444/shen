//
//  DayPhaseTests.swift
//  TerrainTests
//
//  Tests for DayPhase: boundary detection at 5AM/5PM, affinity scoring,
//  intensity shifting, and edge cases.
//

import XCTest
@testable import Terrain

final class DayPhaseTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a Date at the given hour (24h) on an arbitrary day.
    private func date(hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    // MARK: - Phase Boundary Tests

    func testMorningStartsAt5AM() {
        XCTAssertEqual(DayPhase.current(for: date(hour: 5)), .morning)
    }

    func testMorningEndsAt4_59PM() {
        XCTAssertEqual(DayPhase.current(for: date(hour: 16, minute: 59)), .morning)
    }

    func testEveningStartsAt5PM() {
        XCTAssertEqual(DayPhase.current(for: date(hour: 17)), .evening)
    }

    func testEveningAt11PM() {
        XCTAssertEqual(DayPhase.current(for: date(hour: 23)), .evening)
    }

    func testMidnightIsEvening() {
        XCTAssertEqual(DayPhase.current(for: date(hour: 0)), .evening)
    }

    func test4AMIsEvening() {
        // TCM: yang cycle doesn't start until 5AM (卯时)
        XCTAssertEqual(DayPhase.current(for: date(hour: 4)), .evening)
        XCTAssertEqual(DayPhase.current(for: date(hour: 4, minute: 59)), .evening)
    }

    func testNoonIsMorning() {
        XCTAssertEqual(DayPhase.current(for: date(hour: 12)), .morning)
    }

    // MARK: - Affinity Scoring

    func testMorningAffinityForWarmingTags() {
        let tags = ["warming", "supports_deficiency", "moves_qi"]
        XCTAssertEqual(DayPhase.morning.affinityScore(for: tags), 3)
    }

    func testEveningAffinityForCalmingTags() {
        let tags = ["calms_shen", "cooling"]
        XCTAssertEqual(DayPhase.evening.affinityScore(for: tags), 2)
    }

    func testMorningHasNoAffinityForCalmingTags() {
        let tags = ["calms_shen", "cooling"]
        XCTAssertEqual(DayPhase.morning.affinityScore(for: tags), 0)
    }

    func testEveningHasNoAffinityForWarmingTags() {
        let tags = ["warming", "supports_deficiency"]
        XCTAssertEqual(DayPhase.evening.affinityScore(for: tags), 0)
    }

    func testNeutralTagsScoreZeroForBothPhases() {
        let tags = ["dries_damp", "moistens_dryness", "reduces_excess"]
        XCTAssertEqual(DayPhase.morning.affinityScore(for: tags), 0)
        XCTAssertEqual(DayPhase.evening.affinityScore(for: tags), 0)
    }

    func testMixedTagsPartialMatch() {
        // "moves_qi" is morning-affinity, "calms_shen" is evening-affinity
        let tags = ["moves_qi", "calms_shen", "dries_damp"]
        XCTAssertEqual(DayPhase.morning.affinityScore(for: tags), 1) // moves_qi
        XCTAssertEqual(DayPhase.evening.affinityScore(for: tags), 1) // calms_shen
    }

    // MARK: - Net Phase Score

    func testNetScorePositiveForMatchingPhase() {
        // Morning routine with warming + moves_qi: +2*2 = +4, no anti-affinity
        let tags = ["warming", "moves_qi"]
        let score = DayPhase.morning.netPhaseScore(for: tags)
        XCTAssertEqual(score, 4)
    }

    func testNetScoreNegativeForMismatchedPhase() {
        // Warming routine scored against evening: 0 affinity, -3*2 = -6
        let tags = ["warming", "moves_qi"]
        let score = DayPhase.evening.netPhaseScore(for: tags)
        XCTAssertEqual(score, -6)
    }

    func testNetScoreForMixedTags() {
        // "warming" (morning+) + "calms_shen" (evening+)
        // Morning: +2 affinity (warming) - 3 anti (calms_shen) = -1
        let tags = ["warming", "calms_shen"]
        XCTAssertEqual(DayPhase.morning.netPhaseScore(for: tags), -1)
        // Evening: +2 affinity (calms_shen) - 3 anti (warming) = -1
        XCTAssertEqual(DayPhase.evening.netPhaseScore(for: tags), -1)
    }

    // MARK: - Anti-Affinity

    func testAntiAffinityDetectsOppositePhase() {
        let warmingTags = ["warming", "supports_deficiency"]
        XCTAssertEqual(DayPhase.evening.antiAffinityScore(for: warmingTags), 2)
        XCTAssertEqual(DayPhase.morning.antiAffinityScore(for: warmingTags), 0)
    }

    // MARK: - Intensity Preference

    func testMorningIntensityMatchesLevel() {
        XCTAssertEqual(DayPhase.morning.preferredIntensity(for: .full), "moderate")
        XCTAssertEqual(DayPhase.morning.preferredIntensity(for: .medium), "gentle")
        XCTAssertEqual(DayPhase.morning.preferredIntensity(for: .lite), "restorative")
    }

    func testEveningShiftsIntensityCalmer() {
        XCTAssertEqual(DayPhase.evening.preferredIntensity(for: .full), "gentle")
        XCTAssertEqual(DayPhase.evening.preferredIntensity(for: .medium), "restorative")
        XCTAssertEqual(DayPhase.evening.preferredIntensity(for: .lite), "restorative")
    }

    // MARK: - Display Properties

    func testDisplayTitles() {
        XCTAssertEqual(DayPhase.morning.displayTitle, "Morning Practice")
        XCTAssertEqual(DayPhase.evening.displayTitle, "Evening Practice")
    }

    func testIcons() {
        XCTAssertEqual(DayPhase.morning.icon, "sun.horizon.fill")
        XCTAssertEqual(DayPhase.evening.icon, "moon.fill")
    }

    // MARK: - Empty Tags

    func testEmptyTagsScoreZero() {
        XCTAssertEqual(DayPhase.morning.affinityScore(for: []), 0)
        XCTAssertEqual(DayPhase.evening.affinityScore(for: []), 0)
        XCTAssertEqual(DayPhase.morning.netPhaseScore(for: []), 0)
    }
}
