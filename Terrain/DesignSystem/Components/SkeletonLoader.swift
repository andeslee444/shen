//
//  SkeletonLoader.swift
//  Terrain
//
//  Shimmer loading placeholders for content loading states
//

import SwiftUI

// MARK: - Base Skeleton Loader

/// A shimmering placeholder view for loading states.
/// Think of this as a "ghost" version of content that pulses to indicate
/// something is loading, rather than showing a spinner.
struct SkeletonLoader: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 8

    @Environment(\.terrainTheme) private var theme
    @State private var isAnimating = false

    var body: some View {
        shimmerView
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }

    private var shimmerView: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                theme.colors.backgroundSecondary

                // Shimmer gradient
                LinearGradient(
                    colors: [
                        theme.colors.backgroundSecondary.opacity(0),
                        theme.colors.surface.opacity(0.5),
                        theme.colors.backgroundSecondary.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
            }
        }
    }
}

// MARK: - Ingredient Card Skeleton

/// Skeleton placeholder for an ingredient card
struct IngredientCardSkeleton: View {
    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Image placeholder
            SkeletonLoader(height: 100, cornerRadius: theme.cornerRadius.medium)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                // Title
                SkeletonLoader(width: 100, height: 16)

                // Category
                SkeletonLoader(width: 60, height: 12)

                // Tags
                HStack(spacing: theme.spacing.xxs) {
                    SkeletonLoader(width: 50, height: 16, cornerRadius: 4)
                    SkeletonLoader(width: 40, height: 16, cornerRadius: 4)
                }
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

// MARK: - Lesson Card Skeleton

/// Skeleton placeholder for a lesson card
struct LessonCardSkeleton: View {
    @Environment(\.terrainTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Image placeholder
            SkeletonLoader(height: 120, cornerRadius: theme.cornerRadius.medium)

            // Title
            SkeletonLoader(width: 160, height: 16)

            // Subtitle
            SkeletonLoader(width: 180, height: 12)
            SkeletonLoader(width: 140, height: 12)
        }
        .frame(width: 200)
        .padding(theme.spacing.sm)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

// MARK: - Routine Card Skeleton

/// Skeleton placeholder for a routine card
struct RoutineCardSkeleton: View {
    @Environment(\.terrainTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            // Icon placeholder
            SkeletonLoader(width: 48, height: 48, cornerRadius: theme.cornerRadius.medium)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                // Title
                SkeletonLoader(width: 120, height: 16)

                // Subtitle
                SkeletonLoader(width: 80, height: 12)
            }

            Spacer()
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .cornerRadius(theme.cornerRadius.large)
    }
}

// MARK: - Text Line Skeleton

/// Skeleton for a single line of text
struct TextLineSkeleton: View {
    var widthRatio: CGFloat = 1.0
    var height: CGFloat = 14

    @Environment(\.terrainTheme) private var theme

    var body: some View {
        GeometryReader { geometry in
            SkeletonLoader(
                width: geometry.size.width * widthRatio,
                height: height,
                cornerRadius: theme.cornerRadius.small
            )
        }
        .frame(height: height)
    }
}

// MARK: - Skeleton Modifier

/// View modifier to show a skeleton state
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .shimmering()
        } else {
            content
        }
    }
}

extension View {
    /// Apply shimmer effect to any view
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }

    /// Show skeleton state when loading
    func skeleton(isLoading: Bool) -> some View {
        self.modifier(SkeletonModifier(isLoading: isLoading))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: phase * geometry.size.width * 1.5 - geometry.size.width * 0.25)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

// MARK: - Previews

#Preview("Skeleton Loader") {
    VStack(spacing: 16) {
        SkeletonLoader(height: 20)
        SkeletonLoader(width: 200, height: 16)
        SkeletonLoader(width: 150, height: 12)
    }
    .padding()
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Ingredient Card Skeleton") {
    HStack {
        IngredientCardSkeleton()
        IngredientCardSkeleton()
    }
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Lesson Card Skeleton") {
    HStack {
        LessonCardSkeleton()
        LessonCardSkeleton()
    }
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Routine Card Skeleton") {
    VStack {
        RoutineCardSkeleton()
        RoutineCardSkeleton()
    }
    .padding()
    .background(Color(hex: "FAFAF8"))
    .environment(\.terrainTheme, TerrainTheme.default)
}
