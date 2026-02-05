//
//  ParallaxHeroImage.swift
//  Terrain
//
//  Hero image with parallax scrolling effect for routine detail sheets.
//  Shows beautiful food/drink photography that scrolls at a slower rate
//  than content, creating depth and visual interest.
//

import SwiftUI

/// A hero image that scrolls with parallax effect and fades into content below.
///
/// Supports both bundled images (file paths) and remote URLs.
/// Falls back to a themed placeholder when no image is available.
struct ParallaxHeroImage: View {
    let imageUri: String?
    let fallbackIcon: String
    let phase: DayPhase
    let scrollOffset: CGFloat

    @Environment(\.terrainTheme) private var theme

    /// Height of the hero image container
    private let heroHeight: CGFloat = 240

    /// Parallax scroll rate (0.4 = moves at 40% of scroll speed)
    private let parallaxRate: CGFloat = 0.4

    init(
        imageUri: String?,
        fallbackIcon: String = "cup.and.saucer.fill",
        phase: DayPhase = .morning,
        scrollOffset: CGFloat = 0
    ) {
        self.imageUri = imageUri
        self.fallbackIcon = fallbackIcon
        self.phase = phase
        self.scrollOffset = scrollOffset
    }

    private var imageURL: URL? {
        guard let uri = imageUri else { return nil }

        // Remote URL
        if uri.hasPrefix("http://") || uri.hasPrefix("https://") {
            return URL(string: uri)
        }

        // Bundled asset (look in bundle)
        return Bundle.main.url(forResource: uri, withExtension: nil)
    }

    private var parallaxOffset: CGFloat {
        // Move up as user scrolls down (creates depth effect)
        min(scrollOffset * parallaxRate, heroHeight * 0.5)
    }

    private var scaleEffect: CGFloat {
        // Slight zoom as user scrolls
        1.0 + max(0, -scrollOffset) / 500
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Image or fallback
                if let url = imageURL {
                    AsyncImage(url: url) { imagePhase in
                        switch imagePhase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: heroHeight + 60)
                                .clipped()
                                .scaleEffect(scaleEffect)
                                .offset(y: parallaxOffset)

                        case .failure:
                            fallbackPlaceholder

                        case .empty:
                            loadingPlaceholder

                        @unknown default:
                            fallbackPlaceholder
                        }
                    }
                } else {
                    fallbackPlaceholder
                }

                // Gradient fade at bottom (blends into content)
                LinearGradient(
                    colors: [
                        Color.clear,
                        theme.colors.background.opacity(0.6),
                        theme.colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
        }
        .frame(height: heroHeight)
        .clipped()
    }

    // MARK: - Fallback Views

    private var fallbackPlaceholder: some View {
        ZStack {
            // Gradient background matching phase
            LinearGradient(
                colors: [
                    (phase == .morning ? theme.colors.terrainWarm : theme.colors.terrainCool).opacity(0.15),
                    theme.colors.backgroundSecondary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Centered icon
            VStack(spacing: theme.spacing.md) {
                Image(systemName: fallbackIcon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(theme.colors.accent.opacity(0.4))

                // Subtle decorative dots
                HStack(spacing: theme.spacing.xs) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(theme.colors.accent.opacity(0.2))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .offset(y: parallaxOffset * 0.5)
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            theme.colors.backgroundSecondary

            ProgressView()
                .tint(theme.colors.accent)
        }
    }
}

// MARK: - Preview

#Preview("With Image") {
    ScrollView {
        VStack(spacing: 0) {
            ParallaxHeroImage(
                imageUri: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=800",
                fallbackIcon: "cup.and.saucer.fill",
                phase: .morning,
                scrollOffset: 0
            )

            Text("Content below")
                .padding()
        }
    }
    .environment(\.terrainTheme, TerrainTheme.default)
}

#Preview("Fallback") {
    ParallaxHeroImage(
        imageUri: nil,
        fallbackIcon: "cup.and.saucer.fill",
        phase: .evening,
        scrollOffset: 0
    )
    .environment(\.terrainTheme, TerrainTheme.default)
}
