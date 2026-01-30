//
//  TerrainScoringEngine.swift
//  Terrain
//
//  Engine for calculating terrain type from quiz responses
//

import Foundation

/// Engine that calculates terrain type from quiz responses
/// Uses 5 axes: cold_heat, def_excess, damp_dry, qi_stagnation, shen_unsettled
final class TerrainScoringEngine {
    // MARK: - Thresholds

    /// Thresholds for determining primary type from axes
    struct Thresholds {
        static let coldHeatCold: Int = -3      // cold_heat <= -3 means Cold
        static let coldHeatWarm: Int = 3       // cold_heat >= 3 means Warm
        static let defExcessDeficient: Int = -3 // def_excess <= -3 means Deficient
        static let defExcessExcess: Int = 3    // def_excess >= 3 means Excess
        static let dampDryDamp: Int = -3       // damp_dry <= -3 means Damp modifier
        static let dampDryDry: Int = 3         // damp_dry >= 3 means Dry modifier
        static let qiStagnationHigh: Int = 4   // qi_stagnation >= 4 triggers Stagnation
        static let shenUnsettledHigh: Int = 4  // shen_unsettled >= 4 triggers Shen
    }

    // MARK: - Primary Types (8 combinations of cold/heat x def/excess)

    enum PrimaryType: String, CaseIterable {
        case coldDeficient = "cold_deficient_low_flame"
        case coldBalanced = "cold_balanced_cool_core"
        case neutralDeficient = "neutral_deficient_low_battery"
        case neutralBalanced = "neutral_balanced_steady_core"
        case neutralExcess = "neutral_excess_busy_mind"
        case warmBalanced = "warm_balanced_high_flame"
        case warmExcess = "warm_excess_overclocked"
        case warmDeficient = "warm_deficient_bright_but_thin"

        var label: String {
            switch self {
            case .coldDeficient: return "Cold + Deficient"
            case .coldBalanced: return "Cold + Balanced"
            case .neutralDeficient: return "Neutral + Deficient"
            case .neutralBalanced: return "Neutral + Balanced"
            case .neutralExcess: return "Neutral + Excess"
            case .warmBalanced: return "Warm + Balanced"
            case .warmExcess: return "Warm + Excess"
            case .warmDeficient: return "Warm + Deficient"
            }
        }

        var nickname: String {
            switch self {
            case .coldDeficient: return "Low Flame"
            case .coldBalanced: return "Cool Core"
            case .neutralDeficient: return "Low Battery"
            case .neutralBalanced: return "Steady Core"
            case .neutralExcess: return "Busy Mind"
            case .warmBalanced: return "High Flame"
            case .warmExcess: return "Overclocked"
            case .warmDeficient: return "Bright but Thin"
            }
        }

        var terrainProfileId: String { rawValue }
    }

    // MARK: - Scoring Modifier

    /// Modifier result from scoring algorithm (separate from the profile storage type)
    enum Modifier: String, CaseIterable {
        case shen
        case stagnation
        case damp
        case dry
        case none

        var displayName: String {
            switch self {
            case .shen: return "Shen (Restless)"
            case .stagnation: return "Stagnation (Stuck)"
            case .damp: return "Damp (Heavy)"
            case .dry: return "Dry (Thirsty)"
            case .none: return ""
            }
        }
    }

    // MARK: - Scoring Result

    struct ScoringResult {
        let vector: TerrainVector
        let primaryType: PrimaryType
        let modifier: Modifier
        let flags: Set<QuizFlag>

        var terrainProfileId: String {
            primaryType.terrainProfileId
        }
    }

    // MARK: - Quiz Flags

    enum QuizFlag: String {
        case reflux
        case looseStool = "loose_stool"
        case constipation
        case stickyStool = "sticky_stool"
        case nightSweats = "night_sweats"
        case wakeThirstyHot = "wake_thirsty_hot"
    }

    // MARK: - Public API

