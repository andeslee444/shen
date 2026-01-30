//
//  TerrainCopy.swift
//  Terrain
//
//  Shared terrain identity copy — superpower, trap, ritual, truths,
//  and ingredient recommendations for each terrain type.
//  Used by both TerrainRevealView and TerrainIdentityView.
//

import Foundation

// MARK: - Terrain Copy Data

struct TerrainCopy {
    let superpower: String
    let trap: String
    let signatureRitual: String
    let truths: [String]
    let bestMatchesIntro: String
    let recommendedIngredients: [String]

    static func forType(_ type: TerrainScoringEngine.PrimaryType, modifier: TerrainScoringEngine.Modifier) -> TerrainCopy {
        switch type {
        case .coldDeficient:
            return TerrainCopy(
                superpower: "When you're consistent, you become steady. Warmth and routine unlock your best energy.",
                trap: "Cold inputs and skipping meals drain you faster than you expect.",
                signatureRitual: "Warm start within 30 minutes of waking.",
                truths: [
                    "Your system does better with gentle build-up than big pushes.",
                    "Cooked food stabilizes you—raw/cold hits harder for you than most.",
                    "Movement works best for you when it warms you up, not when it exhausts you."
                ],
                bestMatchesIntro: "Your best matches tend to be warming, digestion-supporting, and steadying.",
                recommendedIngredients: ["Ginger", "Red Dates", "Cinnamon", "Oats", "Rice", "Sweet Potato"]
            )

        case .coldBalanced:
            return TerrainCopy(
                superpower: "You stay composed under pressure. Warmth turns that calm into momentum.",
                trap: "If you stay too cold for too long, you get sluggish and heavy.",
                signatureRitual: "Warm your center before your day speeds up.",
                truths: [
                    "You can handle a lot—until cold quietly accumulates.",
                    "Warm prep methods make you feel clearer without changing your diet drastically.",
                    "A little movement goes a long way for you when it's consistent."
                ],
                bestMatchesIntro: "You do best with warming basics and light daily movement.",
                recommendedIngredients: ["Ginger", "Scallion", "Black Pepper", "Lamb", "Walnuts", "Longan"]
            )

        case .neutralDeficient:
            return TerrainCopy(
                superpower: "You're sensitive in a good way. Small changes give you big returns.",
                trap: "Overcommitting drains you. You feel it in sleep, digestion, and focus.",
                signatureRitual: "A steady breakfast + a short reset movement.",
                truths: [
                    "Your body thrives on predictable fuel.",
                    "You recover fastest with gentle routines, not intensity.",
                    "When you're depleted, your mind gets louder—protect your evenings."
                ],
                bestMatchesIntro: "You do best with steady nourishment, gentle movement, and calm evenings.",
                recommendedIngredients: ["Rice", "Chicken", "Eggs", "Sweet Potato", "Mushrooms", "Honey"]
            )

        case .neutralBalanced:
            return TerrainCopy(
                superpower: "You adapt well. With the right ritual, you can fine-tune sleep, digestion, and energy quickly.",
                trap: "When your schedule gets chaotic, your body follows.",
                signatureRitual: "A daily anchor: one warm drink + one short movement.",
                truths: [
                    "You're responsive—small routines keep you aligned.",
                    "Your biggest lever is consistency, not strictness.",
                    "You can tolerate variety, but your body loves rhythm."
                ],
                bestMatchesIntro: "You benefit from balanced routines that keep your rhythm steady.",
                recommendedIngredients: ["Green Tea", "Rice", "Vegetables", "Tofu", "Fish", "Sesame"]
            )

        case .neutralExcess:
            return TerrainCopy(
                superpower: "You have drive. When your flow is smooth, you're magnetic and productive.",
                trap: "You can run on tension. It looks like energy, but it costs sleep and digestion.",
                signatureRitual: "A 3-minute unwind to release tension daily.",
                truths: [
                    "Your body holds stress in your breath, jaw, and shoulders.",
                    "You feel best when you move the stuck energy early.",
                    "Evening calm is your performance enhancer."
                ],
                bestMatchesIntro: "You do best with routines that move tension and settle the mind.",
                recommendedIngredients: ["Chamomile", "Citrus Peel", "Radish", "Celery", "Mint", "Jasmine"]
            )

        case .warmBalanced:
            return TerrainCopy(
                superpower: "You have natural spark. When you stay cool-headed, you feel light and clear.",
                trap: "Too much stimulation (stress, late nights, spicy/alcohol) tips you into restlessness.",
                signatureRitual: "A cooling-down cue in the evening.",
                truths: [
                    "You run better with room-temp hydration than icy extremes.",
                    "When you're over-heated, sleep and skin show it first.",
                    "Gentle movement keeps your flame clean."
                ],
                bestMatchesIntro: "You do best with light, cooling-leaning habits and calming evenings.",
                recommendedIngredients: ["Cucumber", "Mung Bean", "Pear", "Chrysanthemum", "Green Tea", "Watermelon"]
            )

        case .warmExcess:
            return TerrainCopy(
                superpower: "You have intensity. When it's directed, you're powerful and sharp.",
                trap: "You can overrun your nervous system—sleep becomes the first casualty.",
                signatureRitual: "A nightly downshift: breath + screens off.",
                truths: [
                    "Your body runs hot under stress.",
                    "You need deliberate cooling signals, not more stimulation.",
                    "Your best days start with calm, not urgency."
                ],
                bestMatchesIntro: "You do best with calming routines that reduce heat and restlessness.",
                recommendedIngredients: ["Mung Bean", "Bitter Melon", "Celery", "Lotus Root", "Pear", "Mint"]
            )

        case .warmDeficient:
            return TerrainCopy(
                superpower: "You're bright and sensitive. When nourished, you're glowing and creative.",
                trap: "You can feel warm but depleted—restless sleep, dryness, and wired-tired energy.",
                signatureRitual: "Moistening nourishment + a consistent bedtime cue.",
                truths: [
                    "You burn quickly when you skip recovery.",
                    "Your best energy is smooth, not pushed.",
                    "Evening routines matter more for you than morning intensity."
                ],
                bestMatchesIntro: "You do best with moistening nourishment and nervous-system calming habits.",
                recommendedIngredients: ["Pear", "Honey", "Sesame", "Lily Bulb", "Tremella", "Goji Berry"]
            )
        }
    }
}
