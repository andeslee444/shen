//
//  UserProfile.swift
//  Terrain
//
//  SwiftData model for user profile and terrain data
//

import Foundation
import SwiftData

/// A single quiz question response, stored for "How we got this" explainer
struct QuizResponse: Codable, Hashable {
    let questionId: String
    let optionId: String
}

/// User profile with terrain assessment results
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID

    // Terrain vector (raw scores from quiz)
    var coldHeat: Int          // -10 to +10: negative=cold, positive=heat
    var defExcess: Int         // -10 to +10: negative=deficient, positive=excess
    var dampDry: Int           // -10 to +10: negative=damp, positive=dry
    var qiStagnation: Int      // 0 to +10: higher=more stuck
    var shenUnsettled: Int     // 0 to +10: higher=more sleep/mind unsettled

    // Flags from quiz
    var hasReflux: Bool
    var hasLooseStool: Bool
    var hasConstipation: Bool
    var hasStickyStool: Bool
    var hasNightSweats: Bool
    var wakesThirstyHot: Bool

    // Derived terrain
    var terrainProfileId: String?
    var terrainModifier: String?

    // User goals (up to 2)
    var goals: [Goal]

    // Quiz persistence (v2+)
    var quizResponses: [QuizResponse]?  // nil for pre-v2 users
    var quizVersion: Int                // 1 = legacy, 2 = with response tracking

    // Safety preferences
    var safetyPreferences: SafetyPreferences

    // Notification preferences
    var morningNotificationTime: Date?
    var eveningNotificationTime: Date?
    var notificationsEnabled: Bool

    // Timestamps
    var createdAt: Date
    var updatedAt: Date
    var lastQuizCompletedAt: Date?

    init(
        id: UUID = UUID(),
        coldHeat: Int = 0,
        defExcess: Int = 0,
        dampDry: Int = 0,
        qiStagnation: Int = 0,
        shenUnsettled: Int = 0,
        hasReflux: Bool = false,
        hasLooseStool: Bool = false,
        hasConstipation: Bool = false,
        hasStickyStool: Bool = false,
        hasNightSweats: Bool = false,
        wakesThirstyHot: Bool = false,
        terrainProfileId: String? = nil,
        terrainModifier: String? = nil,
        goals: [Goal] = [],
        quizResponses: [QuizResponse]? = nil,
        quizVersion: Int = 1,
        safetyPreferences: SafetyPreferences = SafetyPreferences(),
        morningNotificationTime: Date? = nil,
        eveningNotificationTime: Date? = nil,
        notificationsEnabled: Bool = false
    ) {
        self.id = id
        self.coldHeat = coldHeat
        self.defExcess = defExcess
        self.dampDry = dampDry
        self.qiStagnation = qiStagnation
        self.shenUnsettled = shenUnsettled
        self.hasReflux = hasReflux
        self.hasLooseStool = hasLooseStool
        self.hasConstipation = hasConstipation
        self.hasStickyStool = hasStickyStool
        self.hasNightSweats = hasNightSweats
        self.wakesThirstyHot = wakesThirstyHot
        self.terrainProfileId = terrainProfileId
        self.terrainModifier = terrainModifier
        self.goals = goals
        self.quizResponses = quizResponses
        self.quizVersion = quizVersion
        self.safetyPreferences = safetyPreferences
        self.morningNotificationTime = morningNotificationTime
        self.eveningNotificationTime = eveningNotificationTime
        self.notificationsEnabled = notificationsEnabled
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Returns the persisted modifier, falling back to recomputing from the vector
    var resolvedModifier: TerrainScoringEngine.Modifier {
        if let stored = terrainModifier,
           let modifier = TerrainScoringEngine.Modifier(rawValue: stored) {
            return modifier
        }
        // Fallback: recompute from vector (for pre-modifier users)
        let engine = TerrainScoringEngine()
        return engine.calculateTerrain(from: terrainVector).modifier
    }

    /// Returns the terrain vector for scoring
    var terrainVector: TerrainVector {
        TerrainVector(
            coldHeat: coldHeat,
            defExcess: defExcess,
            dampDry: dampDry,
            qiStagnation: qiStagnation,
            shenUnsettled: shenUnsettled
        )
    }

    /// Update terrain from vector
    func updateTerrain(from vector: TerrainVector, profileId: String, modifier: TerrainScoringEngine.Modifier = .none) {
        coldHeat = vector.coldHeat
        defExcess = vector.defExcess
        dampDry = vector.dampDry
        qiStagnation = vector.qiStagnation
        shenUnsettled = vector.shenUnsettled
        terrainProfileId = profileId
        terrainModifier = modifier.rawValue
        lastQuizCompletedAt = Date()
        updatedAt = Date()
    }
}

/// Terrain vector for scoring calculations
struct TerrainVector: Codable, Hashable {
    var coldHeat: Int
    var defExcess: Int
    var dampDry: Int
    var qiStagnation: Int
    var shenUnsettled: Int

    init(
        coldHeat: Int = 0,
        defExcess: Int = 0,
        dampDry: Int = 0,
        qiStagnation: Int = 0,
        shenUnsettled: Int = 0
    ) {
        self.coldHeat = clamp(coldHeat, min: -10, max: 10)
        self.defExcess = clamp(defExcess, min: -10, max: 10)
        self.dampDry = clamp(dampDry, min: -10, max: 10)
        self.qiStagnation = clamp(qiStagnation, min: 0, max: 10)
        self.shenUnsettled = clamp(shenUnsettled, min: 0, max: 10)
    }

    static var zero: TerrainVector {
        TerrainVector()
    }

    /// Add delta values from a quiz answer
    mutating func add(_ delta: TerrainDelta) {
        coldHeat = clamp(coldHeat + delta.coldHeat, min: -10, max: 10)
        defExcess = clamp(defExcess + delta.defExcess, min: -10, max: 10)
        dampDry = clamp(dampDry + delta.dampDry, min: -10, max: 10)
        qiStagnation = clamp(qiStagnation + delta.qiStagnation, min: 0, max: 10)
        shenUnsettled = clamp(shenUnsettled + delta.shenUnsettled, min: 0, max: 10)
    }
}

/// Delta values to add to terrain vector
struct TerrainDelta: Codable, Hashable {
    var coldHeat: Int = 0
    var defExcess: Int = 0
    var dampDry: Int = 0
    var qiStagnation: Int = 0
    var shenUnsettled: Int = 0

    init(
        coldHeat: Int = 0,
        defExcess: Int = 0,
        dampDry: Int = 0,
        qiStagnation: Int = 0,
        shenUnsettled: Int = 0
    ) {
        self.coldHeat = coldHeat
        self.defExcess = defExcess
        self.dampDry = dampDry
        self.qiStagnation = qiStagnation
        self.shenUnsettled = shenUnsettled
    }

    /// Apply a weight multiplier to the delta
    func weighted(by weight: Double) -> TerrainDelta {
        TerrainDelta(
            coldHeat: Int(Double(coldHeat) * weight),
            defExcess: Int(Double(defExcess) * weight),
            dampDry: Int(Double(dampDry) * weight),
            qiStagnation: Int(Double(qiStagnation) * weight),
            shenUnsettled: Int(Double(shenUnsettled) * weight)
        )
    }
}

// Helper function
private func clamp(_ value: Int, min: Int, max: Int) -> Int {
    Swift.min(Swift.max(value, min), max)
}
