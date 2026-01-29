//
//  ContentPackService.swift
//  Terrain
//
//  Service for loading and parsing content packs into SwiftData
//

import Foundation
import SwiftData

// MARK: - Content Pack Service

/// Service responsible for loading content packs from JSON and persisting to SwiftData.
/// Think of this as a librarian that takes books (JSON) and catalogs them into
/// the library system (SwiftData) so the app can find and use them.
@MainActor
final class ContentPackService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Loads the bundled base content pack if not already loaded.
    /// Returns true if content was loaded, false if already exists.
    func loadBundledContentPackIfNeeded() async throws -> Bool {
        // Check if we already have content loaded
        let ingredientCount = try modelContext.fetchCount(FetchDescriptor<Ingredient>())
        if ingredientCount > 0 {
            return false
        }

        // Load from bundle
        guard let url = Bundle.main.url(forResource: "base-content-pack", withExtension: "json", subdirectory: "ContentPacks") else {
            // Try without subdirectory (flat bundle structure)
            guard let flatUrl = Bundle.main.url(forResource: "base-content-pack", withExtension: "json") else {
                throw ContentPackError.bundleNotFound
            }
            try await loadContentPack(from: flatUrl)
            return true
        }

        try await loadContentPack(from: url)
        return true
    }

    /// Loads a content pack from a specific URL.
    func loadContentPack(from url: URL) async throws {
        let data = try Data(contentsOf: url)
        let pack = try JSONDecoder().decode(ContentPackDTO.self, from: data)

        try await importContentPack(pack)
    }

    // MARK: - Import Logic

    private func importContentPack(_ pack: ContentPackDTO) async throws {
        // Import ingredients
        for dto in pack.ingredients {
            let ingredient = dto.toModel()
            modelContext.insert(ingredient)
        }

        // Import routines
        for dto in pack.routines {
            let routine = dto.toModel()
            modelContext.insert(routine)
        }

        // Import movements
        for dto in pack.movements {
            let movement = dto.toModel()
            modelContext.insert(movement)
        }

        // Import lessons
        for dto in pack.lessons {
            let lesson = dto.toModel()
            modelContext.insert(lesson)
        }

        // Import programs
        for dto in pack.programs {
            let program = dto.toModel()
            modelContext.insert(program)
        }

        // Import terrain profiles
        for dto in pack.terrain_profiles {
            let profile = dto.toModel()
            modelContext.insert(profile)
        }

        try modelContext.save()
    }
}

// MARK: - Errors

enum ContentPackError: Error, LocalizedError {
    case bundleNotFound
    case parsingFailed(Error)
    case importFailed(Error)

    var errorDescription: String? {
        switch self {
        case .bundleNotFound:
            return "Content pack not found in app bundle"
        case .parsingFailed(let error):
            return "Failed to parse content pack: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import content: \(error.localizedDescription)"
        }
    }
}

// MARK: - Data Transfer Objects (DTOs)

/// The root structure of a content pack JSON file.
/// DTOs are like shipping containers - they hold the JSON data in a structured way
/// while it's being transported from the file into the app's database.
struct ContentPackDTO: Decodable {
    let pack: PackMetadataDTO
    let ingredients: [IngredientDTO]
    let routines: [RoutineDTO]
    let movements: [MovementDTO]
    let lessons: [LessonDTO]
    let programs: [ProgramDTO]
    let terrain_profiles: [TerrainProfileDTO]
}

struct PackMetadataDTO: Decodable {
    let version: String
    let default_locale: String
    let supported_locales: [String]
    let updated_at: String
    let review: ReviewStatusDTO
}

struct ReviewStatusDTO: Decodable {
    let status: String
    let reviewed_by: [String]?
}

// MARK: - Localized String DTO

struct LocalizedStringDTO: Decodable {
    private var values: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String: String].self)
    }

    func toModel() -> LocalizedString {
        LocalizedString(values)
    }

    var enUS: String {
        values["en-US"] ?? ""
    }
}

// MARK: - Ingredient DTO

struct IngredientDTO: Decodable {
    let id: String
    let name: IngredientNameDTO
    let category: String
    let tags: [String]
    let goals: [String]
    let seasons: [String]
    let regions: [String]
    let why_it_helps: WhyItHelpsDTO
    let how_to_use: HowToUseDTO
    let cautions: CautionsDTO
    let cultural_context: CulturalContextDTO
    let review: ReviewStatusDTO

    func toModel() -> Ingredient {
        Ingredient(
            id: id,
            name: name.toModel(),
            category: category,
            tags: tags,
            goals: goals,
            seasons: seasons,
            regions: regions,
            whyItHelps: why_it_helps.toModel(),
            howToUse: how_to_use.toModel(),
            cautions: cautions.toModel(),
            culturalContext: cultural_context.toModel()
        )
    }
}

struct IngredientNameDTO: Decodable {
    let common: LocalizedStringDTO
    let pinyin: String?
    let hanzi: String?
    let other_names: [LocalizedStringDTO]?

    func toModel() -> IngredientName {
        IngredientName(
            common: common.toModel(),
            pinyin: pinyin,
            hanzi: hanzi,
            otherNames: other_names?.map { $0.toModel() }
        )
    }
}

