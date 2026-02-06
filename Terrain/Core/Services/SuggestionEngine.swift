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
    /// Scoring uses proportional credit (more matching tags = more points) plus
    /// red-flag penalties. Think of each criterion as a hiring-committee rubric
    /// where partial overlap counts and red flags disqualify.
    ///
    /// | Criterion              | Points | Logic                                                   |
    /// |------------------------|--------|---------------------------------------------------------|
    /// | Tag match to need      | +1/tag, cap 4 | `intersection(need.relevantTags).count`          |
    /// | Terrain fit (explicit) | +5     | `terrainFit` contains profileId (routines only)          |
    /// | Terrain fit (fallback) | +1/tag, cap 3 | `intersection(terrainTags).count`                |
    /// | Modifier boost         | +2     | Any overlap (binary — modifier is 1 tag)                 |
    /// | Symptom alignment      | +1/tag, cap 4 | `intersection(symptomTags).count`                |
    /// | Time-of-day fit        | +2     | Any overlap (binary)                                     |
    /// | Seasonal fit           | +3     | Candidate `seasons` contains current TCM season          |
    /// | Goal alignment         | +2     | Candidate `goals` intersects user's goals                |
    /// | Need-goal match        | +3     | Candidate `goals` intersects need's `relevantGoals`      |
    /// | Cabinet bonus          | +2     | Ingredient ID in user's cabinet (ingredients only)       |
    /// | Routine effectiveness  | +3/+1  | From TrendEngine (routines only)                         |
    /// | Has avoid guidance     | +1     | avoidForHours > 0                                        |
    /// | Avoid-tag penalty      | -4     | Candidate tags intersect terrain's avoidTags             |
    /// | Contradiction penalty  | -3     | Warming+cooling tags AND symptom conflict                |
    /// | Completion suppression | -999   | Candidate ID already in today's completedRoutineIds      |
    ///
    /// All new parameters have defaults so existing call sites still compile.
    func suggest(
        for need: QuickNeed,
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        symptoms: Set<QuickSymptom>,
        timeOfDay: TimeOfDay,
        ingredients: [Ingredient],
        routines: [Routine],
        season: InsightEngine.TCMSeason = .current(),
        userGoals: [String] = [],
        avoidTags: Set<String> = [],
        completedIds: Set<String> = [],
        cabinetIngredientIds: Set<String> = [],
        routineEffectiveness: [String: Double] = [:],
        weatherCondition: String? = nil,
        alcoholFrequency: String? = nil,
        smokingStatus: String? = nil,
        stepCount: Int? = nil,
        sleepQuality: SleepQuality? = nil,
        thermalFeeling: ThermalFeeling? = nil
    ) -> QuickSuggestion {
        var bestCandidate: QuickSuggestion?

        let terrainTags = terrainRecommendedTags(for: terrainType, modifier: modifier)
        let symptomTagSet = symptomTags(for: symptoms)
        let modifierTags = modifierBoostTags(for: modifier)
        let timeTags = timeBoostTags(for: timeOfDay)
        let needTags = Set(need.relevantTags)
        let needGoals = Set(need.relevantGoals)
        let seasonKey = season.contentPackKey
        let userGoalSet = Set(userGoals)
        let symptomHasThermalConflict = hasThermalConflict(in: symptomTagSet)
        let diagnosticBoostTags = diagnosticSignalBoostTags(sleepQuality: sleepQuality, thermalFeeling: thermalFeeling)

        // Score ingredients
        for ingredient in ingredients {
            let tags = Set(ingredient.tags)
            var score = 0

            // +1 per tag, cap 4 — Tag match to need
            score += min(tags.intersection(needTags).count, 4)

            // +1 per tag, cap 3 — Terrain fit (tag-based for ingredients)
            score += min(tags.intersection(terrainTags).count, 3)

            // +2 Modifier boost
            if !tags.isDisjoint(with: modifierTags) {
                score += 2
            }

            // +1 per tag, cap 4 — Symptom alignment
            score += min(tags.intersection(symptomTagSet).count, 4)

            // +2 Time-of-day fit
            if !tags.isDisjoint(with: timeTags) {
                score += 2
            }

            // +3 Seasonal fit
            if ingredient.seasons.contains(seasonKey) || ingredient.seasons.contains("all_year") {
                score += 3
            }

            // +2 Goal alignment
            if !Set(ingredient.goals).isDisjoint(with: userGoalSet) {
                score += 2
            }

            // +3 Need-goal match (does the candidate serve what the user tapped?)
            if !Set(ingredient.goals).isDisjoint(with: needGoals) {
                score += 3
            }

            // +2 Cabinet bonus
            if cabinetIngredientIds.contains(ingredient.id) {
                score += 2
            }

            // Weather scoring
            score += weatherScore(for: tags, weatherCondition: weatherCondition, modifier: modifier)

            // Lifestyle scoring
            if (smokingStatus == "occasional" || smokingStatus == "regular") && tags.contains("moistens_dryness") {
                score += 2
            }
            if (alcoholFrequency == "weekly" || alcoholFrequency == "daily") {
                if tags.contains("dries_damp") { score += 2 }
                if tags.contains("warming") { score -= 2 }
            }

            // Step count scoring
            if let steps = stepCount {
                if steps < 2000 && tags.contains("moves_qi") { score += 2 }
                if steps > 10000 && tags.contains("supports_deficiency") { score += 2 }
            }

            // TCM diagnostic signal boost
            for (tag, boost) in diagnosticBoostTags {
                if tags.contains(tag) { score += boost }
            }

            // -4 Avoid-tag penalty
            if !tags.isDisjoint(with: avoidTags) {
                score -= 4
            }

            // -3 Contradiction penalty (warming+cooling tags AND symptom thermal conflict)
            if symptomHasThermalConflict && candidateHasThermalConflict(tags: tags) {
                score -= 3
            }

            // -999 Completion suppression
            if completedIds.contains(ingredient.id) {
                score -= 999
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

            // +1 per tag, cap 4 — Tag match to need
            score += min(tags.intersection(needTags).count, 4)

            // +5 Terrain fit (explicit) or +1 per tag, cap 3 (fallback)
            if routine.terrainFit.contains(terrainType.terrainProfileId) {
                score += 5
            } else {
                score += min(tags.intersection(terrainTags).count, 3)
            }

            // +2 Modifier boost
            if !tags.isDisjoint(with: modifierTags) {
                score += 2
            }

            // +1 per tag, cap 4 — Symptom alignment
            score += min(tags.intersection(symptomTagSet).count, 4)

            // +2 Time-of-day fit
            if !tags.isDisjoint(with: timeTags) {
                score += 2
            }

            // +3 Seasonal fit
            if routine.seasons.contains(seasonKey) || routine.seasons.contains("all_year") {
                score += 3
            }

            // +2 Goal alignment
            if !Set(routine.goals).isDisjoint(with: userGoalSet) {
                score += 2
            }

            // +3 Need-goal match (does the candidate serve what the user tapped?)
            if !Set(routine.goals).isDisjoint(with: needGoals) {
                score += 3
            }

            // +3 or +1 Routine effectiveness
            if let effectiveness = routineEffectiveness[routine.id] {
                if effectiveness >= 0.3 {
                    score += 3
                } else if effectiveness >= 0 {
                    score += 1
                }
            }

            // +1 Has avoid guidance
            if routine.avoidForHours > 0 {
                score += 1
            }

            // Weather scoring
            score += weatherScore(for: tags, weatherCondition: weatherCondition, modifier: modifier)

            // Lifestyle scoring (routines)
            if (smokingStatus == "occasional" || smokingStatus == "regular") && tags.contains("moistens_dryness") {
                score += 2
            }
            if (alcoholFrequency == "weekly" || alcoholFrequency == "daily") {
                if tags.contains("dries_damp") { score += 2 }
                if tags.contains("warming") { score -= 2 }
            }

            // Step count scoring (routines)
            if let steps = stepCount {
                if steps < 2000 && tags.contains("moves_qi") { score += 2 }
                if steps > 10000 && tags.contains("supports_deficiency") { score += 2 }
            }

            // TCM diagnostic signal boost (routines)
            for (tag, boost) in diagnosticBoostTags {
                if tags.contains(tag) { score += boost }
            }

            // -4 Avoid-tag penalty
            if !tags.isDisjoint(with: avoidTags) {
                score -= 4
            }

            // -3 Contradiction penalty
            if symptomHasThermalConflict && candidateHasThermalConflict(tags: tags) {
                score -= 3
            }

            // -999 Completion suppression
            if completedIds.contains(routine.id) {
                score -= 999
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

        // Fall back to hardcoded if nothing scored positively
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

    // MARK: - Thermal Conflict Detection

    /// Returns true if the symptom tag set contains both warming-relevant and
    /// cooling-relevant tags — meaning the user has contradictory thermal symptoms.
    private func hasThermalConflict(in symptomTagSet: Set<String>) -> Bool {
        symptomTagSet.contains("warming") && symptomTagSet.contains("cooling")
    }

    /// Returns true if a candidate has both warming and cooling tags.
    private func candidateHasThermalConflict(tags: Set<String>) -> Bool {
        tags.contains("warming") && tags.contains("cooling")
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

    // MARK: - Diagnostic Signal Boost

    /// Returns tag → boost pairs derived from daily check-in TCM signals.
    /// Sleep disturbance boosts calming tags; thermal feeling boosts warming/cooling tags.
    private func diagnosticSignalBoostTags(
        sleepQuality: SleepQuality?,
        thermalFeeling: ThermalFeeling?
    ) -> [(String, Int)] {
        var boosts: [(String, Int)] = []

        if let sleep = sleepQuality {
            switch sleep {
            case .hardToFallAsleep, .wokeMiddleOfNight, .wokeEarly, .unrefreshing:
                boosts.append(("calms_shen", 3))
                boosts.append(("calming", 3))
            case .fellAsleepEasily:
                break
            }
        }

        if let thermal = thermalFeeling {
            switch thermal {
            case .cold, .cool:
                boosts.append(("warming", 2))
                boosts.append(("tonifies_yang", 2))
            case .hot, .warm:
                boosts.append(("cooling", 2))
                boosts.append(("clears_heat", 2))
            case .comfortable:
                break
            }
        }

        return boosts
    }

    // MARK: - Weather Scoring

    /// Scores a candidate's tags against the current weather condition.
    /// Think of it as a relevance bonus — cold weather makes warming
    /// ingredients/routines more attractive, hot weather favors cooling, etc.
    ///
    /// | Weather   | Boosted tags            | Points | Extra modifier bonus |
    /// |-----------|-------------------------|--------|----------------------|
    /// | cold      | warming                 | +2     | —                    |
    /// | hot       | cooling                 | +2     | —                    |
    /// | humid     | dries_damp              | +2     | +1 if damp modifier  |
    /// | rainy     | dries_damp              | +2     | +1 if damp modifier  |
    /// | dry       | moistens_dryness        | +2     | +1 if dry modifier   |
    /// | clear     | moistens_dryness        | +2     | +1 if dry modifier   |
    /// | windy     | calms_shen, moves_qi    | +1     | —                    |
    private func weatherScore(
        for tags: Set<String>,
        weatherCondition: String?,
        modifier: TerrainScoringEngine.Modifier
    ) -> Int {
        guard let weather = weatherCondition else { return 0 }
        var score = 0

        switch weather {
        case "cold":
            if tags.contains("warming") { score += 2 }
        case "hot":
            if tags.contains("cooling") { score += 2 }
        case "humid", "rainy":
            if tags.contains("dries_damp") {
                score += 2
                if modifier == .damp { score += 1 }
            }
        case "dry", "clear":
            if tags.contains("moistens_dryness") {
                score += 2
                if modifier == .dry { score += 1 }
            }
        case "windy":
            if tags.contains("calms_shen") || tags.contains("moves_qi") { score += 1 }
        default:
            break
        }

        return score
    }
}
