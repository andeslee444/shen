# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Terrain** is a TCM (Traditional Chinese Medicine) daily rituals iOS app built with SwiftUI and SwiftData. The app determines a user's "Terrain" (body constitution) through a quiz, then delivers personalized daily routines.

**Platform**: iOS 17+ (iPhone only)
**Positioning**: "Co-Star clarity + Muji calm" for TCM lifestyle routines

## Code Quality

Write code as if the maintainer is a violent psychopath who knows where you live. No shortcuts that could cause future problems — act as a L11 Google Fellow would. When explaining technical concepts, use metaphors for non-technical understanding.

## Documentation Workflow

A PostToolUse hook runs after every Edit/Write on files under `Core/`, `Features/`, `DesignSystem/`, `Engine/`, or `Services/`. After significant changes:
- Update `TODO.md` with task status or new items
- Update this `CLAUDE.md` if architecture changed or new files added
- Update `Terrain/README.md` if features changed

## Build and Run Commands

All commands run from the `Terrain/` subdirectory (where `Terrain.xcodeproj` lives).

```bash
# Open in Xcode and run (Cmd+R)
cd Terrain && open Terrain.xcodeproj

# Command-line build
cd Terrain
xcodebuild -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug build

# Run all unit tests
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run a single test class
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TerrainTests/TerrainScoringEngineTests

# Run a single test method
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:TerrainTests/TerrainScoringEngineTests/testColdDeficientType
```

### Test Suites

All in `Terrain/Tests/`:

| File | Covers |
|------|--------|
| `TerrainScoringEngineTests.swift` | All 8 types + 5 modifiers + boundary cases (37 tests) |
| `ConstitutionServiceTests.swift` | Readouts, signals, defaults, watch-fors (11 tests) |
| `ContentPackValidationTests.swift` | Schema integrity, terrain coverage, content pack structure (7+ tests) |
| `ContentPackServiceTests.swift` | JSON parsing, DTO-to-model conversion |
| `SuggestionEngineTests.swift` | Terrain-aware ingredient/routine suggestions |

## Architecture

### Data Flow

```
ContentPack (JSON) → ContentPackService (DTOs) → SwiftData Models → Views
```

Offline-first: `base-content-pack.json` holds all content. `ContentPackService` parses JSON into DTOs with `.toModel()` methods that convert to SwiftData models on first launch. Views query SwiftData via `@Query`. User data (profile, cabinet, logs) persists locally.

**Gotcha**: `loadBundledContentPackIfNeeded()` uses UserDefaults version gating — it compares the content pack version in JSON against the stored version. Bump the version in `base-content-pack.json` to trigger a reload on next launch.

### Key Architectural Decisions

| Component | Choice | Why |
|-----------|--------|-----|
| State | `@Observable` + `@AppStorage` | Modern Swift concurrency, simple onboarding flags |
| Persistence | SwiftData | Native iOS 17+, simpler than Core Data |
| Content | Bundled JSON | Offline-first, instant startup |
| Navigation | Coordinators | `NavigationCoordinator` (tabs) + `OnboardingCoordinatorView` (onboarding) |

### Navigation Architecture

`NavigationCoordinator` is an `@Observable` class initialized as `@State` in `MainTabView` (not app-wide). It manages:
- Tab selection via `Tab` enum: `.home`, `.do`, `.ingredients`, `.learn`, `.you` (note: `.do` requires backticks in Swift since `do` is a reserved keyword)
- Cross-tab navigation: `navigateToDoTab(withLevel:)` passes a routine level from Home CTA to Do tab
- Generic navigation: `coordinator.navigate(to: .ingredients)`
- Legacy CTA mapping: `handleCTAAction()` routes old action strings to new tabs

### SwiftData Schema

