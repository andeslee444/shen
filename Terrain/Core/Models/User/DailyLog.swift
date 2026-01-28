//
//  DailyLog.swift
//  Terrain
//
//  SwiftData model for daily check-in logs
//

import Foundation
import SwiftData

/// Daily check-in log with symptoms, energy, and completions
@Model
final class DailyLog {
    @Attribute(.unique) var id: UUID

    var date: Date

    // Current patterns check-in
    var symptoms: [Symptom]
    var symptomOnset: SymptomOnset?
    var energyLevel: EnergyLevel?

    // Completions
    var completedRoutineIds: [String]
    var completedMovementIds: [String]
    var routineLevel: RoutineLevel?

    // Weather (cached from API)
    var weatherCondition: String?
    var temperatureCelsius: Double?

    // Notes
    var notes: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptoms: [Symptom] = [],
        symptomOnset: SymptomOnset? = nil,
        energyLevel: EnergyLevel? = nil,
        completedRoutineIds: [String] = [],
        completedMovementIds: [String] = [],
        routineLevel: RoutineLevel? = nil,
        weatherCondition: String? = nil,
        temperatureCelsius: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.symptoms = symptoms
        self.symptomOnset = symptomOnset
        self.energyLevel = energyLevel
        self.completedRoutineIds = completedRoutineIds
        self.completedMovementIds = completedMovementIds
        self.routineLevel = routineLevel
        self.weatherCondition = weatherCondition
        self.temperatureCelsius = temperatureCelsius
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Calendar date component for grouping
    var calendarDate: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: date)
    }

    /// Whether the daily routine was completed
    var hasCompletedRoutine: Bool {
        !completedRoutineIds.isEmpty || !completedMovementIds.isEmpty
    }

    func markRoutineComplete(_ routineId: String, level: RoutineLevel) {
        if !completedRoutineIds.contains(routineId) {
            completedRoutineIds.append(routineId)
        }
        routineLevel = level
        updatedAt = Date()
    }

    func markMovementComplete(_ movementId: String) {
        if !completedMovementIds.contains(movementId) {
            completedMovementIds.append(movementId)
        }
        updatedAt = Date()
    }
}

/// Symptoms for daily check-in
enum Symptom: String, Codable, CaseIterable, Identifiable {
    case cough
    case soreThroat = "sore_throat"
    case congestion
    case aches
    case headache

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cough: return "Cough"
        case .soreThroat: return "Sore Throat"
        case .congestion: return "Congestion"
        case .aches: return "Aches"
        case .headache: return "Headache"
        }
    }

    var icon: String {
        switch self {
        case .cough: return "waveform.path"
        case .soreThroat: return "flame"
        case .congestion: return "nose"
        case .aches: return "figure.walk"
        case .headache: return "brain.head.profile"
        }
    }
}

/// Symptom onset timeframe
enum SymptomOnset: String, Codable, CaseIterable {
    case today
    case oneToThreeDays = "1-3_days"
    case fourPlusDays = "4+_days"

    var displayName: String {
        switch self {
        case .today: return "Today"
        case .oneToThreeDays: return "1-3 days"
        case .fourPlusDays: return "4+ days"
        }
    }
}

/// Energy level for daily check-in
enum EnergyLevel: String, Codable, CaseIterable {
    case low
    case normal
    case wired

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .normal: return "battery.75"
        case .wired: return "bolt.fill"
        }
    }
}
