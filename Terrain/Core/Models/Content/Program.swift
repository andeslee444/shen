//
//  Program.swift
//  Terrain
//
//  SwiftData model for multi-day Programs
//

import Foundation
import SwiftData

/// Represents a multi-day structured program (3-30 days).
/// Think of this as a guided journey - a daily checklist for several days in a row.
@Model
final class Program {
    @Attribute(.unique) var id: String

    var title: LocalizedString
    var subtitle: LocalizedString?

    var durationDays: Int

    var tags: [String]
    var goals: [String]
    var terrainFit: [String]

    var days: [ProgramDay]

    // Review
    var reviewStatus: String

    init(
        id: String,
        title: LocalizedString,
        subtitle: LocalizedString? = nil,
        durationDays: Int,
        tags: [String] = [],
        goals: [String] = [],
        terrainFit: [String] = [],
        days: [ProgramDay] = [],
        reviewStatus: String = "draft"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.durationDays = durationDays
        self.tags = tags
        self.goals = goals
        self.terrainFit = terrainFit
        self.days = days
        self.reviewStatus = reviewStatus
    }

    /// Display name for the program
    var displayName: String {
        title.localized
    }
}

/// A single day in a program
struct ProgramDay: Codable, Hashable, Identifiable {
    var id: Int { day }
    var day: Int
    var routineRefs: [String]
    var movementRefs: [String]
    var lessonRef: String?

    init(
        day: Int,
        routineRefs: [String] = [],
        movementRefs: [String] = [],
        lessonRef: String? = nil
    ) {
        self.day = day
        self.routineRefs = routineRefs
        self.movementRefs = movementRefs
        self.lessonRef = lessonRef
    }
}

/// Paywall tiers for content
enum PaywallTier: String, Codable {
    case free
    case paid

    var isLocked: Bool {
        self == .paid
    }
}
