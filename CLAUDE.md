# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Terrain** is a TCM (Traditional Chinese Medicine) daily rituals iOS app built with SwiftUI and SwiftData. The app determines a user's "Terrain" (body constitution) through a quiz, then delivers personalized daily routines.

**Platform**: iOS 17+ (iPhone only)
**Positioning**: "Co-Star clarity + Muji calm" for TCM lifestyle routines

## Git Identity

All commits must use:
- **Name:** `andeslee444`
- **Email:** `203938801+andeslee444@users.noreply.github.com`

Always pass `--author="andeslee444 <203938801+andeslee444@users.noreply.github.com>"` on every `git commit`.

## Code Quality

Write code as if the maintainer is a violent psychopath who knows where you live. No shortcuts that could cause future problems — act as a L11 Google Fellow would. When explaining technical concepts, use metaphors for non-technical understanding.

## Documentation Workflow

A PostToolUse hook runs after every Edit/Write on files under `Core/`, `Features/`, `DesignSystem/`, `Engine/`, or `Services/`. After significant changes:
- Update `TODO.md` with task status or new items
- Update this `CLAUDE.md` if architecture changed or new files added
- Update `Terrain/README.md` if features changed

## Change Log Protocol

After completing any action that modifies 2+ files or makes non-trivial logic changes, append an entry to `REVIEW_LOG.md` in the project root before moving to the next task. Create the file if it doesn't exist yet. This leaves breadcrumbs for a senior engineer to review the work.

### What counts as "non-trivial"
- Any new file created
- Any function signature changed
- Any model/schema property added or removed
- Any scoring logic, engine, or service modified
- Any navigation or coordinator flow changed
- Skip: typo fixes, comment-only edits, import reordering

### Entry format

```
## [YYYY-MM-DD HH:MM] — Short title (e.g., "Add lifestyle quiz questions")

**Files touched:**
- `path/to/file.swift` — what changed in this file (1 sentence)
- `path/to/other.swift` — what changed (1 sentence)

**What changed (plain English):**
2-3 sentences a non-engineer could understand. Use metaphors if helpful.
Example: "Added two new questions to the quiz about drinking and smoking.
These act like seasoning on the terrain score — they nudge it slightly
but can't change the main dish."

**Why:**
1 sentence on the motivation or user request that drove this.

**Risks / watch-fors:**
- Anything that could break, regress, or surprise someone
- Migration concerns (e.g., "new optional field — existing users get nil, no migration needed")
- "None identified" is acceptable if genuinely low-risk

**Testing status:**
- [ ] Builds cleanly
- [ ] Existing tests pass
- [ ] New tests added (list them)
- [ ] Manual verification needed (describe what)

**Reviewer nudge:**
One sentence pointing the reviewer to the most important thing to look at.
Example: "Double-check the 0.4 weight on lifestyle questions doesn't
shift boundary cases in TerrainScoringEngineTests."
```

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
| `TerrainScoringEngineTests.swift` | All 8 types + 5 modifiers + boundary cases |
| `ConstitutionServiceTests.swift` | Readouts, signals, defaults, watch-fors |
| `ContentPackValidationTests.swift` | Schema integrity, terrain coverage, content pack structure |
| `ContentPackServiceTests.swift` | JSON parsing, DTO-to-model conversion |
| `SuggestionEngineTests.swift` | Terrain-aware ingredient/routine suggestions |
| `DayPhaseTests.swift` | Phase boundaries (5AM/5PM), affinity scoring, intensity shifting |

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
- Cross-tab navigation: `coordinator.navigate(to: .do)` switches tabs programmatically
- Generic navigation: `coordinator.navigate(to: .ingredients)`
- Legacy CTA mapping: `handleCTAAction()` routes old action strings to new tabs

### SwiftData Schema

**User Models** (`Core/Models/User/`):
- `UserProfile`: Terrain type, goals, quiz responses, notification prefs, `terrainModifier` (persisted)
- `UserCabinet`: Saved ingredients
- `DailyLog`: Daily check-in data with `moodRating: Int?` (1-10), `quickSymptoms: [QuickSymptom]`, `routineFeedback: [RoutineFeedbackEntry]`, completion tracking
- `ProgressRecord`: Streaks, completion history
- `ProgramEnrollment`: Multi-day program enrollment and day progress tracking