struct WhyItHelpsDTO: Decodable {
    let plain: LocalizedStringDTO
    let tcm: LocalizedStringDTO

    func toModel() -> WhyItHelps {
        WhyItHelps(plain: plain.toModel(), tcm: tcm.toModel())
    }
}

struct HowToUseDTO: Decodable {
    let quick_uses: [QuickUseDTO]
    let typical_amount: LocalizedStringDTO

    func toModel() -> HowToUse {
        HowToUse(
            quickUses: quick_uses.map { $0.toModel() },
            typicalAmount: typical_amount.toModel()
        )
    }
}

struct QuickUseDTO: Decodable {
    let text: LocalizedStringDTO
    let prep_time_min: Int
    let method_tags: [String]

    func toModel() -> QuickUse {
        QuickUse(
            text: text.toModel(),
            prepTimeMin: prep_time_min,
            methodTags: method_tags
        )
    }
}

struct CautionsDTO: Decodable {
    let flags: [String]
    let text: LocalizedStringDTO

    func toModel() -> Cautions {
        Cautions(
            flags: flags.compactMap { SafetyFlag(rawValue: $0) },
            text: text.toModel()
        )
    }
}

struct CulturalContextDTO: Decodable {
    let blurb: LocalizedStringDTO
    let common_in: [String]

    func toModel() -> CulturalContext {
        CulturalContext(blurb: blurb.toModel(), commonIn: common_in)
    }
}

// MARK: - Routine DTO

struct RoutineDTO: Decodable {
    let id: String
    let type: String
    let title: LocalizedStringDTO
    let subtitle: LocalizedStringDTO?
    let duration_min: Int
    let difficulty: String
    let tags: [String]
    let goals: [String]
    let seasons: [String]
    let terrain_fit: [String]
    let ingredient_refs: [String]?
    let steps: [RoutineStepDTO]
    let why: RoutineWhyDTO
    let swaps: [RoutineSwapDTO]?
    let avoid_for_hours: Int?
    let avoid_notes: LocalizedStringDTO?
    let cautions: CautionsDTO
    let review: ReviewStatusDTO

    func toModel() -> Routine {
        Routine(
            id: id,
            type: RoutineType(rawValue: type) ?? .eatDrink,
            title: title.toModel(),
            subtitle: subtitle?.toModel(),
            durationMin: duration_min,
            difficulty: Difficulty(rawValue: difficulty) ?? .easy,
            tags: tags,
            goals: goals,
            seasons: seasons,
            terrainFit: terrain_fit,
            ingredientRefs: ingredient_refs ?? [],
            steps: steps.map { $0.toModel() },
            why: why.toModel(),
            swaps: swaps?.map { $0.toModel() } ?? [],
            avoidForHours: avoid_for_hours ?? 0,
            avoidNotes: avoid_notes?.toModel(),
            cautions: cautions.toModel()
        )
    }
}

struct RoutineStepDTO: Decodable {
    let text: LocalizedStringDTO
    let timer_seconds: Int?

    func toModel() -> RoutineStep {
        RoutineStep(text: text.toModel(), timerSeconds: timer_seconds)
    }
}

struct RoutineWhyDTO: Decodable {
    let one_line: LocalizedStringDTO
    let expanded: ExpandedWhyDTO?

    func toModel() -> RoutineWhy {
        RoutineWhy(
            oneLine: one_line.toModel(),
            expanded: expanded?.toModel()
        )
    }
}

struct ExpandedWhyDTO: Decodable {
    let plain: LocalizedStringDTO
    let tcm: LocalizedStringDTO

    func toModel() -> ExpandedWhy {
        ExpandedWhy(plain: plain.toModel(), tcm: tcm.toModel())
    }
}

struct RoutineSwapDTO: Decodable {
    let label: LocalizedStringDTO
    let type: String
    let routine_ref: String?
    let ingredient_ref: String?

    func toModel() -> RoutineSwap {
        RoutineSwap(
            label: label.toModel(),
            type: SwapType(rawValue: type) ?? .routineRef,
            routineRef: routine_ref,
            ingredientRef: ingredient_ref
        )
    }
}

// MARK: - Movement DTO

struct MovementDTO: Decodable {
    let id: String
    let title: LocalizedStringDTO
    let subtitle: LocalizedStringDTO?
    let duration_min: Int
    let intensity: String
    let tags: [String]
    let goals: [String]
    let seasons: [String]
    let terrain_fit: [String]
    let frames: [MovementFrameDTO]
    let why: RoutineWhyDTO
    let cautions: CautionsDTO
    let review: ReviewStatusDTO

    func toModel() -> Movement {
        Movement(
            id: id,
            title: title.toModel(),
            subtitle: subtitle?.toModel(),
            durationMin: duration_min,
            intensity: Intensity(rawValue: intensity) ?? .gentle,
            tags: tags,
            goals: goals,
            seasons: seasons,
            terrainFit: terrain_fit,
            frames: frames.map { $0.toModel() },
            why: RoutineWhy(
                oneLine: why.one_line.toModel(),
                expanded: why.expanded?.toModel()
            ),
            cautions: cautions.toModel()
        )
    }
}

