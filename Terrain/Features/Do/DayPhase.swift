//
//  DayPhase.swift
//  Terrain
//
//  View-layer enum for morning/evening practice phases.
//  At 5PM (TCM Kidney hour), the body shifts from yang to yin energy.
//  This drives which routines and movements the Do tab surfaces.
//
//  No SwiftData dependency — purely a scoring/display helper.
//

import Foundation

/// Morning (5AM–4:59PM) or Evening (5PM–4:59AM) practice phase.
///
/// TCM background: The body's yang energy peaks in the morning and wanes
/// after 5PM (Kidney hour / 酉时). Evening practices should calm rather
/// than activate, mirroring the natural yin-yang cycle.
enum DayPhase: String, CaseIterable {
    case morning
    case evening

    // MARK: - Phase Detection

    /// Derives the current phase from a reference date (typically `timerTick`).
    /// Uses wall-clock hour: morning = 5..16, evening = 17..4.
    static func current(for date: Date = Date()) -> DayPhase {
        let hour = Calendar.current.component(.hour, from: date)
        return (5..<17).contains(hour) ? .morning : .evening
    }

    // MARK: - Display

    var displayTitle: String {
        switch self {
        case .morning: return "Morning Practice"
        case .evening: return "Evening Practice"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "sun.horizon.fill"
        case .evening: return "moon.fill"
        }
    }

    // MARK: - Tag Affinity

    /// Tags that positively correlate with this phase.
    /// Morning favors activating/warming; evening favors calming/cooling.
    var affinityTags: Set<String> {
        switch self {
        case .morning:
            return ["warming", "supports_deficiency", "moves_qi", "supports_digestion"]
        case .evening:
            return ["calms_shen", "cooling"]
        }
    }

    /// The opposite phase's affinity tags — used for anti-affinity scoring.
    private var antiAffinityTags: Set<String> {
        switch self {
        case .morning: return DayPhase.evening.affinityTags
        case .evening: return DayPhase.morning.affinityTags
        }
    }

    /// Counts how many of the given tags align with this phase.
    /// Higher = better fit for this time of day.
    func affinityScore(for tags: [String]) -> Int {
        let tagSet = Set(tags)
        return tagSet.intersection(affinityTags).count
    }

    /// Counts how many of the given tags conflict with this phase
    /// (i.e., belong to the opposite phase).
    func antiAffinityScore(for tags: [String]) -> Int {
        let tagSet = Set(tags)
        return tagSet.intersection(antiAffinityTags).count
    }

    /// Net phase score: +2 per affinity tag, -3 per anti-affinity tag.
    /// Negative weight is heavier because showing a warming routine in the
    /// evening is worse than missing a calming one in the morning.
    func netPhaseScore(for tags: [String]) -> Int {
        let positive = affinityScore(for: tags) * 2
        let negative = antiAffinityScore(for: tags) * 3
        return positive - negative
    }

    // MARK: - Intensity Preference

    /// Evening shifts the preferred movement intensity one level calmer.
    /// Morning uses the level's natural intensity mapping.
    func preferredIntensity(for level: RoutineLevel) -> String {
        switch self {
        case .morning:
            switch level {
            case .full: return "moderate"
            case .medium: return "gentle"
            case .lite: return "restorative"
            }
        case .evening:
            // Shift one level calmer
            switch level {
            case .full: return "gentle"
            case .medium, .lite: return "restorative"
            }
        }
    }
}
