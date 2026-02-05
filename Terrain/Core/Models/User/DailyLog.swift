//
//  DailyLog.swift
//  Terrain
//
//  SwiftData model for daily check-in logs
//

import Foundation
import SwiftData

/// Daily check-in log with symptoms, energy, and completions
@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID

    var date: Date

    // Current patterns check-in (detailed)
    var symptoms: [Symptom]
    var symptomOnset: SymptomOnset?
    var energyLevel: EnergyLevel?

    // Quick symptoms from Home tab inline check-in
    var quickSymptoms: [QuickSymptom]

    // Completions
    var completedRoutineIds: [String]
    var completedMovementIds: [String]
    var routineLevel: RoutineLevel?

    // Weather (cached from API)
    var weatherCondition: String?
    var temperatureCelsius: Double?

    // Health data (cached from HealthKit)
    var stepCount: Int?

    // Mood rating (1-10 scale, nil = not set)
    var moodRating: Int?

    // Post-routine feedback
    var routineFeedback: [RoutineFeedbackEntry]

    // Quick fix avoid timers (keyed by QuickNeed.rawValue → completion timestamp)
    var quickFixCompletionTimes: [String: Date]

    // Notification micro-action completion (set by "Did This" background action)
    var microActionCompletedAt: Date?

    // TCM diagnostic signals (Phase 13)
    var sleepQuality: SleepQuality?
    var dominantEmotion: DominantEmotion?
    var thermalFeeling: ThermalFeeling?
    var digestiveState: DigestiveState?

    // MARK: - HealthKit Cached Data (Phase 14)
    var sleepDurationMinutes: Double?
    var sleepInBedMinutes: Double?
    var restingHeartRate: Int?

    // MARK: - Phase 14 TCM Personalization
    var cyclePhase: CyclePhase?
    var symptomQuality: SymptomQuality?

    // Notes
    var notes: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptoms: [Symptom] = [],
        symptomOnset: SymptomOnset? = nil,
        energyLevel: EnergyLevel? = nil,
        quickSymptoms: [QuickSymptom] = [],
        completedRoutineIds: [String] = [],
        completedMovementIds: [String] = [],
        routineLevel: RoutineLevel? = nil,
        routineFeedback: [RoutineFeedbackEntry] = [],
        quickFixCompletionTimes: [String: Date] = [:],
        moodRating: Int? = nil,
        weatherCondition: String? = nil,
        temperatureCelsius: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.symptoms = symptoms
        self.symptomOnset = symptomOnset
        self.energyLevel = energyLevel
        self.quickSymptoms = quickSymptoms
        self.completedRoutineIds = completedRoutineIds
        self.completedMovementIds = completedMovementIds
        self.routineLevel = routineLevel
        self.routineFeedback = routineFeedback
        self.quickFixCompletionTimes = quickFixCompletionTimes
        self.moodRating = moodRating
        self.weatherCondition = weatherCondition
        self.temperatureCelsius = temperatureCelsius
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Calendar date component for grouping
    var calendarDate: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }

    /// Whether the daily routine was completed
    var hasCompletedRoutine: Bool {
        !completedRoutineIds.isEmpty || !completedMovementIds.isEmpty
    }

    func markRoutineComplete(_ routineId: String, level: RoutineLevel) {
        if !completedRoutineIds.contains(routineId) {
            completedRoutineIds.append(routineId)
        }
        routineLevel = level
        updatedAt = Date()
    }

    /// Mark a routine complete with duration tracking for analytics
    func markRoutineComplete(
        _ routineId: String,
        level: RoutineLevel,
        startedAt: Date?,
        feedback: PostRoutineFeedback = .better
    ) {
        if !completedRoutineIds.contains(routineId) {
            completedRoutineIds.append(routineId)
        }
        routineLevel = level

        // Calculate duration and create feedback entry for analytics
        let now = Date()
        let durationSeconds: Int? = startedAt.map { Int(now.timeIntervalSince($0)) }

        let entry = RoutineFeedbackEntry(
            routineOrMovementId: routineId,
            feedback: feedback,
            timestamp: now,
            startedAt: startedAt,
            actualDurationSeconds: durationSeconds,
            activityType: .routine
        )
        routineFeedback.append(entry)

        updatedAt = now
    }

    func markMovementComplete(_ movementId: String) {
        if !completedMovementIds.contains(movementId) {
            completedMovementIds.append(movementId)
        }
        updatedAt = Date()
    }

    /// Mark a movement complete with duration tracking for analytics
    func markMovementComplete(
        _ movementId: String,
        startedAt: Date?,
        feedback: PostRoutineFeedback = .better
    ) {
        if !completedMovementIds.contains(movementId) {
            completedMovementIds.append(movementId)
        }

        // Calculate duration and create feedback entry for analytics
        let now = Date()
        let durationSeconds: Int? = startedAt.map { Int(now.timeIntervalSince($0)) }

        let entry = RoutineFeedbackEntry(
            routineOrMovementId: movementId,
            feedback: feedback,
            timestamp: now,
            startedAt: startedAt,
            actualDurationSeconds: durationSeconds,
            activityType: .movement
        )
        routineFeedback.append(entry)

        updatedAt = now
    }
}

