//
//  TerrainDriftDetector.swift
//  Terrain
//
//  Compares a 5-question pulse check-in against the user's current terrain
//  profile to detect whether their body pattern has shifted. Uses the same
//  TerrainScoringEngine classification logic so results stay consistent
//  with the full onboarding quiz.
//

import Foundation

// MARK: - Drift Result

struct TerrainDriftResult {
    let currentType: TerrainScoringEngine.PrimaryType
    let currentModifier: TerrainScoringEngine.Modifier
    let pulseType: TerrainScoringEngine.PrimaryType
    let pulseModifier: TerrainScoringEngine.Modifier
    let hasDrifted: Bool
    let driftSummary: String
    let recommendation: DriftRecommendation
}

// MARK: - Drift Recommendation

enum DriftRecommendation {
    case noChange
    case minorShift
    case significantDrift
}

// MARK: - Drift Detector

struct TerrainDriftDetector {
    private let engine = TerrainScoringEngine()

    /// Detect whether the user's terrain has drifted based on pulse check-in answers.
    ///
    /// - Parameters:
    ///   - answers: Map of question ID to selected option value (the score contribution).
    ///   - currentTerrainId: The raw value of the user's current `PrimaryType` (e.g. "cold_deficient_low_flame").
    ///   - currentModifier: The raw value of the user's current `Modifier` (e.g. "shen"), or nil / empty for none.
    /// - Returns: A `TerrainDriftResult` describing whether drift was detected.
    func detectDrift(
        answers: [Int: Int],
        currentTerrainId: String,
        currentModifier: String?
    ) -> TerrainDriftResult {
        // Build a mini vector from the 5 pulse answers
        var coldHeat = 0
        var defExcess = 0
        var dampDry = 0
        var qiStagnation = 0
        var shenUnsettled = 0

        for question in PulseCheckInQuestions.all {
            guard let selectedValue = answers[question.id] else { continue }
            switch question.axis {
            case "cold_heat": coldHeat = selectedValue
            case "def_excess": defExcess = selectedValue
            case "damp_dry": dampDry = selectedValue
            case "qi_stagnation": qiStagnation = selectedValue
            case "shen_unsettled": shenUnsettled = selectedValue
            default: break
            }
        }

        let pulseVector = TerrainVector(
            coldHeat: coldHeat,
            defExcess: defExcess,
            dampDry: dampDry,
            qiStagnation: qiStagnation,
            shenUnsettled: shenUnsettled
        )

        // Use engine's existing classification so drift detection stays
        // perfectly aligned with the full quiz scoring.
        let pulseResult = engine.calculateTerrain(from: pulseVector)

        let currentType = TerrainScoringEngine.PrimaryType(rawValue: currentTerrainId) ?? .neutralBalanced
        let currentMod = TerrainScoringEngine.Modifier(rawValue: currentModifier ?? "") ?? .none

        let typeChanged = pulseResult.primaryType != currentType
        let modifierChanged = pulseResult.modifier != currentMod

        let recommendation: DriftRecommendation
        let driftSummary: String

        if typeChanged {
            recommendation = .significantDrift
            driftSummary = "Your body may have shifted. Consider retaking the full assessment."
        } else if modifierChanged {
            let modifierName = pulseResult.modifier.displayName
            if modifierName.isEmpty {
                driftSummary = "A secondary pattern may have changed."
            } else {
                driftSummary = "Your \(modifierName) pattern may have changed."
            }
            recommendation = .minorShift
        } else {
            recommendation = .noChange
            driftSummary = "Your terrain profile is stable."
        }

        return TerrainDriftResult(
            currentType: currentType,
            currentModifier: currentMod,
            pulseType: pulseResult.primaryType,
            pulseModifier: pulseResult.modifier,
            hasDrifted: typeChanged || modifierChanged,
            driftSummary: driftSummary,
            recommendation: recommendation
        )
    }
}