**Content Models** (`Core/Models/Content/`):
- `Ingredient`, `Routine`, `Movement`, `Lesson`, `Program`, `TerrainProfile`
- All loaded from content pack on first launch

**Migrations** (`Core/Models/TerrainSchemaV1.swift`):
- SwiftData `VersionedSchema` + `SchemaMigrationPlan`. When adding/removing a model property, define a new schema version here and add a migration stage.

**Shared Models** (`Core/Models/Shared/`):
- Enums, value types, and view models: `HomeInsightModels`, `QuickNeed`, `YouViewModels`, `CommunityStats`, `TerrainCopy`, `Tags`, `SafetyFlags`, `LocalizedString`, `MediaAsset`

### Feature Modules

Each feature in `Features/` is self-contained. Key modules:

| Feature | Key Files | Purpose |
|---------|-----------|---------|
| **Home** | `HomeView.swift` + `Components/` (DateBar, Headline, TypeBlock, InlineCheckIn, DoDont, AreasOfLife, ThemeToday, CapsuleStartCTA, WeatherHealthBarView) | Insight-driven home tab |
| **Do** | `DoView.swift`, `DayPhase.swift` | Capsule routines + quick fixes, morning/evening phase logic (5AM/5PM split based on TCM Kidney hour) |
| **Ingredients** | `IngredientsView.swift`, `IngredientDetailSheet.swift`, `IngredientEmoji.swift` | Browse/search ingredients, terrain-ranked detail sheets, per-ingredient emoji mapping |
| **You** | `YouView.swift` + `Components/` (TerrainHeroHeader, TerrainIdentity, Signals, WatchFors, Defaults, EnhancedPatternMap, SymptomHeatmap, EvolutionTrends, TrendSparklineCard, RoutineEffectivenessCard, PreferencesSafety) + `QuizEditView.swift`, `QuizEditResultView.swift` | Progress (streaks, calendar, trends) + settings + terrain re-quiz |
| **Onboarding** | `OnboardingCoordinatorView.swift`, `WelcomeView.swift`, `HowItWorksView.swift`, `GoalsView.swift`, `QuizView.swift`, `TerrainRevealView.swift`, `TutorialPreviewView.swift`, `SafetyGateView.swift`, `NotificationsView.swift`, `PermissionsView.swift`, `OnboardingCompleteView.swift` | 11-step flow: welcome → how it works → goals → quiz → 2-phase reveal → tutorial (5 pages) → safety → notifications → permissions → account → completion |
| **Auth** | `AuthView.swift` | Email/password + Apple Sign In, used in onboarding and settings |
| **Programs** | `ProgramsView.swift`, `ProgramDetailSheet.swift`, `ProgramDayView.swift` | Multi-day programs with enrollment persistence |
| **Today** | `RoutineDetailSheet.swift`, `MovementPlayerSheet.swift`, `PostRoutineFeedbackSheet.swift`, `DailyCheckInSheet.swift` | Detail sheets used by Do tab (not a tab itself) |
| **Learn** | `LearnView.swift`, `LessonDetailSheet.swift` | TCM education with terrain-ranked lessons |

**Deprecated — do not import or reference these files** (still on disk but dead code):
- `Features/Today/TodayView.swift` → replaced by HomeView + DoView
- `Features/RightNow/RightNowView.swift` → replaced by DoView
- `Features/Progress/ProgressView.swift` → replaced by YouView
- `Features/Settings/SettingsView.swift` → replaced by YouView

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
| `TrendEngine` | `Core/Services/TrendEngine.swift` | 14-day rolling trends across 8 categories (mood, sleep, digestion, stress, energy, headache, cramps, stiffness) + routine effectiveness scoring |
| `ContentPackService` | `Core/Services/ContentPackService.swift` | Parses bundled JSON into SwiftData models (version-gated reload via UserDefaults) |
| `SupabaseSyncService` | `Core/Services/SupabaseSyncService.swift` | Bidirectional sync with Supabase (RLS, last-write-wins). Tables: `user_profiles`, `daily_logs`, `progress_records`, `user_cabinets`, `program_enrollments`. Auth: email/password, Apple Sign In |
| `SuggestionEngine` | `Core/Services/SuggestionEngine.swift` | Terrain-aware ingredient and routine suggestions |
| `HealthService` | `Core/Services/HealthService.swift` | Reads daily step count from HealthKit, caches on DailyLog. Gracefully handles unavailable/denied authorization |
| `WeatherService` | `Core/Services/WeatherService.swift` | WeatherKit integration for location-based weather data |
| `NotificationService` | `Core/Services/NotificationService.swift` | Personalized notification scheduling (7-day rolling window), terrain-aware micro-actions, UNNotificationCenter delegate, deep-link bridge via @AppStorage |
| `TerrainLogger` | `Core/Services/TerrainLogger.swift` | Structured os.log loggers by category: persistence, sync, navigation, contentPack, weather, health, notifications |

