# Terrain - TCM Daily Rituals iOS App

**Terrain** is an iOS app for Traditional Chinese Medicine (TCM) daily rituals. It determines a user's "Terrain" (body constitution) through a quiz, then delivers personalized daily routines with a "Co-Star clarity + Muji calm" aesthetic.

## Features

### MVP (Phase 1)
- **Onboarding Flow**: 7-screen flow with goals selection and 12-question quiz
- **Terrain Scoring Engine**: Determines body constitution from 5 axes
- **Terrain Reveal**: High-impact reveal of user's terrain type with superpowers/traps
- **Today Tab**: Daily routine capsule with Eat/Drink + Move modules
- **Three Routine Levels**: Full (10-15 min), Lite (5 min), Minimum (90 sec)
- **Movement Player**: Frame-by-frame illustrated exercise flows
- **SwiftData Persistence**: Local storage for user data

### Future Phases
- Right Now: Quick fixes for immediate needs
- Ingredients: Cabinet management and discovery
- Learn: Field Guide educational content
- Progress: Streaks, calendar, and insights
- Supabase sync for backup

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
├── Core/
│   ├── Models/                   # SwiftData models
│   │   ├── Content/              # Ingredient, Routine, Movement, Lesson, Program, TerrainProfile
│   │   ├── User/                 # UserProfile, UserCabinet, DailyLog, ProgressRecord
│   │   └── Shared/               # LocalizedString, Tags, SafetyFlags
│   ├── Engine/                   # TerrainScoringEngine
│   ├── Services/                 # ContentPackService, SyncService
│   └── Utilities/
├── Features/                     # Feature modules
│   ├── Onboarding/              # Welcome, Goals, Quiz, Reveal, Safety, Notifications
│   ├── Today/                   # RoutineCapsule, EatDrink, Move modules
│   ├── RightNow/                # Quick fixes
│   ├── Ingredients/             # Cabinet, Discovery
│   ├── Learn/                   # Field Guide lessons
│   └── Progress/                # Streaks, Calendar
├── DesignSystem/
│   ├── Theme/                   # Colors, Typography, Spacing, Animation
│   └── Components/              # Buttons, Cards, TextFields
├── Resources/
│   └── ContentPacks/            # Bundled JSON content
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
- System font with light/regular weights
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

- Ingredients with TCM properties
- Eat/Drink routines for different terrain types
- Movement sequences with frame-by-frame cues
- Field Guide lessons
- Terrain profile definitions

## Testing

```bash
# Run unit tests
xcodebuild test -scheme Terrain -destination 'platform=iOS Simulator,name=iPhone 15'
```

Key test areas:
- TerrainScoringEngine: All 8 types + 5 modifiers
- Content pack parsing
- Quiz flow state management

## License

Proprietary - All rights reserved
