//
//  TutorialPreviewView.swift
//  Terrain
//
//  Five tutorial screens between terrain reveal and safety gate.
//  Proves personalization is real using the user's actual computed terrain data.
//
//  Screen 1: "Your Daily Read" — personalized headline + do/don't preview
//  Screen 2: "How It Adapts" — interactive symptom chips shift content in real time
//  Screen 3: "Your Daily Practice" — capsule preview (routine + movement combos)
//  Screen 4: "Your Ingredients" — tag-matching + combination preview
//  Screen 5: "Quick Fixes" — reactive suggestions for common needs
//

import SwiftUI

struct TutorialPreviewView: View {
    let result: TerrainScoringEngine.ScoringResult
    let coordinator: OnboardingCoordinator
    let onContinue: () -> Void
    let onBack: () -> Void

    @Environment(\.terrainTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentPage: Int = 0
    @State private var showContent = false
    @State private var selectedSymptoms: Set<QuickSymptom> = []

    private let totalPages = 5
    private let insightEngine = InsightEngine()

    private var terrainGlowColor: Color {
        switch result.primaryType {
        case .coldDeficient, .coldBalanced:
            return Color(hex: "7A8E9E")
        case .warmDeficient, .warmBalanced, .warmExcess:
            return Color(hex: "C9956E")
        case .neutralDeficient, .neutralBalanced, .neutralExcess:
            return Color(hex: "9E9E8E")
        }
    }

    var body: some View {
        ZStack {
            theme.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button — always visible
                backButton
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: showContent)

                Group {
                    switch currentPage {
                    case 0:
                        dailyReadPage
                    case 1:
                        symptomShiftPage
                    case 2:
                        dailyPracticePage
                    case 3:
                        ingredientMatchPage
                    default:
                        quickFixesPage
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            coordinator.tutorialPage = currentPage
            triggerEntrance()
        }
        .onChange(of: currentPage) { _, newPage in
            coordinator.tutorialPage = newPage
            showContent = false
            triggerEntrance()
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        HStack {
            Button(action: goBack) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                    Text("Back")
                        .font(theme.typography.labelMedium)
                }
                .foregroundColor(theme.colors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, theme.spacing.md)
    }

    private func goBack() {
        if currentPage == 0 {
            onBack()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage -= 1
            }
        }
    }

    // MARK: - Entrance Animation

    private func triggerEntrance() {
        if reduceMotion {
            showContent = true
            return
        }
        withAnimation(theme.animation.standard) {
            showContent = true
        }
    }

    private func staggerDelay(_ index: Int) -> Double {
        reduceMotion ? 0 : Double(index) * 0.2
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? theme.colors.accent : theme.colors.textTertiary.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .animation(theme.animation.quick, value: currentPage)
            }
        }
        .padding(.bottom, theme.spacing.lg)
    }

    // MARK: - Screen 1: Your Daily Read

