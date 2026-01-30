//
//  OnboardingCoordinatorView.swift
//  Terrain
//
//  Coordinates the onboarding flow
//

import SwiftUI
import SwiftData

/// Manages the onboarding flow state and navigation
@Observable
final class OnboardingCoordinator {
    enum Step: Int, CaseIterable {
        case welcome = 0
        case goals
        case quiz
        case reveal
        case safety
        case notifications
        case account
        case complete

        var progress: Double {
            Double(rawValue) / Double(Step.allCases.count - 1)
        }
    }

    var currentStep: Step = .welcome
    var selectedGoals: Set<Goal> = []
    var quizResponses: [(questionId: String, optionId: String)] = []
    var currentQuestionIndex: Int = 0
    var scoringResult: TerrainScoringEngine.ScoringResult?
    var safetyPreferences = SafetyPreferences()

    // Notification settings
    var notificationsEnabled: Bool = false
    var morningNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()
    var eveningNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()
    var enableMorningNotification: Bool = true
    var enableEveningNotification: Bool = true

    private let scoringEngine = TerrainScoringEngine()

    func nextStep() {
        guard let nextIndex = Step(rawValue: currentStep.rawValue + 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = nextIndex
        }
    }

    func previousStep() {
        guard let prevIndex = Step(rawValue: currentStep.rawValue - 1) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = prevIndex
        }
    }

    func selectGoal(_ goal: Goal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else if selectedGoals.count < 2 {
            selectedGoals.insert(goal)
        }
    }

    func answerQuestion(questionId: String, optionId: String) {
        // Remove existing answer for this question
        quizResponses.removeAll { $0.questionId == questionId }
        quizResponses.append((questionId: questionId, optionId: optionId))
    }

    /// Questions filtered by the user's selected goals
    var filteredQuestions: [QuizQuestions.Question] {
        QuizQuestions.questions(for: selectedGoals)
    }

    func nextQuestion() {
        if currentQuestionIndex < filteredQuestions.count - 1 {
            currentQuestionIndex += 1
        }
    }

    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }

    func calculateTerrain() {
        scoringResult = scoringEngine.calculateTerrain(from: quizResponses)
    }

    var canProceedFromGoals: Bool {
        !selectedGoals.isEmpty
    }

    var canProceedFromQuiz: Bool {
        currentQuestionIndex == filteredQuestions.count - 1 &&
        quizResponses.count == filteredQuestions.count
    }

    var currentQuestion: QuizQuestions.Question? {
        guard currentQuestionIndex < filteredQuestions.count else { return nil }
        return filteredQuestions[currentQuestionIndex]
    }

    var selectedOptionForCurrentQuestion: String? {
        guard let question = currentQuestion else { return nil }
        return quizResponses.first { $0.questionId == question.id }?.optionId
    }

    var quizProgress: Double {
        Double(currentQuestionIndex + 1) / Double(filteredQuestions.count)
    }
}

struct OnboardingCoordinatorView: View {
    @State private var coordinator = OnboardingCoordinator()
    @Environment(\.modelContext) private var modelContext
    @Environment(SupabaseSyncService.self) private var syncService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.terrainTheme) private var theme

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (except for welcome and complete)
                if coordinator.currentStep != .welcome && coordinator.currentStep != .account && coordinator.currentStep != .complete {
                    ProgressView(value: coordinator.currentStep.progress)
                        .tint(theme.colors.accent)
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.md)
                }

                // Content
                Group {
                    switch coordinator.currentStep {
                    case .welcome:
                        WelcomeView(onContinue: { coordinator.nextStep() })

                    case .goals:
                        GoalsView(
                            selectedGoals: coordinator.selectedGoals,
                            onSelectGoal: { coordinator.selectGoal($0) },
                            onContinue: { coordinator.nextStep() },
                            onBack: { coordinator.previousStep() }
                        )

                    case .quiz:
                        QuizView(coordinator: coordinator)

                    case .reveal:
                        if let result = coordinator.scoringResult {
                            TerrainRevealView(
                                result: result,
                                onContinue: { coordinator.nextStep() }
                            )
                        }

                    case .safety:
                        SafetyGateView(
                            preferences: $coordinator.safetyPreferences,
                            onContinue: { coordinator.nextStep() },
                            onSkip: { coordinator.nextStep() }
                        )

                    case .notifications:
                        NotificationsView(
                            coordinator: coordinator,
                            onContinue: { coordinator.nextStep() },
                            onSkip: { coordinator.nextStep() }
                        )

                    case .account:
                        AuthView(
                            syncService: syncService,
                            onContinueWithoutAccount: { completeOnboarding() }
                        )
                        .onChange(of: syncService.isAuthenticated) { _, isAuth in
                            if isAuth { completeOnboarding() }
                        }

                    case .complete:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
    }

    private func completeOnboarding() {
        // Create user profile
        guard let result = coordinator.scoringResult else { return }

        let profile = UserProfile(
            coldHeat: result.vector.coldHeat,
            defExcess: result.vector.defExcess,
            dampDry: result.vector.dampDry,
            qiStagnation: result.vector.qiStagnation,
            shenUnsettled: result.vector.shenUnsettled,
            hasReflux: result.flags.contains(.reflux),
            hasLooseStool: result.flags.contains(.looseStool),
            hasConstipation: result.flags.contains(.constipation),
            hasStickyStool: result.flags.contains(.stickyStool),
            hasNightSweats: result.flags.contains(.nightSweats),
            wakesThirstyHot: result.flags.contains(.wakeThirstyHot),
            terrainProfileId: result.terrainProfileId,
            terrainModifier: result.modifier.rawValue,
            goals: Array(coordinator.selectedGoals),
            quizResponses: coordinator.quizResponses.map {
                QuizResponse(questionId: $0.questionId, optionId: $0.optionId)
            },
            quizVersion: 2,
            safetyPreferences: coordinator.safetyPreferences,
            morningNotificationTime: coordinator.enableMorningNotification ? coordinator.morningNotificationTime : nil,
            eveningNotificationTime: coordinator.enableEveningNotification ? coordinator.eveningNotificationTime : nil,
            notificationsEnabled: coordinator.notificationsEnabled
        )

        modelContext.insert(profile)

        // Create progress record
        let progressRecord = ProgressRecord()
        modelContext.insert(progressRecord)

        try? modelContext.save()

        hasCompletedOnboarding = true
    }
}

#Preview {
    OnboardingCoordinatorView()
        .environment(\.terrainTheme, TerrainTheme.default)
}
