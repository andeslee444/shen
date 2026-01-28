//
//  TerrainProfile.swift
//  Terrain
//
//  SwiftData model for Terrain (body constitution) profiles
//

import Foundation
import SwiftData

/// Represents a Terrain profile (body constitution type).
/// Think of this as a personality profile card, but for your body's tendencies.
/// Each profile describes how your body operates and what it needs.
@Model
final class TerrainProfile {
    @Attribute(.unique) var id: String

    // Labels
    var label: TerrainLabel
    var nickname: LocalizedString

    // Modifier
    var modifier: TerrainModifier

    // TCM Principles
    var principles: TerrainPrinciples

    // Identity content
    var superpower: LocalizedString
    var trap: LocalizedString
    var signatureRitual: LocalizedString
    var truths: [LocalizedString]

    // Recommendations
    var recommendedTags: [String]
    var avoidTags: [String]

    // Starter content
    var starterIngredients: [String]
    var starterMovements: [String]
    var starterRoutines: [String]

    init(
        id: String,
        label: TerrainLabel,
        nickname: LocalizedString,
        modifier: TerrainModifier,
        principles: TerrainPrinciples,
        superpower: LocalizedString,
        trap: LocalizedString,
        signatureRitual: LocalizedString,
        truths: [LocalizedString],
        recommendedTags: [String] = [],
        avoidTags: [String] = [],
        starterIngredients: [String] = [],
        starterMovements: [String] = [],
        starterRoutines: [String] = []
    ) {
        self.id = id
        self.label = label
        self.nickname = nickname
        self.modifier = modifier
        self.principles = principles
        self.superpower = superpower
        self.trap = trap
        self.signatureRitual = signatureRitual
        self.truths = truths
        self.recommendedTags = recommendedTags
        self.avoidTags = avoidTags
        self.starterIngredients = starterIngredients
        self.starterMovements = starterMovements
        self.starterRoutines = starterRoutines
    }

    /// Full display label including nickname and modifier
    var fullDisplayLabel: String {
        var text = "\(label.primary.localized) (\(nickname.localized))"
        if modifier.key != "none" {
            text += " \u{2022} \(modifier.display.localized)"
        }
        return text
    }
}

// MARK: - Supporting Types

/// Terrain label with primary text
struct TerrainLabel: Codable, Hashable {
    var primary: LocalizedString

    init(primary: LocalizedString) {
        self.primary = primary
    }
}

/// Terrain modifier (optional overlay like "Damp" or "Stagnation")
struct TerrainModifier: Codable, Hashable {
    var key: String
    var display: LocalizedString

    init(key: String, display: LocalizedString = "") {
        self.key = key
        self.display = display
    }

    static let none = TerrainModifier(key: "none", display: "")
}

/// TCM principles describing the terrain
struct TerrainPrinciples: Codable, Hashable {
    var yinYang: String
    var coldHeat: String
    var defExcess: String
    var interiorExterior: String

    init(
        yinYang: String = "balanced",
        coldHeat: String = "neutral",
        defExcess: String = "balanced",
        interiorExterior: String = "balanced"
    ) {
        self.yinYang = yinYang
        self.coldHeat = coldHeat
        self.defExcess = defExcess
        self.interiorExterior = interiorExterior
    }
}

// MARK: - Legacy Enums (for reference)

/// Terrain modifier types enum
enum TerrainModifierType: String, Codable, CaseIterable {
    case damp
    case dry
    case stagnation
    case shen
    case none

    var displayName: String {
        switch self {
        case .damp: return "Damp (Heavy)"
        case .dry: return "Dry (Thirsty)"
        case .stagnation: return "Stagnation (Stuck)"
        case .shen: return "Shen (Restless)"
        case .none: return ""
        }
    }
}

/// Yin-Yang balance
enum YinYangBalance: String, Codable {
    case yinLeaning = "yin_leaning"
    case yangLeaning = "yang_leaning"
    case balanced
}

/// Cold-Heat balance (temperature tendency)
enum ColdHeatBalance: String, Codable {
    case cold
    case neutral
    case warm
}

/// Deficiency-Excess balance (energy reserve)
enum DefExcessBalance: String, Codable {
    case deficient
    case balanced
    case excess
}

/// Interior-Exterior balance
enum InteriorExteriorBalance: String, Codable {
    case interior
    case exteriorProne = "exterior_prone"
    case balanced
}