    private var dailyReadPage: some View {
        let headline = insightEngine.generateHeadline(for: result.primaryType, modifier: result.modifier)
        let doDont = insightEngine.generateDoDont(for: result.primaryType, modifier: result.modifier)
        let dos = Array(doDont.dos.prefix(2))
        let donts = Array(doDont.donts.prefix(2))

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    Spacer(minLength: theme.spacing.lg)

                    // Section label
                    Text("YOUR DAILY READ")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .tracking(3)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(0)), value: showContent)

                    // Headline
                    Text("\"\(headline.text)\"")
                        .font(theme.typography.displayMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(1)), value: showContent)

                    // Terrain badge
                    HStack(spacing: theme.spacing.xs) {
                        Circle()
                            .fill(theme.colors.accent)
                            .frame(width: 8, height: 8)
                        Text(result.primaryType.nickname)
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(staggerDelay(2)), value: showContent)

                    Text("Personalized to your terrain")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(2)), value: showContent)

                    // Do / Don't card
                    doDontCard(dos: dos, donts: donts)
                        .padding(.horizontal, theme.spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(3)), value: showContent)

                    // Footnote
                    Text("This changes daily based on your check-in, weather, and activity.")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.xl)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(4)), value: showContent)

                    Spacer(minLength: theme.spacing.lg)
                }
            }

            // Button + indicator pinned to bottom
            VStack(spacing: theme.spacing.md) {
                TerrainPrimaryButton(title: "See How It Adapts") {
                    advancePage()
                }
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(staggerDelay(5)), value: showContent)

                pageIndicator
            }
        }
    }

    // MARK: - Do/Don't Card

    private func doDontCard(dos: [DoDontItem], donts: [DoDontItem]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // DO column
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("DO")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.success)
                    .tracking(1)

                ForEach(Array(dos.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(theme.colors.success)
                                .padding(.top, 3)
                            Text(item.text)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        // Show whyForYou for first item
                        if index == 0, let why = item.whyForYou {
                            Text(why)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                                .padding(.leading, theme.spacing.lg)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 100)
                .padding(.horizontal, theme.spacing.xs)

            // DON'T column
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text("DON'T")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.terrainWarm)
                    .tracking(1)

                ForEach(Array(donts.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        HStack(alignment: .top, spacing: theme.spacing.xs) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(theme.colors.terrainWarm)
                                .padding(.top, 3)
                            Text(item.text)
                                .font(theme.typography.bodySmall)
                                .foregroundColor(theme.colors.textPrimary)
                        }
                        // Show whyForYou for first item
                        if index == 0, let why = item.whyForYou {
                            Text(why)
                                .font(theme.typography.caption)
                                .foregroundColor(theme.colors.textTertiary)
                                .padding(.leading, theme.spacing.lg)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Screen 2: How It Adapts

    private var symptomShiftPage: some View {
        let rankedSymptoms = Array(insightEngine.sortSymptomsByRelevance(
            for: result.primaryType,
            modifier: result.modifier
        ).prefix(4))

        let headline = insightEngine.generateHeadline(
            for: result.primaryType,
            modifier: result.modifier,
            symptoms: selectedSymptoms
        )
        let doDont = insightEngine.generateDoDont(
            for: result.primaryType,
            modifier: result.modifier,
            symptoms: selectedSymptoms
        )

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    Spacer(minLength: theme.spacing.lg)

                    // Section label
                    Text("HOW IT ADAPTS")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .tracking(3)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(0)), value: showContent)

                    // Instruction
                    Text("Tap a symptom. Watch\neverything shift.")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(1)), value: showContent)

                    // Symptom chips — 2x2 grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: theme.spacing.sm),
                        GridItem(.flexible(), spacing: theme.spacing.sm)
                    ], spacing: theme.spacing.sm) {
                        ForEach(rankedSymptoms) { symptom in
                            SymptomChipButton(
                                symptom: symptom,
                                isSelected: selectedSymptoms.contains(symptom),
                                onTap: {
                                    HapticManager.selection()
                                    withAnimation(theme.animation.standard) {
                                        if selectedSymptoms.contains(symptom) {
                                            selectedSymptoms.remove(symptom)
                                        } else {
                                            selectedSymptoms.insert(symptom)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(staggerDelay(2)), value: showContent)

                    // Headline card — animates on symptom change
                    Text("\"\(headline.text)\"")
                        .font(theme.typography.headlineMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(theme.spacing.lg)
                        .frame(maxWidth: .infinity)
                        .background(theme.colors.surface)
                        .cornerRadius(theme.cornerRadius.large)
                        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                        .padding(.horizontal, theme.spacing.lg)
                        .id(headline.text)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(theme.animation.standard, value: headline.text)

                    // Single do + single don't card
                    if let firstDo = doDont.dos.first, let firstDont = doDont.donts.first {
                        adaptiveRecommendationCard(doItem: firstDo, dontItem: firstDont)
                            .padding(.horizontal, theme.spacing.lg)
                            .id("\(firstDo.text)-\(firstDont.text)")
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .animation(theme.animation.standard.delay(0.1), value: selectedSymptoms)
                    }

                    // Accent footnote
                    Text("Every morning, check in.\nTerrain adjusts everything to match.")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(3)), value: showContent)

                    Spacer(minLength: theme.spacing.lg)
                }
            }

            // Button + indicator pinned to bottom
            VStack(spacing: theme.spacing.md) {
                TerrainPrimaryButton(title: "See Your Practice") {
                    advancePage()
                }
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(staggerDelay(4)), value: showContent)

                pageIndicator
            }
        }
    }

    // MARK: - Adaptive Recommendation Card

    private func adaptiveRecommendationCard(doItem: DoDontItem, dontItem: DoDontItem) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // DO item
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xs) {
                    Text("DO")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.success)
                        .tracking(1)
                    Text(doItem.text)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                }
                if let why = doItem.whyForYou {
                    Text(why)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }

            Divider()

            // DON'T item
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xs) {
                    Text("DON'T")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.terrainWarm)
                        .tracking(1)
                    Text(dontItem.text)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                }
                if let why = dontItem.whyForYou {
                    Text(why)
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Screen 3: Your Daily Practice

    private var dailyPracticePage: some View {
        let practice = TerrainDailyPractice.forType(result.primaryType)

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    Spacer(minLength: theme.spacing.lg)

                    // Section label
                    Text("YOUR DAILY PRACTICE")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .tracking(3)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(0)), value: showContent)

                    // Headline
                    Text("Terrain builds a daily practice\ncombining food, drink, and\nmovement.")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(1)), value: showContent)

                    // Morning card
                    practiceTimeCard(
                        icon: "sun.horizon.fill",
                        timeLabel: "MORNING",
                        routine: practice.morning
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(2)), value: showContent)

                    // Evening card
                    practiceTimeCard(
                        icon: "moon.fill",
                        timeLabel: "EVENING",
                        routine: practice.evening
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(3)), value: showContent)

                    // Accent footnote
                    Text("Routines aren\u{2019}t just recipes \u{2014}\nthey combine your best ingredients\ninto a practice you can actually do.")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.accent)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(4)), value: showContent)

                    Spacer(minLength: theme.spacing.lg)
                }
            }

            // Button + indicator pinned to bottom
            VStack(spacing: theme.spacing.md) {
                TerrainPrimaryButton(title: "See Your Ingredients") {
                    advancePage()
                }
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(staggerDelay(5)), value: showContent)

                pageIndicator
            }
        }
    }

    // MARK: - Practice Time Card

    private func practiceTimeCard(icon: String, timeLabel: String, routine: TerrainDailyPractice.TimeBlock) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Time header
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.accent)
                Text(timeLabel)
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.accent)
                    .tracking(1)
            }

            // Routine row
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(routine.routineName)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                Text(routine.ingredientCombo)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                Text("\(routine.routineMinutes) min \u{00B7} Easy")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }

            Divider()

            // Movement row
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                HStack(spacing: theme.spacing.xs) {
                    Text("\u{1F9D8}")
                        .font(.system(size: 14))
                    Text(routine.movementName)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                }
                Text(routine.movementDescription)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                Text("\(routine.movementMinutes) min \u{00B7} \(routine.movementIntensity)")
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Screen 4: Your Ingredients

    private var ingredientMatchPage: some View {
        let tagInfo = TerrainTagInfo.forType(result.primaryType)

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    Spacer(minLength: theme.spacing.lg)

                    // Section label
                    Text("YOUR INGREDIENTS")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .tracking(3)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(0)), value: showContent)

                    // Headline
                    Text("Terrain picks ingredients\nthat match your pattern.")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(1)), value: showContent)

                    // Recommended tags row
                    VStack(spacing: theme.spacing.sm) {
                        Text("Your terrain looks for:")
                            .font(theme.typography.labelMedium)
                            .foregroundColor(theme.colors.textSecondary)

                        FlowLayout(spacing: theme.spacing.xs) {
                            ForEach(tagInfo.recommendedTags, id: \.self) { tag in
                                terrainTintedChip(name: TerrainTagInfo.displayName(for: tag))
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(staggerDelay(2)), value: showContent)

                    // Great match card
                    matchCard(info: tagInfo)
                        .padding(.horizontal, theme.spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(3)), value: showContent)

                    // Mismatch card (or flexible note)
                    if tagInfo.avoidTags.isEmpty {
                        flexibleNote
                            .padding(.horizontal, theme.spacing.lg)
                            .opacity(showContent ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(staggerDelay(4)), value: showContent)
                    } else {
                        mismatchCard(info: tagInfo)
                            .padding(.horizontal, theme.spacing.lg)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(4)), value: showContent)
                    }

                    // Combination preview card
                    combinationPreviewCard(info: tagInfo)
                        .padding(.horizontal, theme.spacing.lg)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(5)), value: showContent)

                    // Footer count
                    Text("43 ingredients. All ranked\nfor your terrain.")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(6)), value: showContent)

                    Spacer(minLength: theme.spacing.lg)
                }
            }

            // Button + indicator pinned to bottom
            VStack(spacing: theme.spacing.md) {
                TerrainPrimaryButton(title: "One More Thing") {
                    advancePage()
                }
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(staggerDelay(7)), value: showContent)

                pageIndicator
            }
        }
    }

    // MARK: - Match Card (Great Match)

    private func matchCard(info: TerrainTagInfo) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Header
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.success)
                Text("GREAT MATCH")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.success)
                    .tracking(1)
            }

            // Ingredient name with emoji
            Text("\(info.matchIngredient.emoji) \(info.matchIngredient.name)")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)

            // Matching tags
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                ForEach(info.matchIngredient.tags, id: \.self) { tag in
                    HStack(spacing: theme.spacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.colors.success)
                        Text(TerrainTagInfo.displayName(for: tag))
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                }
            }

            // Why preview
            Text(info.matchIngredient.why)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
                .lineLimit(2)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Mismatch Card (Not Ideal)

    private func mismatchCard(info: TerrainTagInfo) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Header
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(theme.colors.terrainWarm)
                Text("NOT IDEAL")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.terrainWarm)
                    .tracking(1)
            }

            // Ingredient name with emoji
            Text("\(info.mismatchIngredient.emoji) \(info.mismatchIngredient.name)")
                .font(theme.typography.headlineSmall)
                .foregroundColor(theme.colors.textPrimary)

            // Conflicting tag
            HStack(spacing: theme.spacing.xs) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.colors.terrainWarm)
                Text(TerrainTagInfo.displayName(for: info.mismatchIngredient.conflictTag))
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textPrimary)
            }

            // Explanation
            Text(info.mismatchIngredient.why)
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Flexible Note (for terrains with no avoidTags)

    private var flexibleNote: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(theme.colors.accent)

            Text("Your terrain is flexible \u{2014} most ingredients work for you. We rank the best ones first.")
                .font(theme.typography.bodySmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Terrain-Tinted Ingredient Chip

    private func terrainTintedChip(name: String) -> some View {
        Text(name)
            .font(theme.typography.labelSmall)
            .foregroundColor(theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xxs)
            .background(terrainGlowColor.opacity(0.12))
            .cornerRadius(theme.cornerRadius.full)
    }

    // MARK: - Combination Preview Card

    private func combinationPreviewCard(info: TerrainTagInfo) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.xs) {
                Text("\u{1F375}")
                    .font(.system(size: 14))
                Text("HOW THEY COMBINE")
                    .font(theme.typography.labelMedium)
                    .foregroundColor(theme.colors.accent)
                    .tracking(1)
            }

            ForEach(Array(info.combinations.enumerated()), id: \.offset) { _, combo in
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(combo.ingredients)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("\u{2192} \"\(combo.result)\"")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .italic()
                }
            }

            Text("Perfect pairings, ranked for\nyour terrain.")
                .font(theme.typography.caption)
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(theme.spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Screen 5: Quick Fixes

    private var quickFixesPage: some View {
        let fixes = TerrainQuickFixInfo.forType(result.primaryType)

        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacing.xl) {
                    Spacer(minLength: theme.spacing.lg)

                    // Section label
                    Text("WHEN YOU NEED SOMETHING NOW")
                        .font(theme.typography.caption)
                        .foregroundColor(theme.colors.textTertiary)
                        .tracking(3)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(0)), value: showContent)

                    // Headline
                    Text("Tap what you need.\nTerrain suggests the fix.")
                        .font(theme.typography.headlineSmall)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(1)), value: showContent)

                    // Quick fix cards
                    VStack(spacing: theme.spacing.sm) {
                        ForEach(Array(fixes.enumerated()), id: \.element.emoji) { index, fix in
                            quickFixRow(fix: fix)
                                .opacity(showContent ? 1 : 0)
                                .offset(y: showContent ? 0 : 8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(staggerDelay(2 + index)), value: showContent)
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)

                    // Footer
                    Text("8 quick fix categories.\nAll ranked for your terrain\nand how you\u{2019}re feeling.")
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(staggerDelay(6)), value: showContent)

                    Spacer(minLength: theme.spacing.lg)
                }
            }

            // Button + indicator pinned to bottom
            VStack(spacing: theme.spacing.md) {
                TerrainPrimaryButton(title: "Continue") {
                    onContinue()
                }
                .padding(.horizontal, theme.spacing.lg)
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(staggerDelay(7)), value: showContent)

                pageIndicator
            }
        }
    }

    // MARK: - Quick Fix Row

    private func quickFixRow(fix: TerrainQuickFixInfo.QuickFix) -> some View {
        HStack(spacing: theme.spacing.md) {
            Text(fix.emoji)
                .font(.system(size: 20))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(fix.need)
                    .font(theme.typography.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                Text("\u{2192} \(fix.suggestion)")
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                Text(fix.duration)
                    .font(theme.typography.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }

            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }

    // MARK: - Page Navigation

    private func advancePage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPage += 1
        }
    }
}

