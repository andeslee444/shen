//
//  TodayView.swift
//  Terrain
//
//  Main Today tab showing daily routine capsule
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.terrainTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \Routine.id) private var allRoutines: [Routine]
    @Query(
        filter: #Predicate<DailyLog> { log in
            true // Will filter in view for today's date
        },
        sort: \DailyLog.date,
        order: .reverse
    ) private var dailyLogs: [DailyLog]

    @State private var selectedLevel: RoutineLevel = .full
    @State private var showDailyCheckIn = false
    @State private var showRoutineDetail = false
    @State private var showMovementPlayer = false

    private var userProfile: UserProfile? {
        userProfiles.first
    }

    private var todaysLog: DailyLog? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyLogs.first { calendar.startOfDay(for: $0.date) == today }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(greeting)
                            .font(theme.typography.headlineLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        if let profile = userProfile,
                           let terrainId = profile.terrainProfileId {
                            let type = TerrainScoringEngine.PrimaryType(rawValue: terrainId)
                            Text(todayOneLiner(for: type))
                                .font(theme.typography.bodyMedium)
                                .foregroundColor(theme.colors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, theme.spacing.lg)

                    // Daily check-in prompt (if not logged today)
                    if todaysLog == nil {
                        DailyCheckInPrompt(onTap: { showDailyCheckIn = true })
                            .padding(.horizontal, theme.spacing.lg)
                    }

                    // Routine level selector
                    RoutineLevelSelector(selectedLevel: $selectedLevel)
                        .padding(.horizontal, theme.spacing.lg)

                    // Routine Capsule
                    VStack(spacing: theme.spacing.md) {
                        Text("Your routine capsule")
                            .font(theme.typography.labelLarge)
                            .foregroundColor(theme.colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        // Eat/Drink Module
                        RoutineModuleCard(
                            type: .eatDrink,
                            title: routineTitle(for: selectedLevel),
                            subtitle: routineSubtitle(for: selectedLevel),
                            duration: routineDuration(for: selectedLevel),
                            isCompleted: todaysLog?.completedRoutineIds.isEmpty == false,
                            onTap: { showRoutineDetail = true }
                        )

                        // Move Module
                        RoutineModuleCard(
                            type: .movement,
                            title: movementTitle(for: selectedLevel),
                            subtitle: movementSubtitle(for: selectedLevel),
                            duration: movementDuration(for: selectedLevel),
                            isCompleted: todaysLog?.completedMovementIds.isEmpty == false,
                            onTap: { showMovementPlayer = true }
                        )
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Why today
                    WhyTodayCard(
                        terrain: userProfile?.terrainProfileId ?? "neutral_balanced_steady_core",
                        goals: userProfile?.goals ?? []
                    )
                    .padding(.horizontal, theme.spacing.lg)

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.top, theme.spacing.md)
            }
            .background(theme.colors.background)
            .refreshable {
                // Pull-to-refresh action
                // Future: refresh weather data, check for content updates
                try? await Task.sleep(nanoseconds: 500_000_000)
                HapticManager.success()
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showDailyCheckIn) {
                DailyCheckInSheet(onComplete: { symptoms, onset, energy in
                    createOrUpdateDailyLog(symptoms: symptoms, onset: onset, energy: energy)
                })
            }
            .sheet(isPresented: $showRoutineDetail) {
                if let routine = allRoutines.first(where: { $0.tier == selectedLevel.rawValue }) {
                    RoutineDetailSheet(
                        level: selectedLevel,
                        routineModel: routine,
                        onComplete: { markRoutineComplete() }
                    )
                }
            }
            .sheet(isPresented: $showMovementPlayer) {
                MovementPlayerSheet(
                    level: selectedLevel,
                    onComplete: { markMovementComplete() }
                )
            }
        }
    }

    private func todayOneLiner(for type: TerrainScoringEngine.PrimaryType?) -> String {
        guard let type = type else { return "Keep it steady today." }

        switch type {
        case .coldDeficient:
            return "Low Flame day: warm start, cooked food, gentle movement."
        case .coldBalanced:
            return "Cool Core day: warm the center, then keep moving."
        case .neutralDeficient:
            return "Low Battery day: simple fuel + gentle reset."
        case .neutralBalanced:
            return "Steady Core day: keep your anchor, everything follows."
        case .neutralExcess:
            return "Busy Mind day: release tension, then you're unstoppable."
        case .warmBalanced:
            return "High Flame day: stay light, keep evenings cool."
        case .warmExcess:
            return "Overclocked day: downshift early, sleep is your reset."
        case .warmDeficient:
            return "Bright but Thin day: nourish and soften the edges."
        }
    }

    private func routineTitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Warm Start Congee"
        case .medium: return "Ginger Honey Tea"
        case .lite: return "Warm Water Ritual"
        }
    }

    private func routineSubtitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Nourishing breakfast to warm your center"
        case .medium: return "Quick warming drink"
        case .lite: return "Simple hydration ritual"
        }
    }

    private func routineDuration(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "10-15 min"
        case .medium: return "5 min"
        case .lite: return "90 sec"
        }
    }

    private func movementTitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Morning Qi Flow"
        case .medium: return "Gentle Stretches"
        case .lite: return "3 Deep Breaths"
        }
    }

    private func movementSubtitle(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "Wake up your body gently"
        case .medium: return "Quick tension release"
        case .lite: return "Reset your nervous system"
        }
    }

    private func movementDuration(for level: RoutineLevel) -> String {
        switch level {
        case .full: return "7 min"
        case .medium: return "3 min"
        case .lite: return "1 min"
        }
    }

    private func createOrUpdateDailyLog(symptoms: [Symptom], onset: SymptomOnset?, energy: EnergyLevel?) {
        if let log = todaysLog {
            log.symptoms = symptoms
            log.symptomOnset = onset
            log.energyLevel = energy
            log.updatedAt = Date()
        } else {
            let log = DailyLog(
                symptoms: symptoms,
                symptomOnset: onset,
                energyLevel: energy
            )
            modelContext.insert(log)
        }
        try? modelContext.save()
    }

    private func markRoutineComplete() {
        let routineId = "warm-start-congee-\(selectedLevel.rawValue)"

        if let log = todaysLog {
            log.markRoutineComplete(routineId, level: selectedLevel)
        } else {
            let log = DailyLog()
            log.markRoutineComplete(routineId, level: selectedLevel)
            modelContext.insert(log)
        }

        // Update progress
        updateProgress()
        try? modelContext.save()
    }

    private func markMovementComplete() {
        let movementId = "morning-qi-flow-\(selectedLevel.rawValue)"

        if let log = todaysLog {
            log.markMovementComplete(movementId)
        } else {
            let log = DailyLog()
            log.markMovementComplete(movementId)
            modelContext.insert(log)
        }
        try? modelContext.save()
    }

    private func updateProgress() {
        let fetchDescriptor = FetchDescriptor<ProgressRecord>()
        if let records = try? modelContext.fetch(fetchDescriptor),
           let record = records.first {
            record.recordCompletion()
        }
    }
}