    /// Calculate terrain from quiz responses
    /// - Parameter responses: Array of (questionId, optionId) tuples
    /// - Returns: Scoring result with terrain type
    func calculateTerrain(from responses: [(questionId: String, optionId: String)]) -> ScoringResult {
        var vector = TerrainVector.zero
        var flags = Set<QuizFlag>()

        // Apply deltas from each response
        for response in responses {
            if let question = QuizQuestions.all.first(where: { $0.id == response.questionId }),
               let option = question.options.first(where: { $0.id == response.optionId }) {

                // Apply weight if present
                let delta = question.weight != 1.0
                    ? option.delta.weighted(by: question.weight)
                    : option.delta

                vector.add(delta)

                // Collect flags
                for flag in option.flags {
                    flags.insert(flag)
                }
            }
        }

        // Determine primary type
        let primaryType = determinePrimaryType(from: vector)

        // Determine modifier
        let modifier = determineModifier(from: vector)

        return ScoringResult(
            vector: vector,
            primaryType: primaryType,
            modifier: modifier,
            flags: flags
        )
    }

    /// Calculate terrain directly from a vector (for testing)
    func calculateTerrain(from vector: TerrainVector) -> ScoringResult {
        let primaryType = determinePrimaryType(from: vector)
        let modifier = determineModifier(from: vector)

        return ScoringResult(
            vector: vector,
            primaryType: primaryType,
            modifier: modifier,
            flags: []
        )
    }

    // MARK: - Private Helpers

    private func determinePrimaryType(from vector: TerrainVector) -> PrimaryType {
        let coldHeat = determineColdHeat(vector.coldHeat)
        let defExcess = determineDefExcess(vector.defExcess)

        switch (coldHeat, defExcess) {
        case (.cold, .deficient): return .coldDeficient
        case (.cold, .balanced): return .coldBalanced
        case (.cold, .excess): return .coldBalanced // Cold + Excess is rare, map to Cold + Balanced

        case (.neutral, .deficient): return .neutralDeficient
        case (.neutral, .balanced): return .neutralBalanced
        case (.neutral, .excess): return .neutralExcess

        case (.warm, .deficient): return .warmDeficient
        case (.warm, .balanced): return .warmBalanced
        case (.warm, .excess): return .warmExcess
        }
    }

    private enum ColdHeatResult { case cold, neutral, warm }
    private enum DefExcessResult { case deficient, balanced, excess }

    private func determineColdHeat(_ value: Int) -> ColdHeatResult {
        if value <= Thresholds.coldHeatCold { return .cold }
        if value >= Thresholds.coldHeatWarm { return .warm }
        return .neutral
    }

    private func determineDefExcess(_ value: Int) -> DefExcessResult {
        if value <= Thresholds.defExcessDeficient { return .deficient }
        if value >= Thresholds.defExcessExcess { return .excess }
        return .balanced
    }

    /// Determine modifier using priority: shen > qi_stagnation > damp/dry
    /// Only one modifier is selected based on highest magnitude above threshold
    private func determineModifier(from vector: TerrainVector) -> Modifier {
        // Collect candidates with their magnitudes
        var candidates: [(modifier: Modifier, magnitude: Int)] = []

        // Check shen (highest priority)
        if vector.shenUnsettled >= Thresholds.shenUnsettledHigh {
            candidates.append((.shen, vector.shenUnsettled))
        }

        // Check qi stagnation
        if vector.qiStagnation >= Thresholds.qiStagnationHigh {
            candidates.append((.stagnation, vector.qiStagnation))
        }

        // Check damp/dry
        if vector.dampDry <= Thresholds.dampDryDamp {
            candidates.append((.damp, abs(vector.dampDry)))
        } else if vector.dampDry >= Thresholds.dampDryDry {
            candidates.append((.dry, vector.dampDry))
        }

        // Return none if no candidates
        guard !candidates.isEmpty else { return .none }

        // Sort by magnitude descending, then by priority (shen > stagnation > damp/dry)
        candidates.sort { lhs, rhs in
            if lhs.magnitude != rhs.magnitude {
                return lhs.magnitude > rhs.magnitude
            }
            // Same magnitude: use priority order
            return modifierPriority(lhs.modifier) < modifierPriority(rhs.modifier)
        }

        return candidates.first?.modifier ?? .none
    }

    private func modifierPriority(_ modifier: Modifier) -> Int {
        switch modifier {
        case .shen: return 0
        case .stagnation: return 1
        case .damp, .dry: return 2
        case .none: return 999
        }
    }
}

// MARK: - Quiz Questions Definition

/// All quiz questions with their scoring deltas
enum QuizQuestions {
    struct Question {
        let id: String
        let title: String
        let type: QuestionType
        let options: [Option]
        let weight: Double
        let goalRequirement: Goal?