// MARK: - TerrainTagInfo

/// Static mapping of terrain types to their recommended/avoid tags and example ingredients.
/// Uses hardcoded data (like TerrainCopy) instead of SwiftData queries because terrain
/// profile IDs in the content pack don't match ScoringResult.terrainProfileId directly.
struct TerrainTagInfo {
    let recommendedTags: [String]
    let avoidTags: [String]
    let matchIngredient: MatchIngredient
    let mismatchIngredient: MismatchIngredient
    let combinations: [Combination]

    struct MatchIngredient {
        let name: String
        let emoji: String
        let tags: [String]
        let why: String
    }

    struct MismatchIngredient {
        let name: String
        let emoji: String
        let conflictTag: String
        let why: String
    }

    struct Combination {
        let ingredients: String
        let result: String
    }

    /// Human-readable display name for a raw tag string.
    static func displayName(for tag: String) -> String {
        switch tag {
        case "warming":            return "Warming"
        case "cooling":            return "Cooling"
        case "supports_deficiency": return "Builds Strength"
        case "supports_digestion": return "Supports Digestion"
        case "moves_qi":           return "Moves Energy"
        case "calms_shen":         return "Calms the Mind"
        case "moistens_dryness":   return "Moistening"
        case "dries_damp":         return "Clears Dampness"
        case "reduces_excess":     return "Clears Excess"
        default:
            return tag.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    static func forType(_ type: TerrainScoringEngine.PrimaryType) -> TerrainTagInfo {
        switch type {
        case .coldDeficient:
            return TerrainTagInfo(
                recommendedTags: ["warming", "supports_deficiency", "supports_digestion"],
                avoidTags: ["cooling"],
                matchIngredient: MatchIngredient(
                    name: "Ginger",
                    emoji: "\u{1FAD0}",
                    tags: ["warming", "supports_digestion"],
                    why: "Warms the stomach and supports digestion \u{2014} exactly what a cold, depleted terrain needs."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "Green Tea",
                    emoji: "\u{1F375}",
                    conflictTag: "cooling",
                    why: "Your terrain avoids cooling ingredients."
                ),
                combinations: [
                    Combination(ingredients: "Ginger + Honey + Hot Water", result: "Warming morning tonic"),
                    Combination(ingredients: "Rice + Sweet Potato + Red Dates", result: "Nourishing congee base")
                ]
            )

        case .coldBalanced:
            return TerrainTagInfo(
                recommendedTags: ["warming", "supports_digestion", "moves_qi"],
                avoidTags: ["cooling"],
                matchIngredient: MatchIngredient(
                    name: "Cinnamon",
                    emoji: "\u{1FAB5}",
                    tags: ["warming"],
                    why: "Gently warms the core and supports circulation."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "Mung Bean",
                    emoji: "\u{1FAD8}",
                    conflictTag: "cooling",
                    why: "Your terrain avoids cooling ingredients."
                ),
                combinations: [
                    Combination(ingredients: "Cinnamon + Walnut + Warm Milk", result: "Gentle warming nightcap"),
                    Combination(ingredients: "Ginger + Scallion + Broth", result: "Cold-weather immunity soup")
                ]
            )

        case .neutralDeficient:
            return TerrainTagInfo(
                recommendedTags: ["supports_deficiency", "supports_digestion", "calms_shen"],
                avoidTags: [],
                matchIngredient: MatchIngredient(
                    name: "Rice",
                    emoji: "\u{1F35A}",
                    tags: ["supports_deficiency"],
                    why: "Gentle and nourishing \u{2014} rebuilds energy without overwhelming a depleted system."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "", emoji: "", conflictTag: "", why: ""
                ),
                combinations: [
                    Combination(ingredients: "Rice + Chicken + Goji Berry", result: "Energy-building congee"),
                    Combination(ingredients: "Sweet Potato + Ginger + Honey", result: "Gentle warming bowl")
                ]
            )

        case .neutralBalanced:
            return TerrainTagInfo(
                recommendedTags: ["supports_digestion", "moves_qi"],
                avoidTags: [],
                matchIngredient: MatchIngredient(
                    name: "Green Tea",
                    emoji: "\u{1F375}",
                    tags: ["moves_qi"],
                    why: "Keeps energy flowing smoothly \u{2014} perfect for maintaining your natural balance."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "", emoji: "", conflictTag: "", why: ""
                ),
                combinations: [
                    Combination(ingredients: "Green Tea + Mint + Honey", result: "Balanced afternoon lift"),
                    Combination(ingredients: "Rice + Vegetables + Sesame", result: "Steady-energy lunch bowl")
                ]
            )

        case .neutralExcess:
            return TerrainTagInfo(
                recommendedTags: ["moves_qi", "calms_shen"],
                avoidTags: [],
                matchIngredient: MatchIngredient(
                    name: "Chamomile",
                    emoji: "\u{1F33C}",
                    tags: ["calms_shen"],
                    why: "Settles a busy mind and helps release built-up tension."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "", emoji: "", conflictTag: "", why: ""
                ),
                combinations: [
                    Combination(ingredients: "Chamomile + Lavender + Honey", result: "Mind-settling evening tea"),
                    Combination(ingredients: "Chrysanthemum + Goji Berry", result: "Tension-clearing afternoon drink")
                ]
            )

        case .warmBalanced:
            return TerrainTagInfo(
                recommendedTags: ["cooling", "calms_shen", "moves_qi"],
                avoidTags: ["warming"],
                matchIngredient: MatchIngredient(
                    name: "Chrysanthemum",
                    emoji: "\u{1F3F5}\u{FE0F}",
                    tags: ["cooling"],
                    why: "Gently cools and clears \u{2014} takes the edge off excess warmth."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "Ginger",
                    emoji: "\u{1FAD0}",
                    conflictTag: "warming",
                    why: "Your terrain avoids warming ingredients."
                ),
                combinations: [
                    Combination(ingredients: "Chrysanthemum + Honey + Cool Water", result: "Cooling midday tonic"),
                    Combination(ingredients: "Pear + Lily Bulb + Rock Sugar", result: "Heat-clearing dessert soup")
                ]
            )

        case .warmExcess:
            return TerrainTagInfo(
                recommendedTags: ["cooling", "calms_shen", "reduces_excess"],
                avoidTags: ["warming"],
                matchIngredient: MatchIngredient(
                    name: "Mung Bean",
                    emoji: "\u{1FAD8}",
                    tags: ["cooling", "reduces_excess"],
                    why: "Cools heat and clears excess \u{2014} like opening a window in an overheated room."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "Cinnamon",
                    emoji: "\u{1FAB5}",
                    conflictTag: "warming",
                    why: "Your terrain avoids warming ingredients."
                ),
                combinations: [
                    Combination(ingredients: "Mung Bean + Mint + Barley", result: "Heat-clearing summer soup"),
                    Combination(ingredients: "Cucumber + Celery + Green Tea", result: "Excess-draining afternoon drink")
                ]
            )

        case .warmDeficient:
            return TerrainTagInfo(
                recommendedTags: ["moistens_dryness", "supports_deficiency", "calms_shen"],
                avoidTags: ["warming"],
                matchIngredient: MatchIngredient(
                    name: "Pear",
                    emoji: "\u{1F350}",
                    tags: ["moistens_dryness"],
                    why: "Replenishes moisture gently \u{2014} like rain on dry soil."
                ),
                mismatchIngredient: MismatchIngredient(
                    name: "", emoji: "", conflictTag: "", why: ""
                ),
                combinations: [
                    Combination(ingredients: "Pear + Lily Bulb + Honey", result: "Moisture-restoring dessert"),
                    Combination(ingredients: "Goji Berry + Chrysanthemum + Water", result: "Yin-nourishing evening tea")
                ]
            )
        }
    }
}

// MARK: - TerrainDailyPractice

/// Hardcoded daily practice preview data per terrain type.
/// Shows a morning and evening block to demonstrate the "capsule" concept.
struct TerrainDailyPractice {
    let morning: TimeBlock
    let evening: TimeBlock

    struct TimeBlock {
        let routineName: String
        let ingredientCombo: String
        let routineMinutes: Int
        let movementName: String
        let movementDescription: String
        let movementMinutes: Int
        let movementIntensity: String
    }

    static func forType(_ type: TerrainScoringEngine.PrimaryType) -> TerrainDailyPractice {
        switch type {
        case .coldDeficient:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Warming Morning Tonic",
                    ingredientCombo: "Ginger + Honey + Hot Water",
                    routineMinutes: 10,
                    movementName: "Gentle Qi Wake-Up",
                    movementDescription: "Slow stretching to warm your body",
                    movementMinutes: 8,
                    movementIntensity: "Gentle"
                ),
                evening: TimeBlock(
                    routineName: "Nourishing Congee Prep",
                    ingredientCombo: "Rice + Red Dates + Sweet Potato",
                    routineMinutes: 5,
                    movementName: "Evening Wind-Down",
                    movementDescription: "Restorative stretches for warmth",
                    movementMinutes: 6,
                    movementIntensity: "Restorative"
                )
            )

        case .coldBalanced:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Warming Spice Brew",
                    ingredientCombo: "Cinnamon + Walnut + Warm Milk",
                    routineMinutes: 8,
                    movementName: "Morning Circulation Flow",
                    movementDescription: "Gentle movements to get warmth flowing",
                    movementMinutes: 10,
                    movementIntensity: "Gentle"
                ),
                evening: TimeBlock(
                    routineName: "Broth & Settle",
                    ingredientCombo: "Ginger + Scallion + Broth",
                    routineMinutes: 5,
                    movementName: "Bedtime Stretch",
                    movementDescription: "Warming stretches before sleep",
                    movementMinutes: 6,
                    movementIntensity: "Restorative"
                )
            )

