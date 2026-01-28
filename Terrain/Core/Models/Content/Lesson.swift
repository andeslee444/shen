//
//  Lesson.swift
//  Terrain
//
//  SwiftData model for Field Guide lessons
//

import Foundation
import SwiftData

/// Represents a Field Guide lesson - educational content about TCM concepts.
/// Think of this as a mini-article that teaches users about one concept at a time.
@Model
final class Lesson {
    @Attribute(.unique) var id: String

    var title: LocalizedString
    var topic: String

    var body: [LessonBlock]

    var takeaway: Takeaway

    // Call to action
    var cta: LessonCTA?

    // Review
    var reviewStatus: String

    init(
        id: String,
        title: LocalizedString,
        topic: String,
        body: [LessonBlock] = [],
        takeaway: Takeaway,
        cta: LessonCTA? = nil,
        reviewStatus: String = "draft"
    ) {
        self.id = id
        self.title = title
        self.topic = topic
        self.body = body
        self.takeaway = takeaway
        self.cta = cta
        self.reviewStatus = reviewStatus
    }

    /// Display name for the lesson
    var displayName: String {
        title.localized
    }
}

// MARK: - Supporting Types

/// Content block types for lesson body
struct LessonBlock: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var type: LessonBlockType
    var text: LocalizedString?
    var bullets: [LocalizedString]?
    var asset: MediaAsset?

    init(type: LessonBlockType, text: LocalizedString? = nil, bullets: [LocalizedString]? = nil, asset: MediaAsset? = nil) {
        self.type = type
        self.text = text
        self.bullets = bullets
        self.asset = asset
    }

    static func paragraph(_ text: LocalizedString) -> LessonBlock {
        LessonBlock(type: .paragraph, text: text)
    }

    static func bullets(_ items: [LocalizedString]) -> LessonBlock {
        LessonBlock(type: .bullets, bullets: items)
    }

    static func callout(_ text: LocalizedString) -> LessonBlock {
        LessonBlock(type: .callout, text: text)
    }

    static func image(_ asset: MediaAsset) -> LessonBlock {
        LessonBlock(type: .image, asset: asset)
    }
}

enum LessonBlockType: String, Codable {
    case paragraph
    case bullets
    case callout
    case image
}

/// Takeaway - the key message from a lesson
struct Takeaway: Codable, Hashable {
    var oneLine: LocalizedString

    init(oneLine: LocalizedString) {
        self.oneLine = oneLine
    }
}

/// Call to action for a lesson
struct LessonCTA: Codable, Hashable {
    var label: LocalizedString
    var action: String

    init(label: LocalizedString, action: String) {
        self.label = label
        self.action = action
    }
}

/// Topics for Field Guide lessons
enum LessonTopic: String, Codable, CaseIterable {
    case coldHeat = "cold_heat"
    case dampDry = "damp_dry"
    case shen
    case qiFlow = "qi_flow"
    case seasonality
    case methods
    case safety

    var displayName: String {
        switch self {
        case .coldHeat: return "Cold & Heat"
        case .dampDry: return "Damp & Dry"
        case .shen: return "Shen (Mind)"
        case .qiFlow: return "Qi Flow"
        case .seasonality: return "Seasonality"
        case .methods: return "Methods"
        case .safety: return "Safety"
        }
    }
}

/// Call to action types
enum CTAAction: String, Codable {
    case openToday = "open_today"
    case openRightNow = "open_right_now"
    case openIngredients = "open_ingredients"
    case openRoutine = "open_routine"
    case openMovement = "open_movement"
}
