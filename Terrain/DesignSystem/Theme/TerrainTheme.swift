//
//  TerrainTheme.swift
//  Terrain
//
//  Muji-calm design system theme
//  "Co-Star clarity + Muji calm" aesthetic
//

import SwiftUI

/// Main theme container for Terrain app
struct TerrainTheme: Sendable {
    let colors: TerrainColors
    let typography: TerrainTypography
    let spacing: TerrainSpacing
    let animation: TerrainAnimation
    let cornerRadius: TerrainCornerRadius

    static let `default` = TerrainTheme(
        colors: .default,
        typography: .default,
        spacing: .default,
        animation: .default,
        cornerRadius: .default
    )
}

// MARK: - Environment Key

private struct TerrainThemeKey: EnvironmentKey {
    static let defaultValue = TerrainTheme.default
}

extension EnvironmentValues {
    var terrainTheme: TerrainTheme {
        get { self[TerrainThemeKey.self] }
        set { self[TerrainThemeKey.self] = newValue }
    }
}

// MARK: - Colors

/// Muji-calm color palette
/// Low saturation, warm off-white background, near-black text, warm brown accent
struct TerrainColors: Sendable {
    // Primary
    let background: Color
    let backgroundSecondary: Color
    let surface: Color
    let surfaceElevated: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textInverted: Color

    // Accent
    let accent: Color
    let accentLight: Color
    let accentDark: Color

    // Semantic
    let success: Color
    let warning: Color
    let error: Color
    let info: Color

    // Terrain-specific
    let terrainWarm: Color
    let terrainCool: Color
    let terrainNeutral: Color

    static let `default` = TerrainColors(
        // Primary - Warm off-white background
        background: Color(hex: "FAFAF8"),
        backgroundSecondary: Color(hex: "F5F5F3"),
        surface: Color(hex: "FFFFFF"),
        surfaceElevated: Color(hex: "FFFFFF"),

        // Text - Near-black for readability
        textPrimary: Color(hex: "1A1A1A"),
        textSecondary: Color(hex: "5C5C5C"),
        textTertiary: Color(hex: "8C8C8C"),
        textInverted: Color(hex: "FFFFFF"),

        // Accent - Warm brown
        accent: Color(hex: "8B7355"),
        accentLight: Color(hex: "B8A088"),
        accentDark: Color(hex: "5E4D3B"),

        // Semantic - Muted, calm
        success: Color(hex: "7A9E7E"),
        warning: Color(hex: "C9A96E"),
        error: Color(hex: "B87070"),
        info: Color(hex: "7A8E9E"),

        // Terrain
        terrainWarm: Color(hex: "C9956E"),
        terrainCool: Color(hex: "7A8E9E"),
        terrainNeutral: Color(hex: "9E9E8E")
    )
}

// MARK: - Typography

/// System font with bold/medium weights for modern impact
/// "Mystical Wellness" aesthetic - bold headlines, calm body text
struct TerrainTypography: Sendable {
    // Large Display - Black weight for maximum impact
    let displayLarge: Font
    let displayMedium: Font

    // Headlines - Bold for modern clarity
    let headlineLarge: Font
    let headlineMedium: Font
    let headlineSmall: Font

    // Body - Regular for readability
    let bodyLarge: Font
    let bodyMedium: Font
    let bodySmall: Font

    // Labels - Semibold for UI elements
    let labelLarge: Font
    let labelMedium: Font
    let labelSmall: Font

    // Caption
    let caption: Font

    static let `default` = TerrainTypography(
        // Display: Black weight for dramatic reveal moments
        displayLarge: .system(size: 40, weight: .black, design: .default),
        displayMedium: .system(size: 32, weight: .bold, design: .default),

        // Headlines: Bold for modern, confident look
        headlineLarge: .system(size: 28, weight: .bold, design: .default),
        headlineMedium: .system(size: 24, weight: .bold, design: .default),
        headlineSmall: .system(size: 20, weight: .semibold, design: .default),

        // Body: Regular for calm readability
        bodyLarge: .system(size: 17, weight: .regular, design: .default),
        bodyMedium: .system(size: 15, weight: .regular, design: .default),
        bodySmall: .system(size: 13, weight: .regular, design: .default),

        // Labels: Semibold for UI clarity
        labelLarge: .system(size: 15, weight: .semibold, design: .default),
        labelMedium: .system(size: 13, weight: .semibold, design: .default),
        labelSmall: .system(size: 11, weight: .semibold, design: .default),

        caption: .system(size: 12, weight: .medium, design: .default)
    )
}

// MARK: - Spacing

/// Generous whitespace (base unit 8pt)
struct TerrainSpacing: Sendable {
    let xxs: CGFloat  // 4
    let xs: CGFloat   // 8
    let sm: CGFloat   // 12
    let md: CGFloat   // 16
    let lg: CGFloat   // 24
    let xl: CGFloat   // 32
    let xxl: CGFloat  // 48
    let xxxl: CGFloat // 64

    static let `default` = TerrainSpacing(
        xxs: 4,
        xs: 8,
        sm: 12,
        md: 16,
        lg: 24,
        xl: 32,
        xxl: 48,
        xxxl: 64
    )
}

// MARK: - Animation

/// Subtle, easeInOut animations
struct TerrainAnimation: Sendable {
    let quick: Animation
    let standard: Animation
    let reveal: Animation
    let spring: Animation

    let quickDuration: Double
    let standardDuration: Double
    let revealDuration: Double

    static let `default` = TerrainAnimation(
        quick: .easeInOut(duration: 0.15),
        standard: .easeInOut(duration: 0.3),
        reveal: .easeInOut(duration: 0.5),
        spring: .spring(response: 0.4, dampingFraction: 0.8),

        quickDuration: 0.15,
        standardDuration: 0.3,
        revealDuration: 0.5
    )
}

// MARK: - Corner Radius

struct TerrainCornerRadius: Sendable {
    let small: CGFloat   // 4
    let medium: CGFloat  // 8
    let large: CGFloat   // 12
    let xl: CGFloat      // 16
    let full: CGFloat    // 9999 (pill)

    static let `default` = TerrainCornerRadius(
        small: 4,
        medium: 8,
        large: 12,
        xl: 16,
        full: 9999
    )
}

// MARK: - Scaled Metrics

/// Provides `@ScaledMetric` wrappers for hardcoded sizes that should
/// grow with Dynamic Type. Use these in views where icon/element sizes
/// need to scale with the user's accessibility text size preference.
struct TerrainScaledMetrics {
    @ScaledMetric(relativeTo: .body) var iconSmall: CGFloat = 14
    @ScaledMetric(relativeTo: .body) var iconMedium: CGFloat = 16
    @ScaledMetric(relativeTo: .title) var iconLarge: CGFloat = 24
    @ScaledMetric(relativeTo: .largeTitle) var iconXL: CGFloat = 48
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