        case .neutralDeficient:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Energy Congee",
                    ingredientCombo: "Rice + Chicken + Goji Berry",
                    routineMinutes: 10,
                    movementName: "Gentle Morning Flow",
                    movementDescription: "Easy movement to build energy slowly",
                    movementMinutes: 8,
                    movementIntensity: "Gentle"
                ),
                evening: TimeBlock(
                    routineName: "Nourishing Bowl",
                    ingredientCombo: "Sweet Potato + Ginger + Honey",
                    routineMinutes: 5,
                    movementName: "Restorative Stretch",
                    movementDescription: "Gentle stretching to restore reserves",
                    movementMinutes: 6,
                    movementIntensity: "Restorative"
                )
            )

        case .neutralBalanced:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Balanced Morning Tea",
                    ingredientCombo: "Green Tea + Mint + Honey",
                    routineMinutes: 8,
                    movementName: "Morning Qi Flow",
                    movementDescription: "Balanced stretching to start your day",
                    movementMinutes: 10,
                    movementIntensity: "Moderate"
                ),
                evening: TimeBlock(
                    routineName: "Steady Bowl",
                    ingredientCombo: "Rice + Vegetables + Sesame",
                    routineMinutes: 5,
                    movementName: "Evening Balance",
                    movementDescription: "Calm, centering stretches",
                    movementMinutes: 6,
                    movementIntensity: "Gentle"
                )
            )

        case .neutralExcess:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Morning Calm Tea",
                    ingredientCombo: "Chamomile + Lavender + Honey",
                    routineMinutes: 8,
                    movementName: "Tension Release Flow",
                    movementDescription: "Movement to release built-up energy",
                    movementMinutes: 10,
                    movementIntensity: "Moderate"
                ),
                evening: TimeBlock(
                    routineName: "Mind-Settling Brew",
                    ingredientCombo: "Chrysanthemum + Goji Berry",
                    routineMinutes: 5,
                    movementName: "Deep Calm Stretch",
                    movementDescription: "Slow breathing and gentle stretches",
                    movementMinutes: 8,
                    movementIntensity: "Restorative"
                )
            )

        case .warmBalanced:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Cooling Morning Tonic",
                    ingredientCombo: "Chrysanthemum + Honey + Cool Water",
                    routineMinutes: 8,
                    movementName: "Cool-Down Flow",
                    movementDescription: "Gentle movement that avoids overheating",
                    movementMinutes: 10,
                    movementIntensity: "Gentle"
                ),
                evening: TimeBlock(
                    routineName: "Heat-Clearing Dessert",
                    ingredientCombo: "Pear + Lily Bulb + Rock Sugar",
                    routineMinutes: 5,
                    movementName: "Evening Cool-Down",
                    movementDescription: "Calming stretches to release heat",
                    movementMinutes: 6,
                    movementIntensity: "Restorative"
                )
            )

        case .warmExcess:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Heat-Clearing Brew",
                    ingredientCombo: "Mung Bean + Mint + Barley",
                    routineMinutes: 10,
                    movementName: "Energy Release Flow",
                    movementDescription: "Movement to channel excess energy",
                    movementMinutes: 12,
                    movementIntensity: "Moderate"
                ),
                evening: TimeBlock(
                    routineName: "Cooling Evening Drink",
                    ingredientCombo: "Cucumber + Celery + Green Tea",
                    routineMinutes: 5,
                    movementName: "Settle & Release",
                    movementDescription: "Stretches to drain excess and cool down",
                    movementMinutes: 8,
                    movementIntensity: "Gentle"
                )
            )

        case .warmDeficient:
            return TerrainDailyPractice(
                morning: TimeBlock(
                    routineName: "Moisture Morning Tea",
                    ingredientCombo: "Pear + Lily Bulb + Honey",
                    routineMinutes: 8,
                    movementName: "Gentle Yin Flow",
                    movementDescription: "Slow movement to nourish without depleting",
                    movementMinutes: 10,
                    movementIntensity: "Gentle"
                ),
                evening: TimeBlock(
                    routineName: "Yin-Nourishing Brew",
                    ingredientCombo: "Goji Berry + Chrysanthemum + Water",
                    routineMinutes: 5,
                    movementName: "Restorative Evening",
                    movementDescription: "Deep, slow stretches for recovery",
                    movementMinutes: 6,
                    movementIntensity: "Restorative"
                )
            )
        }
    }
}

