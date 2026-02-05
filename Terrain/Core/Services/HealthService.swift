//
//  HealthService.swift
//  Terrain
//
//  Reads daily health data from HealthKit and caches it on DailyLog.
//  Follows the same pattern as WeatherService: fetch once per calendar day,
//  gracefully handle unavailable/denied, cache result locally.
//
//  Think of this as a health bridge — it translates Apple's health data
//  into simple numbers that InsightEngine, SuggestionEngine, and TrendEngine
//  can use to adjust recommendations and track trends over time.
//
//  Data fetched:
//  - Step count: today's cumulative steps
//  - Sleep analysis: last night's total asleep and in-bed durations
//  - Resting heart rate: most recent sample
//

import Foundation
import HealthKit
import os.log

@MainActor @Observable
final class HealthService {

    // MARK: - Published State

    /// Today's step count (nil if unavailable or not yet fetched)
    private(set) var dailyStepCount: Int?

    /// Last night's total asleep duration in minutes (nil if unavailable)
    private(set) var sleepDurationMinutes: Double?

    /// Last night's total in-bed duration in minutes (nil if unavailable)
    private(set) var sleepInBedMinutes: Double?

    /// Most recent resting heart rate in BPM (nil if unavailable)
    private(set) var restingHeartRate: Int?

    /// Whether a fetch is in progress
    private(set) var isFetching = false

    // MARK: - Private

    private let healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    private static let lastFetchDateKey = "HealthService.lastFetchDate"

    // MARK: - Public API

    /// Fetch health data (steps, sleep, resting HR) if we haven't already fetched today.
    /// Writes results to the provided DailyLog for persistence.
    /// Gracefully no-ops on simulator or if authorization is denied.
    func fetchHealthDataIfNeeded(for dailyLog: DailyLog?) async {
        guard !isFetching else { return }
        guard let healthStore else {
            TerrainLogger.health.info("HealthKit unavailable — skipping health data fetch")
            // Populate from log if available
            populateFromLog(dailyLog)
            return
        }

        guard shouldFetchToday() else {
            // Already fetched today — populate from log
            populateFromLog(dailyLog)
            return
        }

        isFetching = true
        defer { isFetching = false }

        // Build the set of types we want to read
        var readTypes: Set<HKObjectType> = []

        if let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            readTypes.insert(stepType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            readTypes.insert(sleepType)
        }
        if let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            readTypes.insert(restingHRType)
        }

        guard !readTypes.isEmpty else { return }

