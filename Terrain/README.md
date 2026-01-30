# Terrain - TCM Daily Rituals iOS App

**Terrain** is an iOS app for Traditional Chinese Medicine (TCM) daily rituals. It determines a user's "Terrain" (body constitution) through a quiz, then delivers personalized daily routines with a "Co-Star clarity + Muji calm" aesthetic.

## Features

### Tab Structure
| Tab | Purpose |
|-----|---------|
| **Home** | Insight + meaning + direction (Co-Star style) - personalized headlines, do/don'ts, life areas |
| **Do** | Execution - daily capsule (routine + movement) + quick fixes |
| **Ingredients** | Cabinet management and discovery |
| **Learn** | Field Guide educational content |
| **You** | Progress tracking (streaks, calendar) + settings |

### Core Features
- **Onboarding Flow**: 8-screen flow with goals selection, 13-question quiz, and optional account creation
- **Terrain Scoring Engine**: Determines body constitution from 5 axes (8 types × 5 modifiers)
- **Terrain Reveal**: High-impact reveal with community normalization ("X% share your type")
- **InsightEngine**: Generates personalized headlines, do/don'ts, seasonal notes, and "why for you" explanations
- **Terrain-Aware Content**: Do tab filters routines + movements by terrain type and tier (Full/Medium/Lite)
- **Post-Routine Feedback**: Better/Same/Not sure after completing routines and movements
- **Seasonal Awareness**: Home tab shows season-specific guidance per terrain type
- **8 Quick Symptoms**: Check-in chips sorted by terrain relevance, all adjusting daily content
- **TrendEngine**: 14-day rolling trends across 7 health categories + routine effectiveness scoring
- **Trend Visualization**: Sparkline charts, symptom heatmap, and routine effectiveness cards in You tab
- **Movement Player**: Frame-by-frame illustrated exercise flows with feedback on completion
- **Ingredients Cabinet**: Add/remove ingredients with tab badge and detail sheet toggle
- **Programs Enrollment**: Multi-day program persistence via ProgramEnrollment SwiftData model
- **Supabase Sync**: Bidirectional cloud sync (5 tables, RLS, last-write-wins strategy)
- **Authentication**: Email/password, Apple Sign In, optional during onboarding, accessible from Settings
- **Expanded Content**: 43 ingredients, 24 routines, 9 movements, 17 lessons, 5 programs
- **SwiftData Persistence**: Local storage for user data, symptoms, routine feedback
- **Accessibility**: VoiceOver labels, header traits, @ScaledMetric support across views
- **Content Validation Tests**: Schema verification, terrain coverage, content integrity checks

### Future Phases
- WeatherKit integration (requires Apple Developer Program)
- TestFlight deployment (requires Apple Developer Program)

## Technology Stack

| Component | Choice |
|-----------|--------|
| UI | SwiftUI (iOS 17+) |
| Data | SwiftData |
| Architecture | MVVM |
| Min iOS | 17.0 |

## Project Structure

```
Terrain/
├── App/                          # Entry point
│   ├── TerrainApp.swift          # @main app entry
│   ├── MainTabView.swift         # Tab bar (Home, Do, Ingredients, Learn, You)
│   └── NavigationCoordinator.swift # Cross-tab navigation + deep linking
├── Core/
│   ├── Models/                   # SwiftData models
│   │   ├── Content/              # Ingredient, Routine, Movement, Lesson, Program, TerrainProfile
│   │   ├── User/                 # UserProfile, UserCabinet, DailyLog, ProgressRecord, ProgramEnrollment
│   │   └── Shared/               # LocalizedString, Tags, SafetyFlags, MediaAsset, HomeInsightModels, CommunityStats, TerrainCopy, YouViewModels
│   ├── Engine/                   # TerrainScoringEngine (quiz scoring, 13 questions)
│   └── Services/                 # ContentPackService, InsightEngine, ConstitutionService, TrendEngine, SupabaseSyncService, SuggestionEngine
├── Features/                     # Feature modules
│   ├── Onboarding/              # Welcome, Goals, Quiz, TerrainReveal, Safety, Notifications, Account
│   ├── Home/                    # HomeView + Components/ (DateBar, Headline, TypeBlock, etc.)
│   ├── Do/                      # DoView (capsule + quick fixes combined)
│   ├── Today/                   # RoutineDetailSheet, MovementPlayerSheet, PostRoutineFeedbackSheet
│   ├── RightNow/                # RightNowView (legacy, content moved to Do)
│   ├── Ingredients/             # IngredientsView, IngredientDetailSheet
│   ├── Learn/                   # LearnView, LessonDetailSheet
│   ├── Progress/                # ProgressView (legacy, content moved to You)
│   ├── Programs/                # ProgramsView, ProgramDetailSheet, ProgramDayView
│   ├── Auth/                    # AuthView (email/password + Apple Sign In)
│   ├── Settings/                # SettingsView (legacy, content moved to You)
│   └── You/                     # YouView (progress + settings combined)
├── DesignSystem/
│   ├── Theme/                   # TerrainTheme (colors, typography, spacing, animation)
│   ├── Components/              # TerrainButton, TerrainCard, TerrainTextField, TerrainPatternBackground
│   └── Utilities/               # HapticManager
├── Resources/
│   └── ContentPacks/            # base-content-pack.json
└── Tests/
```

