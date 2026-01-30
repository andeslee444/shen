//
//  CommunityStats.swift
//  Terrain
//
//  Static community prevalence data for terrain types.
//  Used for normalization messaging ("X% of Terrain users share your type").
//

import Foundation

/// Provides static community distribution percentages for each terrain type.
/// These represent a plausible distribution across the user base.
enum CommunityStats {
    /// Returns the percentage of users who share the given terrain profile ID.
    /// Falls back to a generic percentage if the ID is unrecognized.
    static func prevalence(for terrainProfileId: String) -> Int {
        switch terrainProfileId {
        case "neutral_balanced_steady_core":
            return 22
        case "cold_deficient_low_flame":
            return 16
        case "warm_excess_overclocked":
            return 14
        case "neutral_excess_busy_mind":
            return 13
        case "warm_balanced_high_flame":
            return 11
        case "cold_balanced_cool_core":
            return 10
        case "neutral_deficient_low_battery":
            return 8
        case "warm_deficient_bright_but_thin":
            return 6
        default:
            return 12
        }
    }

    /// Returns a human-readable normalization string.
    /// Example: "16% of Terrain users share your type"
    static func normalizationText(for terrainProfileId: String) -> String {
        let pct = prevalence(for: terrainProfileId)
        return "\(pct)% of Terrain users share your type"
    }
}