/// Symptoms for daily check-in
enum Symptom: String, Codable, CaseIterable, Identifiable {
    case cough
    case soreThroat = "sore_throat"
    case congestion
    case aches
    case headache

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cough: return "Cough"
        case .soreThroat: return "Sore Throat"
        case .congestion: return "Congestion"
        case .aches: return "Aches"
        case .headache: return "Headache"
        }
    }

    var icon: String {
        switch self {
        case .cough: return "lungs.fill"
        case .soreThroat: return "flame"
        case .congestion: return "nose"
        case .aches: return "figure.walk"
        case .headache: return "brain.head.profile"
        }
    }
}

/// Symptom onset timeframe
enum SymptomOnset: String, Codable, CaseIterable {
    case today
    case oneToThreeDays = "1-3_days"
    case fourPlusDays = "4+_days"

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .oneToThreeDays: return "1-3 days"
        case .fourPlusDays: return "4+ days"
        }
    }
}

/// Energy level for daily check-in
enum EnergyLevel: String, Codable, CaseIterable {
    case low
    case normal
    case wired

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .normal: return "battery.75"
        case .wired: return "bolt.fill"
        }
    }
}

// MARK: - Post-Routine Feedback

/// How the user felt after completing a routine or movement
enum PostRoutineFeedback: String, Codable, CaseIterable {
    case better
    case same
    case notSure = "not_sure"

    var displayName: String {
        switch self {
        case .better: return "Better"
        case .same: return "Same"
        case .notSure: return "Not sure"
        }
    }

    var icon: String {
        switch self {
        case .better: return "arrow.up.circle.fill"
        case .same: return "equal.circle.fill"
        case .notSure: return "questionmark.circle.fill"
        }
    }
}

/// A single feedback entry for a completed routine or movement
struct RoutineFeedbackEntry: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var routineOrMovementId: String
    var feedback: PostRoutineFeedback
    var timestamp: Date

    // Duration tracking for analytics
    /// When the user started the routine/movement (opened the detail sheet)
    var startedAt: Date?
    /// Actual time spent in seconds (calculated at completion)
    var actualDurationSeconds: Int?
    /// Whether this was a routine (food/drink) or movement
    var activityType: ActivityType?

    init(
        routineOrMovementId: String,
        feedback: PostRoutineFeedback,
        timestamp: Date = Date(),
        startedAt: Date? = nil,
        actualDurationSeconds: Int? = nil,
        activityType: ActivityType? = nil
    ) {
        self.routineOrMovementId = routineOrMovementId
        self.feedback = feedback
        self.timestamp = timestamp
        self.startedAt = startedAt
        self.actualDurationSeconds = actualDurationSeconds
        self.activityType = activityType
    }
}

/// Type of activity for analytics categorization
enum ActivityType: String, Codable {
    case routine  // Food/drink routines
    case movement // Physical movements
}

// MARK: - TCM Diagnostic Signals (Phase 13)

/// Sleep quality patterns — TCM maps sleep disturbances to organ imbalances.
/// Difficulty falling asleep → Shen disturbance; waking 1-3 AM → Liver qi stagnation;
/// early waking → Yin deficiency; unrefreshing sleep → Damp accumulation.
enum SleepQuality: String, Codable, CaseIterable, Identifiable {
    case fellAsleepEasily = "fell_asleep_easily"
    case hardToFallAsleep = "hard_to_fall_asleep"
    case wokeMiddleOfNight = "woke_middle_of_night"
    case wokeEarly = "woke_early"
    case unrefreshing

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fellAsleepEasily: return "Fell asleep easily"
        case .hardToFallAsleep: return "Hard to fall asleep"
        case .wokeMiddleOfNight: return "Woke in the night"
        case .wokeEarly: return "Woke too early"
        case .unrefreshing: return "Slept but unrefreshed"
        }
    }

    var icon: String {
        switch self {
        case .fellAsleepEasily: return "moon.zzz.fill"
        case .hardToFallAsleep: return "moon"
        case .wokeMiddleOfNight: return "moon.stars"
        case .wokeEarly: return "sunrise"
        case .unrefreshing: return "cloud.moon"
        }
    }

    /// TCM organ/pattern association for content generation
    var tcmPattern: String {
        switch self {
        case .fellAsleepEasily: return "balanced_shen"
        case .hardToFallAsleep: return "shen_disturbance"
        case .wokeMiddleOfNight: return "liver_qi_stagnation"
        case .wokeEarly: return "yin_deficiency"
        case .unrefreshing: return "damp_accumulation"
        }
    }
}

