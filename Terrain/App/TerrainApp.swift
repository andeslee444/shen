//
//  TerrainApp.swift
//  Terrain
//
//  TCM Daily Rituals iOS App
//  "Co-Star clarity + Muji calm" for TCM lifestyle routines
//

import SwiftUI
import SwiftData

@main
struct TerrainApp: App {
    let modelContainer: ModelContainer

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isContentLoaded = false
    @State private var loadingError: Error?

    init() {
        do {
            let schema = Schema([
                UserProfile.self,
                UserCabinet.self,
                DailyLog.self,
                ProgressRecord.self,
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
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
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
            .animation(.easeInOut, value: isContentLoaded)
        }
        .modelContainer(modelContainer)
        .environment(\.terrainTheme, TerrainTheme.default)
    }

    private func loadContentPack() {
        Task { @MainActor in
            do {
                let service = ContentPackService(modelContext: modelContainer.mainContext)
                _ = try await service.loadBundledContentPackIfNeeded()
                isContentLoaded = true
                loadingError = nil
            } catch {
                loadingError = error
                print("Failed to load content pack: \(error)")
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