**User Models** (`Core/Models/User/`):
- `UserProfile`: Terrain type, goals, quiz responses, notification prefs, `terrainModifier` (persisted)
- `UserCabinet`: Saved ingredients
- `DailyLog`: Daily check-in data with `quickSymptoms: [QuickSymptom]`, `routineFeedback: [RoutineFeedbackEntry]`, completion tracking
- `ProgressRecord`: Streaks, completion history
- `ProgramEnrollment`: Multi-day program enrollment and day progress tracking

**Content Models** (`Core/Models/Content/`):
- `Ingredient`, `Routine`, `Movement`, `Lesson`, `Program`, `TerrainProfile`
- All loaded from content pack on first launch

### Feature Modules

Each feature in `Features/` is self-contained. Key modules:

| Feature | Key Files | Purpose |
|---------|-----------|---------|
| **Home** | `HomeView.swift` + `Components/` (DateBar, Headline, TypeBlock, InlineCheckIn, DoDont, AreasOfLife, ThemeToday, CapsuleStartCTA) | Insight-driven home tab |
| **Do** | `DoView.swift` | Capsule routines + quick fixes |
| **You** | `YouView.swift` | Progress (streaks, calendar) + settings |
| **Onboarding** | `OnboardingCoordinatorView.swift`, `TerrainRevealView.swift` | 8-screen flow (includes account step), quiz, reveal |
| **Auth** | `AuthView.swift` | Email/password + Apple Sign In, used in onboarding and settings |
| **Programs** | `ProgramsView.swift`, `ProgramDetailSheet.swift`, `ProgramDayView.swift` | Multi-day programs with enrollment persistence |
| **Today** | `RoutineDetailSheet.swift`, `MovementPlayerSheet.swift`, `PostRoutineFeedbackSheet.swift` | Detail sheets used by Do tab |

**Deprecated** (still in repo, content moved): `TodayView.swift` → HomeView + DoView, `RightNowView.swift` → DoView, `ProgressView.swift` → YouView, `SettingsView.swift` → YouView.

### InsightEngine (Home Tab Content)

`InsightEngine` (`Core/Services/InsightEngine.swift`) generates personalized content based on terrain type + current symptoms:

| Method | Output | View |
|--------|--------|------|
| `generateHeadline()` | Editorial statement (Co-Star style) | HeadlineView |
| `generateDoDont()` | Two lists of 4 items each (with `whyForYou` text) | DoDontView |
| `generateAreas()` | 4 life areas with tips | AreasOfLifeView |
| `generateTheme()` | Concluding paragraph | ThemeTodayView |
| `generateSeasonalNote()` | Season-specific terrain guidance | SeasonalCardView |
| `generateWhyForYou()` | Terrain-specific explanation for routines/ingredients | RoutineDetailSheet, IngredientDetailSheet |
| `sortSymptomsByRelevance()` | Terrain-ranked symptom order | InlineCheckInView |
| `rankLessons()` | Terrain-relevance scored lessons (+5 terrain_relevance, +3 topic, +2 modifier, +1 goal) | LearnView |

When users select quick symptoms (all 8: cold, bloating, stressed, tired, poorSleep, headache, cramps, stiff), InsightEngine shifts all content to address those symptoms.

### Additional Services

| Service | File | Purpose |
|---------|------|---------|
| `ConstitutionService` | `Core/Services/ConstitutionService.swift` | Generates readouts, signals, defaults, and watch-fors per terrain type |
| `TrendEngine` | `Core/Services/TrendEngine.swift` | 14-day rolling trends across 7 categories (sleep, digestion, stress, energy, headache, cramps, stiffness) + routine effectiveness scoring |
| `ContentPackService` | `Core/Services/ContentPackService.swift` | Parses bundled JSON into SwiftData models (version-gated reload via UserDefaults) |
| `SupabaseSyncService` | `Core/Services/SupabaseSyncService.swift` | Bidirectional sync with Supabase (5 tables, RLS, last-write-wins). Auth: email/password, Apple Sign In |
| `SuggestionEngine` | `Core/Services/SuggestionEngine.swift` | Terrain-aware ingredient and routine suggestions |