struct MovementFrameDTO: Decodable {
    let asset: MediaAssetDTO
    let cue: LocalizedStringDTO
    let seconds: Int

    func toModel() -> MovementFrame {
        MovementFrame(
            asset: asset.toModel(),
            cue: cue.toModel(),
            seconds: seconds
        )
    }
}

struct MediaAssetDTO: Decodable {
    let type: String
    let uri: String

    func toModel() -> MediaAsset {
        MediaAsset(
            type: MediaType(rawValue: type) ?? .svg,
            uri: uri
        )
    }
}

// MARK: - Lesson DTO

struct LessonDTO: Decodable {
    let id: String
    let title: LocalizedStringDTO
    let topic: String
    let body: [LessonBlockDTO]
    let takeaway: TakeawayDTO
    let cta: LessonCTADTO?
    let review: ReviewStatusDTO

    func toModel() -> Lesson {
        Lesson(
            id: id,
            title: title.toModel(),
            topic: topic,
            body: body.map { $0.toModel() },
            takeaway: takeaway.toModel(),
            cta: cta?.toModel()
        )
    }
}

struct LessonBlockDTO: Decodable {
    let type: String
    let text: LocalizedStringDTO?
    let bullets: [LocalizedStringDTO]?
    let asset: MediaAssetDTO?

    func toModel() -> LessonBlock {
        LessonBlock(
            type: LessonBlockType(rawValue: type) ?? .paragraph,
            text: text?.toModel(),
            bullets: bullets?.map { $0.toModel() },
            asset: asset?.toModel()
        )
    }
}

struct TakeawayDTO: Decodable {
    let one_line: LocalizedStringDTO

    func toModel() -> Takeaway {
        Takeaway(oneLine: one_line.toModel())
    }
}

struct LessonCTADTO: Decodable {
    let label: LocalizedStringDTO
    let action: String

    func toModel() -> LessonCTA {
        LessonCTA(label: label.toModel(), action: action)
    }
}

// MARK: - Program DTO

struct ProgramDTO: Decodable {
    let id: String
    let title: LocalizedStringDTO
    let subtitle: LocalizedStringDTO?
    let duration_days: Int
    let tags: [String]
    let goals: [String]
    let terrain_fit: [String]
    let days: [ProgramDayDTO]
    let review: ReviewStatusDTO

    func toModel() -> Program {
        Program(
            id: id,
            title: title.toModel(),
            subtitle: subtitle?.toModel(),
            durationDays: duration_days,
            tags: tags,
            goals: goals,
            terrainFit: terrain_fit,
            days: days.map { $0.toModel() }
        )
    }
}

struct ProgramDayDTO: Decodable {
    let day: Int
    let routine_refs: [String]
    let movement_refs: [String]?
    let lesson_ref: String?

    func toModel() -> ProgramDay {
        ProgramDay(
            day: day,
            routineRefs: routine_refs,
            movementRefs: movement_refs ?? [],
            lessonRef: lesson_ref
        )
    }
}

// MARK: - Terrain Profile DTO

struct TerrainProfileDTO: Decodable {
    let id: String
    let label: TerrainLabelDTO
    let nickname: LocalizedStringDTO
    let modifier: TerrainModifierDTO
    let principles: TerrainPrinciplesDTO
    let superpower: LocalizedStringDTO
    let trap: LocalizedStringDTO
    let signature_ritual: LocalizedStringDTO
    let truths: [LocalizedStringDTO]
    let recommended_tags: [String]
    let avoid_tags: [String]
    let starter_ingredients: [String]
    let starter_movements: [String]
    let starter_routines: [String]

    func toModel() -> TerrainProfile {
        TerrainProfile(
            id: id,
            label: label.toModel(),
            nickname: nickname.toModel(),
            modifier: modifier.toModel(),
            principles: principles.toModel(),
            superpower: superpower.toModel(),
            trap: trap.toModel(),
            signatureRitual: signature_ritual.toModel(),
            truths: truths.map { $0.toModel() },
            recommendedTags: recommended_tags,
            avoidTags: avoid_tags,
            starterIngredients: starter_ingredients,
            starterMovements: starter_movements,
            starterRoutines: starter_routines
        )
    }
}

struct TerrainLabelDTO: Decodable {
    let primary: LocalizedStringDTO

    func toModel() -> TerrainLabel {
        TerrainLabel(primary: primary.toModel())
    }
}

struct TerrainModifierDTO: Decodable {
    let key: String
    let display: LocalizedStringDTO

    func toModel() -> TerrainModifier {
        TerrainModifier(key: key, display: display.toModel())
    }
}

struct TerrainPrinciplesDTO: Decodable {
    let yin_yang: String
    let cold_heat: String
    let def_excess: String
    let interior_exterior: String

    func toModel() -> TerrainPrinciples {
        TerrainPrinciples(
            yinYang: yin_yang,
            coldHeat: cold_heat,
            defExcess: def_excess,
            interiorExterior: interior_exterior
        )
    }
}
