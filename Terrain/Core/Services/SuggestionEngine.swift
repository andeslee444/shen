//
//  SuggestionEngine.swift
//  Terrain
//
//  Terrain/time/symptom-aware suggestion ranking for Quick Fixes.
//  Think of this as a hiring committee scoring resumes — each candidate
//  ingredient or routine gets points across multiple criteria, and
//  the highest scorer wins the recommendation slot.
//

import Foundation

// MARK: - Result Type

/// A ranked suggestion with metadata for display and avoid-timer persistence.
struct QuickSuggestion {
    let title: String
    let description: String
    let avoidHours: Int?
    let avoidNotes: String?
    let sourceId: String?
    let score: Int
}

// MARK: - Time of Day

/// Rough time bucket derived from the wall clock.
/// Morning is when warming/energy-boosting suggestions rank higher;
/// night is when calming suggestions dominate.
enum TimeOfDay {
    case morning    // 05:00–11:59
    case afternoon  // 12:00–16:59
    case evening    // 17:00–21:59
    case night      // 22:00–04:59

    static func current(for date: Date = Date()) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default:      return .night
        }
    }
}

// MARK: - Engine

/// Stateless service that scores and ranks suggestions for a given QuickNeed.
final class SuggestionEngine {

    // MARK: - Public API

    /// Find the best suggestion for a need given the user's context.
    ///
    /// Each candidate (ingredient or routine) is scored independently:
    ///
    /// | Criterion          | Points | Logic                                           |
    /// |--------------------|--------|-------------------------------------------------|
    /// | Tag match to need  | +3     | Candidate tags intersect QuickNeed.relevantTags  |
    /// | Terrain fit        | +4     | terrainFit contains profile ID or tags match      |
    /// | Modifier boost     | +2     | Tags match modifier-specific tags                 |
    /// | Symptom alignment  | +3     | Tags match symptom-mapped needs                   |
    /// | Time-of-day fit    | +2     | Tags match time-appropriate boosting              |
    /// | Has avoid guidance | +1     | Routine with avoidForHours > 0                    |
    ///
    /// Falls back to `QuickNeed.suggestion` if no candidate scores > 0.
    func suggest(
        for need: QuickNeed,
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        timeOfDay: TimeOfDay,
        ingredients: [Ingredient],
        routines: [Routine]
    ) -> QuickSuggestion {
        var bestCandidate: QuickSuggestion?

        let terrainTags = terrainRecommendedTags(for: terrainType, modifier: modifier)
        let symptomTagSet = symptomTags(for: symptoms)
        let modifierTags = modifierBoostTags(for: modifier)
        let timeTags = timeBoostTags(for: timeOfDay)

        // Score ingredients
        for ingredient in ingredients {
            let tags = Set(ingredient.tags)
            var score = 0

            // +3 Tag match to need
            if !tags.isDisjoint(with: need.relevantTags) {
                score += 3
            }

            // +4 Terrain fit (ingredient tags overlap terrain's recommended tags)
            if !tags.isDisjoint(with: terrainTags) {
                score += 4
            }

            // +2 Modifier boost
            if !tags.isDisjoint(with: modifierTags) {
                score += 2
            }

            // +3 Symptom alignment
            if !tags.isDisjoint(with: symptomTagSet) {
                score += 3
            }

            // +2 Time-of-day fit
            if !tags.isDisjoint(with: timeTags) {
                score += 2
            }

            if score > 0, score > (bestCandidate?.score ?? 0) {
                let description = ingredient.howToUse.quickUses.first?.text.localized
                    ?? ingredient.whyItHelps.plain.localized
                bestCandidate = QuickSuggestion(
                    title: ingredient.displayName,
                    description: description,
                    avoidHours: nil,
                    avoidNotes: nil,
                    sourceId: ingredient.id,
                    score: score
                )
            }
        }

        // Score routines
        for routine in routines {
            let tags = Set(routine.tags)
            var score = 0

            // +3 Tag match to need
            if !tags.isDisjoint(with: need.relevantTags) {
                score += 3
            }

            // +4 Terrain fit (routine's terrainFit contains profile ID)
            if routine.terrainFit.contains(terrainType.terrainProfileId) {
                score += 4
            } else if !tags.isDisjoint(with: terrainTags) {
                // Fallback: tag-based terrain match (weaker signal)
                score += 2
            }

            // +2 Modifier boost
            if !tags.isDisjoint(with: modifierTags) {
                score += 2
            }

            // +3 Symptom alignment
            if !tags.isDisjoint(with: symptomTagSet) {
                score += 3
            }

            // +2 Time-of-day fit
            if !tags.isDisjoint(with: timeTags) {
                score += 2
            }

            // +1 Has avoid guidance
            if routine.avoidForHours > 0 {
                score += 1
            }

            if score > 0, score > (bestCandidate?.score ?? 0) {
                let description = routine.why.oneLine.localized
                bestCandidate = QuickSuggestion(
                    title: routine.displayName,
                    description: description,
                    avoidHours: routine.avoidForHours > 0 ? routine.avoidForHours : nil,
                    avoidNotes: routine.avoidNotes?.localized,
                    sourceId: routine.id,
                    score: score
                )
            }
        }

        // Fall back to hardcoded if nothing scored
        if let best = bestCandidate {
            return best
        }

        let fallback = need.suggestion
        return QuickSuggestion(
            title: fallback.title,
            description: fallback.description,
            avoidHours: fallback.avoidHours,
            avoidNotes: nil,
            sourceId: nil,
            score: 0
        )
    }

