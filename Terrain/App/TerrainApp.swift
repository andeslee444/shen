//
//  TerrainApp.swift
//  Terrain
//
//  TCM Daily Rituals iOS App
//  "Co-Star clarity + Muji calm" for TCM lifestyle routines
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TerrainApp: App {
    let modelContainer: ModelContainer
    @State private var syncService = SupabaseSyncService()

    /// Retained strongly — UNUserNotificationCenter holds only a weak reference.
    private let notificationDelegate: NotificationDelegate

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isContentLoaded = false
    @State private var loadingError: Error?
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                UserCabinet.self,
                DailyLog.self,
                ProgressRecord.self,
                ProgramEnrollment.self,
                Ingredient.self,
                Routine.self,
                Movement.self,
                Lesson.self,
                Program.self,
                TerrainProfile.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: TerrainMigrationPlan.self,
                configurations: [modelConfiguration]
            )
        } catch {
            TerrainLogger.persistence.critical("ModelContainer init failed: \(error.localizedDescription)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }

        // Register notification categories and wire delegate
        NotificationService.registerCategories()
        let delegate = NotificationDelegate(modelContainer: modelContainer)
        UNUserNotificationCenter.current().delegate = delegate
        self.notificationDelegate = delegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = loadingError {
                    ContentLoadingErrorView(error: error) {
                        loadContentPack()
                    }
                } else if !isContentLoaded {
                    ContentLoadingView()
                        .task {
                            loadContentPack()
                        }
                } else if hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingCoordinatorView()
                }
            }
            .preferredColorScheme(.light)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .animation(.easeInOut, value: isContentLoaded)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    if syncService.isAuthenticated {
                        Task { await syncService.sync() }
                    }
                    // Refill the 7-day notification window each time the app comes to foreground
                    Task { @MainActor in
                        let profiles = try? modelContainer.mainContext.fetch(FetchDescriptor<UserProfile>())
                        if let profile = profiles?.first, profile.notificationsEnabled {
                            NotificationService.scheduleUpcoming(
                                profile: profile,
                                modelContainer: modelContainer
                            )
                        }
                    }
                }
            }
        }
        .modelContainer(modelContainer)
        .environment(\.terrainTheme, TerrainTheme.default)
        .environment(syncService)
    }

    private func loadContentPack() {
        Task { @MainActor in
            do {
                // Step 1: Load content FIRST so SwiftData models exist before sync touches them
                let service = ContentPackService(modelContext: modelContainer.mainContext)
                _ = try await service.loadBundledContentPackIfNeeded()
                isContentLoaded = true
                loadingError = nil

                // Step 2: Now that content is loaded, configure sync and do initial pull
                syncService.configure(modelContext: modelContainer.mainContext)
                await syncService.sync(force: true)
            } catch {
                loadingError = error
                TerrainLogger.contentPack.error("Failed to load content pack: \(error)")
            }
        }
    }
}

// MARK: - Loading Views

/// Minimal loading view shown while content pack loads.
/// Keep it simple - just show the app name with a subtle animation.
struct ContentLoadingView: View {
    @Environment(\.terrainTheme) private var theme
    @State private var opacity: Double = 0.5

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("Terrain")
                .font(theme.typography.displayLarge)
                .foregroundColor(theme.colors.textPrimary)

            ProgressView()
                .tint(theme.colors.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                opacity = 1
            }
        }
    }
}

/// Error view shown if content pack fails to load.
struct ContentLoadingErrorView: View {
    let error: Error
    let retry: () -> Void

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(theme.colors.warning)

            Text("Unable to Load Content")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)

            Text(error.localizedDescription)
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xl)

            Button("Try Again", action: retry)
                .font(theme.typography.labelLarge)
                .foregroundColor(theme.colors.background)
                .padding(.horizontal, theme.spacing.xl)
                .padding(.vertical, theme.spacing.md)
                .background(theme.colors.accent)
                .cornerRadius(theme.cornerRadius.medium)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
    }
}
