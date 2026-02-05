//
//  YouViewModels.swift
//  Terrain
//
//  Model structs for the You tab's section views.
//

import Foundation

// MARK: - Constitution Card

/// A practitioner-style 5-axis readout of the user's terrain
struct ConstitutionReadout {
    struct Axis {
        let label: String      // "Temperature"
        let value: String      // "Warm (Heat-leaning)"
        let tooltip: String    // Plain-language explanation
    }
    let axes: [Axis]           // Always 5
}

// MARK: - Signal Explanations ("How We Got This")

/// One of the top quiz signals explaining the terrain determination
struct SignalExplanation {
    let summary: String        // "You sweat easily and prefer cold drinks → Heat tendency"
    let axisLabel: String      // "Temperature"
}

// MARK: - Defaults

/// Stable baseline do/don't guidance for a terrain type
struct DefaultsContent {
    let bestDefaults: [String]
    let avoidDefaults: [String]
}

// MARK: - Watch-Fors

/// An identity-level pattern the user should watch for when off-balance
struct WatchForItem {
    let text: String
    let icon: String           // SF Symbol name
}

// MARK: - Trends

/// Direction of a 14-day trend
enum TrendDirection: String {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }
}

/// Result from trend analysis for one category
struct TrendResult {
    let category: String       // "Sleep", "Digestion", "Stress", "Energy"
    let direction: TrendDirection
    let icon: String           // SF Symbol for the category
    let dailyRates: [Double]   // 14 values (0.0-1.0), one per day in the window
}

// MARK: - Terrain-Aware Trends (Phase 13)

/// An annotated trend result with terrain-specific prioritization and interpretation
struct AnnotatedTrendResult: Identifiable {
    let id = UUID()
    let base: TrendResult
    let priority: Int           // 1 = highest priority for this terrain type
    let terrainNote: String     // "For your terrain, this means..."
    let isWatchFor: Bool        // True if this is a "watch for" category for this terrain

    var category: String { base.category }
    var direction: TrendDirection { base.direction }
    var icon: String { base.icon }
    var dailyRates: [Double] { base.dailyRates }
}

/// A healthy zone range for a trend category, specific to terrain type
struct TerrainHealthyZone {
    let category: String
    let range: ClosedRange<Double>  // 0.0-1.0 scale
    let label: String               // "Your healthy range"
    let terrainContext: String      // Why this range differs for this terrain
}

/// Activity minutes breakdown by type
struct ActivityMinutesResult {
    let routineMinutes: [Double]    // Daily routine (food/drink) minutes, one per day
    let movementMinutes: [Double]   // Daily movement minutes, one per day
    let totalRoutineMinutes: Double
    let totalMovementMinutes: Double
    let windowDays: Int
}

/// Personalized terrain pulse insight for the hero card
struct TerrainPulseInsight {
    let headline: String            // Editorial-style headline
    let body: String                // Terrain-specific interpretation
    let accentCategory: String?     // Which trend category this references (optional)
    let isUrgent: Bool              // True for declining trends needing attention
}
