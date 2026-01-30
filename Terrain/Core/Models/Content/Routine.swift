//
//  Routine.swift
//  Terrain
//
//  SwiftData model for Eat/Drink routines
//

import Foundation
import SwiftData

/// Represents an Eat/Drink routine - a guided food/drink preparation activity.
/// Think of this as a recipe card with TCM wisdom attached.
@Model
final class Routine {
    @Attribute(.unique) var id: String

    var type: RoutineType
    var tier: String?  // "full", "medium", or "lite"
    var title: LocalizedString
    var subtitle: LocalizedString?

    var durationMin: Int
    var difficulty: Difficulty

    var tags: [String]
    var goals: [String]
    var seasons: [String]

    var terrainFit: [String]
    var ingredientRefs: [String]

    var steps: [RoutineStep]

    // Why
    var why: RoutineWhy

    // Swaps
    var swaps: [RoutineSwap]

    // Avoid guidance
    var avoidForHours: Int
    var avoidNotes: LocalizedString?

    // Safety
    var cautions: Cautions

    // Review
    var reviewStatus: String

    init(
        id: String,
        type: RoutineType = .eatDrink,
        tier: String? = nil,
        title: LocalizedString,
        subtitle: LocalizedString? = nil,
        durationMin: Int,
        difficulty: Difficulty = .easy,
        tags: [String] = [],
        goals: [String] = [],
        seasons: [String] = ["all_year"],
        terrainFit: [String] = [],
        ingredientRefs: [String] = [],
        steps: [RoutineStep] = [],
        why: RoutineWhy,
        swaps: [RoutineSwap] = [],
        avoidForHours: Int = 0,
        avoidNotes: LocalizedString? = nil,
        cautions: Cautions = Cautions(),
        reviewStatus: String = "draft"
    ) {
        self.id = id
        self.type = type
        self.tier = tier
        self.title = title
        self.subtitle = subtitle
        self.durationMin = durationMin
        self.difficulty = difficulty
        self.tags = tags
        self.goals = goals
        self.seasons = seasons
        self.terrainFit = terrainFit
        self.ingredientRefs = ingredientRefs
        self.steps = steps
        self.why = why
        self.swaps = swaps
        self.avoidForHours = avoidForHours
        self.avoidNotes = avoidNotes
        self.cautions = cautions
        self.reviewStatus = reviewStatus
    }

    /// Display name for the routine
    var displayName: String {
        title.localized
    }

    /// Total duration including all steps with timers
    var totalStepsDuration: Int {
        steps.compactMap { $0.timerSeconds }.reduce(0, +)
    }
}

// MARK: - Supporting Types

enum RoutineType: String, Codable {
    case eatDrink = "eat_drink"
}

/// A single step in a routine
struct RoutineStep: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var text: LocalizedString
    var timerSeconds: Int?

    init(text: LocalizedString, timerSeconds: Int? = nil) {
        self.text = text
        self.timerSeconds = timerSeconds
    }
}

/// Why section for routines
struct RoutineWhy: Codable, Hashable {
    var oneLine: LocalizedString
    var expanded: ExpandedWhy?

    init(oneLine: LocalizedString, expanded: ExpandedWhy? = nil) {
        self.oneLine = oneLine
        self.expanded = expanded
    }
}

/// Expanded why with plain and TCM explanations
struct ExpandedWhy: Codable, Hashable {
    var plain: LocalizedString
    var tcm: LocalizedString

    init(plain: LocalizedString, tcm: LocalizedString) {
        self.plain = plain
        self.tcm = tcm
    }
}

/// Swap option for alternative routines or ingredients
struct RoutineSwap: Codable, Hashable {
    var label: LocalizedString
    var type: SwapType
    var routineRef: String?
    var ingredientRef: String?

    init(label: LocalizedString, type: SwapType, routineRef: String? = nil, ingredientRef: String? = nil) {
        self.label = label
        self.type = type
        self.routineRef = routineRef
        self.ingredientRef = ingredientRef
    }
}

enum SwapType: String, Codable {
    case routineRef = "routine_ref"
    case ingredientSwapNote = "ingredient_swap_note"
}

/// Routine difficulty levels
enum Difficulty: String, Codable, CaseIterable {
    case easy
    case medium

    var displayName: String {
        rawValue.capitalized
    }
}

/// Routine effort levels (for daily routine selection)
enum RoutineLevel: String, Codable, CaseIterable {
    case full
    case medium
    case lite

    var displayName: String {
        switch self {
        case .full: return "Full"
        case .medium: return "Medium"
        case .lite: return "Lite"
        }
    }

    var durationDescription: String {
        switch self {
        case .full: return "10-15 min"
        case .medium: return "5 min"
        case .lite: return "90 sec"
        }
    }
}
