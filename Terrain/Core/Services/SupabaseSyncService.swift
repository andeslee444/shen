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

    // MARK: - Init

    /// Reads Supabase credentials from Supabase.plist bundled in the app.
    /// Falls back to hardcoded project values if the plist is missing.
    init() {
        let url: URL
        let key: String

        if let plistPath = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any],
           let plistURL = dict["SUPABASE_URL"] as? String,
           let plistKey = dict["SUPABASE_ANON_KEY"] as? String {
            url = URL(string: plistURL)!
            key = plistKey
        } else {
            // Fallback to project defaults
            url = URL(string: "https://xsxiykrjwzayrhwxwxbv.supabase.co")!
            key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzeGl5a3Jqd3pheXJod3h3eGJ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3NTI0NzksImV4cCI6MjA4NTMyODQ3OX0.XY06FTCJBUa2YjtfV0_Zi1nYI1uHoC4fcfcnxCis5iA"
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

    /// Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        currentUserId = nil
        currentUserEmail = nil
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
    func sync() async {
        guard let userId = currentUserId, let context = modelContext else { return }
        guard !isSyncing else { return }

        isSyncing = true
        lastSyncError = nil

        do {
            try await syncUserProfile(userId: userId, context: context)
            try await syncDailyLogs(userId: userId, context: context)
            try await syncProgressRecord(userId: userId, context: context)
            try await syncCabinet(userId: userId, context: context)
            try await syncEnrollments(userId: userId, context: context)
        } catch {
            lastSyncError = error
            print("[SupabaseSyncService] Sync error: \(error)")
        }

        isSyncing = false
    }

    /// Push-only sync for a quick save after a user action
    func syncUp() async {
        guard let userId = currentUserId, let context = modelContext else { return }

        do {
            try await syncUserProfile(userId: userId, context: context)
            try await syncDailyLogs(userId: userId, context: context)
            try await syncProgressRecord(userId: userId, context: context)
            try await syncCabinet(userId: userId, context: context)
            try await syncEnrollments(userId: userId, context: context)
        } catch {
            print("[SupabaseSyncService] SyncUp error: \(error)")
        }
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
            if local.updatedAt > remote.updatedAt {
                // Local is newer → push up
                try await client
                    .from("user_profiles")
                    .update(local.toRow(userId: userId))
                    .eq("id", value: remote.id.uuidString)
                    .execute()
            } else if remote.updatedAt > local.updatedAt {
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
            .gte("date", value: ISO8601DateFormatter().string(from: cutoff))
            .execute()
            .value

        let remoteByDate = Dictionary(grouping: remoteRows, by: { $0.date })

        for local in recentLogs {
            let dateKey = Self.dateString(from: local.date)
            if let remote = remoteByDate[dateKey]?.first {
                if local.updatedAt > remote.updatedAt {
                    try await client
                        .from("daily_logs")
                        .update(local.toRow(userId: userId))
                        .eq("id", value: remote.id.uuidString)
                        .execute()
                } else if remote.updatedAt > local.updatedAt {
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
        let localDates = Set(recentLogs.map { Self.dateString(from: $0.date) })
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
            if local.updatedAt > remote.updatedAt {
                try await client
                    .from("progress_records")
                    .update(local.toRow(userId: userId))
                    .eq("id", value: remote.id.uuidString)
                    .execute()
            } else if remote.updatedAt > local.updatedAt {
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

        let remoteByIngredient = Dictionary(uniqueKeysWithValues:
            remoteRows.map { ($0.ingredientId, $0) }
        )
        let localByIngredient = Dictionary(uniqueKeysWithValues:
            localItems.map { ($0.ingredientId, $0) }
        )

        // Push local items not in remote
        for local in localItems {
            if remoteByIngredient[local.ingredientId] == nil {
                try await client
                    .from("user_cabinets")
                    .insert(UserCabinetRow(
                        id: UUID(),
                        userId: userId,
                        ingredientId: local.ingredientId,
                        addedAt: local.addedAt
                    ))
                    .execute()
            }
        }

        // Pull remote items not in local
        for remote in remoteRows {
            if localByIngredient[remote.ingredientId] == nil {
                let item = UserCabinet(ingredientId: remote.ingredientId)
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

        let remoteByProgram = Dictionary(uniqueKeysWithValues:
            remoteRows.map { ($0.programId, $0) }
        )

        for local in localEnrollments {
            if let remote = remoteByProgram[local.programId] {
                if local.updatedAt > remote.updatedAt {
                    try await client
                        .from("program_enrollments")
                        .update(local.toRow(userId: userId))
                        .eq("id", value: remote.id.uuidString)
                        .execute()
                } else if remote.updatedAt > local.updatedAt {
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

    // MARK: - Helpers

    static func dateString(from date: Date) -> String {
        dateFormatter.string(from: date)
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
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case terrainProfileId = "terrain_profile_id"
        case terrainModifier = "terrain_modifier"
        case goals
        case quizResponses = "quiz_responses"
        case notificationPreferences = "notification_preferences"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Apply remote values to a local UserProfile
    func apply(to profile: UserProfile) {
        profile.terrainProfileId = terrainProfileId
        profile.terrainModifier = terrainModifier
        profile.goals = goals.compactMap { Goal(rawValue: $0) }
        profile.notificationsEnabled = notificationPreferences.enabled
        profile.updatedAt = updatedAt
    }
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
    var energyLevel: String?
    var quickSymptoms: [String]
    var completedRoutineIds: [String]
    var completedMovementIds: [String]
    var routineLevel: String?
    var routineFeedback: [RoutineFeedbackDTO]
    var quickFixCompletionTimes: [String: String]
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case symptoms
        case energyLevel = "energy_level"
        case quickSymptoms = "quick_symptoms"
        case completedRoutineIds = "completed_routine_ids"
        case completedMovementIds = "completed_movement_ids"
        case routineLevel = "routine_level"
        case routineFeedback = "routine_feedback"
        case quickFixCompletionTimes = "quick_fix_completion_times"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Apply remote values to a local DailyLog
    func apply(to log: DailyLog) {
        log.symptoms = symptoms.compactMap { Symptom(rawValue: $0) }
        log.energyLevel = energyLevel.flatMap { EnergyLevel(rawValue: $0) }
        log.quickSymptoms = quickSymptoms.compactMap { QuickSymptom(rawValue: $0) }
        log.completedRoutineIds = completedRoutineIds
        log.completedMovementIds = completedMovementIds
        log.routineLevel = routineLevel.flatMap { RoutineLevel(rawValue: $0) }
        log.routineFeedback = routineFeedback.map { $0.toModel() }
        log.notes = notes
        log.updatedAt = updatedAt
    }

    /// Create a new DailyLog model from this row
    func toModel() -> DailyLog {
        let formatter = SupabaseSyncService.dateFormatter
        let logDate = formatter.date(from: date) ?? Date()

        return DailyLog(
            date: logDate,
            symptoms: symptoms.compactMap { Symptom(rawValue: $0) },
            energyLevel: energyLevel.flatMap { EnergyLevel(rawValue: $0) },
            quickSymptoms: quickSymptoms.compactMap { QuickSymptom(rawValue: $0) },
            completedRoutineIds: completedRoutineIds,
            completedMovementIds: completedMovementIds,
            routineLevel: routineLevel.flatMap { RoutineLevel(rawValue: $0) },
            routineFeedback: routineFeedback.map { $0.toModel() }
        )
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
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
        RoutineFeedbackEntry(
            routineOrMovementId: routineOrMovementId,
            feedback: PostRoutineFeedback(rawValue: feedback) ?? .notSure
        )
    }
}

struct ProgressRecordRow: Codable {
    let id: UUID
    let userId: UUID
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalCompletions = "total_completions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func apply(to record: ProgressRecord) {
        record.currentStreak = currentStreak
        record.longestStreak = longestStreak
        record.totalCompletions = totalCompletions
        record.updatedAt = updatedAt
    }
}

struct UserCabinetRow: Codable {
    let id: UUID
    let userId: UUID
    var ingredientId: String
    var addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case ingredientId = "ingredient_id"
        case addedAt = "added_at"
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
    var completedAt: Date?
    var createdAt: Date
    var updatedAt: Date

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
        enrollment.completedAt = completedAt
        enrollment.updatedAt = updatedAt
    }

    func toModel() -> ProgramEnrollment {
        let formatter = SupabaseSyncService.dateFormatter
        let start = formatter.date(from: startDate) ?? Date()

        return ProgramEnrollment(
            programId: programId,
            startDate: start,
            currentDay: currentDay,
            dayCompletions: dayCompletions,
            isActive: isActive,
            completedAt: completedAt
        )
    }
}

// MARK: - Model → Row Conversions

extension UserProfile {
    func toRow(userId: UUID) -> UserProfileRow {
        UserProfileRow(
            id: id,
            userId: userId,
            terrainProfileId: terrainProfileId,
            terrainModifier: terrainModifier,
            goals: goals.map { $0.rawValue },
            quizResponses: Dictionary(uniqueKeysWithValues:
                (quizResponses ?? []).map { ($0.questionId, $0.optionId) }
            ),
            notificationPreferences: NotificationPrefsDTO(
                enabled: notificationsEnabled,
                morningTime: morningNotificationTime.map {
                    ISO8601DateFormatter().string(from: $0)
                },
                eveningTime: eveningNotificationTime.map {
                    ISO8601DateFormatter().string(from: $0)
                }
            ),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension DailyLog {
    func toRow(userId: UUID) -> DailyLogRow {
        DailyLogRow(
            id: id,
            userId: userId,
            date: SupabaseSyncService.dateString(from: date),
            symptoms: symptoms.map { $0.rawValue },
            energyLevel: energyLevel?.rawValue,
            quickSymptoms: quickSymptoms.map { $0.rawValue },
            completedRoutineIds: completedRoutineIds,
            completedMovementIds: completedMovementIds,
            routineLevel: routineLevel?.rawValue,
            routineFeedback: routineFeedback.map {
                RoutineFeedbackDTO(
                    routineOrMovementId: $0.routineOrMovementId,
                    feedback: $0.feedback.rawValue,
                    timestamp: ISO8601DateFormatter().string(from: $0.timestamp)
                )
            },
            quickFixCompletionTimes: Dictionary(uniqueKeysWithValues:
                quickFixCompletionTimes.map { ($0.key, ISO8601DateFormatter().string(from: $0.value)) }
            ),
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ProgressRecord {
    func toRow(userId: UUID) -> ProgressRecordRow {
        ProgressRecordRow(
            id: id,
            userId: userId,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompletions: totalCompletions,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ProgramEnrollment {
    func toRow(userId: UUID) -> ProgramEnrollmentRow {
        ProgramEnrollmentRow(
            id: id,
            userId: userId,
            programId: programId,
            startDate: SupabaseSyncService.dateString(from: startDate),
            currentDay: currentDay,
            dayCompletions: dayCompletions,
            isActive: isActive,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Date Formatter (internal access for Row types)

extension SupabaseSyncService {
    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f
    }()
}
