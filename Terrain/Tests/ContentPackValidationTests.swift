//
//  ContentPackValidationTests.swift
//  TerrainTests
//
//  Automated validation of the base content pack JSON.
//  These tests load the real content pack from the bundle and verify
//  structural integrity — like a quality control inspector checking
//  every item before it goes on the shelf.
//

import XCTest
@testable import Terrain

final class ContentPackValidationTests: XCTestCase {

    var pack: ContentPackDTO!

    override func setUp() {
        super.setUp()
        do {
            let url = try XCTUnwrap(
                Bundle(for: type(of: self)).url(forResource: "base-content-pack", withExtension: "json", subdirectory: "ContentPacks")
                ?? Bundle(for: type(of: self)).url(forResource: "base-content-pack", withExtension: "json")
                ?? Bundle.main.url(forResource: "base-content-pack", withExtension: "json", subdirectory: "ContentPacks")
                ?? Bundle.main.url(forResource: "base-content-pack", withExtension: "json"),
                "base-content-pack.json not found in test bundle"
            )
            let data = try Data(contentsOf: url)
            pack = try JSONDecoder().decode(ContentPackDTO.self, from: data)
        } catch {
            XCTFail("Failed to load content pack: \(error)")
        }
    }

    override func tearDown() {
        pack = nil
        super.tearDown()
    }

    // MARK: - Version

    func testContentPackHasVersion() {
        XCTAssertFalse(pack.pack.version.isEmpty, "Content pack version must not be empty")

        // Basic semver format check: at least "X.Y.Z"
        let parts = pack.pack.version.split(separator: ".")
        XCTAssertGreaterThanOrEqual(parts.count, 3, "Version should follow semver (X.Y.Z), got: \(pack.pack.version)")
    }

    // MARK: - Terrain Coverage

    func testAllTerrainProfilesHaveContent() {
        let terrainIds = Set(pack.terrain_profiles.map(\.id))
        XCTAssertFalse(terrainIds.isEmpty, "Content pack must have at least one terrain profile")

        // Check every terrain profile has at least one routine tagged for it
        for profileId in terrainIds {
            let matchingRoutines = pack.routines.filter { $0.terrain_fit.contains(profileId) }
            // Some profiles may be universal (empty terrain_fit), so also count those
            let universalRoutines = pack.routines.filter { $0.terrain_fit.isEmpty }
            let total = matchingRoutines.count + universalRoutines.count
            XCTAssertGreaterThan(total, 0, "Terrain '\(profileId)' has no routines (specific or universal)")
        }
    }

    // MARK: - Timer Values

    func testAllTimerValuesReasonable() {
        for routine in pack.routines {
            for (stepIndex, step) in routine.steps.enumerated() {
                if let timer = step.timer_seconds {
                    XCTAssertGreaterThanOrEqual(
                        timer, 0,
                        "Routine '\(routine.id)' step \(stepIndex) has negative timer: \(timer)"
                    )
                    XCTAssertLessThanOrEqual(
                        timer, 3600,
                        "Routine '\(routine.id)' step \(stepIndex) timer exceeds 1 hour: \(timer)s"
                    )
                }
            }
        }
    }

    // MARK: - Reference Integrity

    func testIngredientRefIntegrity() {
        let ingredientIds = Set(pack.ingredients.map(\.id))

        for routine in pack.routines {
            guard let refs = routine.ingredient_refs else { continue }
            for ref in refs {
                XCTAssertTrue(
                    ingredientIds.contains(ref),
                    "Routine '\(routine.id)' references unknown ingredient '\(ref)'"
                )
            }
        }
    }

    func testRoutineRefIntegrity() {
        let routineIds = Set(pack.routines.map(\.id))
        let movementIds = Set(pack.movements.map(\.id))

        for program in pack.programs {
            for day in program.days {
                for ref in day.routine_refs {
                    XCTAssertTrue(
                        routineIds.contains(ref),
                        "Program '\(program.id)' day \(day.day) references unknown routine '\(ref)'"
                    )
                }
                if let movementRefs = day.movement_refs {
                    for ref in movementRefs {
                        XCTAssertTrue(
                            movementIds.contains(ref),
                            "Program '\(program.id)' day \(day.day) references unknown movement '\(ref)'"
                        )
                    }
                }
            }
        }
    }

    func testLessonRefIntegrity() {
        let lessonIds = Set(pack.lessons.map(\.id))

        for program in pack.programs {
            for day in program.days {
                if let lessonRef = day.lesson_ref {
                    XCTAssertTrue(
                        lessonIds.contains(lessonRef),
                        "Program '\(program.id)' day \(day.day) references unknown lesson '\(lessonRef)'"
                    )
                }
            }
        }
    }

    // MARK: - Category Coverage

    func testCategoryCoverage() {
        // Group ingredients by category
        var categoryCounts: [String: Int] = [:]
        for ingredient in pack.ingredients {
            categoryCounts[ingredient.category, default: 0] += 1
        }

        XCTAssertFalse(categoryCounts.isEmpty, "Content pack must have at least one ingredient category")

        for (category, count) in categoryCounts {
            XCTAssertGreaterThanOrEqual(
                count, 2,
                "Category '\(category)' has only \(count) ingredient(s), expected at least 2"
            )
        }
    }

    // MARK: - Basic Counts

