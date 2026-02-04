//
//  Movement.swift
//  Terrain
//
//  SwiftData model for Movement flows
//

import Foundation
import SwiftData

/// Represents a Movement flow (illustrated exercise sequence).
/// Think of this as a flip-book of gentle exercises with verbal cues.
@Model
final class Movement {
    @Attribute(.unique) var id: String

    var title: LocalizedString
    var subtitle: LocalizedString?
    var tier: String?

    var durationMin: Int
    var intensity: Intensity

    var tags: [String]
    var goals: [String]
    var seasons: [String]

    var terrainFit: [String]

    var frames: [MovementFrame]

    // Why
    var why: RoutineWhy

    // Safety
    var cautions: Cautions

    // Review
    var reviewStatus: String

    init(
        id: String,
        title: LocalizedString,
        subtitle: LocalizedString? = nil,
        tier: String? = nil,
        durationMin: Int,
        intensity: Intensity = .gentle,
        tags: [String] = [],
        goals: [String] = [],
        seasons: [String] = ["all_year"],
        terrainFit: [String] = [],
        frames: [MovementFrame] = [],
        why: RoutineWhy,
        cautions: Cautions = Cautions(),
        reviewStatus: String = "draft"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.tier = tier
        self.durationMin = durationMin
        self.intensity = intensity
        self.tags = tags
        self.goals = goals
        self.seasons = seasons
        self.terrainFit = terrainFit
        self.frames = frames
        self.why = why
        self.cautions = cautions
        self.reviewStatus = reviewStatus
    }

    /// Display name for the movement
    var displayName: String {
        title.localized
    }

    /// Total duration in seconds based on frames
    var totalDurationSeconds: Int {
        frames.reduce(0) { $0 + $1.seconds }
    }

    /// Seconds-based display for sub-2-min movements, minutes otherwise
    var durationDisplay: String {
        let totalSeconds = totalDurationSeconds
        if totalSeconds > 0 && totalSeconds < 120 {
            return "\(totalSeconds) sec"
        }
        return "\(durationMin) min"
    }
}

// MARK: - Supporting Types

/// A single frame in a movement sequence
struct MovementFrame: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var asset: MediaAsset
    var cue: LocalizedString
    var seconds: Int

    init(asset: MediaAsset, cue: LocalizedString, seconds: Int = 10) {
        self.asset = asset
        self.cue = cue
        self.seconds = seconds
    }
}

/// Movement intensity levels
enum Intensity: String, Codable, CaseIterable {
    case restorative
    case gentle
    case moderate

    var displayName: String {
        rawValue.capitalized
    }
}
