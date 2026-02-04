//
//  IngredientBenefitTests.swift
//  TerrainTests
//
//  Tests for IngredientBenefit.matches(): headache AND logic,
//  cramps vs stiffness differentiation, cold filter exclusion,
//  and goal-based fallback matching.
//

import XCTest
@testable import Terrain

final class IngredientBenefitTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a minimal Ingredient with the given tags and goals.
    private func makeIngredient(
        id: String = "test",
        tags: [String],
        goals: [String] = []
    ) -> Ingredient {
        Ingredient(
            id: id,
            name: IngredientName(common: LocalizedString(english: "Test")),
            category: "test",
            tags: tags,
            goals: goals,
            whyItHelps: WhyItHelps(
                plain: LocalizedString(english: "Test"),
                tcm: LocalizedString(english: "Test")
            ),
            howToUse: HowToUse(
                quickUses: [QuickUse(text: LocalizedString(english: "Use it"))],
                typicalAmount: LocalizedString(english: "1 cup")
            ),
            culturalContext: CulturalContext(blurb: LocalizedString(english: "Test"))
        )
    }

    // MARK: - Headache (AND logic)

    func testHeadacheRequiresBothCoolingAndMovesQi() {
        let both = makeIngredient(tags: ["cooling", "moves_qi"])
        XCTAssertTrue(IngredientBenefit.headache.matches(both))
    }

    func testHeadacheRejectsCoolingAlone() {
        let coolingOnly = makeIngredient(tags: ["cooling"])
        XCTAssertFalse(IngredientBenefit.headache.matches(coolingOnly))
    }

    func testHeadacheRejectsMovesQiAlone() {
        let qiOnly = makeIngredient(tags: ["moves_qi"])
        XCTAssertFalse(IngredientBenefit.headache.matches(qiOnly))
    }

    func testHeadacheRejectsUnrelatedTags() {
        let unrelated = makeIngredient(tags: ["warming", "supports_digestion"])
        XCTAssertFalse(IngredientBenefit.headache.matches(unrelated))
    }

    func testHeadacheMatchesWithExtraTags() {
        // Both required tags present alongside others
        let extra = makeIngredient(tags: ["cooling", "moves_qi", "calms_shen"])
        XCTAssertTrue(IngredientBenefit.headache.matches(extra))
    }

    // MARK: - Cramps vs Stiffness differentiation

    func testCrampsMatchesWarmingOrMovesQi() {
        let warming = makeIngredient(tags: ["warming"])
        let qi = makeIngredient(tags: ["moves_qi"])
        XCTAssertTrue(IngredientBenefit.cramps.matches(warming))
        XCTAssertTrue(IngredientBenefit.cramps.matches(qi))
    }

    func testStiffnessMatchesMovesQiOrDriesDamp() {
        let qi = makeIngredient(tags: ["moves_qi"])
        let damp = makeIngredient(tags: ["dries_damp"])
        XCTAssertTrue(IngredientBenefit.stiffness.matches(qi))
        XCTAssertTrue(IngredientBenefit.stiffness.matches(damp))
    }

    func testCrampsAndStiffnessReturnDifferentResults() {
        // dries_damp matches stiffness but NOT cramps
        let dampDrainer = makeIngredient(tags: ["dries_damp"])
        XCTAssertTrue(IngredientBenefit.stiffness.matches(dampDrainer))
        XCTAssertFalse(IngredientBenefit.cramps.matches(dampDrainer))

        // warming matches cramps but NOT stiffness
        let warmer = makeIngredient(tags: ["warming"])
        XCTAssertTrue(IngredientBenefit.cramps.matches(warmer))
        XCTAssertFalse(IngredientBenefit.stiffness.matches(warmer))
    }

    // MARK: - Cold filter (warming only)

    func testColdMatchesWarmingTag() {
        let warming = makeIngredient(tags: ["warming"])
        XCTAssertTrue(IngredientBenefit.cold.matches(warming))
    }

    func testColdRejectsSupportsDeficiencyAlone() {
        // Tofu scenario: supports_deficiency but cooling nature
        let deficiencyOnly = makeIngredient(tags: ["supports_deficiency"])
        XCTAssertFalse(IngredientBenefit.cold.matches(deficiencyOnly))
    }

    func testColdRejectsCoolingIngredient() {
        let cooling = makeIngredient(tags: ["cooling"])
        XCTAssertFalse(IngredientBenefit.cold.matches(cooling))
    }

    // MARK: - Goal-based matching (OR with tags)

    func testSleepMatchesCalmsShenTag() {
        let calming = makeIngredient(tags: ["calms_shen"])
        XCTAssertTrue(IngredientBenefit.sleep.matches(calming))
    }

    func testSleepMatchesSleepGoal() {
        let goalBased = makeIngredient(tags: [], goals: ["sleep"])
        XCTAssertTrue(IngredientBenefit.sleep.matches(goalBased))
    }

    func testSleepMatchesEitherTagOrGoal() {
        // Tag only
        let tagOnly = makeIngredient(tags: ["calms_shen"], goals: [])
        XCTAssertTrue(IngredientBenefit.sleep.matches(tagOnly))

        // Goal only
        let goalOnly = makeIngredient(tags: [], goals: ["sleep"])
        XCTAssertTrue(IngredientBenefit.sleep.matches(goalOnly))

        // Both
        let both = makeIngredient(tags: ["calms_shen"], goals: ["sleep"])
        XCTAssertTrue(IngredientBenefit.sleep.matches(both))
    }

    func testCrampsMatchesMenstrualComfortGoal() {
        let goalBased = makeIngredient(tags: [], goals: ["menstrual_comfort"])
        XCTAssertTrue(IngredientBenefit.cramps.matches(goalBased))
    }

    // MARK: - Empty / no match

    func testNoMatchForEmptyTagsAndGoals() {
        let empty = makeIngredient(tags: [], goals: [])
        for benefit in IngredientBenefit.allCases {
            XCTAssertFalse(benefit.matches(empty), "\(benefit) should not match empty ingredient")
        }
    }

    func testNoMatchForIrrelevantTags() {
        let irrelevant = makeIngredient(tags: ["gentle_for_acute"])
        XCTAssertFalse(IngredientBenefit.cold.matches(irrelevant))
        XCTAssertFalse(IngredientBenefit.energy.matches(irrelevant))
        XCTAssertFalse(IngredientBenefit.headache.matches(irrelevant))
    }

    // MARK: - Each benefit has at least one matching path

    func testEveryBenefitCanMatchSomething() {
        // Verifies no benefit is accidentally unreachable
        let allTagIngredients: [(IngredientBenefit, Ingredient)] = [
            (.sleep, makeIngredient(tags: ["calms_shen"])),
            (.digestion, makeIngredient(tags: ["supports_digestion"])),
            (.stress, makeIngredient(tags: ["calms_shen"])),
            (.energy, makeIngredient(tags: ["supports_deficiency"])),
            (.headache, makeIngredient(tags: ["moves_qi", "cooling"])),
            (.cramps, makeIngredient(tags: ["warming"])),
            (.stiffness, makeIngredient(tags: ["dries_damp"])),
            (.cold, makeIngredient(tags: ["warming"])),
            (.beauty, makeIngredient(tags: ["moistens_dryness"])),
        ]

        for (benefit, ingredient) in allTagIngredients {
            XCTAssertTrue(benefit.matches(ingredient), "\(benefit) should match its primary tags")
        }
    }
}
