//
//  IngredientEmoji.swift
//  Terrain
//
//  Maps each ingredient to a distinct emoji for visual identification.
//  Uses a three-tier fallback: specific ID → category → default leaf.
//

import Foundation

extension Ingredient {

    /// Per-ingredient emoji for visual identification on cards and detail sheets.
    ///
    /// Think of this like a name badge — each ingredient gets its own icon so you
    /// can spot ginger vs. watermelon at a glance, rather than every card wearing
    /// the same generic leaf.
    var emoji: String {
        if let specific = Self.emojiMap[id] {
            return specific
        }
        if let fallback = Self.categoryEmojiMap[category] {
            return fallback
        }
        return "🌿"
    }

    // MARK: - ID-Specific Mapping (43 ingredients)

    private static let emojiMap: [String: String] = [
        // Spices & warming agents
        "ginger":        "🫚",
        "turmeric":      "🫚",
        "cinnamon":      "🪵",
        "fennel-seed":   "🌱",
        "star-anise":    "⭐",
        "black-pepper":  "🌶️",
        "cardamom":      "🫛",

        // Fruits
        "red-dates":     "🍎",
        "goji-berry":    "🫐",
        "pear":          "🍐",
        "watermelon":    "🍉",
        "dried-longan":  "🍑",
        "persimmon":     "🍊",

        // Teas & flowers
        "green-tea":     "🍵",
        "chamomile":     "🌼",
        "chrysanthemum": "🏵️",

        // Legumes
        "mung-bean":     "🫘",
        "adzuki-bean":   "🫘",
        "tofu":          "🧈",

        // Grains
        "rice":          "🍚",
        "jobs-tears":    "🌾",

        // Seeds & nuts
        "walnut":        "🌰",
        "lotus-seed":    "🪷",
        "sesame":        "🫘",
        "almond":        "🥜",
        "jujube-seed":   "🌰",

        // Herbs & aromatics
        "mint":          "🌿",
        "lavender":      "🪻",
        "passionflower": "🌺",
        "citrus-peel":   "🍋",
        "rosemary":      "🌿",
        "corn-silk":     "🌽",

        // Mushrooms & fungi
        "tremella":      "🍄",
        "reishi":        "🍄",
        "poria":         "🍄",

        // Meat
        "lamb":          "🍖",
        "chicken":       "🍗",

        // Vegetables
        "cucumber":      "🥒",
        "bitter-melon":  "🍈",
        "celery":        "🥬",
        "lettuce":       "🥗",

        // Other
        "lily-bulb":     "🌷",
        "honey":         "🍯",
    ]

    // MARK: - Category Fallback

    /// Covers future ingredients that aren't in the ID map yet.
    private static let categoryEmojiMap: [String: String] = [
        "spice":     "🌶️",
        "root":      "🫚",
        "fruit":     "🍎",
        "grain":     "🌾",
        "legume":    "🫘",
        "mushroom":  "🍄",
        "tea":       "🍵",
        "meat":      "🍖",
        "herb":      "🌿",
        "vegetable": "🥬",
        "seed":      "🌰",
        "other":     "🌿",
    ]
}