        init(id: String, title: String, type: QuestionType = .singleSelect, options: [Option], weight: Double = 1.0, goalRequirement: Goal? = nil) {
            self.id = id
            self.title = title
            self.type = type
            self.options = options
            self.weight = weight
            self.goalRequirement = goalRequirement
        }
    }

    enum QuestionType {
        case singleSelect
    }

    struct Option {
        let id: String
        let label: String
        let delta: TerrainDelta
        let flags: [TerrainScoringEngine.QuizFlag]

        init(id: String, label: String, delta: TerrainDelta = TerrainDelta(), flags: [TerrainScoringEngine.QuizFlag] = []) {
            self.id = id
            self.label = label
            self.delta = delta
            self.flags = flags
        }
    }

    // MARK: - All Questions (13 base + 1 conditional)

    static let all: [Question] = [
        // Q1: Temperature
        Question(
            id: "q1_run_temp",
            title: "Do you generally run cold or run hot?",
            options: [
                Option(id: "always_cold", label: "Always cold", delta: TerrainDelta(coldHeat: -4)),
                Option(id: "often_cold", label: "Often cold", delta: TerrainDelta(coldHeat: -2)),
                Option(id: "neutral", label: "Neutral", delta: TerrainDelta()),
                Option(id: "often_hot", label: "Often hot", delta: TerrainDelta(coldHeat: 2)),
                Option(id: "always_hot", label: "Always hot", delta: TerrainDelta(coldHeat: 4))
            ]
        ),

        // Q2: Drinks
        Question(
            id: "q2_drinks_feel_best",
            title: "What drinks feel best most of the time?",
            options: [
                Option(id: "hot_tea", label: "Hot tea", delta: TerrainDelta(coldHeat: -2)),
                Option(id: "warm_water", label: "Warm water", delta: TerrainDelta(coldHeat: -1)),
                Option(id: "room_temp", label: "Room temp", delta: TerrainDelta()),
                Option(id: "iced", label: "Iced", delta: TerrainDelta(coldHeat: 1)),
                Option(id: "anything_cold", label: "Anything cold", delta: TerrainDelta(coldHeat: 2))
            ]
        ),

        // Q3: Sweating pattern (broadened from night-only for better thermal signal)
        Question(
            id: "q3_sweat_night",
            title: "Sweating tends to be...",
            options: [
                Option(id: "rarely_sweat", label: "Rarely—I almost never sweat", delta: TerrainDelta(coldHeat: -2, defExcess: -1)),
                Option(id: "easily_sweat", label: "Easily—even light activity gets me sweating", delta: TerrainDelta(coldHeat: 1, defExcess: -1)),
                Option(id: "night_sweats", label: "Night sweats—I wake up damp", delta: TerrainDelta(coldHeat: 2, defExcess: -1, dampDry: 1), flags: [.nightSweats]),
                Option(id: "wake_hot_thirsty", label: "I wake up hot and thirsty", delta: TerrainDelta(coldHeat: 3, defExcess: -1, dampDry: 2), flags: [.nightSweats, .wakeThirstyHot]),
                Option(id: "not_sure", label: "Not sure—it varies too much to say", delta: TerrainDelta())
            ]
        ),

        // Q4: Energy pattern
        Question(
            id: "q4_energy_pattern",
            title: "Your energy pattern is...",
            options: [
                Option(id: "low_all_day", label: "Low all day", delta: TerrainDelta(defExcess: -4)),
                Option(id: "am_better_crash", label: "AM better then crash", delta: TerrainDelta(defExcess: -2)),
                Option(id: "pm_better", label: "PM better", delta: TerrainDelta(defExcess: -1, shenUnsettled: 1)),
                Option(id: "wired_but_tired", label: "Wired but tired", delta: TerrainDelta(defExcess: 2, qiStagnation: 1, shenUnsettled: 2)),
                Option(id: "steady", label: "Steady", delta: TerrainDelta())
            ]
        ),

        // Q5: After-meal response (Spleen/Stomach signal, replaces energy low point)
        Question(
            id: "q5_after_meals",
            title: "After meals you usually feel...",
            options: [
                Option(id: "light_normal", label: "Light and normal—food sits well", delta: TerrainDelta()),
                Option(id: "sleepy_heavy", label: "Sleepy and heavy—I need to lie down", delta: TerrainDelta(defExcess: -2, dampDry: -2)),
                Option(id: "bloated_gassy", label: "Bloated or gassy—digestion feels sluggish", delta: TerrainDelta(dampDry: -2, qiStagnation: 2)),
                Option(id: "acid_reflux", label: "Acid or reflux—stomach feels hot", delta: TerrainDelta(coldHeat: 2, defExcess: 1, dampDry: -1), flags: [.reflux]),
                Option(id: "hungry_again", label: "Hungry again quickly—food burns right through", delta: TerrainDelta(coldHeat: 2, defExcess: 1))
            ]
        ),

        // Q6: Environmental sensitivity (clarified from "most likely")
        Question(
            id: "q6_environmental",
            title: "Which environmental factor tends to affect your comfort the most?",
            options: [
                Option(id: "cold_weather", label: "Cold weather—I feel it in my bones", delta: TerrainDelta(coldHeat: -2)),
                Option(id: "hot_weather", label: "Hot weather—I overheat easily", delta: TerrainDelta(coldHeat: 2)),
                Option(id: "humid_conditions", label: "Humid conditions—I feel heavy and sluggish", delta: TerrainDelta(dampDry: -2)),
                Option(id: "dry_air", label: "Dry air—my skin and throat get parched", delta: TerrainDelta(dampDry: 2)),
                Option(id: "not_sure", label: "I'm not sure—I adapt to most conditions", delta: TerrainDelta())
            ]
        ),

        // Q7: Stress response (moved from old Q5)
        Question(
            id: "q7_stress_response",
            title: "When you're stressed, what does your body do first?",
            options: [
                Option(id: "shuts_down", label: "Shuts down—I feel fatigued", delta: TerrainDelta(defExcess: -2)),
                Option(id: "tightens_up", label: "Tightens up—neck, jaw, or shoulders", delta: TerrainDelta(defExcess: 1, qiStagnation: 3)),
                Option(id: "runs_hot", label: "Runs hot—I get irritable or flushed", delta: TerrainDelta(coldHeat: 2, defExcess: 1, qiStagnation: 2)),
                Option(id: "gets_bloated", label: "Gets bloated—digestion suffers", delta: TerrainDelta(dampDry: -2, qiStagnation: 2)),
                Option(id: "gets_anxious", label: "Gets anxious—mind races", delta: TerrainDelta(defExcess: 1, qiStagnation: 1, shenUnsettled: 3))
            ]
        ),

        // Q8: Stools (renumbered)
        Question(
            id: "q8_stools_usually",
            title: "Your stools are usually...",
            options: [
                Option(id: "loose_soft", label: "Loose/soft", delta: TerrainDelta(coldHeat: -1, defExcess: -1, dampDry: -2), flags: [.looseStool]),
                Option(id: "normal", label: "Normal", delta: TerrainDelta()),
                Option(id: "constipated_dry", label: "Constipated/dry", delta: TerrainDelta(coldHeat: 1, dampDry: 3), flags: [.constipation]),
                Option(id: "alternating", label: "Alternating", delta: TerrainDelta(dampDry: -1, qiStagnation: 2)),
                Option(id: "sticky_hard_to_wipe", label: "Sticky, hard to wipe", delta: TerrainDelta(dampDry: -3), flags: [.stickyStool])
            ]
        ),

        // Q9: Cravings (weighted 0.6, renumbered)
        Question(
            id: "q9_cravings",
            title: "Cravings you relate to most:",
            options: [
                Option(id: "sweet", label: "Sweet", delta: TerrainDelta(dampDry: -1)),
                Option(id: "salty", label: "Salty", delta: TerrainDelta(dampDry: -1)),
                Option(id: "spicy", label: "Spicy", delta: TerrainDelta(coldHeat: 1)),
                Option(id: "greasy_fried", label: "Greasy/fried", delta: TerrainDelta(dampDry: -2)),
                Option(id: "cold_foods", label: "Cold foods (ice cream, smoothies)", delta: TerrainDelta(coldHeat: 1)),
                Option(id: "not_sure", label: "I'm not sure—no strong cravings", delta: TerrainDelta())
            ],
            weight: 0.6
        ),

        // Q10: Body tends to be (with clearer frequency context)
        Question(
            id: "q10_body_tends",
            title: "How often do you notice these body tendencies?",
            options: [
                Option(id: "puffy_often", label: "Often puffy or heavy (weekly or more)", delta: TerrainDelta(dampDry: -4)),
                Option(id: "dry_often", label: "Often dry—skin, lips, or eyes (weekly or more)", delta: TerrainDelta(dampDry: 4)),
                Option(id: "mucusy_sometimes", label: "Sometimes mucusy (a few times a month)", delta: TerrainDelta(dampDry: -3)),
                Option(id: "swollen_sometimes", label: "Sometimes swollen legs or face (a few times a month)", delta: TerrainDelta(dampDry: -3)),
                Option(id: "normal", label: "Rarely notice any of these", delta: TerrainDelta())
            ]
        ),

        // Q11: Thirst pattern (refined to separate heat vs yin deficiency)
        Question(
            id: "q11_thirst_mouth",
            title: "Thirst feels like...",
            options: [
                Option(id: "rarely_thirsty", label: "Rarely thirsty—I forget to drink", delta: TerrainDelta(coldHeat: -1, dampDry: -2)),
                Option(id: "small_sips", label: "Prefer small, frequent sips", delta: TerrainDelta(dampDry: -1)),
                Option(id: "very_thirsty_cold", label: "Very thirsty—I prefer cold drinks", delta: TerrainDelta(coldHeat: 2, dampDry: 3)),
                Option(id: "dry_mouth_night", label: "Dry mouth, especially at night", delta: TerrainDelta(coldHeat: 1, dampDry: 3, shenUnsettled: 1)),
                Option(id: "sip_often_habit", label: "I sip often, more from habit than thirst", delta: TerrainDelta())
            ]
        ),

        // Q12: Mood/flow
        Question(
            id: "q12_mood_flow",
            title: "Which mood pattern do you relate to most?",
            options: [
                Option(id: "easygoing", label: "Easygoing—generally calm", delta: TerrainDelta()),
                Option(id: "overthinking", label: "Overthinking—mind won't quiet", delta: TerrainDelta(qiStagnation: 1, shenUnsettled: 2)),
                Option(id: "irritable_snappy", label: "Irritable—snappy or easily frustrated", delta: TerrainDelta(coldHeat: 1, qiStagnation: 3)),
                Option(id: "sad_low", label: "Sad or low—energy and mood drop together", delta: TerrainDelta(defExcess: -1, shenUnsettled: 1)),
                Option(id: "restless", label: "Restless—hard to sit still", delta: TerrainDelta(defExcess: 1, shenUnsettled: 3))
            ]
        ),

        // Q13: Sleep (renumbered to fit 13 questions)
        Question(
            id: "q13_sleep",
            title: "How is your sleep usually?",
            options: [
                Option(id: "sleep_good", label: "Fall asleep easily, stay asleep", delta: TerrainDelta()),
                Option(id: "trouble_falling", label: "Trouble falling asleep—mind races", delta: TerrainDelta(defExcess: 1, qiStagnation: 1, shenUnsettled: 3)),
                Option(id: "wake_at_night", label: "Wake up during the night", delta: TerrainDelta(dampDry: 1, shenUnsettled: 2)),
                Option(id: "vivid_dreams", label: "Vivid or restless dreams", delta: TerrainDelta(qiStagnation: 1, shenUnsettled: 2)),
                Option(id: "wake_tired", label: "Wake up tired, even after enough hours", delta: TerrainDelta(defExcess: -2, shenUnsettled: 1))
            ]
        ),

        // Q14: Menstrual pattern (shown only when menstrualComfort goal selected)
        Question(
            id: "q14_menstrual",
            title: "Your menstrual cycle tends to...",
            options: [
                Option(id: "clots_dark", label: "Clots or dark blood", delta: TerrainDelta(coldHeat: -1, qiStagnation: 3)),
                Option(id: "pale_light", label: "Pale or light flow", delta: TerrainDelta(defExcess: -3)),
                Option(id: "cramps_warmth", label: "Cramping relieved by warmth", delta: TerrainDelta(coldHeat: -2, qiStagnation: 1)),
                Option(id: "irritable_breast", label: "Irritable with breast tenderness", delta: TerrainDelta(qiStagnation: 3, shenUnsettled: 1)),
                Option(id: "not_applicable", label: "Not applicable", delta: TerrainDelta())
            ],
            goalRequirement: .menstrualComfort
        )
    ]

    /// Returns questions filtered by the user's selected goals.
    /// Questions with a `goalRequirement` are only included when that goal is selected.
    static func questions(for goals: Set<Goal>) -> [Question] {
        all.filter { question in
            guard let requirement = question.goalRequirement else { return true }
            return goals.contains(requirement)
        }
    }
}
