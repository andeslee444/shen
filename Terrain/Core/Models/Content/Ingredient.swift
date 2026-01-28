//
//  Ingredient.swift
//  Terrain
//
//  SwiftData model for TCM ingredients
//

import Foundation
import SwiftData

/// Represents a TCM-aligned ingredient (food, herb, tea, etc.)
/// Think of this as a detailed card in a recipe box - it contains everything
/// about an ingredient including what it does, how to use it, and when to be careful.
@Model
final class Ingredient {
    @Attribute(.unique) var id: String

    // Name structure stored as JSON
    var name: IngredientName

    // Classification
    var category: String
    var tags: [String]
    var goals: [String]
    var seasons: [String]
    var regions: [String]

    // Why it helps
    var whyItHelps: WhyItHelps

    // How to use
    var howToUse: HowToUse

    // Safety
    var cautions: Cautions

    // Cultural context
    var culturalContext: CulturalContext

    // Review status
    var reviewStatus: String

    init(
        id: String,
        name: IngredientName,
        category: String,
        tags: [String] = [],
        goals: [String] = [],
        seasons: [String] = ["all_year"],
        regions: [String] = ["pan_chinese_common"],
        whyItHelps: WhyItHelps,
        howToUse: HowToUse,
        cautions: Cautions = Cautions(),
        culturalContext: CulturalContext,
        reviewStatus: String = "draft"
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.tags = tags
        self.goals = goals
        self.seasons = seasons
        self.regions = regions
        self.whyItHelps = whyItHelps
        self.howToUse = howToUse
        self.cautions = cautions
        self.culturalContext = culturalContext
        self.reviewStatus = reviewStatus
    }

    /// Common name for display
    var displayName: String {
        name.common.localized
    }
}

// MARK: - Nested Types

/// Ingredient name with localization and Chinese names
struct IngredientName: Codable, Hashable {
    var common: LocalizedString
    var pinyin: String?
    var hanzi: String?
    var otherNames: [LocalizedString]?

    init(common: LocalizedString, pinyin: String? = nil, hanzi: String? = nil, otherNames: [LocalizedString]? = nil) {
        self.common = common
        self.pinyin = pinyin
        self.hanzi = hanzi
        self.otherNames = otherNames
    }
}

/// Why the ingredient helps - plain language and TCM explanation
struct WhyItHelps: Codable, Hashable {
    var plain: LocalizedString
    var tcm: LocalizedString

    init(plain: LocalizedString, tcm: LocalizedString) {
        self.plain = plain
        self.tcm = tcm
    }
}

/// How to use the ingredient
struct HowToUse: Codable, Hashable {
    var quickUses: [QuickUse]
    var typicalAmount: LocalizedString

    init(quickUses: [QuickUse] = [], typicalAmount: LocalizedString = "") {
        self.quickUses = quickUses
        self.typicalAmount = typicalAmount
    }
}

/// Quick use suggestion for an ingredient
struct QuickUse: Codable, Hashable {
    var text: LocalizedString
    var prepTimeMin: Int
    var methodTags: [String]

    init(text: LocalizedString, prepTimeMin: Int = 0, methodTags: [String] = []) {
        self.text = text
        self.prepTimeMin = prepTimeMin
        self.methodTags = methodTags
    }
}

/// Safety cautions
struct Cautions: Codable, Hashable {
    var flags: [SafetyFlag]
    var text: LocalizedString

    init(flags: [SafetyFlag] = [], text: LocalizedString = "") {
        self.flags = flags
        self.text = text
    }
}

/// Cultural context and provenance
struct CulturalContext: Codable, Hashable {
    var blurb: LocalizedString
    var commonIn: [String]

    init(blurb: LocalizedString = "", commonIn: [String] = []) {
        self.blurb = blurb
        self.commonIn = commonIn
    }
}

// MARK: - Legacy Support

/// Review status for content items
enum ReviewStatus: String, Codable {
    case draft
    case internallyReviewed = "internally_reviewed"
    case practitionerReviewed = "practitioner_reviewed"
    case influencerReviewed = "influencer_reviewed"
    case published

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .internallyReviewed: return "Internally Reviewed"
        case .practitionerReviewed: return "Practitioner Reviewed"
        case .influencerReviewed: return "Influencer Reviewed"
        case .published: return "Published"
        }
    }
}