## Common Pitfalls

- **`.do` tab requires backticks**: `Tab.do` is a Swift reserved keyword. Always write `` Tab.`do` `` or you'll get a cryptic compiler error.
- **SwiftData migrations — know when you need one**: Adding a new **optional** property to an `@Model` does NOT require a versioned migration — SwiftData handles it automatically (existing rows get `nil`). A new schema version in `Core/Models/TerrainSchemaV1.swift` is only needed for renaming/deleting columns or custom data transforms. **Important**: each `VersionedSchema` must contain distinct model type definitions (nested typealias or separate classes). If two versions both reference the same live `.self` class, SwiftData crashes with "Duplicate version checksums."
- **Content pack version gating**: `ContentPackService.loadBundledContentPackIfNeeded()` compares the JSON version against UserDefaults. If you edit `base-content-pack.json` but don't bump the version number, your changes won't load on existing installs.
- **Localized string wrapping**: Every user-facing string in `base-content-pack.json` must be an object: `{ "en-US": "..." }`. A bare string will crash the DTO parser.

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

### Reusable Components (`DesignSystem/Components/`)
```swift
// Buttons (TerrainButton.swift) — all use HapticManager.light()
TerrainPrimaryButton(title: "Continue", action: { })
TerrainSecondaryButton(title: "Back", action: { })
TerrainTextButton(title: "Skip", action: { })
TerrainChip(label: "Tag", isSelected: true, action: { })
TerrainIconButton(systemName: "xmark", action: { })

// Other components
TerrainCard { ... }              // Standard card container
TerrainTextField(...)            // Themed text input
TerrainEmptyState(...)           // Empty state placeholder
SkeletonLoader(...)              // Loading placeholder
TerrainPatternBackground(...)    // Animated terrain-type background
```

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

## Config Files

- `Resources/Supabase.plist` — Supabase project URL + anon key for cloud sync
- `Resources/Assets.xcassets/` — Asset catalog (AppIcon placeholder + AccentColor #8B7355)
- `Resources/PrivacyInfo.xcprivacy` — Apple privacy manifest (UserDefaults, email collection, no tracking)
- `Terrain.entitlements` — App capabilities (Sign in with Apple, WeatherKit, HealthKit)
- `ExportOptions.plist` — App Store export config (team ID `3HC23XC5KA`, automatic signing, symbol upload)
- `Package.swift` — SPM compatibility shim (primary builds use `Terrain.xcodeproj`)

### SPM Dependencies

Managed via Xcode's SPM integration (see `project.xcworkspace/xcshareddata/swiftpm/Package.resolved`):
- **Supabase Swift SDK** (v2.41.0) — cloud sync, auth. Pulls in transitive deps: Auth, Functions, PostgREST, Realtime, Storage, Helpers

## App Store Build Settings

- **iPhone-only**: `TARGETED_DEVICE_FAMILY = 1` (no iPad)
- **Portrait-only**: Landscape orientations removed
- **Entitlements**: `CODE_SIGN_ENTITLEMENTS = Terrain.entitlements`
- **Notification description**: Daily ritual reminders
- **Deferred**: `DEVELOPMENT_TEAM`, actual app icon, App Store Connect metadata

## Repository

GitHub: `https://github.com/andeslee444/shen.git`

## Reference Documents

- `PRD - TCM App.rtf` - Full product requirements
- `Content Schema JSON.rtf` - JSON schema for content packs
- `Terrain Scoring Table.rtf` - Quiz scoring algorithm details
- `Copy for Terrain Types.rtf` - Copy templates for all terrain types
