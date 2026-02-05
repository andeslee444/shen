//
//  InsightEngineTests.swift
//  TerrainTests
//
//  Tests for InsightEngine's generateWhyForYou methods (routine + ingredient)
//  and TCMSeason.current(for:) month-to-season mapping.
//
//  These test the "brain" that personalizes content explanations per terrain type —
//  like verifying a translator correctly pairs the right phrase with the right audience.
//

import XCTest
@testable import Terrain

final class InsightEngineTests: XCTestCase {

    private var engine: InsightEngine!

    override func setUp() {
        super.setUp()
        engine = InsightEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Create a Date for a given month (day 15) to test season mapping.
    private func date(month: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: 2025, month: month, day: 15))!
    }

    // MARK: - generateWhyForYou (Routine Tags)

    func testRoutine_ColdDeficient_WarmingTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["warming"],
            terrainType: .coldDeficient,
            modifier: .none
        )
        XCTAssertNotNil(result, "Cold deficient + warming tag should produce a why-for-you string")
        XCTAssertTrue(result!.lowercased().contains("warm"), "Should mention warming concept")
    }

    func testRoutine_ColdBalanced_WarmingTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["warming"],
            terrainType: .coldBalanced,
            modifier: .none
        )
        XCTAssertNotNil(result, "Cold balanced + warming tag should produce a why-for-you string")
    }

    func testRoutine_WarmExcess_CoolingTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["cooling"],
            terrainType: .warmExcess,
            modifier: .none
        )
        XCTAssertNotNil(result, "Warm excess + cooling tag should produce a why-for-you string")
        XCTAssertTrue(result!.lowercased().contains("cool"), "Should mention cooling concept")
    }

    func testRoutine_WarmBalanced_CoolingTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["cooling"],
            terrainType: .warmBalanced,
            modifier: .none
        )
        XCTAssertNotNil(result, "Warm balanced + cooling tag should produce a why-for-you string")
    }

    func testRoutine_NeutralExcess_MovesQiTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["moves_qi"],
            terrainType: .neutralExcess,
            modifier: .none
        )
        XCTAssertNotNil(result, "Neutral excess + moves_qi tag should produce a why-for-you string")
    }

    func testRoutine_WarmDeficient_CalmsShenTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["calms_shen"],
            terrainType: .warmDeficient,
            modifier: .none
        )
        XCTAssertNotNil(result, "Warm deficient + calms_shen tag should produce a why-for-you string")
    }

    func testRoutine_ShenModifier_CalmsShenTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["calms_shen"],
            terrainType: .neutralBalanced,
            modifier: .shen
        )
        XCTAssertNotNil(result, "Shen modifier + calms_shen tag should produce a why-for-you string")
        XCTAssertTrue(result!.lowercased().contains("shen"), "Should mention shen")
    }

    func testRoutine_StagnationModifier_MovesQiTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["moves_qi"],
            terrainType: .neutralBalanced,
            modifier: .stagnation
        )
        XCTAssertNotNil(result, "Stagnation modifier + moves_qi tag should produce a why-for-you string")
        XCTAssertTrue(result!.lowercased().contains("stagnation"), "Should mention stagnation")
    }

    func testRoutine_DampModifier_DriesDampTag() {
        let result = engine.generateWhyForYou(
            routineTags: ["dries_damp"],
            terrainType: .neutralBalanced,
            modifier: .damp
        )
        XCTAssertNotNil(result, "Damp modifier + dries_damp tag should produce a why-for-you string")
        XCTAssertTrue(result!.lowercased().contains("damp"), "Should mention dampness")
    }

    func testRoutine_TerrainMatchTakesPriorityOverModifier() {
        // When both terrain and modifier could match, terrain wins (switch runs first)
        let result = engine.generateWhyForYou(
            routineTags: ["warming", "calms_shen"],
            terrainType: .coldDeficient,
            modifier: .shen
        )
        XCTAssertNotNil(result, "Should produce a result when both terrain and modifier match")
        // The terrain branch (coldDeficient + warming) should fire first
        XCTAssertTrue(result!.lowercased().contains("warm"),
                       "Terrain match (warming) should take priority over modifier match (shen)")
    }

    func testRoutine_NeutralBalanced_NoModifier_WarmingTag_ReturnsNil() {
        let result = engine.generateWhyForYou(
            routineTags: ["warming"],
            terrainType: .neutralBalanced,
            modifier: .none
        )
        XCTAssertNil(result, "Neutral balanced + no modifier + warming tag has no matching branch")
    }

    func testRoutine_NeutralDeficient_NoModifier_CoolingTag_ReturnsNil() {
        let result = engine.generateWhyForYou(
            routineTags: ["cooling"],
            terrainType: .neutralDeficient,
            modifier: .none
        )
        XCTAssertNil(result, "Neutral deficient + cooling tag has no matching branch")
    }

    func testRoutine_ColdDeficient_CoolingTag_ReturnsNil() {
        let result = engine.generateWhyForYou(
            routineTags: ["cooling"],
            terrainType: .coldDeficient,
            modifier: .none
        )
        XCTAssertNil(result, "Cold deficient + cooling (wrong tag) should return nil")
    }

    func testRoutine_EmptyTags_ReturnsNil() {
        let result = engine.generateWhyForYou(
            routineTags: [],
            terrainType: .coldDeficient,
            modifier: .none
        )
        XCTAssertNil(result, "Empty tags should always return nil")
    }

    // MARK: - generateWhyForYou (Ingredient Tags)

    func testIngredient_ColdDeficient_WarmingTag() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["warming"],
            terrainType: .coldDeficient,
            modifier: .none
        )
        XCTAssertNotNil(result, "Cold deficient + warming ingredient should produce positive text")
        XCTAssertTrue(result!.lowercased().contains("warm"), "Should mention warming benefit")
    }

    func testIngredient_ColdBalanced_CoolingTag_Warning() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["cooling"],
            terrainType: .coldBalanced,
            modifier: .none
        )
        XCTAssertNotNil(result, "Cold balanced + cooling ingredient should produce a warning")
        XCTAssertTrue(result!.lowercased().contains("spar") || result!.lowercased().contains("weaken") || result!.lowercased().contains("careful"),
                       "Should contain cautionary language")
    }

    func testIngredient_WarmExcess_CoolingTag() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["cooling"],
            terrainType: .warmExcess,
            modifier: .none
        )
        XCTAssertNotNil(result, "Warm excess + cooling ingredient should produce positive text")
        XCTAssertTrue(result!.lowercased().contains("cool"), "Should mention cooling benefit")
    }

    func testIngredient_WarmBalanced_WarmingTag_Warning() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["warming"],
            terrainType: .warmBalanced,
            modifier: .none
        )
        XCTAssertNotNil(result, "Warm balanced + warming ingredient should produce a warning")
        XCTAssertTrue(result!.lowercased().contains("careful") || result!.lowercased().contains("heat") || result!.lowercased().contains("warm"),
                       "Should contain cautionary language about heat")
    }

    func testIngredient_WarmDeficient_MoisteningTag() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["moistens_dryness"],
            terrainType: .warmDeficient,
            modifier: .none
        )
        XCTAssertNotNil(result, "Warm deficient + moistening ingredient should produce text")
        XCTAssertTrue(result!.lowercased().contains("moist") || result!.lowercased().contains("fluid") || result!.lowercased().contains("dry"),
                       "Should mention moistening or dryness concept")
    }

    func testIngredient_NeutralDeficient_SupportsDeficiencyTag() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["supports_deficiency"],
            terrainType: .neutralDeficient,
            modifier: .none
        )
        XCTAssertNotNil(result, "Neutral deficient + supports_deficiency should produce text")
        XCTAssertTrue(result!.lowercased().contains("nourish") || result!.lowercased().contains("build"),
                       "Should mention nourishing or building up")
    }

    func testIngredient_ShenModifier_CalmingShenTag() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["calms_shen"],
            terrainType: .neutralBalanced,
            modifier: .shen
        )
        XCTAssertNotNil(result, "Shen modifier + calming ingredient should produce text")
        XCTAssertTrue(result!.lowercased().contains("shen") || result!.lowercased().contains("mind") || result!.lowercased().contains("calm"),
                       "Should mention shen or calming concept")
    }

    func testIngredient_DampModifier_DriesDampTag() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["dries_damp"],
            terrainType: .neutralBalanced,
            modifier: .damp
        )
        XCTAssertNotNil(result, "Damp modifier + dries_damp ingredient should produce text")
        XCTAssertTrue(result!.lowercased().contains("damp") || result!.lowercased().contains("moisture") || result!.lowercased().contains("drain"),
                       "Should mention dampness or drainage concept")
    }

    func testIngredient_NeutralBalanced_NoModifier_WarmingTag_ReturnsNil() {
        let result = engine.generateWhyForYou(
            ingredientTags: ["warming"],
            terrainType: .neutralBalanced,
            modifier: .none
        )
        XCTAssertNil(result, "Neutral balanced + no modifier + warming tag has no matching branch")
    }

    // MARK: - TCMSeason.current(for:)

    func testSeason_January_IsWinter() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 1)), .winter)
    }

    func testSeason_February_IsWinter() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 2)), .winter)
    }

    func testSeason_March_IsSpring() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 3)), .spring)
    }

    func testSeason_April_IsSpring() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 4)), .spring)
    }

    func testSeason_May_IsSpring() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 5)), .spring)
    }

    func testSeason_June_IsSummer() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 6)), .summer)
    }

    func testSeason_July_IsSummer() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 7)), .summer)
    }

    func testSeason_August_IsLateSummer() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 8)), .lateSummer)
    }

    func testSeason_September_IsLateSummer() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 9)), .lateSummer)
    }

    func testSeason_October_IsAutumn() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 10)), .autumn)
    }

    func testSeason_November_IsAutumn() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 11)), .autumn)
    }

    func testSeason_December_IsWinter() {
        XCTAssertEqual(InsightEngine.TCMSeason.current(for: date(month: 12)), .winter)
    }

    func testSeason_LateSummer_ContentPackKey() {
        XCTAssertEqual(InsightEngine.TCMSeason.lateSummer.contentPackKey, "late_summer",
                        "lateSummer should map to 'late_summer' for content pack matching")
    }

    func testSeason_OtherSeasons_ContentPackKeyMatchesRawValue() {
        let nonLateSummer: [InsightEngine.TCMSeason] = [.spring, .summer, .autumn, .winter]
        for season in nonLateSummer {
            XCTAssertEqual(season.contentPackKey, season.rawValue,
                            "\(season) contentPackKey should match rawValue")
        }
    }

    // MARK: - generateLifeAreaReadings

    func testLifeAreaReadings_Returns5Areas() {
        let readings = engine.generateLifeAreaReadings(for: .neutralBalanced)
        XCTAssertEqual(readings.count, 5, "Should return exactly 5 life area readings")

        let types = readings.map { $0.type }
        XCTAssertTrue(types.contains(.energy), "Should include energy")
        XCTAssertTrue(types.contains(.digestion), "Should include digestion")
        XCTAssertTrue(types.contains(.sleep), "Should include sleep")
        XCTAssertTrue(types.contains(.mood), "Should include mood")
        XCTAssertTrue(types.contains(.seasonality), "Should include seasonality")
    }

    func testLifeAreaReadings_ColdDeficient_EnergyIsModerate() {
        let readings = engine.generateLifeAreaReadings(for: .coldDeficient)
        let energy = readings.first { $0.type == .energy }
        XCTAssertNotNil(energy)
        XCTAssertEqual(energy?.focusLevel, .moderate, "Cold deficient energy should be moderate focus")
    }

    func testLifeAreaReadings_WarmExcess_EnergyIsPriority() {
        let readings = engine.generateLifeAreaReadings(for: .warmExcess)
        let energy = readings.first { $0.type == .energy }
        XCTAssertNotNil(energy)
        XCTAssertEqual(energy?.focusLevel, .priority, "Warm excess energy should be priority focus")
    }

    func testLifeAreaReadings_NeutralBalanced_EnergyIsNeutral() {
        let readings = engine.generateLifeAreaReadings(for: .neutralBalanced)
        let energy = readings.first { $0.type == .energy }
        XCTAssertNotNil(energy)
        XCTAssertEqual(energy?.focusLevel, .neutral, "Neutral balanced energy should be neutral focus")
    }

    func testLifeAreaReadings_TiredSymptom_RaisesEnergyToPriority() {
        let readings = engine.generateLifeAreaReadings(
            for: .neutralBalanced,
            symptoms: [.tired]
        )
        let energy = readings.first { $0.type == .energy }
        XCTAssertNotNil(energy)
        XCTAssertEqual(energy?.focusLevel, .priority, "Tired symptom should raise energy to priority")
        XCTAssertTrue(energy?.reasons.contains { $0.source == "Symptoms" } ?? false,
                      "Should include Symptoms reason")
    }

    func testLifeAreaReadings_BloatingSymptom_RaisesDigestionToPriority() {
        let readings = engine.generateLifeAreaReadings(
            for: .neutralBalanced,
            symptoms: [.bloating]
        )
        let digestion = readings.first { $0.type == .digestion }
        XCTAssertNotNil(digestion)
        XCTAssertEqual(digestion?.focusLevel, .priority, "Bloating symptom should raise digestion to priority")
    }

    func testLifeAreaReadings_PoorSleepSymptom_RaisesSleepToPriority() {
        let readings = engine.generateLifeAreaReadings(
            for: .neutralBalanced,
            symptoms: [.poorSleep]
        )
        let sleep = readings.first { $0.type == .sleep }
        XCTAssertNotNil(sleep)
        XCTAssertEqual(sleep?.focusLevel, .priority, "Poor sleep symptom should raise sleep to priority")
    }

    func testLifeAreaReadings_StressedSymptom_RaisesMoodToPriority() {
        let readings = engine.generateLifeAreaReadings(
            for: .neutralBalanced,
            symptoms: [.stressed]
        )
        let mood = readings.first { $0.type == .mood }
        XCTAssertNotNil(mood)
        XCTAssertEqual(mood?.focusLevel, .priority, "Stressed symptom should raise mood to priority")
    }

    func testLifeAreaReadings_DampModifier_RaisesDigestionToPriority() {
        let readings = engine.generateLifeAreaReadings(
            for: .neutralBalanced,
            modifier: .damp
        )
        let digestion = readings.first { $0.type == .digestion }
        XCTAssertNotNil(digestion)
        XCTAssertEqual(digestion?.focusLevel, .priority, "Damp modifier should raise digestion to priority")
    }

    func testLifeAreaReadings_ShenModifier_RaisesSleepToPriority() {
        let readings = engine.generateLifeAreaReadings(
            for: .neutralBalanced,
            modifier: .shen
        )
        let sleep = readings.first { $0.type == .sleep }
        XCTAssertNotNil(sleep)
        XCTAssertEqual(sleep?.focusLevel, .priority, "Shen modifier should raise sleep to priority")
    }

    func testLifeAreaReadings_AllHaveReadingAndAdvice() {
        let readings = engine.generateLifeAreaReadings(for: .coldDeficient, modifier: .damp)
        for reading in readings {
            XCTAssertFalse(reading.reading.isEmpty, "\(reading.type) should have non-empty reading")
            XCTAssertFalse(reading.balanceAdvice.isEmpty, "\(reading.type) should have non-empty advice")
        }
    }

    func testLifeAreaReadings_AllHaveAtLeastOneReason() {
        let readings = engine.generateLifeAreaReadings(for: .warmExcess, modifier: .stagnation)
        for reading in readings {
            XCTAssertFalse(reading.reasons.isEmpty, "\(reading.type) should have at least one reason")
        }
    }

    // MARK: - generateModifierAreaReadings

    func testModifierAreaReadings_ColdDeficient_ReturnsInnerClimate() {
        let readings = engine.generateModifierAreaReadings(for: .coldDeficient)
        XCTAssertTrue(readings.contains { $0.type == .innerClimate },
                      "Cold deficient should produce Inner Climate reading")
    }

    func testModifierAreaReadings_WarmExcess_ReturnsInnerClimate() {
        let readings = engine.generateModifierAreaReadings(for: .warmExcess)
        XCTAssertTrue(readings.contains { $0.type == .innerClimate },
                      "Warm excess should produce Inner Climate reading")
    }

    func testModifierAreaReadings_NeutralBalanced_NoInnerClimate() {
        let readings = engine.generateModifierAreaReadings(for: .neutralBalanced)
        XCTAssertFalse(readings.contains { $0.type == .innerClimate },
                       "Neutral balanced should NOT produce Inner Climate reading")
    }

    func testModifierAreaReadings_DampModifier_ReturnsFluidBalance() {
        let readings = engine.generateModifierAreaReadings(for: .neutralBalanced, modifier: .damp)
        XCTAssertTrue(readings.contains { $0.type == .fluidBalance },
                      "Damp modifier should produce Fluid Balance reading")
    }

    func testModifierAreaReadings_DryModifier_ReturnsFluidBalance() {
        let readings = engine.generateModifierAreaReadings(for: .neutralBalanced, modifier: .dry)
        XCTAssertTrue(readings.contains { $0.type == .fluidBalance },
                      "Dry modifier should produce Fluid Balance reading")
    }

    func testModifierAreaReadings_StagnationModifier_ReturnsQiMovement() {
        let readings = engine.generateModifierAreaReadings(for: .neutralBalanced, modifier: .stagnation)
        XCTAssertTrue(readings.contains { $0.type == .qiMovement },
                      "Stagnation modifier should produce Qi Movement reading")
    }

    func testModifierAreaReadings_StiffSymptom_ReturnsQiMovement() {
        let readings = engine.generateModifierAreaReadings(
            for: .neutralBalanced,
            modifier: .none,
            symptoms: [.stiff]
        )
        XCTAssertTrue(readings.contains { $0.type == .qiMovement },
                      "Stiff symptom should produce Qi Movement reading")
    }

    func testModifierAreaReadings_StressedSymptom_ReturnsQiMovement() {
        let readings = engine.generateModifierAreaReadings(
            for: .neutralBalanced,
            modifier: .none,
            symptoms: [.stressed]
        )
        XCTAssertTrue(readings.contains { $0.type == .qiMovement },
                      "Stressed symptom should produce Qi Movement reading")
    }

    func testModifierAreaReadings_NoModifierNoSymptoms_ReturnsEmpty() {
        let readings = engine.generateModifierAreaReadings(for: .neutralBalanced, modifier: .none)
        XCTAssertTrue(readings.isEmpty, "No modifier + neutral terrain should produce no readings")
    }

    func testModifierAreaReadings_AllHaveReadingAndAdvice() {
        let readings = engine.generateModifierAreaReadings(for: .coldDeficient, modifier: .damp, symptoms: [.stiff])
        for reading in readings {
            XCTAssertFalse(reading.reading.isEmpty, "\(reading.type) should have non-empty reading")
            XCTAssertFalse(reading.balanceAdvice.isEmpty, "\(reading.type) should have non-empty advice")
        }
    }
}
