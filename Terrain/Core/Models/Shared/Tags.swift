//
//  Tags.swift
//  Terrain
//
//  Enums for content tagging and categorization
//  Note: Content models use String arrays for flexibility, but these enums
//  provide type safety for UI code and help with display formatting.
//

import Foundation

/// Goals users can focus on
enum Goal: String, Codable, CaseIterable, Identifiable {
    case sleep
    case digestion
    case energy
    case stress
    case skin
    case menstrualComfort = "menstrual_comfort"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .digestion: return "Digestion"
        case .energy: return "Energy"
        case .stress: return "Stress"
        case .skin: return "Skin"
        case .menstrualComfort: return "Menstrual Comfort"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .digestion: return "leaf.fill"
        case .energy: return "bolt.fill"
        case .stress: return "heart.fill"
        case .skin: return "sparkles"
        case .menstrualComfort: return "waveform.path"
        }
    }

    /// Create from a string (for JSON parsing)
    static func from(_ string: String) -> Goal? {
        Goal(rawValue: string)
    }
}

/// Axis tags for personalization and filtering
enum AxisTag: String, Codable, CaseIterable, Identifiable {
    case warming
    case cooling
    case supportsDeficiency = "supports_deficiency"
    case reducesExcess = "reduces_excess"
    case movesQi = "moves_qi"
    case calmsShen = "calms_shen"
    case driesDamp = "dries_damp"
    case moistensDryness = "moistens_dryness"
    case supportsDigestion = "supports_digestion"
    case gentleForAcute = "gentle_for_acute"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .warming: return "Warming"
        case .cooling: return "Cooling"
        case .supportsDeficiency: return "Supports Deficiency"
        case .reducesExcess: return "Reduces Excess"
        case .movesQi: return "Moves Qi"
        case .calmsShen: return "Calms Shen"
        case .driesDamp: return "Dries Damp"
        case .moistensDryness: return "Moistens Dryness"
        case .supportsDigestion: return "Supports Digestion"
        case .gentleForAcute: return "Gentle for Acute"
        }
    }

    /// Create from a string (for JSON parsing)
    static func from(_ string: String) -> AxisTag? {
        AxisTag(rawValue: string)
    }
}

/// Season tags for seasonal content
enum SeasonTag: String, Codable, CaseIterable, Identifiable {
    case spring
    case summer
    case lateSummer = "late_summer"
    case autumn
    case winter
    case allYear = "all_year"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .lateSummer: return "Late Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        case .allYear: return "All Year"
        }
    }

    /// Create from a string (for JSON parsing)
    static func from(_ string: String) -> SeasonTag? {
        SeasonTag(rawValue: string)
    }
}

/// Regional provenance tags
enum RegionTag: String, Codable, CaseIterable, Identifiable {
    case cantoneseHomeSoups = "cantonese_home_soups"
    case northernWinterWarmth = "northern_winter_warmth"
    case fujianMinStyle = "fujian_min_style"
    case sichuanFlavorNotes = "sichuan_flavor_notes"
    case jiangnanGentle = "jiangnan_gentle"
    case taiwaneseHomeStyle = "taiwanese_home_style"
    case panChineseCommon = "pan_chinese_common"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cantoneseHomeSoups: return "Cantonese Home Soups"
        case .northernWinterWarmth: return "Northern Winter Warmth"
        case .fujianMinStyle: return "Fujian Min Style"
        case .sichuanFlavorNotes: return "Sichuan Flavor Notes"
        case .jiangnanGentle: return "Jiangnan Gentle"
        case .taiwaneseHomeStyle: return "Taiwanese Home Style"
        case .panChineseCommon: return "Pan-Chinese Common"
        }
    }

    /// Create from a string (for JSON parsing)
    static func from(_ string: String) -> RegionTag? {
        RegionTag(rawValue: string)
    }
}

/// Ingredient categories
enum IngredientCategory: String, Codable, CaseIterable, Identifiable {
    case spice
    case root
    case fruit
    case grain
    case legume
    case fungus
    case tea
    case protein
    case aromatic
    case other

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    /// Create from a string (for JSON parsing)
    static func from(_ string: String) -> IngredientCategory? {
        IngredientCategory(rawValue: string)
    }
}

/// Preparation method tags
enum MethodTag: String, Codable, CaseIterable {
    case simmer
    case steep
    case stirIn = "stir_in"
    case top
    case broth
    case congee
    case oatmeal
    case saute
    case bake

    var displayName: String {
        switch self {
        case .simmer: return "Simmer"
        case .steep: return "Steep"
        case .stirIn: return "Stir In"
        case .top: return "Top"
        case .broth: return "Broth"
        case .congee: return "Congee"
        case .oatmeal: return "Oatmeal"
        case .saute: return "Saut\u{00E9}"
        case .bake: return "Bake"
        }
    }
}

// MARK: - Helper Extensions

extension String {
    /// Get the display name for a goal string
    var goalDisplayName: String {
        Goal.from(self)?.displayName ?? self.capitalized
    }

    /// Get the display name for a tag string
    var tagDisplayName: String {
        AxisTag.from(self)?.displayName ?? self.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Get the display name for a season string
    var seasonDisplayName: String {
        SeasonTag.from(self)?.displayName ?? self.capitalized
    }
}