## Design System

Access via `@Environment(\.terrainTheme)`. Theme is set app-wide in `TerrainApp.swift`.

```swift
@Environment(\.terrainTheme) private var theme
```

### Colors
```swift
theme.colors.background        // #FAFAF8 warm off-white
theme.colors.backgroundSecondary // #F5F5F3
theme.colors.surface           // #FFFFFF
theme.colors.textPrimary       // #1A1A1A near-black
theme.colors.textSecondary     // #5C5C5C
theme.colors.textTertiary      // #8C8C8C
theme.colors.accent            // #8B7355 warm brown
theme.colors.accentLight       // #B8A088
theme.colors.accentDark        // #5E4D3B
theme.colors.success           // #7A9E7E
theme.colors.warning           // #C9A96E
theme.colors.terrainWarm       // #C9956E
theme.colors.terrainCool       // #7A8E9E
theme.colors.terrainNeutral    // #9E9E8E
```

### Spacing (8pt base)
```swift
theme.spacing.xxs  // 4
theme.spacing.xs   // 8
theme.spacing.sm   // 12
theme.spacing.md   // 16
theme.spacing.lg   // 24
theme.spacing.xl   // 32
theme.spacing.xxl  // 48
theme.spacing.xxxl // 64
```

### Corner Radius
```swift
theme.cornerRadius.small   // 4
theme.cornerRadius.medium  // 8
theme.cornerRadius.large   // 12
theme.cornerRadius.xl      // 16
theme.cornerRadius.full    // 9999 (pill shapes)
```

### Typography
Full scale: `displayLarge`, `displayMedium`, `headlineLarge`, `headlineMedium`, `headlineSmall`, `bodyLarge`, `bodyMedium`, `bodySmall`, `labelLarge`, `labelMedium`, `labelSmall`, `caption`. Display uses `.black` weight, headlines use `.bold`, body uses `.regular`.

### Animation
```swift
theme.animation.quick    // 0.15s easeInOut
theme.animation.standard // 0.3s easeInOut
theme.animation.reveal   // 0.5s easeInOut
theme.animation.spring   // .spring(response: 0.4, dampingFraction: 0.8)
```

### Button Components (`DesignSystem/Components/TerrainButton.swift`)
```swift
TerrainPrimaryButton(title: "Continue", action: { })
TerrainSecondaryButton(title: "Back", action: { })
TerrainTextButton(title: "Skip", action: { })
TerrainChip(label: "Tag", isSelected: true, action: { })
TerrainIconButton(systemName: "xmark", action: { })
```
All buttons use `HapticManager.light()` for tactile feedback.

### Card Shadow Pattern
```swift
.shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
.shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
```

## Terrain Scoring System

The quiz produces a 5-axis vector mapping to 8 primary types x 5 modifiers. Scoring engine is in `Core/Engine/TerrainScoringEngine.swift`.

```
13 questions across 5 axes:
- cold_heat: -10 to +10 (thermal tendency)
- def_excess: -10 to +10 (energy level)
- damp_dry: -10 to +10 (fluid metabolism)
- qi_stagnation: 0 to +10 (stuck energy)
- shen_unsettled: 0 to +10 (mind/sleep)

Primary Type (8 types):
  cold_heat:  ≤-3 → Cold  | -2..2 → Neutral | ≥3 → Warm
  def_excess: ≤-3 → Deficient | -2..2 → Balanced | ≥3 → Excess

Modifier Priority (first match wins):
  1. Shen (shen_unsettled ≥ 4)
  2. Stagnation (qi_stagnation ≥ 4)
  3. Damp (damp_dry ≤ -3) or Dry (damp_dry ≥ 3)
  4. None
```

## Content Pack Schema (base-content-pack.json)

