//
//  SupabaseSyncService.swift
//  Terrain
//
//  Bidirectional sync between local SwiftData and Supabase.
//  Think of this as a postal service: it picks up local changes (letters)
//  and delivers them to the cloud, then picks up any cloud changes and
//  delivers them back to the device. Last-write-wins via updatedAt timestamps.
//

import Foundation
import SwiftData
import Supabase

/// Handles authentication state and bidirectional data sync with Supabase.
///
/// The sync strategy is simple: **last-write-wins**.
/// Each record carries an `updatedAt` timestamp. When syncing, whichever
/// copy (local or remote) has the more recent timestamp is the winner.
/// This is the same strategy Google Docs uses for offline edits.
@MainActor
@Observable
final class SupabaseSyncService {

    // MARK: - Public State

    /// Whether the user is currently signed in
    var isAuthenticated: Bool { currentUserId != nil }

    /// The signed-in user's Supabase UUID (nil if signed out or local-only)
    private(set) var currentUserId: UUID?

    /// The signed-in user's email (nil if signed out or used Apple Sign In without email)
    private(set) var currentUserEmail: String?

    /// Last sync error (nil if last sync succeeded)
    private(set) var lastSyncError: Error?

    /// Whether a sync is currently in progress
    private(set) var isSyncing = false

    // MARK: - Private

    private let client: SupabaseClient
    private var modelContext: ModelContext?

    /// Timestamp of the last successful sync start — used for debouncing.
    private var lastSyncTime: Date?

    /// Minimum seconds between sync() calls. Prevents rapid-fire syncs
    /// (e.g., repeated foreground/background transitions) from hammering Supabase.
    private let minimumSyncInterval: TimeInterval = 30

    // MARK: - Init

    /// Reads Supabase credentials from Supabase.plist bundled in the app.
    /// If the plist is missing or malformed, sync is disabled gracefully.
    init() {
        let url: URL
        let key: String

        if let plistPath = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
           let plistURL = dict["SUPABASE_URL"] as? String,
           let plistKey = dict["SUPABASE_ANON_KEY"] as? String,
           let parsedURL = URL(string: plistURL) {
            url = parsedURL
            key = plistKey
        } else {
            TerrainLogger.sync.critical("Supabase.plist missing or malformed — sync will be unavailable")
            url = URL(string: "https://invalid.supabase.co")!
            key = ""
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    /// Attach the SwiftData model context (called from TerrainApp on launch)
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task { await restoreSession() }
    }

    // MARK: - Auth

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(email: email, password: password)
        currentUserId = session.user.id
        currentUserEmail = session.user.email
    }