// MARK: - TerrainQuickFixInfo

/// Hardcoded quick fix scenarios per terrain type.
/// Shows 4 "feeling X? do Y" pairs personalized to the terrain.
struct TerrainQuickFixInfo {
    struct QuickFix {
        let emoji: String
        let need: String
        let suggestion: String
        let duration: String
    }

    static func forType(_ type: TerrainScoringEngine.PrimaryType) -> [QuickFix] {
        switch type {
        case .coldDeficient:
            return [
                QuickFix(emoji: "\u{1F976}", need: "Feeling cold?", suggestion: "Ginger tea with honey", duration: "5 min"),
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Warm congee with red dates", duration: "10 min"),
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "Warm foot soak + deep breathing", duration: "8 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Gentle warming stretches", duration: "6 min")
            ]

        case .coldBalanced:
            return [
                QuickFix(emoji: "\u{1F976}", need: "Feeling cold?", suggestion: "Cinnamon bark tea", duration: "5 min"),
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Morning qi flow routine", duration: "8 min"),
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "Warming hand massage", duration: "5 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Circulation-boosting stretches", duration: "6 min")
            ]

        case .neutralDeficient:
            return [
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Goji berry + honey water", duration: "3 min"),
                QuickFix(emoji: "\u{1F4A4}", need: "Poor sleep?", suggestion: "Warm milk with dates", duration: "5 min"),
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "Gentle breathing exercise", duration: "5 min"),
                QuickFix(emoji: "\u{1F922}", need: "Bloating?", suggestion: "Ginger + fennel tea", duration: "5 min")
            ]

        case .neutralBalanced:
            return [
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Green tea + mint", duration: "3 min"),
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "5-minute qi flow", duration: "5 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Balanced morning stretch", duration: "8 min"),
                QuickFix(emoji: "\u{1F4A4}", need: "Poor sleep?", suggestion: "Chamomile wind-down", duration: "5 min")
            ]

        case .neutralExcess:
            return [
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "Chamomile wind-down", duration: "3 min"),
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Morning qi flow", duration: "8 min"),
                QuickFix(emoji: "\u{1F4A4}", need: "Can\u{2019}t sleep?", suggestion: "Lavender tea + deep breathing", duration: "5 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Tension-release stretches", duration: "6 min")
            ]

        case .warmBalanced:
            return [
                QuickFix(emoji: "\u{1F525}", need: "Feeling hot?", suggestion: "Chrysanthemum cool-down tea", duration: "5 min"),
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "Cooling breathing exercise", duration: "5 min"),
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Pear + honey hydration", duration: "3 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Gentle cooling stretches", duration: "6 min")
            ]

        case .warmExcess:
            return [
                QuickFix(emoji: "\u{1F525}", need: "Feeling hot?", suggestion: "Mung bean cool-down soup", duration: "5 min"),
                QuickFix(emoji: "\u{1F630}", need: "Stressed?", suggestion: "Energy release movement", duration: "8 min"),
                QuickFix(emoji: "\u{1F4A4}", need: "Can\u{2019}t sleep?", suggestion: "Mint + chrysanthemum tea", duration: "5 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Full-body release stretch", duration: "10 min")
            ]

        case .warmDeficient:
            return [
                QuickFix(emoji: "\u{1F525}", need: "Feeling dry/hot?", suggestion: "Pear + lily bulb tea", duration: "5 min"),
                QuickFix(emoji: "\u{1F634}", need: "Low energy?", suggestion: "Goji + honey water", duration: "3 min"),
                QuickFix(emoji: "\u{1F4A4}", need: "Poor sleep?", suggestion: "Yin-nourishing evening tea", duration: "5 min"),
                QuickFix(emoji: "\u{1F9B4}", need: "Feeling stiff?", suggestion: "Slow yin stretches", duration: "8 min")
            ]
        }
    }
}

// MARK: - Preview

#Preview {
    let result = TerrainScoringEngine.ScoringResult(
        vector: TerrainVector(coldHeat: -4, defExcess: -4),
        primaryType: .coldDeficient,
        modifier: .damp,
        flags: []
    )
    let coordinator = OnboardingCoordinator()
    return TutorialPreviewView(
        result: result,
        coordinator: coordinator,
        onContinue: {},
        onBack: {}
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