    func testContentPackHasMinimumContent() {
        XCTAssertGreaterThan(pack.ingredients.count, 0, "Pack must have ingredients")
        XCTAssertGreaterThan(pack.routines.count, 0, "Pack must have routines")
        XCTAssertGreaterThan(pack.movements.count, 0, "Pack must have movements")
        XCTAssertGreaterThan(pack.lessons.count, 0, "Pack must have lessons")
        XCTAssertGreaterThan(pack.terrain_profiles.count, 0, "Pack must have terrain profiles")
        XCTAssertEqual(pack.programs.count, 8, "Pack must have 8 programs (v1.3.0)")
    }

    // MARK: - Terrain Relevance

    func testAllLessonsHaveTerrainRelevance() {
        for lesson in pack.lessons {
            let relevance = lesson.terrain_relevance ?? []
            XCTAssertFalse(
                relevance.isEmpty,
                "Lesson '\(lesson.id)' is missing terrain_relevance"
            )
        }
    }

    func testTerrainRelevanceRefIntegrity() {
        let profileIds = Set(pack.terrain_profiles.map(\.id))
        for lesson in pack.lessons {
            for ref in lesson.terrain_relevance ?? [] {
                XCTAssertTrue(
                    profileIds.contains(ref),
                    "Lesson '\(lesson.id)' terrain_relevance references unknown profile '\(ref)'"
                )
            }
        }
    }

    func testEveryTerrainTypeAppearsInLessonRelevance() {
        let profileIds = Set(pack.terrain_profiles.map(\.id))
        for profileId in profileIds {
            let count = pack.lessons.filter { ($0.terrain_relevance ?? []).contains(profileId) }.count
            XCTAssertGreaterThanOrEqual(
                count, 3,
                "Terrain '\(profileId)' appears in only \(count) lessons' terrain_relevance, expected at least 3"
            )
        }
    }

    // MARK: - Movement Tier Coverage

    func testAllMovementTiersHaveSufficientContent() {
        // Each tier (full, medium, lite) should have at least 4 movements
        // to give the scoring engine real choices for different terrains
        let tiers = ["full", "medium", "lite"]
        for tier in tiers {
            let count = pack.movements.filter { $0.tier == tier }.count
            XCTAssertGreaterThanOrEqual(
                count, 4,
                "Tier '\(tier)' has only \(count) movement(s), expected at least 4"
            )
        }
    }

    func testEveryTerrainTypeHasMovementPerTier() {
        // For every terrain profile and every tier, at least one movement should
        // have that terrain in its terrain_fit (or be universal with all 8)
        let profileIds = Set(pack.terrain_profiles.map(\.id))
        let tiers = ["full", "medium", "lite"]

        for tier in tiers {
            let tierMovements = pack.movements.filter { $0.tier == tier }
            for profileId in profileIds {
                let matching = tierMovements.filter {
                    $0.terrain_fit.contains(profileId)
                }
                // Also count "universal" movements (those that list all 8 terrains)
                let universal = tierMovements.filter {
                    $0.terrain_fit.count == profileIds.count
                }
                let total = Set(matching.map(\.id)).union(Set(universal.map(\.id))).count
                XCTAssertGreaterThan(
                    total, 0,
                    "Terrain '\(profileId)' has no movements in tier '\(tier)'"
                )
            }
        }
    }

    func testMovementTierDurationsMatchExpectations() {
        // Full ≈ 10 min, Medium ≈ 5 min, Lite ≈ 90 sec
        for movement in pack.movements {
            guard let tier = movement.tier else { continue }
            switch tier {
            case "full":
                XCTAssertGreaterThanOrEqual(
                    movement.duration_min, 8,
                    "Full-tier movement '\(movement.id)' is only \(movement.duration_min) min, expected ≥8"
                )
            case "medium":
                XCTAssertTrue(
                    (3...7).contains(movement.duration_min),
                    "Medium-tier movement '\(movement.id)' is \(movement.duration_min) min, expected 3-7"
                )
            case "lite":
                XCTAssertLessThanOrEqual(
                    movement.duration_min, 3,
                    "Lite-tier movement '\(movement.id)' is \(movement.duration_min) min, expected ≤3"
                )
            default:
                XCTFail("Unknown tier '\(tier)' on movement '\(movement.id)'")
            }
        }
    }

    func testAllIdsUnique() {
        // Ingredient IDs
        let ingredientIds = pack.ingredients.map(\.id)
        XCTAssertEqual(ingredientIds.count, Set(ingredientIds).count, "Duplicate ingredient IDs found")

        // Routine IDs
        let routineIds = pack.routines.map(\.id)
        XCTAssertEqual(routineIds.count, Set(routineIds).count, "Duplicate routine IDs found")

        // Movement IDs
        let movementIds = pack.movements.map(\.id)
        XCTAssertEqual(movementIds.count, Set(movementIds).count, "Duplicate movement IDs found")

        // Lesson IDs
        let lessonIds = pack.lessons.map(\.id)
        XCTAssertEqual(lessonIds.count, Set(lessonIds).count, "Duplicate lesson IDs found")

        // Program IDs
        let programIds = pack.programs.map(\.id)
        XCTAssertEqual(programIds.count, Set(programIds).count, "Duplicate program IDs found")

        // Terrain profile IDs
        let profileIds = pack.terrain_profiles.map(\.id)
        XCTAssertEqual(profileIds.count, Set(profileIds).count, "Duplicate terrain profile IDs found")
    }
}