    /// Sign up with email and password
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(email: email, password: password)
        currentUserId = response.user.id
        currentUserEmail = response.user.email
    }

    /// Sign in with Apple ID token
    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        currentUserId = session.user.id
        currentUserEmail = session.user.email
    }

    /// Sign out and optionally clear all local user data.
    ///
    /// - Parameter clearLocalData: When `true` (default), deletes all SwiftData user
    ///   records so the next person signing in on this device cannot see the previous
    ///   user's health data. Cloud data is unaffected — signing back in will re-sync.
    func signOut(clearLocalData: Bool = true) async throws {
        try await client.auth.signOut()

        if clearLocalData, let context = modelContext {
            do {
                for profile in try context.fetch(FetchDescriptor<UserProfile>()) { context.delete(profile) }
                for log in try context.fetch(FetchDescriptor<DailyLog>()) { context.delete(log) }
                for record in try context.fetch(FetchDescriptor<ProgressRecord>()) { context.delete(record) }
                for item in try context.fetch(FetchDescriptor<UserCabinet>()) { context.delete(item) }
                for enrollment in try context.fetch(FetchDescriptor<ProgramEnrollment>()) { context.delete(enrollment) }
                try context.save()
                TerrainLogger.sync.info("Local user data cleared on sign-out")
            } catch {
                TerrainLogger.sync.error("Failed to clear local data on sign-out: \(error)")
            }
        }

        currentUserId = nil
        currentUserEmail = nil
        lastSyncTime = nil
    }

    /// Restore session from stored token on app launch
    private func restoreSession() async {
        do {
            let session = try await client.auth.session
            currentUserId = session.user.id
            currentUserEmail = session.user.email
        } catch {
            currentUserId = nil
            currentUserEmail = nil
        }
    }

    // MARK: - Sync

    /// Full bidirectional sync: push local changes up, pull remote changes down.
    /// Call this on app launch, after significant writes, or on app resume.
    ///
    /// Each table syncs independently — a failure in `daily_logs` won't block
    /// `user_profiles` from syncing. Think of it like five separate postal
    /// deliveries: if the "logs" truck breaks down, the other four still deliver.
    ///
    /// - Parameter force: Bypass the debounce timer (use after auth or quiz changes).
    func sync(force: Bool = false) async {
        guard let userId = currentUserId, let context = modelContext else { return }
        guard !isSyncing else { return }

        // Debounce: skip if last sync was less than 30 seconds ago (unless forced)
        if !force, let lastSync = lastSyncTime,
           Date().timeIntervalSince(lastSync) < minimumSyncInterval {
            TerrainLogger.sync.info("Sync debounced — \(Int(Date().timeIntervalSince(lastSync)))s since last sync")
            return
        }

        isSyncing = true
        lastSyncError = nil
        defer {
            isSyncing = false
            lastSyncTime = Date()
        }

        let errors = await syncAllTables(userId: userId, context: context)

        if let firstError = errors.values.first {
            lastSyncError = firstError
            TerrainLogger.sync.error("Sync completed with \(errors.count) table error(s): \(errors.keys.joined(separator: ", "))")
        }
    }

    /// Push-only sync for a quick save after a user action.
    /// Same per-table isolation as `sync()`.
    func syncUp() async {
        guard let userId = currentUserId, let context = modelContext else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        let errors = await syncAllTables(userId: userId, context: context)

        if let firstError = errors.values.first {
            lastSyncError = firstError
            TerrainLogger.sync.error("SyncUp completed with \(errors.count) table error(s)")
        }
    }

    /// Syncs each table independently, returning a dictionary of table-name → error
    /// for any tables that failed. An empty dictionary means full success.
    private func syncAllTables(userId: UUID, context: ModelContext) async -> [String: Error] {
        var errors: [String: Error] = [:]

        do {
            try await syncUserProfile(userId: userId, context: context)
        } catch {
            errors["user_profiles"] = error
            TerrainLogger.sync.error("Sync user_profiles failed: \(error)")
        }

        do {
            try await syncDailyLogs(userId: userId, context: context)
        } catch {
            errors["daily_logs"] = error
            TerrainLogger.sync.error("Sync daily_logs failed: \(error)")
        }

        do {
            try await syncProgressRecord(userId: userId, context: context)
        } catch {
            errors["progress_records"] = error
            TerrainLogger.sync.error("Sync progress_records failed: \(error)")
        }

        do {
            try await syncCabinet(userId: userId, context: context)
        } catch {
            errors["user_cabinets"] = error
            TerrainLogger.sync.error("Sync user_cabinets failed: \(error)")
        }

        do {
            try await syncEnrollments(userId: userId, context: context)
        } catch {
            errors["program_enrollments"] = error
            TerrainLogger.sync.error("Sync program_enrollments failed: \(error)")
        }

        return errors
    }

    // MARK: - User Profile Sync

    private func syncUserProfile(userId: UUID, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<UserProfile>()
        let localProfiles = try context.fetch(descriptor)
        guard let local = localProfiles.first else { return }

        // Fetch remote
        let remoteRows: [UserProfileRow] = try await client
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if let remote = remoteRows.first {
            // Compare timestamps — last write wins
            if local.updatedAt > remote.updatedAtDate {
                // Local is newer → push up
                try await client
                    .from("user_profiles")
                    .update(local.toRow(userId: userId))
                    .eq("id", value: remote.id.uuidString)
                    .execute()
            } else if remote.updatedAtDate > local.updatedAt {
                // Remote is newer → pull down
                remote.apply(to: local)
                try context.save()
            }
        } else {
            // No remote record — create one
            try await client
                .from("user_profiles")
                .insert(local.toRow(userId: userId))
                .execute()
        }
    }

    // MARK: - Daily Logs Sync

    private func syncDailyLogs(userId: UUID, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let localLogs = try context.fetch(descriptor)

        // Only sync the last 30 days to avoid large transfers
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentLogs = localLogs.filter { $0.date >= cutoff }

        let remoteRows: [DailyLogRow] = try await client
            .from("daily_logs")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("date", value: SyncDateFormatters.iso8601Formatter.string(from: cutoff))
            .execute()
            .value

        let remoteByDate = Dictionary(grouping: remoteRows, by: { $0.date })

        for local in recentLogs {
            let dateKey = SyncDateFormatters.dateString(from: local.date)
            if let remote = remoteByDate[dateKey]?.first {
                if local.updatedAt > remote.updatedAtDate {
                    try await client
                        .from("daily_logs")
                        .update(local.toRow(userId: userId))
                        .eq("id", value: remote.id.uuidString)
                        .execute()
                } else if remote.updatedAtDate > local.updatedAt {
                    remote.apply(to: local)
                }
            } else {
                try await client
                    .from("daily_logs")
                    .insert(local.toRow(userId: userId))
                    .execute()
            }
        }

        // Pull logs that exist remotely but not locally
        let localDates = Set(recentLogs.map { SyncDateFormatters.dateString(from: $0.date) })
        for (dateKey, rows) in remoteByDate {
            if !localDates.contains(dateKey), let remote = rows.first {
                let newLog = remote.toModel()
                context.insert(newLog)
            }
        }

        try context.save()
    }

    // MARK: - Progress Record Sync

    private func syncProgressRecord(userId: UUID, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<ProgressRecord>()
        let localRecords = try context.fetch(descriptor)
        guard let local = localRecords.first else { return }

        let remoteRows: [ProgressRecordRow] = try await client
            .from("progress_records")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        if let remote = remoteRows.first {
            if local.updatedAt > remote.updatedAtDate {
                try await client
                    .from("progress_records")
                    .update(local.toRow(userId: userId))
                    .eq("id", value: remote.id.uuidString)
                    .execute()
            } else if remote.updatedAtDate > local.updatedAt {
                remote.apply(to: local)
                try context.save()
            }
        } else {
            try await client
                .from("progress_records")
                .insert(local.toRow(userId: userId))
                .execute()
        }
    }

    // MARK: - Cabinet Sync

    private func syncCabinet(userId: UUID, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<UserCabinet>()
        let localItems = try context.fetch(descriptor)

        let remoteRows: [UserCabinetRow] = try await client
            .from("user_cabinets")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let remoteByIngredient = Dictionary(
            remoteRows.map { ($0.ingredientId, $0) },
            uniquingKeysWith: { _, latest in latest }
        )
        let localByIngredient = Dictionary(
            localItems.map { ($0.ingredientId, $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        for local in localItems {
            if let remote = remoteByIngredient[local.ingredientId] {
                // Both exist — resolve conflict using lastUsedAt (or addedAt as fallback)
                let localTimestamp = local.lastUsedAt ?? local.addedAt
                let remoteTimestamp = remote.lastUsedAtDate ?? remote.addedAtDate

                if localTimestamp > remoteTimestamp {
                    // Local is newer — push isStaple and lastUsedAt
                    try await client
                        .from("user_cabinets")
                        .update(UserCabinetRow(
                            id: remote.id,
                            userId: userId,
                            ingredientId: local.ingredientId,
                            addedAt: SyncDateFormatters.iso8601Formatter.string(from: local.addedAt),
                            isStaple: local.isStaple,
                            lastUsedAt: local.lastUsedAt.map { SyncDateFormatters.iso8601Formatter.string(from: $0) }
                        ))
                        .eq("id", value: remote.id.uuidString)
                        .execute()
                } else if remoteTimestamp > localTimestamp {
                    // Remote is newer — pull isStaple and lastUsedAt
                    local.isStaple = remote.isStaple
                    local.lastUsedAt = remote.lastUsedAtDate
                }
                // Equal timestamps: no-op (already in sync)
            } else {
                // Not in remote — push
                try await client
                    .from("user_cabinets")
                    .insert(UserCabinetRow(
                        id: UUID(),
                        userId: userId,
                        ingredientId: local.ingredientId,
                        addedAt: SyncDateFormatters.iso8601Formatter.string(from: local.addedAt),
                        isStaple: local.isStaple,
                        lastUsedAt: local.lastUsedAt.map { SyncDateFormatters.iso8601Formatter.string(from: $0) }
                    ))
                    .execute()
            }
        }

        // Pull remote items not in local
        for remote in remoteRows {
            if localByIngredient[remote.ingredientId] == nil {
                let item = UserCabinet(ingredientId: remote.ingredientId)
                item.isStaple = remote.isStaple
                item.lastUsedAt = remote.lastUsedAtDate
                context.insert(item)
            }
        }

        try context.save()
    }

    // MARK: - Enrollments Sync

    private func syncEnrollments(userId: UUID, context: ModelContext) async throws {
        let descriptor = FetchDescriptor<ProgramEnrollment>()
        let localEnrollments = try context.fetch(descriptor)

        let remoteRows: [ProgramEnrollmentRow] = try await client
            .from("program_enrollments")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        let remoteByProgram = Dictionary(
            remoteRows.map { ($0.programId, $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        for local in localEnrollments {
            if let remote = remoteByProgram[local.programId] {
                if local.updatedAt > remote.updatedAtDate {
                    try await client
                        .from("program_enrollments")
                        .update(local.toRow(userId: userId))
                        .eq("id", value: remote.id.uuidString)
                        .execute()
                } else if remote.updatedAtDate > local.updatedAt {
                    remote.apply(to: local)
                }
            } else {
                try await client
                    .from("program_enrollments")
                    .insert(local.toRow(userId: userId))
                    .execute()
            }
        }

        // Pull remote enrollments not in local
        let localPrograms = Set(localEnrollments.map { $0.programId })
        for remote in remoteRows {
            if !localPrograms.contains(remote.programId) {
                let enrollment = remote.toModel()
                context.insert(enrollment)
            }
        }

        try context.save()
    }

}

// MARK: - Row Types (Codable DTOs for Supabase)

/// These are thin Codable wrappers that map between SwiftData models
/// and the Supabase table columns. Think of them as translation cards
/// between two languages (Swift objects and Postgres rows).

struct UserProfileRow: Codable {
    let id: UUID
    let userId: UUID
    var terrainProfileId: String?
    var terrainModifier: String?
    var goals: [String]
    var quizResponses: [String: String]  // questionId → optionId
    var notificationPreferences: NotificationPrefsDTO
    // Terrain vector axes
    var coldHeat: Int
    var defExcess: Int
    var dampDry: Int
    var qiStagnation: Int
    var shenUnsettled: Int
    // Quiz flags
    var hasReflux: Bool
    var hasLooseStool: Bool
    var hasConstipation: Bool
    var hasStickyStool: Bool
    var hasNightSweats: Bool
    var wakesThirstyHot: Bool
    // Safety
    var safetyPreferences: SafetyPreferencesDTO
    // Quiz metadata
    var quizVersion: Int
    var lastQuizCompletedAt: String?
    // User identity & lifestyle (previously local-only)
    var displayName: String?
    var alcoholFrequency: String?
    var smokingStatus: String?
    // Demographics
    var age: Int?
    var gender: String?
    var ethnicity: String?
    // Phase 14 TCM personalization
    var hydrationPattern: String?
    var sweatPattern: String?
    // Pulse check-in
    var lastPulseCheckInDate: String?
    var createdAt: String
    var updatedAt: String

    /// Parsed updatedAt timestamp
    var updatedAtDate: Date {
        SyncDateFormatters.parseTimestamp(updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case terrainProfileId = "terrain_profile_id"
        case terrainModifier = "terrain_modifier"
        case goals
        case quizResponses = "quiz_responses"
        case notificationPreferences = "notification_preferences"
        case coldHeat = "cold_heat"
        case defExcess = "def_excess"
        case dampDry = "damp_dry"
        case qiStagnation = "qi_stagnation"
        case shenUnsettled = "shen_unsettled"
        case hasReflux = "has_reflux"
        case hasLooseStool = "has_loose_stool"
        case hasConstipation = "has_constipation"
        case hasStickyStool = "has_sticky_stool"
        case hasNightSweats = "has_night_sweats"
        case wakesThirstyHot = "wakes_thirsty_hot"
        case safetyPreferences = "safety_preferences"
        case quizVersion = "quiz_version"
        case lastQuizCompletedAt = "last_quiz_completed_at"
        case displayName = "display_name"
        case alcoholFrequency = "alcohol_frequency"
        case smokingStatus = "smoking_status"
        case age
        case gender
        case ethnicity
        case hydrationPattern = "hydration_pattern"
        case sweatPattern = "sweat_pattern"
        case lastPulseCheckInDate = "last_pulse_check_in_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Apply remote values to a local UserProfile
    func apply(to profile: UserProfile) {
        profile.terrainProfileId = terrainProfileId
        profile.terrainModifier = terrainModifier
        profile.goals = goals.compactMap { Goal(rawValue: $0) }
        profile.notificationsEnabled = notificationPreferences.enabled
        // Terrain vector
        profile.coldHeat = coldHeat
        profile.defExcess = defExcess
        profile.dampDry = dampDry
        profile.qiStagnation = qiStagnation
        profile.shenUnsettled = shenUnsettled
        // Quiz flags
        profile.hasReflux = hasReflux
        profile.hasLooseStool = hasLooseStool
        profile.hasConstipation = hasConstipation
        profile.hasStickyStool = hasStickyStool
        profile.hasNightSweats = hasNightSweats
        profile.wakesThirstyHot = wakesThirstyHot
        // Safety
        profile.safetyPreferences = safetyPreferences.toModel()
        // Quiz metadata
        profile.quizVersion = quizVersion
        if let dateString = lastQuizCompletedAt {
            profile.lastQuizCompletedAt = SyncDateFormatters.iso8601Formatter.date(from: dateString)
        }
        // User identity & lifestyle
        profile.displayName = displayName
        profile.alcoholFrequency = alcoholFrequency
        profile.smokingStatus = smokingStatus
        // Demographics
        profile.age = age
        profile.gender = gender
        profile.ethnicity = ethnicity
        // Phase 14 TCM personalization
        profile.hydrationPattern = hydrationPattern.flatMap { HydrationPattern(rawValue: $0) }
        profile.sweatPattern = sweatPattern.flatMap { SweatPattern(rawValue: $0) }
        // Pulse check-in
        if let dateString = lastPulseCheckInDate {
            profile.lastPulseCheckInDate = SyncDateFormatters.iso8601Formatter.date(from: dateString)
        }
        profile.updatedAt = updatedAtDate
    }

    private static let iso8601Formatter = ISO8601DateFormatter()
}

/// Codable DTO for SafetyPreferences to/from Supabase JSON column
struct SafetyPreferencesDTO: Codable {
    var isPregnant: Bool = false
    var isBreastfeeding: Bool = false
    var hasGerd: Bool = false
    var takesBloodThinners: Bool = false
    var takesBpMeds: Bool = false
    var takesThyroidMeds: Bool = false
    var takesDiabetesMeds: Bool = false
    var avoidsCaffeine: Bool = false
    var hasHistamineIntolerance: Bool = false

    func toModel() -> SafetyPreferences {
        var prefs = SafetyPreferences()
        prefs.isPregnant = isPregnant
        prefs.isBreastfeeding = isBreastfeeding
        prefs.hasGerd = hasGerd
        prefs.takesBloodThinners = takesBloodThinners
        prefs.takesBpMeds = takesBpMeds
        prefs.takesThyroidMeds = takesThyroidMeds
        prefs.takesDiabetesMeds = takesDiabetesMeds
        prefs.avoidsCaffeine = avoidsCaffeine
        prefs.hasHistamineIntolerance = hasHistamineIntolerance
        return prefs
    }

    init(from model: SafetyPreferences) {
        self.isPregnant = model.isPregnant
        self.isBreastfeeding = model.isBreastfeeding
        self.hasGerd = model.hasGerd
        self.takesBloodThinners = model.takesBloodThinners
        self.takesBpMeds = model.takesBpMeds
        self.takesThyroidMeds = model.takesThyroidMeds
        self.takesDiabetesMeds = model.takesDiabetesMeds
        self.avoidsCaffeine = model.avoidsCaffeine
        self.hasHistamineIntolerance = model.hasHistamineIntolerance
    }

    init() {}

    // Codable conformance uses default synthesis
}

struct NotificationPrefsDTO: Codable {
    var enabled: Bool
    var morningTime: String?
    var eveningTime: String?
}

struct DailyLogRow: Codable {
    let id: UUID
    let userId: UUID
    var date: String
    var symptoms: [String]
    var symptomOnset: String?
    var energyLevel: String?
    var quickSymptoms: [String]
    var completedRoutineIds: [String]
    var completedMovementIds: [String]
    var routineLevel: String?
    var routineFeedback: [RoutineFeedbackDTO]
    var quickFixCompletionTimes: [String: String]
    var notes: String?
    // Previously local-only fields — now synced
    var moodRating: Int?
    var weatherCondition: String?
    var temperatureCelsius: Double?
    var stepCount: Int?
    var microActionCompletedAt: String?
    // TCM diagnostic signals (Phase 13)
    var sleepQuality: String?
    var dominantEmotion: String?
    var thermalFeeling: String?
    var digestiveState: DigestiveStateDTO?
    // HealthKit cached data (Phase 14)
    var sleepDurationMinutes: Double?
    var sleepInBedMinutes: Double?
    var restingHeartRate: Int?
    // Phase 14 TCM personalization
    var cyclePhase: String?
    var symptomQuality: String?
    var createdAt: String
    var updatedAt: String

    /// Parsed createdAt timestamp
    var createdAtDate: Date {
        SyncDateFormatters.parseTimestamp(createdAt)
    }

    /// Parsed updatedAt timestamp
    var updatedAtDate: Date {
        SyncDateFormatters.parseTimestamp(updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case symptoms
        case symptomOnset = "symptom_onset"
        case energyLevel = "energy_level"
        case quickSymptoms = "quick_symptoms"
        case completedRoutineIds = "completed_routine_ids"
        case completedMovementIds = "completed_movement_ids"
        case routineLevel = "routine_level"
        case routineFeedback = "routine_feedback"
        case quickFixCompletionTimes = "quick_fix_completion_times"
        case notes
        case moodRating = "mood_rating"
        case weatherCondition = "weather_condition"
        case temperatureCelsius = "temperature_celsius"
        case stepCount = "step_count"
        case microActionCompletedAt = "micro_action_completed_at"
        case sleepQuality = "sleep_quality"
        case dominantEmotion = "dominant_emotion"
        case thermalFeeling = "thermal_feeling"
        case digestiveState = "digestive_state"
        case sleepDurationMinutes = "sleep_duration_minutes"
        case sleepInBedMinutes = "sleep_in_bed_minutes"
        case restingHeartRate = "resting_heart_rate"
        case cyclePhase = "cycle_phase"
        case symptomQuality = "symptom_quality"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Apply remote values to a local DailyLog
    func apply(to log: DailyLog) {
        log.symptoms = symptoms.compactMap { Symptom(rawValue: $0) }
        log.symptomOnset = symptomOnset.flatMap { SymptomOnset(rawValue: $0) }
        log.energyLevel = energyLevel.flatMap { EnergyLevel(rawValue: $0) }
        log.quickSymptoms = quickSymptoms.compactMap { QuickSymptom(rawValue: $0) }
        log.completedRoutineIds = completedRoutineIds
        log.completedMovementIds = completedMovementIds
        log.routineLevel = routineLevel.flatMap { RoutineLevel(rawValue: $0) }
        log.routineFeedback = routineFeedback.map { $0.toModel() }
        // Parse quickFixCompletionTimes ISO8601 strings back to Dates
        var parsedTimes: [String: Date] = [:]
        let isoFormatter = SyncDateFormatters.iso8601Formatter
        for (key, value) in quickFixCompletionTimes {
            if let date = isoFormatter.date(from: value) {
                parsedTimes[key] = date
            }
        }
        log.quickFixCompletionTimes = parsedTimes
        log.notes = notes
        // Previously local-only fields
        log.moodRating = moodRating
        log.weatherCondition = weatherCondition
        log.temperatureCelsius = temperatureCelsius
        log.stepCount = stepCount
        if let isoString = microActionCompletedAt {
            log.microActionCompletedAt = SyncDateFormatters.iso8601Formatter.date(from: isoString)
        }
        // TCM diagnostic signals
        log.sleepQuality = sleepQuality.flatMap { SleepQuality(rawValue: $0) }
        log.dominantEmotion = dominantEmotion.flatMap { DominantEmotion(rawValue: $0) }
        log.thermalFeeling = thermalFeeling.flatMap { ThermalFeeling(rawValue: $0) }
        log.digestiveState = digestiveState?.toModel()
        // HealthKit cached data
        log.sleepDurationMinutes = sleepDurationMinutes
        log.sleepInBedMinutes = sleepInBedMinutes
        log.restingHeartRate = restingHeartRate
        // Phase 14 TCM personalization
        log.cyclePhase = cyclePhase.flatMap { CyclePhase(rawValue: $0) }
        log.symptomQuality = symptomQuality.flatMap { SymptomQuality(rawValue: $0) }
        log.updatedAt = updatedAtDate
    }

    /// Create a new DailyLog model from this row
    func toModel() -> DailyLog {
        let formatter = SyncDateFormatters.dateFormatter
        let logDate = formatter.date(from: date) ?? Date()

        // Parse quickFixCompletionTimes
        var parsedTimes: [String: Date] = [:]
        let isoFormatter = SyncDateFormatters.iso8601Formatter
        for (key, value) in quickFixCompletionTimes {
            if let date = isoFormatter.date(from: value) {
                parsedTimes[key] = date
            }
        }

        let log = DailyLog(
            date: logDate,
            symptoms: symptoms.compactMap { Symptom(rawValue: $0) },
            symptomOnset: symptomOnset.flatMap { SymptomOnset(rawValue: $0) },
            energyLevel: energyLevel.flatMap { EnergyLevel(rawValue: $0) },
            quickSymptoms: quickSymptoms.compactMap { QuickSymptom(rawValue: $0) },
            completedRoutineIds: completedRoutineIds,
            completedMovementIds: completedMovementIds,
            routineLevel: routineLevel.flatMap { RoutineLevel(rawValue: $0) },
            routineFeedback: routineFeedback.map { $0.toModel() },
            quickFixCompletionTimes: parsedTimes,
            moodRating: moodRating,
            weatherCondition: weatherCondition,
            temperatureCelsius: temperatureCelsius,
            notes: notes
        )
        // Fields not in DailyLog init — set after construction
        log.stepCount = stepCount
        if let isoString = microActionCompletedAt {
            log.microActionCompletedAt = SyncDateFormatters.iso8601Formatter.date(from: isoString)
        }
        // TCM diagnostic signals
        log.sleepQuality = sleepQuality.flatMap { SleepQuality(rawValue: $0) }
        log.dominantEmotion = dominantEmotion.flatMap { DominantEmotion(rawValue: $0) }
        log.thermalFeeling = thermalFeeling.flatMap { ThermalFeeling(rawValue: $0) }
        log.digestiveState = digestiveState?.toModel()
        // HealthKit cached data
        log.sleepDurationMinutes = sleepDurationMinutes
        log.sleepInBedMinutes = sleepInBedMinutes
        log.restingHeartRate = restingHeartRate
        // Phase 14 TCM personalization
        log.cyclePhase = cyclePhase.flatMap { CyclePhase(rawValue: $0) }
        log.symptomQuality = symptomQuality.flatMap { SymptomQuality(rawValue: $0) }
        // Preserve remote timestamp
        log.updatedAt = updatedAtDate
        return log
    }
}

/// Codable DTO for DigestiveState to/from Supabase JSON column
struct DigestiveStateDTO: Codable {
    var appetiteLevel: String
    var stoolQuality: String

    init(appetiteLevel: String = "normal", stoolQuality: String = "normal") {
        self.appetiteLevel = appetiteLevel
        self.stoolQuality = stoolQuality
    }

    init(from model: DigestiveState) {
        self.appetiteLevel = model.appetiteLevel.rawValue
        self.stoolQuality = model.stoolQuality.rawValue
    }

    func toModel() -> DigestiveState {
        DigestiveState(
            appetiteLevel: AppetiteLevel(rawValue: appetiteLevel) ?? .normal,
            stoolQuality: StoolQuality(rawValue: stoolQuality) ?? .normal
        )
    }
}

struct RoutineFeedbackDTO: Codable {
    var routineOrMovementId: String
    var feedback: String
    var timestamp: String

    enum CodingKeys: String, CodingKey {
        case routineOrMovementId = "routine_or_movement_id"
        case feedback
        case timestamp
    }

    func toModel() -> RoutineFeedbackEntry {
        let parsedTimestamp = SyncDateFormatters.iso8601Formatter.date(from: timestamp) ?? Date()
        return RoutineFeedbackEntry(
            routineOrMovementId: routineOrMovementId,
            feedback: PostRoutineFeedback(rawValue: feedback) ?? .notSure,
            timestamp: parsedTimestamp
        )
    }
}

struct ProgressRecordRow: Codable {
    let id: UUID
    let userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var lastCompletionDate: String?
    var monthlyCompletions: [String: Int]
    var createdAt: String
    var updatedAt: String

    /// Parsed updatedAt timestamp
    var updatedAtDate: Date {
        SyncDateFormatters.parseTimestamp(updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalCompletions = "total_completions"
        case lastCompletionDate = "last_completion_date"
        case monthlyCompletions = "monthly_completions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func apply(to record: ProgressRecord) {
        record.currentStreak = currentStreak
        record.longestStreak = longestStreak
        record.totalCompletions = totalCompletions
        if let dateString = lastCompletionDate {
            record.lastCompletionDate = SyncDateFormatters.dateFormatter.date(from: dateString)
        }
        record.monthlyCompletions = monthlyCompletions
        record.updatedAt = updatedAtDate
    }
}

struct UserCabinetRow: Codable {
    let id: UUID
    let userId: UUID
    var ingredientId: String
    var addedAt: String
    var isStaple: Bool
    var lastUsedAt: String?

    /// Parsed addedAt timestamp
    var addedAtDate: Date {
        SyncDateFormatters.parseTimestamp(addedAt)
    }

    /// Parsed lastUsedAt timestamp
    var lastUsedAtDate: Date? {
        lastUsedAt.map { SyncDateFormatters.parseTimestamp($0) }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ingredientId = "ingredient_id"
        case addedAt = "added_at"
        case isStaple = "is_staple"
        case lastUsedAt = "last_used_at"
    }
}

struct ProgramEnrollmentRow: Codable {
    let id: UUID
    let userId: UUID
    var programId: String
    var startDate: String
    var currentDay: Int
    var dayCompletions: [ProgramDayCompletion]
    var isActive: Bool
    var completedAt: String?
    var createdAt: String
    var updatedAt: String

    /// Parsed completedAt timestamp
    var completedAtDate: Date? {
        completedAt.map { SyncDateFormatters.parseTimestamp($0) }
    }

    /// Parsed updatedAt timestamp
    var updatedAtDate: Date {
        SyncDateFormatters.parseTimestamp(updatedAt)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case programId = "program_id"
        case startDate = "start_date"
        case currentDay = "current_day"
        case dayCompletions = "day_completions"
        case isActive = "is_active"
        case completedAt = "completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func apply(to enrollment: ProgramEnrollment) {
        enrollment.currentDay = currentDay
        enrollment.dayCompletions = dayCompletions
        enrollment.isActive = isActive
        enrollment.completedAt = completedAtDate
        enrollment.updatedAt = updatedAtDate
    }

    func toModel() -> ProgramEnrollment {
        let formatter = SyncDateFormatters.dateFormatter
        let start = formatter.date(from: startDate) ?? Date()

        return ProgramEnrollment(
            programId: programId,
            startDate: start,
            currentDay: currentDay,
            dayCompletions: dayCompletions,
            isActive: isActive,
            completedAt: completedAtDate
        )
    }
}

// MARK: - Model → Row Conversions

extension UserProfile {
    func toRow(userId: UUID) -> UserProfileRow {
        let isoFormatter = SyncDateFormatters.iso8601Formatter
        return UserProfileRow(
            id: id,
            userId: userId,
            terrainProfileId: terrainProfileId,
            terrainModifier: terrainModifier,
            goals: goals.map { $0.rawValue },
            quizResponses: Dictionary(
                (quizResponses ?? []).map { ($0.questionId, $0.optionId) },
                uniquingKeysWith: { _, latest in latest }
            ),
            notificationPreferences: NotificationPrefsDTO(
                enabled: notificationsEnabled,
                morningTime: morningNotificationTime.map { isoFormatter.string(from: $0) },
                eveningTime: eveningNotificationTime.map { isoFormatter.string(from: $0) }
            ),
            coldHeat: coldHeat,
            defExcess: defExcess,
            dampDry: dampDry,
            qiStagnation: qiStagnation,
            shenUnsettled: shenUnsettled,
            hasReflux: hasReflux,
            hasLooseStool: hasLooseStool,
            hasConstipation: hasConstipation,
            hasStickyStool: hasStickyStool,
            hasNightSweats: hasNightSweats,
            wakesThirstyHot: wakesThirstyHot,
            safetyPreferences: SafetyPreferencesDTO(from: safetyPreferences),
            quizVersion: quizVersion,
            lastQuizCompletedAt: lastQuizCompletedAt.map { isoFormatter.string(from: $0) },
            displayName: displayName,
            alcoholFrequency: alcoholFrequency,
            smokingStatus: smokingStatus,
            age: age,
            gender: gender,
            ethnicity: ethnicity,
            hydrationPattern: hydrationPattern?.rawValue,
            sweatPattern: sweatPattern?.rawValue,
            lastPulseCheckInDate: lastPulseCheckInDate.map { isoFormatter.string(from: $0) },
            createdAt: isoFormatter.string(from: createdAt),
            updatedAt: isoFormatter.string(from: updatedAt)
        )
    }
}

extension DailyLog {
    func toRow(userId: UUID) -> DailyLogRow {
        let isoFormatter = SyncDateFormatters.iso8601Formatter
        return DailyLogRow(
            id: id,
            userId: userId,
            date: SyncDateFormatters.dateString(from: date),
            symptoms: symptoms.map { $0.rawValue },
            symptomOnset: symptomOnset?.rawValue,
            energyLevel: energyLevel?.rawValue,
            quickSymptoms: quickSymptoms.map { $0.rawValue },
            completedRoutineIds: completedRoutineIds,
            completedMovementIds: completedMovementIds,
            routineLevel: routineLevel?.rawValue,
            routineFeedback: routineFeedback.map {
                RoutineFeedbackDTO(
                    routineOrMovementId: $0.routineOrMovementId,
                    feedback: $0.feedback.rawValue,
                    timestamp: isoFormatter.string(from: $0.timestamp)
                )
            },
            quickFixCompletionTimes: Dictionary(
                quickFixCompletionTimes.map { ($0.key, isoFormatter.string(from: $0.value)) },
                uniquingKeysWith: { _, latest in latest }
            ),
            notes: notes,
            moodRating: moodRating,
            weatherCondition: weatherCondition,
            temperatureCelsius: temperatureCelsius,
            stepCount: stepCount,
            microActionCompletedAt: microActionCompletedAt.map { isoFormatter.string(from: $0) },
            sleepQuality: sleepQuality?.rawValue,
            dominantEmotion: dominantEmotion?.rawValue,
            thermalFeeling: thermalFeeling?.rawValue,
            digestiveState: digestiveState.map { DigestiveStateDTO(from: $0) },
            sleepDurationMinutes: sleepDurationMinutes,
            sleepInBedMinutes: sleepInBedMinutes,
            restingHeartRate: restingHeartRate,
            cyclePhase: cyclePhase?.rawValue,
            symptomQuality: symptomQuality?.rawValue,
            createdAt: isoFormatter.string(from: createdAt),
            updatedAt: isoFormatter.string(from: updatedAt)
        )
    }
}

extension ProgressRecord {
    func toRow(userId: UUID) -> ProgressRecordRow {
        let isoFormatter = SyncDateFormatters.iso8601Formatter
        return ProgressRecordRow(
            id: id,
            userId: userId,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompletions: totalCompletions,
            lastCompletionDate: lastCompletionDate.map { SyncDateFormatters.dateFormatter.string(from: $0) },
            monthlyCompletions: monthlyCompletions,
            createdAt: isoFormatter.string(from: createdAt),
            updatedAt: isoFormatter.string(from: updatedAt)
        )
    }
}

extension ProgramEnrollment {
    func toRow(userId: UUID) -> ProgramEnrollmentRow {
        let isoFormatter = SyncDateFormatters.iso8601Formatter
        return ProgramEnrollmentRow(
            id: id,
            userId: userId,
            programId: programId,
            startDate: SyncDateFormatters.dateString(from: startDate),
            currentDay: currentDay,
            dayCompletions: dayCompletions,
            isActive: isActive,
            completedAt: completedAt.map { isoFormatter.string(from: $0) },
            createdAt: isoFormatter.string(from: createdAt),
            updatedAt: isoFormatter.string(from: updatedAt)
        )
    }
}

// MARK: - Date Formatters (nonisolated so Row/model extensions can use them)

/// Standalone namespace for date formatters used by sync Row types.
/// Kept outside `SupabaseSyncService` to avoid `@MainActor` isolation,
/// which would block non-actor-isolated `toRow()` extensions.
enum SyncDateFormatters {
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    /// Fallback for strings without fractional seconds
    static let iso8601BasicFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// PostgreSQL timestamp format: "2026-02-05 06:54:06.536161+00"
    static let postgresTimestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZZZZZ"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    /// Fallback PostgreSQL timestamp without fractional seconds
    static let postgresTimestampBasicFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Parse PostgreSQL or ISO8601 timestamp string to Date
    static func parseTimestamp(_ string: String) -> Date {
        // Try ISO8601 with fractional seconds first
        if let date = iso8601Formatter.date(from: string) {
            return date
        }
        // Try ISO8601 basic (no fractional seconds)
        if let date = iso8601BasicFormatter.date(from: string) {
            return date
        }
        // Try PostgreSQL format (space instead of T)
        if let date = postgresTimestampFormatter.date(from: string) {
            return date
        }
        // Try PostgreSQL basic format
        if let date = postgresTimestampBasicFormatter.date(from: string) {
            return date
        }
        // Last resort: return distant past
        return Date.distantPast
    }
}
