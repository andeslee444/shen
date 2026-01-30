//
//  ProgramEnrollment.swift
//  Terrain
//
//  SwiftData model for tracking multi-day program enrollments.
//  Think of this as a bookmark in a recipe book — it remembers which
//  program you're working through, which day you're on, and which
//  items you've completed each day.
//

import Foundation
import SwiftData

/// Tracks a user's enrollment in a multi-day program.
@Model
final class ProgramEnrollment {
    @Attribute(.unique) var id: UUID

    /// The content pack ID of the enrolled program
    var programId: String

    /// When the user started the program
    var startDate: Date

    /// Which day the user is currently on (1-based).
    /// Advances automatically based on calendar days elapsed since startDate.
    var currentDay: Int

    /// Completion records for each day the user has finished
    var dayCompletions: [ProgramDayCompletion]

    /// Whether this enrollment is the active one (only one at a time)
    var isActive: Bool

    /// When the user completed the entire program (nil if still in progress)
    var completedAt: Date?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        programId: String,
        startDate: Date = Date(),
        currentDay: Int = 1,
        dayCompletions: [ProgramDayCompletion] = [],
        isActive: Bool = true,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.programId = programId
        self.startDate = startDate
        self.currentDay = currentDay
        self.dayCompletions = dayCompletions
        self.isActive = isActive
        self.completedAt = completedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Computes which day the user should be on based on calendar days
    /// elapsed since they started. Capped at the program's duration.
    func computedCurrentDay(programDurationDays: Int) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let today = calendar.startOfDay(for: Date())
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        // Day 1 on start date, day 2 the next day, etc.
        return min(elapsed + 1, programDurationDays)
    }

    /// Whether a specific day has been completed
    func isDayCompleted(_ day: Int) -> Bool {
        dayCompletions.contains { $0.day == day }
    }

    /// Get completed item IDs for a specific day
    func completedItemIds(forDay day: Int) -> Set<String> {
        guard let completion = dayCompletions.first(where: { $0.day == day }) else {
            return []
        }
        return Set(completion.completedItemIds)
    }

    /// Mark an item as completed for a specific day
    func markItemCompleted(_ itemId: String, forDay day: Int) {
        if let index = dayCompletions.firstIndex(where: { $0.day == day }) {
            if !dayCompletions[index].completedItemIds.contains(itemId) {
                dayCompletions[index].completedItemIds.append(itemId)
            }
        } else {
            dayCompletions.append(
                ProgramDayCompletion(day: day, completedItemIds: [itemId])
            )
        }
        updatedAt = Date()
    }

    /// Mark a day as fully completed
    func markDayCompleted(_ day: Int, programDurationDays: Int) {
        if !isDayCompleted(day) {
            // Ensure there's at least an entry for this day
            if !dayCompletions.contains(where: { $0.day == day }) {
                dayCompletions.append(ProgramDayCompletion(day: day, completedItemIds: []))
            }
        }

        // If this was the last day, mark the whole program complete
        if day >= programDurationDays {
            completedAt = Date()
            isActive = false
        }

        updatedAt = Date()
    }
}

/// Record of items completed on a specific program day
struct ProgramDayCompletion: Codable, Hashable {
    var day: Int
    var completedItemIds: [String]
    var completedAt: Date

    init(day: Int, completedItemIds: [String], completedAt: Date = Date()) {
        self.day = day
        self.completedItemIds = completedItemIds
        self.completedAt = completedAt
    }
}
