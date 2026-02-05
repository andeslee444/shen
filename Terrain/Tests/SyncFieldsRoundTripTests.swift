//
//  SyncFieldsRoundTripTests.swift
//  TerrainTests
//
//  Round-trip tests for Phase 14 enum fields: verifies that every case
//  survives rawValue → init(rawValue:) without data loss. This protects
//  against accidental rawValue changes that would silently break sync.
//

import XCTest
@testable import Terrain

final class SyncFieldsRoundTripTests: XCTestCase {

    // MARK: - CyclePhase

    func testCyclePhaseRoundTrip() {
        for phase in CyclePhase.allCases {
            let raw = phase.rawValue
            let restored = CyclePhase(rawValue: raw)
            XCTAssertEqual(restored, phase, "CyclePhase.\(phase) failed round-trip via rawValue '\(raw)'")
        }
    }

    func testCyclePhaseAllCasesCount() {
        XCTAssertEqual(CyclePhase.allCases.count, 5, "Expected 5 CyclePhase cases")
    }

    func testCyclePhaseSnakeCaseRawValues() {
        // Verify the snake_case value explicitly — changing this would break existing Supabase rows
        XCTAssertEqual(CyclePhase.notApplicable.rawValue, "not_applicable")
        XCTAssertEqual(CyclePhase.menstrual.rawValue, "menstrual")
        XCTAssertEqual(CyclePhase.follicular.rawValue, "follicular")
        XCTAssertEqual(CyclePhase.ovulatory.rawValue, "ovulatory")
        XCTAssertEqual(CyclePhase.luteal.rawValue, "luteal")
    }

    // MARK: - SymptomQuality

    func testSymptomQualityRoundTrip() {
        for quality in SymptomQuality.allCases {
            let raw = quality.rawValue
            let restored = SymptomQuality(rawValue: raw)
            XCTAssertEqual(restored, quality, "SymptomQuality.\(quality) failed round-trip via rawValue '\(raw)'")
        }
    }

    func testSymptomQualityAllCasesCount() {
        XCTAssertEqual(SymptomQuality.allCases.count, 5, "Expected 5 SymptomQuality cases")
    }

    func testSymptomQualityTCMPatterns() {
        // Verify TCM patterns are non-empty for all cases
        for quality in SymptomQuality.allCases {
            XCTAssertFalse(quality.tcmPattern.isEmpty, "SymptomQuality.\(quality) should have a non-empty tcmPattern")
        }
    }

    // MARK: - HydrationPattern

    func testHydrationPatternRoundTrip() {
        for pattern in HydrationPattern.allCases {
            let raw = pattern.rawValue
            let restored = HydrationPattern(rawValue: raw)
            XCTAssertEqual(restored, pattern, "HydrationPattern.\(pattern) failed round-trip via rawValue '\(raw)'")
        }
    }

    func testHydrationPatternAllCasesCount() {
        XCTAssertEqual(HydrationPattern.allCases.count, 4, "Expected 4 HydrationPattern cases")
    }

    func testHydrationPatternSnakeCaseRawValues() {
        XCTAssertEqual(HydrationPattern.prefersWarm.rawValue, "prefers_warm")
        XCTAssertEqual(HydrationPattern.prefersCold.rawValue, "prefers_cold")
        XCTAssertEqual(HydrationPattern.rarelyThirsty.rawValue, "rarely_thirsty")
        XCTAssertEqual(HydrationPattern.constantlyThirsty.rawValue, "constantly_thirsty")
    }

    // MARK: - SweatPattern

    func testSweatPatternRoundTrip() {
        for pattern in SweatPattern.allCases {
            let raw = pattern.rawValue
            let restored = SweatPattern(rawValue: raw)
            XCTAssertEqual(restored, pattern, "SweatPattern.\(pattern) failed round-trip via rawValue '\(raw)'")
        }
    }

    func testSweatPatternAllCasesCount() {
        XCTAssertEqual(SweatPattern.allCases.count, 5, "Expected 5 SweatPattern cases")
    }

    func testSweatPatternSnakeCaseRawValues() {
        XCTAssertEqual(SweatPattern.spontaneousDaytime.rawValue, "spontaneous_daytime")
        XCTAssertEqual(SweatPattern.nightSweats.rawValue, "night_sweats")
        XCTAssertEqual(SweatPattern.rarelySweat.rawValue, "rarely_sweat")
        XCTAssertEqual(SweatPattern.heavyWithExertion.rawValue, "heavy_with_exertion")
        XCTAssertEqual(SweatPattern.normal.rawValue, "normal")
    }

    // MARK: - Nil Handling

    func testNilRawValueReturnsNil() {
        XCTAssertNil(CyclePhase(rawValue: "invalid"))
        XCTAssertNil(SymptomQuality(rawValue: "nonexistent"))
        XCTAssertNil(HydrationPattern(rawValue: "bogus"))
        XCTAssertNil(SweatPattern(rawValue: "made_up"))
    }

    func testEmptyStringReturnsNil() {
        XCTAssertNil(CyclePhase(rawValue: ""))
        XCTAssertNil(SymptomQuality(rawValue: ""))
        XCTAssertNil(HydrationPattern(rawValue: ""))
        XCTAssertNil(SweatPattern(rawValue: ""))
    }
}