/// Dominant emotional state — TCM maps emotions to organ systems.
/// Anger/irritability → Liver; worry → Spleen; fear/anxiety → Kidney;
/// grief → Lung; restlessness → Heart/Shen.
enum DominantEmotion: String, Codable, CaseIterable, Identifiable {
    case calm
    case irritable
    case worried
    case anxious
    case sad
    case restless
    case overwhelmed

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .irritable: return "flame"
        case .worried: return "thought.bubble"
        case .anxious: return "waveform.path.ecg"
        case .sad: return "cloud.rain"
        case .restless: return "wind"
        case .overwhelmed: return "tornado"
        }
    }

    /// TCM organ association for content generation
    var tcmOrgan: String {
        switch self {
        case .calm: return "balanced"
        case .irritable: return "liver"
        case .worried: return "spleen"
        case .anxious: return "kidney"
        case .sad: return "lung"
        case .restless: return "heart"
        case .overwhelmed: return "spleen_kidney"
        }
    }
}

/// Current thermal sensation — detects terrain drift between quiz retakes.
/// Consistently feeling warm when terrain is "cold" suggests the pattern may be shifting.
enum ThermalFeeling: String, Codable, CaseIterable, Identifiable {
    case cold
    case cool
    case comfortable
    case warm
    case hot

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .cold: return "snowflake"
        case .cool: return "thermometer.snowflake"
        case .comfortable: return "thermometer.medium"
        case .warm: return "thermometer.sun"
        case .hot: return "flame.fill"
        }
    }

    /// Numeric value for trend calculation (-2 cold to +2 hot)
    var thermalValue: Int {
        switch self {
        case .cold: return -2
        case .cool: return -1
        case .comfortable: return 0
        case .warm: return 1
        case .hot: return 2
        }
    }
}

/// Digestive state — tracks what the quiz captures once as a daily signal.
/// Stool quality is a primary TCM diagnostic indicator.
struct DigestiveState: Codable, Hashable {
    var appetiteLevel: AppetiteLevel
    var stoolQuality: StoolQuality

    init(appetiteLevel: AppetiteLevel = .normal, stoolQuality: StoolQuality = .normal) {
        self.appetiteLevel = appetiteLevel
        self.stoolQuality = stoolQuality
    }
}

enum AppetiteLevel: String, Codable, CaseIterable, Identifiable {
    case none
    case low
    case normal
    case strong

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "No appetite"
        case .low: return "Low appetite"
        case .normal: return "Normal appetite"
        case .strong: return "Strong appetite"
        }
    }

    var icon: String {
        switch self {
        case .none: return "xmark.circle"
        case .low: return "circle.bottomhalf.filled"
        case .normal: return "circle.fill"
        case .strong: return "plus.circle.fill"
        }
    }
}

enum StoolQuality: String, Codable, CaseIterable, Identifiable {
    case normal
    case loose
    case constipated
    case sticky
    case mixed

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .loose: return "Loose"
        case .constipated: return "Constipated"
        case .sticky: return "Sticky"
        case .mixed: return "Mixed/variable"
        }
    }

    /// TCM pattern association
    var tcmPattern: String {
        switch self {
        case .normal: return "balanced"
        case .loose: return "spleen_qi_deficiency"
        case .constipated: return "heat_or_yin_deficiency"
        case .sticky: return "damp_accumulation"
        case .mixed: return "liver_spleen_disharmony"
        }
    }
}

// MARK: - Cycle Phase (Phase 14)

/// Menstrual cycle phase — TCM maps each phase to a dominant quality,
/// guiding what foods, movements, and rest patterns to recommend.
enum CyclePhase: String, Codable, CaseIterable, Identifiable {
    case menstrual
    case follicular
    case ovulatory
    case luteal
    case notApplicable = "not_applicable"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulatory: return "Ovulatory"
        case .luteal: return "Luteal"
        case .notApplicable: return "Not Applicable"
        }
    }

    /// TCM rationale for this phase
    var tcmContext: String {
        switch self {
        case .menstrual: return "Gentle descent — blood moving downward, rest and warmth"
        case .follicular: return "Building blood — nourish yin, light activity, blood-building foods"
        case .ovulatory: return "Moving qi — peak energy, outward expression, cooling if warm type"
        case .luteal: return "Warming kidney yang — grounding, warming foods, slower pace"
        case .notApplicable: return ""
        }
    }
}

// MARK: - Symptom Quality (Phase 14)

/// Pain quality descriptor — TCM distinguishes pain types because each maps
/// to a specific pattern imbalance, informing different treatment strategies.
enum SymptomQuality: String, Codable, CaseIterable, Identifiable {
    case dull        // deficiency pattern
    case sharp       // blood stagnation
    case heavy       // damp pattern
    case burning     // heat pattern
    case migrating   // wind / qi stagnation

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dull: return "Dull"
        case .sharp: return "Sharp"
        case .heavy: return "Heavy"
        case .burning: return "Burning"
        case .migrating: return "Migrating"
        }
    }

    /// TCM pattern this quality indicates
    var tcmPattern: String {
        switch self {
        case .dull: return "Deficiency"
        case .sharp: return "Blood stagnation"
        case .heavy: return "Dampness"
        case .burning: return "Heat"
        case .migrating: return "Wind or qi stagnation"
        }
    }
}
