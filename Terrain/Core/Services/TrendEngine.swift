//
//  TrendEngine.swift
//  Terrain
//
//  Computes 14-day rolling trends from daily logs.
//  Compares first half vs second half of the window to determine direction.
//

import Foundation

final class TrendEngine {

    /// Computes trends across 7 categories from recent daily logs.
    /// Returns an empty array if fewer than 3 days of data exist.
    func computeTrends(logs: [DailyLog], windowDays: Int = 14) -> [TrendResult] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: today) else {
            return []
        }

        // Filter to logs within the window
        let windowLogs = logs.filter { log in
            let logDay = calendar.startOfDay(for: log.date)
            return logDay >= windowStart && logDay <= today
        }

        // Need at least 3 days of data for a meaningful trend
        let uniqueDays = Set(windowLogs.map { calendar.startOfDay(for: $0.date) })
        guard uniqueDays.count >= 3 else { return [] }

        // Split into first half and second half
        let midpoint = calendar.date(byAdding: .day, value: -windowDays / 2, to: today)!
        let firstHalf = windowLogs.filter { calendar.startOfDay(for: $0.date) < midpoint }
        let secondHalf = windowLogs.filter { calendar.startOfDay(for: $0.date) >= midpoint }

        var results: [TrendResult] = []

        // Sleep: count poorSleep symptom frequency
        results.append(computeSymptomTrend(
            category: "Sleep",
            icon: "moon.zzz",
            symptom: .poorSleep,
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            invertedBetter: true, // fewer = improving
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Digestion: count bloating frequency
        results.append(computeSymptomTrend(
            category: "Digestion",
            icon: "stomach",
            symptom: .bloating,
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            invertedBetter: true,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Stress: count stressed frequency
        results.append(computeSymptomTrend(
            category: "Stress",
            icon: "brain.head.profile",
            symptom: .stressed,
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            invertedBetter: true,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Energy: compare energyLevel distributions
        results.append(computeEnergyTrend(
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Headache: count headache frequency
        results.append(computeSymptomTrend(
            category: "Headache",
            icon: "head.profile",
            symptom: .headache,
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            invertedBetter: true,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Cramps: count cramps frequency
        results.append(computeSymptomTrend(
            category: "Cramps",
            icon: "waveform.path",
            symptom: .cramps,
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            invertedBetter: true,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Stiffness: count stiff frequency
        results.append(computeSymptomTrend(
            category: "Stiffness",
            icon: "figure.walk",
            symptom: .stiff,
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            invertedBetter: true,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        return results
    }

    // MARK: - Private Helpers

    /// Computes a trend for a single QuickSymptom by comparing frequency rates
    /// between first and second halves, and producing per-day rates for sparklines.
    private func computeSymptomTrend(
        category: String,
        icon: String,
        symptom: QuickSymptom,
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        invertedBetter: Bool,
        allWindowLogs: [DailyLog] = [],
        windowDays: Int = 14
    ) -> TrendResult {
        let firstRate = symptomRate(symptom, in: firstHalf)
        let secondRate = symptomRate(symptom, in: secondHalf)

        let direction: TrendDirection
        let threshold = 0.15 // 15% change needed to register

        if invertedBetter {
            // Fewer symptoms = improving
            if firstRate - secondRate > threshold {
                direction = .improving
            } else if secondRate - firstRate > threshold {
                direction = .declining
            } else {
                direction = .stable
            }
        } else {
            if secondRate - firstRate > threshold {
                direction = .improving
            } else if firstRate - secondRate > threshold {
                direction = .declining
            } else {
                direction = .stable
            }
        }

        let dailyRates = computeDailySymptomRates(
            symptom: symptom,
            logs: allWindowLogs,
            windowDays: windowDays,
            inverted: invertedBetter
        )

        return TrendResult(category: category, direction: direction, icon: icon, dailyRates: dailyRates)
    }

    /// Fraction of logs in the slice that contain the given quick symptom
    private func symptomRate(_ symptom: QuickSymptom, in logs: [DailyLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let count = logs.filter { $0.quickSymptoms.contains(symptom) }.count
        return Double(count) / Double(logs.count)
    }

    /// Computes energy trend by scoring: low=-1, normal=0, wired=+1
    /// A higher average in the second half is improving (more normal/wired vs low).
    /// But "wired" is not ideal either, so we use a simple "fewer low" heuristic.
    private func computeEnergyTrend(
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        allWindowLogs: [DailyLog] = [],
        windowDays: Int = 14
    ) -> TrendResult {
        let firstLowRate = energyLowRate(firstHalf)
        let secondLowRate = energyLowRate(secondHalf)

        let threshold = 0.15
        let direction: TrendDirection

        if firstLowRate - secondLowRate > threshold {
            direction = .improving
        } else if secondLowRate - firstLowRate > threshold {
            direction = .declining
        } else {
            direction = .stable
        }

        let dailyRates = computeDailyEnergyRates(
            logs: allWindowLogs,
            windowDays: windowDays
        )

        return TrendResult(category: "Energy", direction: direction, icon: "bolt", dailyRates: dailyRates)
    }

    /// Fraction of logs with energyLevel == .low
    private func energyLowRate(_ logs: [DailyLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let lowCount = logs.filter { $0.energyLevel == .low }.count
        return Double(lowCount) / Double(logs.count)
    }

    // MARK: - Routine Effectiveness

    /// Computes how effective a routine appears by correlating post-routine feedback
    /// with symptom frequency in the days following the routine.
    ///
    /// Returns a value from -1.0 (symptoms worsened after doing this routine)
    /// to +1.0 (symptoms improved after doing this routine), or nil if insufficient data.
    ///
    /// The method compares symptom rates on days when the routine was completed
    /// (and feedback was "better") vs days when it was not completed.
    func computeRoutineEffectiveness(
        logs: [DailyLog],
        routineId: String
    ) -> Double? {
        // Need at least 5 logs to compute anything meaningful
        guard logs.count >= 5 else { return nil }

        let calendar = Calendar.current

        // Separate logs into "routine done" and "routine not done" days
        let routineDays = logs.filter { log in
            log.routineFeedback.contains { $0.routineOrMovementId == routineId }
        }
        let nonRoutineDays = logs.filter { log in
            !log.routineFeedback.contains { $0.routineOrMovementId == routineId }
        }

        // Need data in both groups
        guard !routineDays.isEmpty, !nonRoutineDays.isEmpty else { return nil }

        // Calculate average "better" rate on routine days
        let betterCount = routineDays.filter { log in
            log.routineFeedback.contains {
                $0.routineOrMovementId == routineId && $0.feedback == .better
            }
        }.count
        let betterRate = Double(betterCount) / Double(routineDays.count)

        // Calculate average symptom count on routine days vs non-routine days
        let routineDaySymptomRate = averageSymptomCount(routineDays)
        let nonRoutineDaySymptomRate = averageSymptomCount(nonRoutineDays)

        // Combine: high "better" feedback + fewer symptoms on routine days = effective
        // Score from -1 to +1
        let feedbackScore = (betterRate - 0.5) * 2.0 // maps 0..1 to -1..1
        let symptomDelta = nonRoutineDaySymptomRate - routineDaySymptomRate
        let symptomScore = min(max(symptomDelta / 3.0, -1.0), 1.0) // normalize

        // Weighted combination: feedback matters more since it's direct user input
        return feedbackScore * 0.7 + symptomScore * 0.3
    }

    /// Average number of quick symptoms per log entry
    private func averageSymptomCount(_ logs: [DailyLog]) -> Double {
        guard !logs.isEmpty else { return 0 }
        let total = logs.reduce(0) { $0 + $1.quickSymptoms.count }
        return Double(total) / Double(logs.count)
    }

    // MARK: - Daily Rate Computation (for sparklines)

    /// Produces one rate per day in the window for a specific symptom.
    /// For inverted symptoms, 1.0 = no symptom that day (good), 0.0 = symptom present (bad).
    private func computeDailySymptomRates(
        symptom: QuickSymptom,
        logs: [DailyLog],
        windowDays: Int,
        inverted: Bool
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard !dayLogs.isEmpty else { return 0.5 } // no data = neutral midpoint

            let hasSymptom = dayLogs.contains { $0.quickSymptoms.contains(symptom) }
            if inverted {
                return hasSymptom ? 0.0 : 1.0 // no symptom is good
            } else {
                return hasSymptom ? 1.0 : 0.0
            }
        }
    }

    /// Produces one rate per day for energy level.
    /// Maps: low=0.0, normal=0.5, wired=1.0 (higher = more energized).
    private func computeDailyEnergyRates(
        logs: [DailyLog],
        windowDays: Int
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard let log = dayLogs.first, let energy = log.energyLevel else {
                return 0.5 // no data = neutral midpoint
            }

            switch energy {
            case .low: return 0.0
            case .normal: return 0.5
            case .wired: return 1.0
            }
        }
    }
}
