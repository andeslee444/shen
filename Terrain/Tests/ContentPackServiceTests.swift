//
//  ContentPackServiceTests.swift
//  TerrainTests
//
//  Unit tests for the ContentPackService
//

import XCTest
import SwiftData
@testable import Terrain

final class ContentPackServiceTests: XCTestCase {

    // MARK: - JSON Parsing Tests

    func testParseIngredientDTO() throws {
        let json = """
        {
            "id": "ginger",
            "name": {
                "common": { "en-US": "Ginger" },
                "pinyin": "shēng jiāng",
                "hanzi": "生姜"
            },
            "category": "root",
            "tags": ["warming", "supports_digestion"],
            "goals": ["digestion", "energy"],
            "seasons": ["all_year"],
            "regions": ["pan_chinese_common"],
            "why_it_helps": {
                "plain": { "en-US": "Warms the stomach." },
                "tcm": { "en-US": "Warms the Middle Jiao." }
            },
            "how_to_use": {
                "quick_uses": [
                    { "text": { "en-US": "Add to tea" }, "prep_time_min": 5, "method_tags": ["steep"] }
                ],
                "typical_amount": { "en-US": "2-3 slices" }
            },
            "cautions": {
                "flags": [],
                "text": { "en-US": "Use moderately." }
            },
            "cultural_context": {
                "blurb": { "en-US": "A kitchen staple." },
                "common_in": ["pan_chinese_common"]
            },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(IngredientDTO.self, from: json)

        XCTAssertEqual(dto.id, "ginger")
        XCTAssertEqual(dto.name.common.enUS, "Ginger")
        XCTAssertEqual(dto.name.pinyin, "shēng jiāng")
        XCTAssertEqual(dto.category, "root")
        XCTAssertEqual(dto.tags, ["warming", "supports_digestion"])
        XCTAssertEqual(dto.goals, ["digestion", "energy"])
        XCTAssertEqual(dto.why_it_helps.plain.enUS, "Warms the stomach.")
        XCTAssertEqual(dto.how_to_use.quick_uses.count, 1)
        XCTAssertEqual(dto.cautions.text.enUS, "Use moderately.")
    }

    func testParseRoutineDTO() throws {
        let json = """
        {
            "id": "ginger-tea",
            "type": "eat_drink",
            "title": { "en-US": "Ginger Tea" },
            "subtitle": { "en-US": "Quick warming drink" },
            "duration_min": 5,
            "difficulty": "easy",
            "tags": ["warming"],
            "goals": ["digestion"],
            "seasons": ["all_year"],
            "terrain_fit": ["cold_deficient_low_flame"],
            "ingredient_refs": ["ginger"],
            "steps": [
                { "text": { "en-US": "Slice ginger" }, "timer_seconds": 0 },
                { "text": { "en-US": "Pour hot water" }, "timer_seconds": 180 }
            ],
            "why": {
                "one_line": { "en-US": "Warms the stomach." },
                "expanded": {
                    "plain": { "en-US": "Ginger tea is warming." },
                    "tcm": { "en-US": "Warms the Middle Jiao." }
                }
            },
            "swaps": [],
            "avoid_for_hours": 2,
            "cautions": { "flags": [], "text": { "en-US": "" } },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(RoutineDTO.self, from: json)

        XCTAssertEqual(dto.id, "ginger-tea")
        XCTAssertEqual(dto.type, "eat_drink")
        XCTAssertEqual(dto.title.enUS, "Ginger Tea")
        XCTAssertEqual(dto.duration_min, 5)
        XCTAssertEqual(dto.steps.count, 2)
        XCTAssertEqual(dto.steps[1].timer_seconds, 180)
        XCTAssertEqual(dto.why.one_line.enUS, "Warms the stomach.")
    }

    func testParseMovementDTO() throws {
        let json = """
        {
            "id": "morning-stretch",
            "title": { "en-US": "Morning Stretch" },
            "subtitle": { "en-US": "Gentle wake-up" },
            "tier": "full",
            "duration_min": 5,
            "intensity": "gentle",
            "tags": ["moves_qi"],
            "goals": ["energy"],
            "seasons": ["all_year"],
            "terrain_fit": ["neutral_balanced_steady_core"],
            "frames": [
                {
                    "asset": { "type": "svg", "uri": "movements/stretch-1" },
                    "cue": { "en-US": "Stand tall" },
                    "seconds": 10
                }
            ],
            "why": {
                "one_line": { "en-US": "Wakes up your body." }
            },
            "cautions": { "flags": [], "text": { "en-US": "" } },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(MovementDTO.self, from: json)

        XCTAssertEqual(dto.id, "morning-stretch")
        XCTAssertEqual(dto.tier, "full")
        XCTAssertEqual(dto.intensity, "gentle")
        XCTAssertEqual(dto.frames.count, 1)
        XCTAssertEqual(dto.frames[0].seconds, 10)
        XCTAssertEqual(dto.frames[0].asset.type, "svg")
    }

    func testParseMovementDTOWithoutTier() throws {
        // Backward compatibility: movements without a tier field should still parse
        let json = """
        {
            "id": "legacy-movement",
            "title": { "en-US": "Legacy" },
            "duration_min": 5,
            "intensity": "gentle",
            "tags": [],
            "goals": [],
            "seasons": ["all_year"],
            "terrain_fit": [],
            "frames": [],
            "why": { "one_line": { "en-US": "Test." } },
            "cautions": { "flags": [], "text": { "en-US": "" } },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(MovementDTO.self, from: json)

        XCTAssertEqual(dto.id, "legacy-movement")
        XCTAssertNil(dto.tier)

        let model = dto.toModel()
        XCTAssertNil(model.tier)
    }

    func testParseLessonDTO() throws {
        let json = """
        {
            "id": "cold-heat-intro",
            "title": { "en-US": "Understanding Cold & Heat" },
            "topic": "cold_heat",
            "body": [
                { "type": "paragraph", "text": { "en-US": "Cold and heat are patterns." } },
                { "type": "bullets", "bullets": [
                    { "en-US": "Cold signs: feeling chilly" },
                    { "en-US": "Heat signs: feeling warm" }
                ] }
            ],
            "takeaway": {
                "one_line": { "en-US": "Understand your temperature tendency." }
            },
            "cta": {
                "label": { "en-US": "See your routine" },
                "action": "open_today"
            },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(LessonDTO.self, from: json)

        XCTAssertEqual(dto.id, "cold-heat-intro")
        XCTAssertEqual(dto.topic, "cold_heat")
        XCTAssertEqual(dto.body.count, 2)
        XCTAssertEqual(dto.body[0].type, "paragraph")
        XCTAssertEqual(dto.body[1].bullets?.count, 2)
        XCTAssertEqual(dto.takeaway.one_line.enUS, "Understand your temperature tendency.")
    }

    func testParseTerrainProfileDTO() throws {
        let json = """
        {
            "id": "cold_deficient_low_flame",
            "label": {
                "primary": { "en-US": "Cold + Deficient" }
            },
            "nickname": { "en-US": "Low Flame" },
            "modifier": { "key": "none", "display": { "en-US": "" } },
            "principles": {
                "yin_yang": "yin_leaning",
                "cold_heat": "cold",
                "def_excess": "deficient",
                "interior_exterior": "interior"
            },
            "superpower": { "en-US": "Warmth unlocks your best energy." },
            "trap": { "en-US": "Cold inputs drain you." },
            "signature_ritual": { "en-US": "Warm start within 30 minutes." },
            "truths": [
                { "en-US": "Your system does better with gentle build-up." },
                { "en-US": "Cooked food stabilizes you." }
            ],
            "recommended_tags": ["warming", "supports_deficiency"],
            "avoid_tags": ["cooling"],
            "starter_ingredients": ["ginger", "red-dates"],
            "starter_movements": ["morning-qi-flow"],
            "starter_routines": ["warm-start-congee"]
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(TerrainProfileDTO.self, from: json)

        XCTAssertEqual(dto.id, "cold_deficient_low_flame")
        XCTAssertEqual(dto.label.primary.enUS, "Cold + Deficient")
        XCTAssertEqual(dto.nickname.enUS, "Low Flame")
        XCTAssertEqual(dto.principles.cold_heat, "cold")
        XCTAssertEqual(dto.truths.count, 2)
        XCTAssertEqual(dto.recommended_tags, ["warming", "supports_deficiency"])
        XCTAssertEqual(dto.starter_ingredients, ["ginger", "red-dates"])
    }

    // MARK: - Model Conversion Tests

    func testIngredientDTOToModel() throws {
        let json = """
        {
            "id": "test-ingredient",
            "name": {
                "common": { "en-US": "Test" },
                "pinyin": "test",
                "hanzi": "测试"
            },
            "category": "root",
            "tags": ["warming"],
            "goals": ["energy"],
            "seasons": ["winter"],
            "regions": ["pan_chinese_common"],
            "why_it_helps": {
                "plain": { "en-US": "Helps with energy." },
                "tcm": { "en-US": "Tonifies Qi." }
            },
            "how_to_use": {
                "quick_uses": [],
                "typical_amount": { "en-US": "1 piece" }
            },
            "cautions": {
                "flags": [],
                "text": { "en-US": "" }
            },
            "cultural_context": {
                "blurb": { "en-US": "Common ingredient." },
                "common_in": []
            },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(IngredientDTO.self, from: json)
        let model = dto.toModel()

        XCTAssertEqual(model.id, "test-ingredient")
        XCTAssertEqual(model.name.common.en_US, "Test")
        XCTAssertEqual(model.category, "root")
        XCTAssertEqual(model.tags, ["warming"])
        XCTAssertEqual(model.whyItHelps.plain.en_US, "Helps with energy.")
    }

    func testRoutineDTOToModel() throws {
        let json = """
        {
            "id": "test-routine",
            "type": "eat_drink",
            "title": { "en-US": "Test Routine" },
            "duration_min": 10,
            "difficulty": "easy",
            "tags": [],
            "goals": [],
            "seasons": [],
            "terrain_fit": [],
            "steps": [],
            "why": {
                "one_line": { "en-US": "Test." }
            },
            "swaps": [],
            "cautions": { "flags": [], "text": { "en-US": "" } },
            "review": { "status": "draft" }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(RoutineDTO.self, from: json)
        let model = dto.toModel()

        XCTAssertEqual(model.id, "test-routine")
        XCTAssertEqual(model.type, .eatDrink)
        XCTAssertEqual(model.durationMin, 10)
        XCTAssertEqual(model.difficulty, .easy)
    }

    // MARK: - Full Content Pack Tests

    func testParseFullContentPack() throws {
        let json = """
        {
            "pack": {
                "version": "1.0.0",
                "default_locale": "en-US",
                "supported_locales": ["en-US"],
                "updated_at": "2025-01-28T00:00:00Z",
                "review": { "status": "draft", "reviewed_by": [] }
            },
            "ingredients": [],
            "routines": [],
            "movements": [],
            "lessons": [],
            "programs": [],
            "terrain_profiles": []
        }
        """.data(using: .utf8)!

        let pack = try JSONDecoder().decode(ContentPackDTO.self, from: json)

        XCTAssertEqual(pack.pack.version, "1.0.0")
        XCTAssertEqual(pack.pack.default_locale, "en-US")
        XCTAssertTrue(pack.ingredients.isEmpty)
        XCTAssertTrue(pack.terrain_profiles.isEmpty)
    }
}