    // MARK: - Symptom-Based Need Ordering

    /// Reorder QuickNeed cases so the most relevant ones for today's
    /// symptoms appear first. If the user is "stressed", Calm and Focus
    /// float to the top; if "cold", Warmth leads, etc.
    func orderedNeeds(for symptoms: Set<QuickSymptom>) -> [QuickNeed] {
        guard !symptoms.isEmpty else { return QuickNeed.allCases.map { $0 } }

        let scored = QuickNeed.allCases.map { need -> (need: QuickNeed, score: Int) in
            var score = 0
            let relevantTags = Set(need.relevantTags)

            for symptom in symptoms {
                let sTags = Set(singleSymptomTags(for: symptom))
                if !relevantTags.isDisjoint(with: sTags) {
                    score += 2
                }
            }

            // Direct mapping boosts
            for symptom in symptoms {
                switch (symptom, need) {
                case (.cold, .warmth):       score += 3
                case (.tired, .energy):      score += 3
                case (.stressed, .calm):     score += 3
                case (.stressed, .focus):    score += 1
                case (.bloating, .digestion): score += 3
                case (.headache, .calm):     score += 2
                case (.headache, .focus):    score += 1
                case (.poorSleep, .calm):    score += 3
                case (.stiff, .energy):      score += 2
                case (.cramps, .warmth):     score += 2
                default: break
                }
            }

            return (need, score)
        }

        return scored
            .sorted { $0.score > $1.score }
            .map { $0.need }
    }

    // MARK: - Internal Mapping Tables

    /// Tags that a given terrain type + modifier would benefit from.
    /// Think of it as the "shopping list" for someone with that body pattern.
    func terrainRecommendedTags(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> Set<String> {
        var tags: Set<String> = []

        // Primary type tags
        switch terrainType {
        case .coldDeficient:
            tags.formUnion(["warming", "supports_deficiency", "supports_digestion"])
        case .coldBalanced:
            tags.formUnion(["warming", "supports_digestion"])
        case .neutralDeficient:
            tags.formUnion(["supports_deficiency", "supports_digestion"])
        case .neutralBalanced:
            tags.formUnion(["supports_digestion", "moves_qi"])
        case .neutralExcess:
            tags.formUnion(["moves_qi", "calms_shen", "cooling"])
        case .warmBalanced:
            tags.formUnion(["cooling", "moistens_dryness"])
        case .warmExcess:
            tags.formUnion(["cooling", "calms_shen"])
        case .warmDeficient:
            tags.formUnion(["moistens_dryness", "calms_shen", "supports_deficiency"])
        }

        // Modifier overlay
        switch modifier {
        case .shen:       tags.insert("calms_shen")
        case .stagnation: tags.insert("moves_qi")
        case .damp:       tags.insert("dries_damp")
        case .dry:        tags.insert("moistens_dryness")
        case .none:       break
        }

        return tags
    }

    /// Tags that correspond to modifier-specific benefits.
    private func modifierBoostTags(for modifier: TerrainScoringEngine.Modifier) -> Set<String> {
        switch modifier {
        case .shen:       return ["calms_shen"]
        case .stagnation: return ["moves_qi"]
        case .damp:       return ["dries_damp"]
        case .dry:        return ["moistens_dryness"]
        case .none:       return []
        }
    }

    /// Tags that symptoms map to — when a user checks "stressed", content
    /// tagged "calms_shen" becomes more relevant.
    private func symptomTags(for symptoms: Set<QuickSymptom>) -> Set<String> {
        var tags: Set<String> = []
        for symptom in symptoms {
            tags.formUnion(singleSymptomTags(for: symptom))
        }
        return tags
    }

    /// Tag mapping for a single symptom.
    private func singleSymptomTags(for symptom: QuickSymptom) -> [String] {
        switch symptom {
        case .cold:      return ["warming"]
        case .bloating:  return ["supports_digestion", "moves_qi", "dries_damp"]
        case .stressed:  return ["calms_shen", "moves_qi"]
        case .tired:     return ["supports_deficiency", "warming"]
        case .poorSleep: return ["calms_shen"]
        case .headache:  return ["moves_qi", "cooling"]
        case .cramps:    return ["warming", "moves_qi"]
        case .stiff:     return ["moves_qi"]
        }
    }

    /// Tags that are particularly relevant at different times of day.
    /// Morning favors warming/energizing; evening favors calming.
    private func timeBoostTags(for time: TimeOfDay) -> Set<String> {
        switch time {
        case .morning:   return ["warming", "supports_deficiency"]
        case .afternoon: return ["moves_qi", "supports_digestion"]
        case .evening:   return ["calms_shen", "cooling"]
        case .night:     return ["calms_shen"]
        }
    }
}
