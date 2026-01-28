//
//  ProgressRecord.swift
//  Terrain
//
//  SwiftData model for tracking streaks and progress
//

import Foundation
import SwiftData

/// Progress tracking for streaks and completions
@Model
final class ProgressRecord {
    @Attribute(.unique) var id: UUID

    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int

    var lastCompletionDate: Date?

    // Monthly summaries
    var monthlyCompletions: [String: Int]  // "2024-01": 15

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalCompletions: Int = 0,
        lastCompletionDate: Date? = nil,
        monthlyCompletions: [String: Int] = [:]
    ) {
        self.id = id
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalCompletions = totalCompletions
        self.lastCompletionDate = lastCompletionDate
        self.monthlyCompletions = monthlyCompletions
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Record a completion for today
    func recordCompletion() {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already completed today
        if let lastDate = lastCompletionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            if lastDay == today {
                return // Already recorded today
            }

            // Check if this continues the streak (completed yesterday)
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                currentStreak += 1
            } else {
                currentStreak = 1 // Streak broken, start new
            }
        } else {
            currentStreak = 1 // First completion
        }

        // Update records
        totalCompletions += 1
        lastCompletionDate = today
        longestStreak = max(longestStreak, currentStreak)

        // Update monthly count
        let monthKey = Self.monthKey(for: today)
        monthlyCompletions[monthKey, default: 0] += 1

        updatedAt = Date()
    }

    /// Check and update streak if broken (call on app launch)
    func checkStreakContinuity() {
        guard let lastDate = lastCompletionDate else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: lastDate)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // If last completion was before yesterday, streak is broken
        if lastDay < yesterday {
            currentStreak = 0
            updatedAt = Date()
        }
    }

    /// Get completions for a specific month
    func completions(for date: Date) -> Int {
        let key = Self.monthKey(for: date)
        return monthlyCompletions[key] ?? 0
    }

    private static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
}