// MARK: - Supporting Views

struct DailyCheckInPrompt: View {
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: "sparkle")
                    .font(.system(size: 20))
                    .foregroundColor(theme.colors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Anything affecting you today?")
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Text("Quick check-in helps personalize your routine")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoutineLevelSelector: View {
    @Binding var selectedLevel: RoutineLevel

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(RoutineLevel.allCases, id: \.self) { level in
                Button(action: { selectedLevel = level }) {
                    VStack(spacing: 2) {
                        Text(level.displayName)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(selectedLevel == level ? theme.colors.textInverted : theme.colors.textSecondary)

                        Text(level.durationDescription)
                            .font(theme.typography.caption)
                            .foregroundColor(selectedLevel == level ? theme.colors.textInverted.opacity(0.8) : theme.colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.sm)
                    .background(selectedLevel == level ? theme.colors.accent : theme.colors.surface)
                    .cornerRadius(theme.cornerRadius.medium)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(theme.spacing.xxs)
        .background(theme.colors.backgroundSecondary)
        .cornerRadius(theme.cornerRadius.large)
    }
}

enum ModuleType {
    case eatDrink
    case movement

    var icon: String {
        switch self {
        case .eatDrink: return "cup.and.saucer.fill"
        case .movement: return "figure.walk"
        }
    }

    var label: String {
        switch self {
        case .eatDrink: return "Nourish"
        case .movement: return "Move"
        }
    }

    /// Type-specific tint: warm amber for nourish (Spleen/Stomach), cool blue-gray for movement (meridian circulation)
    func tintColor(theme: TerrainTheme) -> Color {
        switch self {
        case .eatDrink: return theme.colors.terrainWarm
        case .movement: return theme.colors.terrainCool
        }
    }
}

struct RoutineModuleCard: View {
    let type: ModuleType
    let title: String
    let subtitle: String
    let duration: String
    var isCompleted: Bool = false
    let onTap: () -> Void

    @Environment(\.terrainTheme) private var theme

    private var tint: Color {
        type.tintColor(theme: theme)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: theme.spacing.md) {
                // Icon — uses type-specific tint color
                ZStack {
                    Circle()
                        .fill(isCompleted ? theme.colors.success.opacity(0.15) : tint.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: isCompleted ? "checkmark" : type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isCompleted ? theme.colors.success : tint)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(type.label)
                            .font(theme.typography.labelSmall)
                            .foregroundColor(theme.colors.textTertiary)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(duration)
                                .font(theme.typography.caption)
                        }
                        .foregroundColor(theme.colors.textTertiary)
                    }

                    Text(title)
                        .font(theme.typography.bodyLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Text(subtitle)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.textTertiary)
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .cornerRadius(theme.cornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius.large)
                    .stroke(isCompleted ? theme.colors.success.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WhyTodayCard: View {
    let terrain: String
    let goals: [Goal]

    @Environment(\.terrainTheme) private var theme
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text("Why today")
                        .font(theme.typography.labelLarge)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Text(whyText)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)

            if isExpanded {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text("In TCM terms:")
                        .font(theme.typography.labelSmall)
                        .foregroundColor(theme.colors.textTertiary)

                    Text(tcmText)
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .padding(.top, theme.spacing.xs)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }

    private var whyText: String {
        "Warming your center in the morning supports steady energy throughout the day. For your terrain, this helps build reserves without overwhelming."
    }

    private var tcmText: String {
        "This routine supports the Spleen and Stomach, which are responsible for transforming food into usable energy (Qi). Morning warmth protects digestive fire."
    }
}

#Preview {
    TodayView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