All localized strings are objects keyed by locale (e.g., `{ "en-US": "..." }`). This applies to `title`, `subtitle`, `name.common`, `why_it_helps.plain`, `why_it_helps.tcm`, step `text`, etc. When adding content, every user-facing string must be wrapped: `{ "en-US": "..." }`.

```
ingredients[]:
  id, name{ common{}, pinyin, hanzi, other_names[] }, category, tags[], goals[],
  seasons[], regions[],
  why_it_helps{ plain{}, tcm{} },
  how_to_use{ quick_uses[{ text{}, prep_time_min, method_tags[] }], typical_amount{} },
  cautions{ flags[], text{} }, cultural_context{ blurb{}, common_in[] }, review{}

routines[]:
  id, type, title{}, subtitle{}, duration_min, difficulty, tier(full|medium|lite),
  tags[], goals[], seasons[], terrain_fit[], ingredient_refs[],
  steps[{ text{}, timer_seconds }],
  why{ one_line{}, expanded{ plain{}, tcm{} } },
  swaps[], avoid_for_hours, cautions{}, review{}

movements[]:
  id, title{}, subtitle{}, duration_min, intensity(restorative|gentle|moderate),
  tags[], goals[], seasons[], terrain_fit[],
  frames[{ asset{ type, uri }, cue{}, seconds }],
  why{ one_line{}, expanded{ plain{}, tcm{} } }, cautions{}, review{}

lessons[]:
  id, title{}, topic,
  body[{ type(paragraph|bullets|callout), text{} | bullets[] }],
  takeaway{ one_line{} }, cta{ label{}, action },
  terrain_relevance[]

terrain_profiles[]:
  id, label{ primary{} }, nickname{}, modifier{ key, display{} },
  principles{ yin_yang, cold_heat, def_excess, interior_exterior },
  superpower{}, trap{}, signature_ritual{}, truths[],
  recommended_tags[], avoid_tags[],
  starter_ingredients[], starter_movements[], starter_routines[]

programs[]:
  id, title{}, subtitle{}, duration_days, tags[], goals[], terrain_fit[],
  days[{ day, routine_refs[], movement_refs[], lesson_ref }]
```

## Naming Conventions

```
Files:
- Tab views: [Feature]View.swift (HomeView, DoView, YouView, LearnView)
- Tab components: Features/[Tab]/Components/*.swift
- Detail sheets: [Feature]DetailSheet.swift or [Item]Sheet.swift
- Models: PascalCase matching content (Ingredient, Routine, Movement)

IDs in content pack:
- kebab-case: "ginger-honey-tea-lite", "morning-qi-flow-full"
- Terrain profiles: "cold_deficient_low_flame", "warm_excess_overclocked"

SwiftUI:
- State: @State private var showSheet = false
- Bindings: @Binding var isPresented: Bool
- Environment: @Environment(\.terrainTheme) private var theme
- Coordinator: @Environment(NavigationCoordinator.self) private var coordinator
```

## Content Tone

- Muji-calm, chic, informational
- Short sentences, gentle confidence
- **Never say "diagnosis"** → use "profile," "terrain," "pattern"
- **Never say "treatment"** → use "routine," "ritual," "practice"
- Surface human-friendly terms; expand TCM vocabulary via tooltips

## UI Patterns

```swift
// ALWAYS use theme tokens, never hardcode colors/spacing
@Environment(\.terrainTheme) private var theme

// SwiftData queries
@Query(sort: \Ingredient.id) private var ingredients: [Ingredient]
@Query private var userProfiles: [UserProfile]

// Sheet presentation
@State private var selectedItem: Item?
.sheet(item: $selectedItem) { item in DetailSheet(item: item) }
```

## Reference Documents

- `PRD - TCM App.rtf` - Full product requirements
- `Content Schema JSON.rtf` - JSON schema for content packs
- `Terrain Scoring Table.rtf` - Quiz scoring algorithm details
- `Copy for Terrain Types.rtf` - Copy templates for all terrain types
