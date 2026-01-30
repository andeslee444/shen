//
//  HomeInsightModels.swift
//  Terrain
//
//  Models for the Home tab insight system
//

import Foundation

// MARK: - Quick Symptom

/// Quick symptoms for inline check-in on Home tab
/// These are simpler than the full Symptom enum - just quick buttons for common issues
enum QuickSymptom: String, CaseIterable, Codable, Identifiable {
    case cold
    case bloating
    case cramps
    case stressed
    case tired
    case headache
    case poorSleep = "poor_sleep"
    case stiff

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cold: return "Cold"
        case .bloating: return "Bloating"
        case .cramps: return "Cramps"
        case .stressed: return "Stressed"
        case .tired: return "Tired"
        case .headache: return "Headache"
        case .poorSleep: return "Poor Sleep"
        case .stiff: return "Stiff"
        }
    }

    var icon: String {
        switch self {
        case .cold: return "thermometer.snowflake"
        case .bloating: return "stomach"
        case .cramps: return "waveform.path"
        case .stressed: return "brain.head.profile"
        case .tired: return "battery.25"
        case .headache: return "head.profile"
        case .poorSleep: return "moon.zzz"
        case .stiff: return "figure.walk"
        }
    }
}

// MARK: - Daily Tone

/// The daily tone/energy for contextual messaging
/// Combines user's terrain with environmental factors
struct DailyTone: Codable, Hashable {
    let label: String
    let environmentalNote: String?

    init(label: String, environmentalNote: String? = nil) {
        self.label = label
        self.environmentalNote = environmentalNote
    }

    /// Creates a daily tone from terrain type and optional weather
    static func forTerrain(
        _ terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier? = nil,
        weatherCondition: String? = nil
    ) -> DailyTone {
        // Base label from terrain
        let baseLabel: String
        switch terrainType {
        case .coldDeficient:
            baseLabel = "Low Flame Day"
        case .coldBalanced:
            baseLabel = "Cool Core Day"
        case .neutralDeficient:
            baseLabel = "Steady Build Day"
        case .neutralBalanced:
            baseLabel = "Balance Day"
        case .neutralExcess:
            baseLabel = "Release Day"
        case .warmBalanced:
            baseLabel = "High Flame Day"
        case .warmExcess:
            baseLabel = "Cool Down Day"
        case .warmDeficient:
            baseLabel = "Nourish Day"
        }

        // Environmental note from weather
        let envNote: String?
        if let weather = weatherCondition?.lowercased() {
            switch weather {
            case let w where w.contains("dry") || w.contains("clear"):
                envNote = "Dry air"
            case let w where w.contains("humid") || w.contains("rain"):
                envNote = "Humid"
            case let w where w.contains("cold") || w.contains("snow"):
                envNote = "Cold out"
            case let w where w.contains("hot") || w.contains("heat"):
                envNote = "Hot out"
            case let w where w.contains("wind"):
                envNote = "Windy"
            default:
                envNote = nil
            }
        } else {
            envNote = nil
        }

        return DailyTone(label: baseLabel, environmentalNote: envNote)
    }
}

// MARK: - Headline Content

/// Content for the main headline on Home tab
struct HeadlineContent: Codable, Hashable {
    let text: String
    let isSymptomAdjusted: Bool

    init(text: String, isSymptomAdjusted: Bool = false) {
        self.text = text
        self.isSymptomAdjusted = isSymptomAdjusted
    }
}

// MARK: - Do/Don't Item

/// A single do or don't recommendation
struct DoDontItem: Codable, Hashable, Identifiable {
    var id: String { text }
    let text: String
    let priority: Int  // Lower = higher priority
    let whyForYou: String?  // Terrain-specific explanation

    init(text: String, priority: Int = 1, whyForYou: String? = nil) {
        self.text = text
        self.priority = priority
        self.whyForYou = whyForYou
    }
}

// MARK: - Seasonal Note Content

/// Content for the seasonal awareness card on Home tab
struct SeasonalNoteContent: Codable, Hashable {
    let season: String
    let icon: String
    let note: String
    let tips: [String]

    init(season: String, icon: String, note: String, tips: [String]) {
        self.season = season
        self.icon = icon
        self.note = note
        self.tips = tips
    }
}

// MARK: - Area of Life

/// Areas of life with expandable content
enum AreaOfLifeType: String, CaseIterable, Codable, Identifiable {
    case energyFocus = "energy_focus"
    case digestion
    case sleepWindDown = "sleep_wind_down"
    case moodStress = "mood_stress"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .energyFocus: return "Energy & Focus"
        case .digestion: return "Digestion"
        case .sleepWindDown: return "Sleep & Wind-down"
        case .moodStress: return "Mood & Stress"
        }
    }

    var icon: String {
        switch self {
        case .energyFocus: return "bolt.fill"
        case .digestion: return "stomach"
        case .sleepWindDown: return "moon.fill"
        case .moodStress: return "heart.fill"
        }
    }
}

/// Content for an area of life
struct AreaOfLifeContent: Codable, Hashable, Identifiable {
    var id: AreaOfLifeType { type }
    let type: AreaOfLifeType
    let tips: [String]
    let tcmNote: String?

    init(type: AreaOfLifeType, tips: [String], tcmNote: String? = nil) {
        self.type = type
        self.tips = tips
        self.tcmNote = tcmNote
    }
}

// MARK: - Theme Today

/// The concluding theme/message for the day
struct ThemeTodayContent: Codable, Hashable {
    let title: String
    let body: String

    init(title: String = "Your theme today", body: String) {
        self.title = title
        self.body = body
    }
}

// MARK: - Type Block

/// Components for displaying the user's terrain type as chips
struct TypeBlockComponents: Codable, Hashable {
    let temperature: TemperatureChip
    let reserve: ReserveChip
    let modifier: ModifierChip?

    enum TemperatureChip: String, Codable {
        case cold = "Cold"
        case neutral = "Neutral"
        case warm = "Warm"
    }

    enum ReserveChip: String, Codable {
        case low = "Low"
        case balanced = "Balanced"
        case high = "High"
    }

    enum ModifierChip: String, Codable {
        case damp = "Damp"
        case dry = "Dry"
        case stagnation = "Stagnation"
        case shen = "Shen"
    }

    init(temperature: TemperatureChip, reserve: ReserveChip, modifier: ModifierChip? = nil) {
        self.temperature = temperature
        self.reserve = reserve
        self.modifier = modifier
    }

    /// Creates type block components from terrain type and modifier
    static func from(
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> TypeBlockComponents {
        // Determine temperature chip
        let temperature: TemperatureChip
        switch terrainType {
        case .coldDeficient, .coldBalanced:
            temperature = .cold
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            temperature = .neutral
        case .warmBalanced, .warmExcess, .warmDeficient:
            temperature = .warm
        }

        // Determine reserve chip
        let reserve: ReserveChip
        switch terrainType {
        case .coldDeficient, .neutralDeficient, .warmDeficient:
            reserve = .low
        case .coldBalanced, .neutralBalanced, .warmBalanced:
            reserve = .balanced
        case .neutralExcess, .warmExcess:
            reserve = .high
        }

        // Determine modifier chip
        let modifierChip: ModifierChip?
        switch modifier {
        case .damp: modifierChip = .damp
        case .dry: modifierChip = .dry
        case .stagnation: modifierChip = .stagnation
        case .shen: modifierChip = .shen
        case .none: modifierChip = nil
        }

        return TypeBlockComponents(
            temperature: temperature,
            reserve: reserve,
            modifier: modifierChip
        )
    }
}
