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

        // Mood: overall feeling (1-10), most holistic metric so it appears first
        results.append(computeMoodTrend(
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Sleep: use SleepQuality if available, else fall back to poorSleep symptom
        results.append(computeSleepQualityTrend(
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Digestion: use DigestiveState if available, else fall back to bloating symptom
        results.append(computeDigestiveTrend(
            firstHalf: firstHalf,
            secondHalf: secondHalf,
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
            icon: "drop.fill",
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

        // Sleep Duration: HealthKit-sourced total asleep minutes
        results.append(computeSleepDurationTrend(
            firstHalf: firstHalf,
            secondHalf: secondHalf,
            allWindowLogs: windowLogs,
            windowDays: windowDays
        ))

        // Resting Heart Rate: HealthKit-sourced resting BPM
        results.append(computeRestingHeartRateTrend(
            firstHalf: firstHalf,
            secondHalf: secondHalf,
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

    /// Computes mood trend by comparing average mood rating in first half vs second half.
    /// Higher mood in the second half = improving (NOT inverted — higher mood is better).
    /// Uses a 1.5-point threshold on the 10-point scale (equivalent to 15%).
    private func computeMoodTrend(
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        allWindowLogs: [DailyLog],
        windowDays: Int
    ) -> TrendResult {
        let firstAvg = averageMoodRating(firstHalf)
        let secondAvg = averageMoodRating(secondHalf)

        let threshold = 1.5 // 1.5 points on a 10-point scale ≈ 15%
        let direction: TrendDirection

        if secondAvg - firstAvg > threshold {
            direction = .improving
        } else if firstAvg - secondAvg > threshold {
            direction = .declining
        } else {
            direction = .stable
        }

        let dailyRates = computeDailyMoodRates(
            logs: allWindowLogs,
            windowDays: windowDays
        )

        return TrendResult(category: "Mood", direction: direction, icon: "face.smiling", dailyRates: dailyRates)
    }

    /// Average mood rating across logs that have a mood entry.
    /// Returns 5.0 (midpoint) if no logs have mood data.
    private func averageMoodRating(_ logs: [DailyLog]) -> Double {
        let moodLogs = logs.compactMap { $0.moodRating }
        guard !moodLogs.isEmpty else { return 5.0 }
        return Double(moodLogs.reduce(0, +)) / Double(moodLogs.count)
    }

    /// Produces one rate per day for mood rating.
    /// Maps: moodRating / 10.0 (so 1→0.1, 10→1.0). No data → 0.5 (neutral midpoint).
    private func computeDailyMoodRates(
        logs: [DailyLog],
        windowDays: Int
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard let log = dayLogs.first, let mood = log.moodRating else {
                return 0.5 // no data = neutral midpoint
            }

            return Double(mood) / 10.0
        }
    }

    // MARK: - Sleep Quality Trend (Phase 13)

    /// Computes sleep quality trend using SleepQuality enum when available,
    /// falling back to poorSleep symptom when not.
    /// "fellAsleepEasily" = good (1.0), all others = varying degrees of poor sleep.
    private func computeSleepQualityTrend(
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        allWindowLogs: [DailyLog],
        windowDays: Int
    ) -> TrendResult {
        // Check if we have any SleepQuality data
        let hasQualityData = allWindowLogs.contains { $0.sleepQuality != nil }

        if hasQualityData {
            let firstAvg = averageSleepScore(firstHalf)
            let secondAvg = averageSleepScore(secondHalf)

            let threshold = 0.15 // 15% change threshold
            let direction: TrendDirection

            // Higher score = better sleep
            if secondAvg - firstAvg > threshold {
                direction = .improving
            } else if firstAvg - secondAvg > threshold {
                direction = .declining
            } else {
                direction = .stable
            }

            let dailyRates = computeDailySleepQualityRates(
                logs: allWindowLogs,
                windowDays: windowDays
            )

            return TrendResult(category: "Sleep", direction: direction, icon: "moon.zzz", dailyRates: dailyRates)
        } else {
            // Fall back to poorSleep symptom
            return computeSymptomTrend(
                category: "Sleep",
                icon: "moon.zzz",
                symptom: .poorSleep,
                firstHalf: firstHalf,
                secondHalf: secondHalf,
                invertedBetter: true,
                allWindowLogs: allWindowLogs,
                windowDays: windowDays
            )
        }
    }

    /// Maps SleepQuality to a 0-1 score.
    /// fellAsleepEasily = 1.0 (best), others degrade progressively.
    private func sleepQualityScore(_ quality: SleepQuality) -> Double {
        switch quality {
        case .fellAsleepEasily: return 1.0
        case .hardToFallAsleep: return 0.4 // Shen disturbance
        case .wokeMiddleOfNight: return 0.3 // Liver qi stagnation
        case .wokeEarly: return 0.35 // Yin deficiency
        case .unrefreshing: return 0.25 // Damp accumulation
        }
    }

    /// Average sleep score for a set of logs (0-1 scale)
    private func averageSleepScore(_ logs: [DailyLog]) -> Double {
        let qualityLogs = logs.compactMap { $0.sleepQuality }
        guard !qualityLogs.isEmpty else { return 0.5 }
        return qualityLogs.map { sleepQualityScore($0) }.reduce(0, +) / Double(qualityLogs.count)
    }

    /// Daily sleep quality rates for sparkline
    private func computeDailySleepQualityRates(
        logs: [DailyLog],
        windowDays: Int
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard let log = dayLogs.first, let quality = log.sleepQuality else {
                return 0.5 // no data = neutral midpoint
            }

            return sleepQualityScore(quality)
        }
    }

    // MARK: - Digestive Trend (Phase 13)

    /// Computes digestive trend using DigestiveState when available,
    /// falling back to bloating symptom when not.
    private func computeDigestiveTrend(
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        allWindowLogs: [DailyLog],
        windowDays: Int
    ) -> TrendResult {
        // Check if we have any DigestiveState data
        let hasDigestiveData = allWindowLogs.contains { $0.digestiveState != nil }

        if hasDigestiveData {
            let firstAvg = averageDigestiveScore(firstHalf)
            let secondAvg = averageDigestiveScore(secondHalf)

            let threshold = 0.15
            let direction: TrendDirection

            // Higher score = better digestion
            if secondAvg - firstAvg > threshold {
                direction = .improving
            } else if firstAvg - secondAvg > threshold {
                direction = .declining
            } else {
                direction = .stable
            }

            let dailyRates = computeDailyDigestiveRates(
                logs: allWindowLogs,
                windowDays: windowDays
            )

            return TrendResult(category: "Digestion", direction: direction, icon: "fork.knife", dailyRates: dailyRates)
        } else {
            // Fall back to bloating symptom
            return computeSymptomTrend(
                category: "Digestion",
                icon: "fork.knife",
                symptom: .bloating,
                firstHalf: firstHalf,
                secondHalf: secondHalf,
                invertedBetter: true,
                allWindowLogs: allWindowLogs,
                windowDays: windowDays
            )
        }
    }

    /// Maps DigestiveState to a 0-1 score.
    /// Combines appetite and stool quality into a single metric.
    private func digestiveScore(_ state: DigestiveState) -> Double {
        let appetiteScore: Double
        switch state.appetiteLevel {
        case .normal: appetiteScore = 1.0
        case .low: appetiteScore = 0.5
        case .none: appetiteScore = 0.2
        case .strong: appetiteScore = 0.7 // Strong can indicate heat
        }

        let stoolScore: Double
        switch state.stoolQuality {
        case .normal: stoolScore = 1.0
        case .loose: stoolScore = 0.4 // Spleen qi deficiency
        case .constipated: stoolScore = 0.4 // Heat or yin deficiency
        case .sticky: stoolScore = 0.3 // Damp accumulation
        case .mixed: stoolScore = 0.5 // Variable
        }

        // Weighted average: stool quality is a stronger TCM indicator
        return appetiteScore * 0.3 + stoolScore * 0.7
    }

    /// Average digestive score for a set of logs
    private func averageDigestiveScore(_ logs: [DailyLog]) -> Double {
        let digestiveLogs = logs.compactMap { $0.digestiveState }
        guard !digestiveLogs.isEmpty else { return 0.5 }
        return digestiveLogs.map { digestiveScore($0) }.reduce(0, +) / Double(digestiveLogs.count)
    }

    /// Daily digestive rates for sparkline
    private func computeDailyDigestiveRates(
        logs: [DailyLog],
        windowDays: Int
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard let log = dayLogs.first, let state = log.digestiveState else {
                return 0.5 // no data = neutral midpoint
            }

            return digestiveScore(state)
        }
    }

    // MARK: - Sleep Duration Trend (Phase 14 — HealthKit)

    /// Computes sleep duration trend from HealthKit-sourced sleepDurationMinutes.
    /// More sleep = improving (up direction). Maps 480 min (8h) to 1.0 on the sparkline.
    ///
    /// Think of this like a fuel gauge for recovery — the trend tells you whether
    /// your body is getting the recharge time it needs, distinct from the subjective
    /// sleep *quality* trend which captures how restful sleep felt.
    func computeSleepDurationTrend(
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        allWindowLogs: [DailyLog],
        windowDays: Int
    ) -> TrendResult {
        let firstAvg = averageSleepDuration(firstHalf)
        let secondAvg = averageSleepDuration(secondHalf)

        // Threshold: 30 minutes change (about 6% of 8h) to register as meaningful
        let threshold: Double = 30.0
        let direction: TrendDirection

        // More sleep = improving
        if secondAvg - firstAvg > threshold {
            direction = .improving
        } else if firstAvg - secondAvg > threshold {
            direction = .declining
        } else {
            direction = .stable
        }

        let dailyRates = computeDailySleepDurationRates(
            logs: allWindowLogs,
            windowDays: windowDays
        )

        return TrendResult(
            category: "Sleep Duration",
            direction: direction,
            icon: "bed.double.fill",
            dailyRates: dailyRates
        )
    }

    /// Average sleep duration in minutes across logs that have the data.
    /// Returns 450 min (7.5h neutral midpoint) if no data.
    private func averageSleepDuration(_ logs: [DailyLog]) -> Double {
        let sleepLogs = logs.compactMap { $0.sleepDurationMinutes }
        guard !sleepLogs.isEmpty else { return 450.0 }
        return sleepLogs.reduce(0, +) / Double(sleepLogs.count)
    }

    /// Daily sleep duration rates for sparkline.
    /// Maps minutes to 0-1 scale: 480 min (8h) = 1.0, 0 min = 0.0.
    /// No data = 0.5 (neutral midpoint).
    private func computeDailySleepDurationRates(
        logs: [DailyLog],
        windowDays: Int
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard let log = dayLogs.first, let minutes = log.sleepDurationMinutes else {
                return 0.5 // no data = neutral midpoint
            }

            // Scale: 480 min (8h) = 1.0, clamped to [0, 1]
            return min(max(minutes / 480.0, 0.0), 1.0)
        }
    }

    // MARK: - Resting Heart Rate Trend (Phase 14 — HealthKit)

    /// Computes resting heart rate trend from HealthKit-sourced restingHeartRate.
    /// LOWER HR = improving (down direction is good — opposite of most trends).
    /// Maps 60 BPM to 1.0 (great), 80 BPM to 0.0 (needs attention).
    ///
    /// Resting heart rate is like an engine's idle speed — lower means more
    /// efficient cardiovascular function. A rising trend could indicate stress,
    /// poor sleep, or deconditioning.
    func computeRestingHeartRateTrend(
        firstHalf: [DailyLog],
        secondHalf: [DailyLog],
        allWindowLogs: [DailyLog],
        windowDays: Int
    ) -> TrendResult {
        let firstAvg = averageRestingHeartRate(firstHalf)
        let secondAvg = averageRestingHeartRate(secondHalf)

        // Threshold: 3 BPM change to register as meaningful
        let threshold: Double = 3.0
        let direction: TrendDirection

        // LOWER HR = improving (inverted from typical)
        if firstAvg - secondAvg > threshold {
            direction = .improving
        } else if secondAvg - firstAvg > threshold {
            direction = .declining
        } else {
            direction = .stable
        }

        let dailyRates = computeDailyRestingHeartRateRates(
            logs: allWindowLogs,
            windowDays: windowDays
        )

        return TrendResult(
            category: "Resting HR",
            direction: direction,
            icon: "heart.fill",
            dailyRates: dailyRates
        )
    }

    /// Average resting heart rate across logs that have the data.
    /// Returns 70.0 (neutral midpoint) if no data.
    private func averageRestingHeartRate(_ logs: [DailyLog]) -> Double {
        let hrLogs = logs.compactMap { $0.restingHeartRate }
        guard !hrLogs.isEmpty else { return 70.0 }
        return Double(hrLogs.reduce(0, +)) / Double(hrLogs.count)
    }

    /// Daily resting HR rates for sparkline.
    /// Maps BPM to 0-1 scale: 60 BPM = 1.0 (great), 80 BPM = 0.0 (needs attention).
    /// No data = 0.5 (neutral midpoint).
    private func computeDailyRestingHeartRateRates(
        logs: [DailyLog],
        windowDays: Int
    ) -> [Double] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<windowDays).map { daysAgo in
            let targetDay = calendar.date(byAdding: .day, value: -(windowDays - 1 - daysAgo), to: today)!
            let dayStart = calendar.startOfDay(for: targetDay)

            let dayLogs = logs.filter { calendar.startOfDay(for: $0.date) == dayStart }
            guard let log = dayLogs.first, let bpm = log.restingHeartRate else {
                return 0.5 // no data = neutral midpoint
            }

            // Scale: 60 BPM = 1.0, 80 BPM = 0.0, clamped to [0, 1]
            // Formula: (80 - bpm) / 20
            return min(max(Double(80 - bpm) / 20.0, 0.0), 1.0)
        }
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

    // MARK: - Terrain-Aware Trend Prioritization (Phase 13)

    /// Prioritizes and annotates trends based on the user's terrain type.
    /// Each terrain type has categories that matter more — this reorders
    /// trends so the most relevant ones appear first.
    func prioritizeTrends(
        logs: [DailyLog],
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        windowDays: Int = 14
    ) -> [AnnotatedTrendResult] {
        let baseTrends = computeTrends(logs: logs, windowDays: windowDays)
        guard !baseTrends.isEmpty else { return [] }

        let priorityMap = terrainPriorityMap(for: terrainType)
        let watchForCategories = terrainWatchForCategories(for: terrainType, modifier: modifier)

        var annotated: [AnnotatedTrendResult] = baseTrends.map { trend in
            let priority = priorityMap[trend.category] ?? 99
            let isWatchFor = watchForCategories.contains(trend.category)
            let note = terrainNoteForTrend(
                category: trend.category,
                direction: trend.direction,
                terrainType: terrainType,
                modifier: modifier
            )

            return AnnotatedTrendResult(
                base: trend,
                priority: priority,
                terrainNote: note,
                isWatchFor: isWatchFor
            )
        }

        // Sort by priority (lowest number = highest priority)
        annotated.sort { $0.priority < $1.priority }

        return annotated
    }

    /// Returns the priority ordering for trend categories based on terrain type.
    /// Lower number = higher priority (shows first in UI).
    private func terrainPriorityMap(for terrainType: TerrainScoringEngine.PrimaryType) -> [String: Int] {
        switch terrainType {
        case .coldDeficient:
            // Energy and digestion matter most — cold types struggle with both
            return [
                "Energy": 1, "Digestion": 2, "Stiffness": 3, "Sleep": 4,
                "Mood": 5, "Stress": 6, "Headache": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .coldBalanced:
            // Stiffness and energy — cold can cause both
            return [
                "Stiffness": 1, "Energy": 2, "Sleep": 3, "Digestion": 4,
                "Mood": 5, "Cramps": 6, "Stress": 7, "Headache": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .neutralDeficient:
            // Energy and sleep are primary concerns for deficient types
            return [
                "Energy": 1, "Sleep": 2, "Digestion": 3, "Mood": 4,
                "Stress": 5, "Stiffness": 6, "Headache": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .neutralBalanced:
            // Balanced types should watch for any extreme shifts
            return [
                "Mood": 1, "Energy": 2, "Sleep": 3, "Digestion": 4,
                "Stress": 5, "Stiffness": 6, "Headache": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .neutralExcess:
            // Stress and stiffness — excess energy stagnates
            return [
                "Stress": 1, "Stiffness": 2, "Headache": 3, "Sleep": 4,
                "Mood": 5, "Energy": 6, "Digestion": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .warmBalanced:
            // Sleep and headache — heat rises and disrupts
            return [
                "Sleep": 1, "Headache": 2, "Stress": 3, "Digestion": 4,
                "Mood": 5, "Energy": 6, "Stiffness": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .warmExcess:
            // All heat symptoms are important — runs hot
            return [
                "Stress": 1, "Sleep": 2, "Headache": 3, "Mood": 4,
                "Digestion": 5, "Energy": 6, "Stiffness": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        case .warmDeficient:
            // Sleep and energy — bright but thin
            return [
                "Sleep": 1, "Energy": 2, "Stress": 3, "Mood": 4,
                "Digestion": 5, "Headache": 6, "Stiffness": 7, "Cramps": 8,
                "Sleep Duration": 9, "Resting HR": 10
            ]
        }
    }

    /// Returns the "watch for" categories — trends that signal trouble for this terrain.
    private func terrainWatchForCategories(
        for terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> Set<String> {
        var watchFor: Set<String> = []

        // Terrain-specific watch-fors
        switch terrainType {
        case .coldDeficient:
            watchFor.insert("Mood") // Reserve depletion shows in mood first
            watchFor.insert("Energy")
        case .coldBalanced:
            watchFor.insert("Stiffness") // Cold symptoms
        case .neutralDeficient:
            watchFor.insert("Mood")
            watchFor.insert("Stress")
        case .neutralBalanced:
            // Any extreme shift is notable for balanced types
            break
        case .neutralExcess:
            watchFor.insert("Sleep")
        case .warmBalanced:
            watchFor.insert("Digestion")
        case .warmExcess:
            // Everything can flare for warm excess
            watchFor.insert("Sleep")
            watchFor.insert("Headache")
        case .warmDeficient:
            watchFor.insert("Energy") // Dryness symptoms
        }

        // Modifier-specific watch-fors
        switch modifier {
        case .shen:
            watchFor.insert("Sleep")
            watchFor.insert("Stress")
            watchFor.insert("Mood")
            watchFor.insert("Resting HR") // Shen disturbance often elevates resting HR
        case .stagnation:
            watchFor.insert("Stiffness")
            watchFor.insert("Headache")
            watchFor.insert("Stress")
        case .damp:
            watchFor.insert("Digestion")
            watchFor.insert("Energy")
        case .dry:
            watchFor.insert("Sleep") // Yin deficiency affects sleep
        case .none:
            break
        }

        // Terrain-specific watch-fors for new HealthKit categories
        switch terrainType {
        case .coldDeficient, .neutralDeficient, .warmDeficient:
            watchFor.insert("Sleep Duration") // Deficient types need more recovery sleep
        default:
            break
        }

        return watchFor
    }

    /// Generates a terrain-specific note explaining what a trend means for this user.
    private func terrainNoteForTrend(
        category: String,
        direction: TrendDirection,
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> String {
        // Only generate notes for declining trends (they need explanation)
        guard direction == .declining else {
            if direction == .improving {
                return "Trending in a good direction."
            }
            return "Holding steady."
        }

        // Terrain-specific declining notes
        switch (category, terrainType) {
        case ("Sleep", .coldDeficient), ("Sleep", .coldBalanced):
            return "Cold patterns often struggle with sleep when warmth depletes. Warm feet before bed can help."
        case ("Sleep", .warmExcess), ("Sleep", .warmBalanced):
            return "Heat rises at night, disrupting sleep. Earlier wind-down and cooling foods may help."
        case ("Sleep", .warmDeficient):
            return "Your reserves run thin at night. Nourishing foods and earlier bedtime rebuild what you need."

        case ("Energy", .coldDeficient):
            return "Low Flame types feel energy dips most. Warm starts and cooked foods rebuild your fire."
        case ("Energy", .neutralDeficient):
            return "Your battery needs consistent charging. Regular meals and gentle rest fill the tank."
        case ("Energy", .warmDeficient):
            return "Bright but thin — your energy needs nourishment, not more stimulation."

        case ("Digestion", .coldDeficient), ("Digestion", .coldBalanced):
            return "Cold weakens digestive fire. Warm, cooked foods are easier for your system to process."
        case ("Digestion", .warmExcess):
            return "Heat can disrupt digestion. Cooling foods and lighter meals help balance."

        case ("Stress", .warmExcess):
            return "Warm types feel stress as heat rising. Cooling practices and release matter more now."
        case ("Stress", .neutralExcess):
            return "Excess energy stagnates under stress. Movement is your release valve."

        case ("Mood", .coldDeficient):
            return "Low mood often follows low reserves. Warmth and nourishment lift your spirits naturally."
        case ("Mood", .neutralDeficient):
            return "Energy and mood are closely linked for you. Rest is productive, not lazy."

        case ("Headache", .warmExcess), ("Headache", .warmBalanced):
            return "Heat rises, causing tension headaches. Cooling and releasing pressure helps."

        case ("Stiffness", .coldBalanced):
            return "Cold settles into joints. Gentle warmth and movement prevent stagnation."
        case ("Stiffness", _) where modifier == .stagnation:
            return "Your energy gets stuck easily. Regular movement keeps things flowing."

        // Sleep Duration (HealthKit)
        case ("Sleep Duration", .coldDeficient), ("Sleep Duration", .neutralDeficient), ("Sleep Duration", .warmDeficient):
            return "Deficient types need more recovery time. Shorter sleep means less rebuilding overnight."
        case ("Sleep Duration", .warmExcess):
            return "Heat can make sleep restless, cutting total hours. Evening cooling helps you stay asleep longer."
        case ("Sleep Duration", _):
            return "Your total sleep time is dropping. Consistent bedtimes help protect sleep quantity."

        // Resting Heart Rate (HealthKit)
        case ("Resting HR", .warmExcess):
            return "Rising heart rate can signal accumulating heat. Cooling practices and rest bring it down."
        case ("Resting HR", .coldDeficient):
            return "Your heart works harder when reserves are low. Gentle nourishment helps your system settle."
        case ("Resting HR", _) where modifier == .shen:
            return "An unsettled spirit shows up in your heart rate. Calming practices lower it naturally."
        case ("Resting HR", _):
            return "Rising resting heart rate may reflect stress or poor recovery. Prioritize rest this week."

        default:
            break
        }

        // Modifier-specific fallbacks
        switch (category, modifier) {
        case ("Sleep", .shen):
            return "Your mind tends to race. A settling routine before bed helps your spirit rest."
        case ("Stress", .shen):
            return "Your shen modifier means stress affects you more deeply. Calming practices are essential."
        case ("Digestion", .damp):
            return "Dampness accumulates when digestion struggles. Light, warm meals help your body process."
        case ("Stiffness", .stagnation):
            return "Stagnation shows as stiffness first. Movement is medicine for your pattern."
        default:
            break
        }

        // Generic fallback
        return "This trend deserves attention. Your terrain suggests focusing on balance."
    }

    // MARK: - Terrain-Specific Healthy Zones

    /// Returns the healthy zone for a trend category based on terrain type.
    /// Different terrains have different "normal" ranges.
    func healthyZone(
        for category: String,
        terrainType: TerrainScoringEngine.PrimaryType
    ) -> TerrainHealthyZone {
        switch (category, terrainType) {
        // Energy zones
        case ("Energy", .coldDeficient), ("Energy", .neutralDeficient), ("Energy", .warmDeficient):
            return TerrainHealthyZone(
                category: category,
                range: 0.4...0.7,
                label: "Your healthy range",
                terrainContext: "Deficient types have lower baseline energy — steady beats high."
            )
        case ("Energy", .warmExcess), ("Energy", .neutralExcess):
            return TerrainHealthyZone(
                category: category,
                range: 0.5...0.8,
                label: "Your healthy range",
                terrainContext: "Excess types run higher, but too high means burnout risk."
            )

        // Sleep zones
        case ("Sleep", .warmExcess), ("Sleep", .warmBalanced):
            return TerrainHealthyZone(
                category: category,
                range: 0.5...0.85,
                label: "Your healthy range",
                terrainContext: "Warm types need extra attention to sleep — heat disrupts rest."
            )
        case ("Sleep", .coldDeficient):
            return TerrainHealthyZone(
                category: category,
                range: 0.6...0.9,
                label: "Your healthy range",
                terrainContext: "Good sleep rebuilds your reserves. Prioritize it."
            )

        // Stress zones
        case ("Stress", .warmExcess):
            return TerrainHealthyZone(
                category: category,
                range: 0.5...0.8,
                label: "Your healthy range",
                terrainContext: "Your threshold for stress symptoms is lower than others. Early intervention helps."
            )

        // Digestion zones
        case ("Digestion", .coldDeficient), ("Digestion", .coldBalanced):
            return TerrainHealthyZone(
                category: category,
                range: 0.5...0.85,
                label: "Your healthy range",
                terrainContext: "Cold patterns have more sensitive digestion. Consistency matters."
            )

        // Sleep Duration zones — terrain-specific sleep needs
        case ("Sleep Duration", .coldDeficient), ("Sleep Duration", .neutralDeficient), ("Sleep Duration", .warmDeficient):
            // Deficient types need more recovery: 7.5-9h (450-540 min → 0.94-1.0 on 480-scale)
            return TerrainHealthyZone(
                category: category,
                range: 0.65...1.0,
                label: "Your healthy range",
                terrainContext: "Deficient types need more sleep for recovery — aim for 7.5-9 hours."
            )
        case ("Sleep Duration", .warmExcess), ("Sleep Duration", .neutralExcess):
            // Excess types need less: 7-8h (420-480 min → 0.875-1.0 on 480-scale)
            return TerrainHealthyZone(
                category: category,
                range: 0.6...0.9,
                label: "Your healthy range",
                terrainContext: "Excess types do well with 7-8 hours — more isn't always better."
            )
        case ("Sleep Duration", _):
            // Neutral/balanced: 7-8.5h (420-510 min → 0.875-1.0 on 480-scale)
            return TerrainHealthyZone(
                category: category,
                range: 0.6...0.95,
                label: "Healthy range",
                terrainContext: "Most people feel best with 7-8.5 hours of sleep."
            )

        // Resting Heart Rate zones — lower is generally better
        case ("Resting HR", .warmExcess), ("Resting HR", .warmBalanced):
            return TerrainHealthyZone(
                category: category,
                range: 0.6...1.0,
                label: "Your healthy range",
                terrainContext: "Warm types run hotter — a lower resting heart rate means your system is managing heat well."
            )
        case ("Resting HR", .coldDeficient), ("Resting HR", .neutralDeficient):
            return TerrainHealthyZone(
                category: category,
                range: 0.4...0.8,
                label: "Your healthy range",
                terrainContext: "Deficient types may have slightly higher resting rates — focus on steady improvement."
            )
        case ("Resting HR", _):
            return TerrainHealthyZone(
                category: category,
                range: 0.5...1.0,
                label: "Healthy range",
                terrainContext: "A lower resting heart rate generally indicates good cardiovascular health."
            )

        default:
            // Default healthy zone for most categories
            return TerrainHealthyZone(
                category: category,
                range: 0.5...0.9,
                label: "Healthy range",
                terrainContext: "Most people feel best in this range."
            )
        }
    }

    // MARK: - Activity Minutes Tracking

    /// Computes total activity minutes broken down by type (routine vs movement).
    /// Uses the actualDurationSeconds from RoutineFeedbackEntry when available.
    func computeActivityMinutes(
        logs: [DailyLog],
        windowDays: Int = 14
    ) -> ActivityMinutesResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: today) else {
            return ActivityMinutesResult(
                routineMinutes: Array(repeating: 0, count: windowDays),
                movementMinutes: Array(repeating: 0, count: windowDays),
                totalRoutineMinutes: 0,
                totalMovementMinutes: 0,
                windowDays: windowDays
            )
        }

        // Filter to logs within the window
        let windowLogs = logs.filter { log in
            let logDay = calendar.startOfDay(for: log.date)
            return logDay >= windowStart && logDay <= today
        }

        var routineMinutesPerDay: [Double] = Array(repeating: 0, count: windowDays)
        var movementMinutesPerDay: [Double] = Array(repeating: 0, count: windowDays)

        for log in windowLogs {
            let logDay = calendar.startOfDay(for: log.date)
            guard let dayIndex = calendar.dateComponents([.day], from: windowStart, to: logDay).day,
                  dayIndex >= 0 && dayIndex < windowDays else { continue }

            for entry in log.routineFeedback {
                guard let seconds = entry.actualDurationSeconds else { continue }
                let minutes = Double(seconds) / 60.0

                switch entry.activityType {
                case .routine:
                    routineMinutesPerDay[dayIndex] += minutes
                case .movement:
                    movementMinutesPerDay[dayIndex] += minutes
                case .none:
                    // Legacy entries without type — assume routine if it's not a movement ID
                    // (This is a best-effort fallback)
                    routineMinutesPerDay[dayIndex] += minutes
                }
            }
        }

        let totalRoutine = routineMinutesPerDay.reduce(0, +)
        let totalMovement = movementMinutesPerDay.reduce(0, +)

        return ActivityMinutesResult(
            routineMinutes: routineMinutesPerDay,
            movementMinutes: movementMinutesPerDay,
            totalRoutineMinutes: totalRoutine,
            totalMovementMinutes: totalMovement,
            windowDays: windowDays
        )
    }

    // MARK: - Terrain Pulse Generation

    /// Generates a personalized terrain pulse insight based on recent trends.
    /// This is the headline insight for the hero card at the top of the Trends section.
    func generateTerrainPulse(
        logs: [DailyLog],
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        windowDays: Int = 14
    ) -> TerrainPulseInsight {
        let annotatedTrends = prioritizeTrends(
            logs: logs,
            terrainType: terrainType,
            modifier: modifier,
            windowDays: windowDays
        )

        // Find the most significant declining trend (if any)
        let decliningTrends = annotatedTrends.filter { $0.direction == .declining }
        let significantDecline = decliningTrends.first { $0.isWatchFor }
            ?? decliningTrends.first

        if let decline = significantDecline {
            return generateDeclineInsight(
                trend: decline,
                terrainType: terrainType,
                modifier: modifier,
                windowDays: windowDays,
                logs: logs
            )
        }

        // Find any improving trends to celebrate
        let improvingTrends = annotatedTrends.filter { $0.direction == .improving }
        if let improving = improvingTrends.first {
            return generateImprovingInsight(
                trend: improving,
                terrainType: terrainType,
                modifier: modifier
            )
        }

        // All stable — generate a maintenance message
        return generateStableInsight(
            terrainType: terrainType,
            modifier: modifier
        )
    }

    private func generateDeclineInsight(
        trend: AnnotatedTrendResult,
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        windowDays: Int,
        logs: [DailyLog]
    ) -> TerrainPulseInsight {
        // Count consecutive declining days
        let recentRates = Array(trend.dailyRates.suffix(7))
        var declineDays = 0
        for i in stride(from: recentRates.count - 1, through: 1, by: -1) {
            if recentRates[i] < recentRates[i - 1] {
                declineDays += 1
            } else {
                break
            }
        }
        let dayWord = declineDays == 1 ? "day" : "days"

        let headline: String
        let body: String

        switch (trend.category, terrainType) {
        case ("Sleep", .coldDeficient):
            headline = "Your sleep has been declining"
            body = "For Low Flame types, sleep is when your reserves rebuild. This \(declineDays > 2 ? "\(declineDays)-day decline" : "recent dip") deserves attention — warm feet before bed and earlier wind-down can help restore your pattern."

        case ("Sleep", .warmExcess):
            headline = "Sleep is showing strain"
            body = "Heat rises at night for your terrain. When sleep declines, it often means your system is running too hot. Prioritize evening cooling and earlier quiet time this week."

        case ("Sleep", _) where modifier == .shen:
            headline = "Your sleep pattern needs attention"
            body = "With a Shen modifier, your mind races more than most. This sleep decline suggests your spirit needs settling — calming routines and less stimulation before bed will help."

        case ("Energy", .coldDeficient):
            headline = "Energy is trending down"
            body = "Low Flame types feel energy dips most acutely. This \(declineDays)-\(dayWord) decline is your body asking for warmth and gentle nourishment. Warm starts and cooked foods will help rebuild."

        case ("Energy", .neutralDeficient):
            headline = "Your energy needs attention"
            body = "Low Battery types can push through fatigue, but it costs you. This decline is a signal to prioritize rest and regular meals — your body rebuilds with consistency."

        case ("Stress", .warmExcess):
            headline = "Stress is building up"
            body = "Overclocked types feel stress as rising heat. This trend suggests your system needs release — movement, cooling foods, and deliberate wind-down will help before it compounds."

        case ("Stress", _) where modifier == .stagnation:
            headline = "Stress is accumulating"
            body = "Your Stagnation modifier means stress gets stuck rather than flowing through. Movement is your release valve — prioritize it now before tension builds."

        case ("Digestion", .coldDeficient), ("Digestion", .coldBalanced):
            headline = "Digestion is struggling"
            body = "Cold patterns have sensitive digestive fire. This decline suggests your body needs warmer, easier-to-digest foods. Cooked meals and warm drinks will help."

        case ("Digestion", _) where modifier == .damp:
            headline = "Your digestion needs support"
            body = "With a Damp modifier, digestive struggles mean moisture is accumulating. Light, warm meals and gentle movement help your body process and drain."

        case ("Mood", .coldDeficient):
            headline = "Mood is dipping"
            body = "For Low Flame types, mood follows energy. This decline often signals reserve depletion — warmth and nourishment will lift your spirits naturally."

        case ("Headache", .warmExcess):
            headline = "Headaches are increasing"
            body = "Heat rises for Overclocked types, often causing tension headaches. This trend calls for cooling practices and releasing pressure before it builds."

        case ("Stiffness", _) where modifier == .stagnation:
            headline = "Stiffness is building"
            body = "Your Stagnation modifier makes you prone to stuck energy showing as stiffness. Regular movement — even short breaks — keeps things flowing."

        default:
            headline = "\(trend.category) deserves attention"
            body = "Your \(trend.category.lowercased()) trend has been declining. For \(terrainType.nickname) types\(modifier != .none ? " with a \(modifier.displayName) modifier" : ""), this is worth addressing now."
        }

        return TerrainPulseInsight(
            headline: headline,
            body: body,
            accentCategory: trend.category,
            isUrgent: trend.isWatchFor
        )
    }

    private func generateImprovingInsight(
        trend: AnnotatedTrendResult,
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> TerrainPulseInsight {
        let headline: String
        let body: String

        switch (trend.category, terrainType) {
        case ("Sleep", .warmExcess), ("Sleep", .warmBalanced):
            headline = "Your sleep is improving"
            body = "For \(terrainType.nickname) types, better sleep means your cooling practices are working. Keep the evening routine steady — this momentum matters."

        case ("Energy", .coldDeficient):
            headline = "Energy is building"
            body = "Low Flame types build energy slowly but surely. This upward trend shows your warming practices are working — keep kindling that fire."

        case ("Digestion", _):
            headline = "Digestion is smoothing out"
            body = "Your digestive pattern is improving. Whatever you've been doing — keep it up. Consistency is the foundation for lasting change."

        case ("Stress", .warmExcess):
            headline = "Stress is easing"
            body = "Your stress levels are improving. For Overclocked types, this is hard-won progress — protect it with continued cooling and release."

        default:
            headline = "\(trend.category) is trending well"
            body = "Your \(trend.category.lowercased()) pattern is improving. This is your body responding to the right inputs — stay consistent."
        }

        return TerrainPulseInsight(
            headline: headline,
            body: body,
            accentCategory: trend.category,
            isUrgent: false
        )
    }

    // MARK: - Daily Log Drift Detection

    /// Detects gradual terrain drift from thermalFeeling and dominantEmotion
    /// patterns in daily logs. Unlike the pulse check-in (5-question quiz),
    /// this watches for slow shifts — like a thermometer noticing the room
    /// temperature is gradually changing even though nobody touched the dial.
    func detectDailyLogDrift(
        logs: [DailyLog],
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier,
        windowDays: Int = 14
    ) -> DailyLogDriftInsight {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let windowStart = calendar.date(byAdding: .day, value: -windowDays, to: today) else {
            return noDriftInsight(for: terrainType)
        }

        let windowLogs = logs.filter { log in
            let logDay = calendar.startOfDay(for: log.date)
            return logDay >= windowStart && logDay <= today
        }

        // --- Thermal drift ---
        let expectedRange = expectedThermalRange(for: terrainType)
        let thermalValues = windowLogs.compactMap { $0.thermalFeeling?.thermalValue }
        let thermalAvg: Double
        let hasThermalDrift: Bool
        var thermalSummary: String?

        if thermalValues.count >= 7 {
            thermalAvg = Double(thermalValues.reduce(0, +)) / Double(thermalValues.count)
            // Drift = average is more than 1.5 units away from the expected range
            let distanceFromRange: Double
            if thermalAvg < expectedRange.lowerBound {
                distanceFromRange = expectedRange.lowerBound - thermalAvg
            } else if thermalAvg > expectedRange.upperBound {
                distanceFromRange = thermalAvg - expectedRange.upperBound
            } else {
                distanceFromRange = 0
            }
            hasThermalDrift = distanceFromRange >= 1.5

            if hasThermalDrift {
                if thermalAvg > expectedRange.upperBound {
                    thermalSummary = "You've been feeling warmer than your \(terrainType.nickname) pattern expects. This may signal your terrain is shifting warmer."
                } else {
                    thermalSummary = "You've been feeling cooler than your \(terrainType.nickname) pattern expects. This may signal your terrain is shifting cooler."
                }
            }
        } else {
            thermalAvg = 0
            hasThermalDrift = false
        }

        // --- Emotion drift ---
        let emotions = windowLogs.compactMap { $0.dominantEmotion }
        var hasEmotionDrift = false
        var emotionSummary: String?
        var dominantEmotion: DominantEmotion?
        var dominantEmotionCount = 0

        if emotions.count >= 7 {
            // Count frequency of each non-calm emotion
            var counts: [DominantEmotion: Int] = [:]
            for emotion in emotions where emotion != .calm {
                counts[emotion, default: 0] += 1
            }

            if let (topEmotion, count) = counts.max(by: { $0.value < $1.value }), count >= 8 {
                dominantEmotion = topEmotion
                dominantEmotionCount = count

                // Check if it matches current modifier
                let matchesModifier = modifierMatchesEmotion(modifier, emotion: topEmotion)
                if !matchesModifier {
                    hasEmotionDrift = true
                    emotionSummary = "\(topEmotion.displayName) has appeared \(count) times in the last \(windowDays) days. Your \(topEmotion.tcmOrgan.capitalized) system may need attention — consider retaking the quiz."
                }
            }
        }

        return DailyLogDriftInsight(
            hasThermalDrift: hasThermalDrift,
            thermalSummary: thermalSummary,
            thermalAverage: thermalAvg,
            expectedThermalRange: expectedRange,
            hasEmotionDrift: hasEmotionDrift,
            emotionSummary: emotionSummary,
            dominantEmotion: dominantEmotion,
            dominantEmotionCount: dominantEmotionCount
        )
    }

    /// Expected thermal value range for a terrain type.
    /// Cold terrains expect negative values, warm expect positive, neutral near zero.
    private func expectedThermalRange(for type: TerrainScoringEngine.PrimaryType) -> ClosedRange<Double> {
        switch type {
        case .coldDeficient, .coldBalanced:
            return -2.0...(-1.0)
        case .warmBalanced, .warmExcess:
            return 1.0...2.0
        case .warmDeficient:
            // Warm but thin — runs warm but can swing either way
            return 0.0...2.0
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            return -0.5...0.5
        }
    }

    /// Whether a modifier already accounts for the given dominant emotion.
    /// If shen modifier is set and the dominant emotion is restless/anxious,
    /// that's expected, not drift.
    private func modifierMatchesEmotion(
        _ modifier: TerrainScoringEngine.Modifier,
        emotion: DominantEmotion
    ) -> Bool {
        switch modifier {
        case .shen:
            return emotion == .restless || emotion == .anxious
        case .stagnation:
            return emotion == .irritable
        case .damp:
            return emotion == .worried || emotion == .overwhelmed
        case .dry, .none:
            return false
        }
    }

    /// Returns a no-drift result with the expected range for the terrain type.
    private func noDriftInsight(for type: TerrainScoringEngine.PrimaryType) -> DailyLogDriftInsight {
        DailyLogDriftInsight(
            hasThermalDrift: false,
            thermalSummary: nil,
            thermalAverage: 0,
            expectedThermalRange: expectedThermalRange(for: type),
            hasEmotionDrift: false,
            emotionSummary: nil,
            dominantEmotion: nil,
            dominantEmotionCount: 0
        )
    }

    private func generateStableInsight(
        terrainType: TerrainScoringEngine.PrimaryType,
        modifier: TerrainScoringEngine.Modifier
    ) -> TerrainPulseInsight {
        let headline: String
        let body: String

        switch terrainType {
        case .coldDeficient:
            headline = "Holding steady"
            body = "Your patterns are stable — a good sign for Low Flame types. Keep the warmth consistent and your body will continue building."

        case .neutralBalanced:
            headline = "In your rhythm"
            body = "Steady Core types thrive on consistency. Your stable trends show your body is calibrated — trust your routines."

        case .warmExcess:
            headline = "Well balanced"
            body = "For Overclocked types, stability is an achievement. Your cooling and pacing practices are keeping your heat in check."

        default:
            let modifierNote = modifier != .none
                ? " Your \(modifier.displayName) modifier is well-managed."
                : ""
            headline = "All systems steady"
            body = "Your trends are stable — your \(terrainType.nickname) pattern is well-supported.\(modifierNote) Keep doing what you're doing."
        }

        return TerrainPulseInsight(
            headline: headline,
            body: body,
            accentCategory: nil,
            isUrgent: false
        )
    }
}