        // Request authorization for all types at once
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        } catch {
            TerrainLogger.health.error("HealthKit authorization failed: \(error.localizedDescription)")
            return
        }

        // Fetch all data concurrently — each fetch handles its own errors
        // so one failure doesn't block the others
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await self.fetchStepCount(healthStore: healthStore, dailyLog: dailyLog)
            }
            group.addTask { @MainActor in
                await self.fetchSleepAnalysis(healthStore: healthStore, dailyLog: dailyLog)
            }
            group.addTask { @MainActor in
                await self.fetchRestingHeartRate(healthStore: healthStore, dailyLog: dailyLog)
            }
        }

        markFetchedToday()
    }

    // MARK: - Step Count

    private func fetchStepCount(healthStore: HKHealthStore, dailyLog: DailyLog?) async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        do {
            let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let count = Int(result?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    continuation.resume(returning: count)
                }
                healthStore.execute(query)
            }

            dailyStepCount = steps

            if let log = dailyLog {
                log.stepCount = steps
                log.updatedAt = Date()
            }

            TerrainLogger.health.info("Steps fetched: \(steps)")
        } catch {
            TerrainLogger.health.error("Step count query failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sleep Analysis

    /// Queries last night's sleep data from HealthKit.
    ///
    /// Apple Watch records sleep in stages (asleepCore, asleepDeep, asleepREM, inBed).
    /// iPhone-only users get a simpler asleepUnspecified category.
    /// We calculate:
    /// - sleepDurationMinutes: total time actually asleep (all asleep stages combined)
    /// - sleepInBedMinutes: total time in bed (includes awake time in bed)
    private func fetchSleepAnalysis(healthStore: HKHealthStore, dailyLog: DailyLog?) async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        // Look for sleep that ended between yesterday 5PM and now.
        // Sleep sessions typically span midnight, so we cast a wide net and
        // rely on the sample's value to distinguish in-bed from asleep.
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        // Look back to yesterday at 5PM to capture evening sleep onset
        guard let sleepWindowStart = calendar.date(byAdding: .hour, value: -7, to: startOfToday) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: sleepWindowStart, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let categorySamples = (results as? [HKCategorySample]) ?? []
                    continuation.resume(returning: categorySamples)
                }
                healthStore.execute(query)
            }

            guard !samples.isEmpty else {
                TerrainLogger.health.info("No sleep data found for last night")
                return
            }

            // Accumulate durations by category
            var totalAsleepSeconds: TimeInterval = 0
            var totalInBedSeconds: TimeInterval = 0

            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { continue }

                switch value {
                case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified:
                    // Actual sleeping time
                    totalAsleepSeconds += duration
                    totalInBedSeconds += duration
                case .inBed:
                    // In bed but not necessarily asleep (includes falling asleep, waking)
                    totalInBedSeconds += duration
                case .awake:
                    // Awake period during the night — counts as in-bed time
                    totalInBedSeconds += duration
                @unknown default:
                    // Future sleep categories — conservatively count as in-bed
                    totalInBedSeconds += duration
                }
            }

            let asleepMinutes = totalAsleepSeconds / 60.0
            let inBedMinutes = totalInBedSeconds / 60.0

            // Only set if we got meaningful data (at least 30 min of sleep)
            if asleepMinutes >= 30 {
                sleepDurationMinutes = asleepMinutes
                sleepInBedMinutes = inBedMinutes

                if let log = dailyLog {
                    log.sleepDurationMinutes = asleepMinutes
                    log.sleepInBedMinutes = inBedMinutes
                    log.updatedAt = Date()
                }

                TerrainLogger.health.info("Sleep fetched: \(String(format: "%.0f", asleepMinutes)) min asleep, \(String(format: "%.0f", inBedMinutes)) min in bed")
            } else {
                TerrainLogger.health.info("Sleep data too short (\(String(format: "%.0f", asleepMinutes)) min) — ignoring")
            }

        } catch {
            TerrainLogger.health.error("Sleep analysis query failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Resting Heart Rate

    /// Queries the most recent resting heart rate sample from HealthKit.
    /// Resting HR is typically computed by Apple Watch overnight, so there
    /// may be only one sample per day (or none if user lacks a Watch).
    private func fetchRestingHeartRate(healthStore: HKHealthStore, dailyLog: DailyLog?) async {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }

        // Look for samples from the last 24 hours
        let now = Date()
        guard let dayAgo = Calendar.current.date(byAdding: .hour, value: -24, to: now) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: dayAgo, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        do {
            let bpm = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Int?, Error>) in
                let query = HKSampleQuery(
                    sampleType: restingHRType,
                    predicate: predicate,
                    limit: 1,
                    sortDescriptors: [sortDescriptor]
                ) { _, results, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let sample = results?.first as? HKQuantitySample else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let heartRate = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())))
                    continuation.resume(returning: heartRate)
                }
                healthStore.execute(query)
            }

            if let bpm {
                restingHeartRate = bpm

                if let log = dailyLog {
                    log.restingHeartRate = bpm
                    log.updatedAt = Date()
                }

                TerrainLogger.health.info("Resting heart rate fetched: \(bpm) BPM")
            } else {
                TerrainLogger.health.info("No resting heart rate data found")
            }

        } catch {
            TerrainLogger.health.error("Resting heart rate query failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// Populates published properties from a cached DailyLog (used when
    /// HealthKit is unavailable or we've already fetched today).
    private func populateFromLog(_ log: DailyLog?) {
        dailyStepCount = log?.stepCount
        sleepDurationMinutes = log?.sleepDurationMinutes
        sleepInBedMinutes = log?.sleepInBedMinutes
        restingHeartRate = log?.restingHeartRate
    }

    // MARK: - Date Gate

    private func shouldFetchToday() -> Bool {
        guard let lastDate = UserDefaults.standard.object(forKey: Self.lastFetchDateKey) as? Date else {
            return true
        }
        return !Calendar.current.isDateInToday(lastDate)
    }

    private func markFetchedToday() {
        UserDefaults.standard.set(Date(), forKey: Self.lastFetchDateKey)
    }
}