## Design System

### Colors (Muji Calm)
- **Background**: #FAFAF8 (warm off-white)
- **Text Primary**: #1A1A1A (near-black)
- **Accent**: #8B7355 (warm brown)
- **Success**: #7A9E7E
- **Warning**: #C9A96E

### Typography
- System font with bold/black weights for headlines (modern impact)
- Regular weights for body text (calm readability)
- Display: `.black` weight for dramatic reveals
- Headlines: `.bold` weight for confident clarity
- Generous line height for readability

### Spacing
- Base unit: 8pt
- Scale: xxs(4), xs(8), sm(12), md(16), lg(24), xl(32), xxl(48)

### Animation
- Standard: 0.3s easeInOut
- Reveal: 0.5s for signature moments

## Terrain System

### 5 Scoring Axes
1. `cold_heat`: -10 to +10 (negative=cold, positive=heat)
2. `def_excess`: -10 to +10 (negative=deficient, positive=excess)
3. `damp_dry`: -10 to +10 (negative=damp, positive=dry)
4. `qi_stagnation`: 0 to +10 (higher=more stuck)
5. `shen_unsettled`: 0 to +10 (higher=more sleep/mind unsettled)

### 8 Primary Types
| Type | Nickname | Condition |
|------|----------|-----------|
| Cold + Deficient | Low Flame | cold_heat ≤ -3, def_excess ≤ -3 |
| Cold + Balanced | Cool Core | cold_heat ≤ -3, -2 ≤ def_excess ≤ 2 |
| Neutral + Deficient | Low Battery | -2 ≤ cold_heat ≤ 2, def_excess ≤ -3 |
| Neutral + Balanced | Steady Core | -2 ≤ cold_heat ≤ 2, -2 ≤ def_excess ≤ 2 |
| Neutral + Excess | Busy Mind | -2 ≤ cold_heat ≤ 2, def_excess ≥ 3 |
| Warm + Balanced | High Flame | cold_heat ≥ 3, -2 ≤ def_excess ≤ 2 |
| Warm + Excess | Overclocked | cold_heat ≥ 3, def_excess ≥ 3 |
| Warm + Deficient | Bright but Thin | cold_heat ≥ 3, def_excess ≤ -3 |

### 5 Modifiers
- **Damp (Heavy)**: damp_dry ≤ -3
- **Dry (Thirsty)**: damp_dry ≥ 3
- **Stagnation (Stuck)**: qi_stagnation ≥ 4
- **Shen (Restless)**: shen_unsettled ≥ 4
- **None**: No modifier threshold met

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- macOS 14.0+ (Sonoma)

### Setup

1. Open the project in Xcode:
   ```bash
   cd Terrain
   open Terrain.xcodeproj
   ```

   Or create a new Xcode project and add these source files.

2. Build and run on simulator or device.

### Creating Xcode Project

If you don't have the `.xcodeproj` file:

1. Open Xcode → File → New → Project
2. Select "App" under iOS
3. Product Name: "Terrain"
4. Interface: SwiftUI
5. Language: Swift
6. Storage: SwiftData
7. Delete the generated ContentView.swift
8. Add all files from this directory to the project
9. Set deployment target to iOS 17.0

## Content Pack

The app ships with a bundled content pack at `Resources/ContentPacks/base-content-pack.json`. This includes:

- **43 Ingredients** with TCM properties, cautions, and cultural context
- **24 Routines** (8 per tier: full/medium/lite) covering all 8 terrain types
- **9 Movements** across restorative, gentle, and moderate intensities
- **17 Lessons** organized by topic (cold_heat, damp_dry, qi_flow, shen, safety, seasonality, methods)
- **5 Programs** (multi-day guided sequences per terrain cluster)
- **8 Terrain Profiles** with superpowers, traps, truths, and starter ingredients

## Testing

```bash
# Run unit tests
xcodebuild test -scheme Terrain -destination 'platform=iOS Simulator,name=iPhone 15'
```

59+ unit tests covering:
- **TerrainScoringEngine**: All 8 types + 5 modifiers + boundary cases (37 tests)
- **ConstitutionService**: Readouts, signals, defaults, watch-fors (11 tests)
- **TrendEngine**: 7-category trends, empty/insufficient data handling (4 tests)
- **ContentPackValidation**: Schema integrity, terrain coverage, content pack structure (7+ tests)
- **SuggestionEngine**: Terrain-aware ingredient/routine suggestions

## License

Proprietary - All rights reserved
