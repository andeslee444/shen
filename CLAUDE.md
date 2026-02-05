# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Terrain** is a TCM (Traditional Chinese Medicine) daily rituals iOS app built with SwiftUI and SwiftData. The app determines a user's "Terrain" (body constitution) through a quiz, then delivers personalized daily routines.

**Platform**: iOS 17+ (iPhone only, portrait only)
**Positioning**: "Co-Star clarity + Muji calm" for TCM lifestyle routines
**Repository**: `https://github.com/andeslee444/Terrain-App.git`

## Git Identity

All commits must use:
- **Name:** `andeslee444`
- **Email:** `203938801+andeslee444@users.noreply.github.com`

Always pass `--author="andeslee444 <203938801+andeslee444@users.noreply.github.com>"` on every `git commit`.

## Code Quality

Write code as if the maintainer is a violent psychopath who knows where you live. No shortcuts that could cause future problems — act as a L11 Google Fellow would. When explaining technical concepts, use metaphors for non-technical understanding.

## Documentation Workflow

A PostToolUse hook (`.claude/hooks/docs-reminder.sh`) runs after every Edit/Write on files under `Core/`, `Features/`, `DesignSystem/`, `Engine/`, or `Services/`. The hook prints a reminder to stderr — it's **informational only** and never blocks. After significant changes:
- Update `TODO.md` with task status or new items
- Update this `CLAUDE.md` if architecture changed or new files added
- Update `Terrain/README.md` if features changed

## Change Log Protocol

After completing any action that modifies 2+ files or makes non-trivial logic changes, append an entry to `REVIEW_LOG.md` in the project root before moving to the next task. **Create the file if it doesn't exist yet** — the first entry should include a header like `# Review Log`.

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

**What changed (plain English):**
2-3 sentences a non-engineer could understand. Use metaphors if helpful.

**Why:**
1 sentence on the motivation or user request that drove this.

**Risks / watch-fors:**
- Anything that could break, regress, or surprise someone
- "None identified" is acceptable if genuinely low-risk

**Testing status:**
- [ ] Builds cleanly
- [ ] Existing tests pass
- [ ] New tests added (list them)
- [ ] Manual verification needed (describe what)

**Reviewer nudge:**
One sentence pointing the reviewer to the most important thing to look at.
```

## Build and Run Commands

**Working directory**: The Xcode project lives in `Terrain/` (one level below the repo root). All `xcodebuild` commands run from there.

```bash
# Open in Xcode
cd Terrain && open Terrain.xcodeproj

# Command-line build
cd Terrain
xcodebuild -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  -configuration Debug build

# Run all unit tests (OS version required — use 18.4 or 18.5)
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4'

# Run a single test class
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  -only-testing:TerrainTests/TerrainScoringEngineTests

# Run a single test method
xcodebuild test -project Terrain.xcodeproj -scheme Terrain \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.4' \
  -only-testing:TerrainTests/TerrainScoringEngineTests/testColdDeficientType
```

### Test Suites

All in `Terrain/Tests/` — **276 unit tests** across 14 files:

| File | Covers |
|------|--------|
| `TerrainScoringEngineTests.swift` | All 8 types + 5 modifiers + boundary cases (38 tests) |
| `ConstitutionServiceTests.swift` | Readouts, signals, defaults, watch-fors (15 tests) |
| `ContentPackValidationTests.swift` | Schema integrity, terrain coverage, content pack structure (15 tests) |
| `ContentPackServiceTests.swift` | JSON parsing, DTO-to-model conversion (9 tests) |
| `SuggestionEngineTests.swift` | Terrain-aware ingredient/routine suggestions (33 tests) |
| `DayPhaseTests.swift` | Phase boundaries (5AM/5PM), affinity scoring, intensity shifting (22 tests) |
| `InsightEngineTests.swift` | Personalized headlines, do/don'ts, themes, symptom-shifted content, life area readings (59 tests) |
| `IngredientBenefitTests.swift` | Ingredient benefit logic and terrain relevance (18 tests) |
| `OnboardingDataConsistencyTests.swift` | Onboarding data flow integrity across all screens (10 tests) |
| `TrendEngineTests.swift` | Terrain-aware trend prioritization, healthy zones, activity minutes, terrain pulse (26 tests) |
| `SyncDateFormattersTests.swift` | PostgreSQL/ISO8601 timestamp parsing, round-trip, timezone offsets (9 tests) |
| `SyncFieldsRoundTripTests.swift` | Enum rawValue round-trips for CyclePhase, SymptomQuality, HydrationPattern, SweatPattern (13 tests) |
| `HealthTrendTests.swift` | Sleep duration + resting heart rate trends, nil handling, priority ordering (9 tests) |
| `TerrainDriftDetectorTests.swift` | Terrain drift detection: no-change, minor-shift, significant-drift, engine consistency (9 tests) |

## Architecture

### Directory Layout

```
Terrain/                        ← Xcode project root
├── App/                        ← Entry point: TerrainApp, MainTabView, NavigationCoordinator
├── Core/
│   ├── Constants/              ← LegalURLs (Terms, Privacy, support email)
│   ├── Engine/                 ← TerrainScoringEngine (quiz → terrain type)
│   ├── Models/
│   │   ├── Content/            ← Ingredient, Routine, Movement, Lesson, Program, TerrainProfile
│   │   ├── User/               ← UserProfile, UserCabinet, DailyLog, ProgressRecord, ProgramEnrollment
│   │   ├── Shared/             ← Enums, value types, view models (Tags, SafetyFlags, LocalizedString, etc.)
│   │   └── TerrainSchemaV1.swift ← SwiftData VersionedSchema + migration plan
│   └── Services/               ← InsightEngine, ContentPackService, SupabaseSyncService, etc.
├── Features/                   ← One directory per feature (see Tab Mapping below)
├── DesignSystem/               ← TerrainTheme, reusable components, HapticManager
├── Resources/                  ← Assets, base-content-pack.json, Supabase.plist, privacy manifest
└── Tests/                      ← 11 test files
```

### Data Flow

```
ContentPack (JSON) → ContentPackService (DTOs) → SwiftData Models → Views
```

Offline-first: `base-content-pack.json` holds all content. `ContentPackService` parses JSON into DTOs with `.toModel()` methods that convert to SwiftData models on first launch. Views query SwiftData via `@Query`. User data (profile, cabinet, logs) persists locally.

### Key Architectural Decisions

| Component | Choice | Why |
|-----------|--------|-----|
| State | `@Observable` + `@AppStorage` | Modern Swift concurrency, simple onboarding flags |
| Persistence | SwiftData | Native iOS 17+, simpler than Core Data |
| Content | Bundled JSON | Offline-first, instant startup |
| Navigation | Coordinators | `NavigationCoordinator` (tabs) + `OnboardingCoordinatorView` (onboarding) |
| Cloud sync | Supabase | Bidirectional sync (RLS, last-write-wins) with email + Apple Sign In auth |
| Dependency | SPM via Xcode | Supabase Swift SDK v2.41.0 (only external dep) |

### App Startup Sequence

`TerrainApp.init()` creates the `ModelContainer` with migration plan, registers notification categories, wires `NotificationDelegate` (in `App/TerrainApp.swift` — handles deep-link routing from notification taps via `@AppStorage`). On first frame: loads content pack → configures Supabase sync → shows either `OnboardingCoordinatorView` or `MainTabView` based on `@AppStorage("hasCompletedOnboarding")`. On every foreground: syncs with Supabase and refills the 7-day notification window.

### Tab Mapping

| Tab | Feature directory | Purpose |
|-----|-------------------|---------|
| **Home** | `Features/Home/` | Insight-driven daily content (InsightEngine-powered) |
| **Do** | `Features/Do/` + `Features/Today/` (sheets) | Capsule routines + quick fixes, morning/evening phase (5AM/5PM split) |
| **Ingredients** | `Features/Ingredients/` | Browse/search ingredients, terrain-ranked detail sheets |
| **Learn** | `Features/Learn/` | TCM education with terrain-relevance scoring |
| **You** | `Features/You/` | Progress (streaks, trends, heatmap) + settings + terrain re-quiz |

Other feature directories: `Onboarding/` (12-step flow: welcome → howItWorks → goals → demographics → quiz → reveal → tutorial → safety → notifications → permissions → account → complete), `Auth/` (email + Apple Sign In), `Programs/` (multi-day programs).

**Deprecated — do not import or reference** (dead code still on disk):
- `Features/Today/TodayView.swift`, `Features/RightNow/`, `Features/Progress/ProgressView.swift`, `Features/Settings/SettingsView.swift`
- `Features/Home/Components/AreasOfLifeView.swift` — deleted, replaced by `LifeAreaRow` + `LifeAreaDetailSheet`

### Navigation

`NavigationCoordinator` (`App/NavigationCoordinator.swift`) is an `@Observable` class initialized as `@State` in `MainTabView` (not app-wide). Tab enum: `.home`, `` .`do` ``, `.ingredients`, `.learn`, `.you`. Cross-tab navigation via `coordinator.navigate(to:)`. CTA action strings via `handleCTAAction()` with legacy mapping for old action names.

### SwiftData Schema

**User Models** (`Core/Models/User/`):
- `UserProfile`: Terrain type, goals, quiz responses, notification prefs, `terrainModifier`, lifestyle fields (`displayName`, `alcoholFrequency`, `smokingStatus`), demographics (`age: Int?`, `gender: String?`, `ethnicity: String?`) — all synced
- `UserCabinet`: Saved ingredients with `isStaple` flag and `lastUsedAt` tracking — all synced
- `DailyLog`: Check-in data — `moodRating: Int?` (1-10), `quickSymptoms`, `routineFeedback` (includes `startedAt`, `actualDurationSeconds`, `activityType`), completion tracking, `weatherCondition`, `temperatureCelsius`, `stepCount`, `microActionCompletedAt`. TCM diagnostic signals: `sleepQuality: SleepQuality?` (5 cases with TCM pattern mapping), `dominantEmotion: DominantEmotion?` (7 cases with organ mapping), `thermalFeeling: ThermalFeeling?` (5 thermal values), `digestiveState: DigestiveState?` (appetite + stool quality struct stored as JSONB) — all synced
- `ProgressRecord`: Streaks, completion history
- `ProgramEnrollment`: Multi-day program enrollment and day progress

**Content Models** (`Core/Models/Content/`): `Ingredient`, `Routine`, `Movement`, `Lesson`, `Program`, `TerrainProfile` — all loaded from content pack on first launch.

**Migrations** (`Core/Models/TerrainSchemaV1.swift`): `VersionedSchema` + `SchemaMigrationPlan`. See Common Pitfalls for when you do/don't need a new version.

### Core Services

| Service | Purpose |
|---------|---------|
| `InsightEngine` | Personalized headlines, do/don'ts, seasonal notes, "why for you", symptom-shifted content, lesson ranking, life area readings (5 core + 3 modifier areas with focus levels), TCM diagnostic signal interpretation |
| `ConstitutionService` | Readouts, signals, defaults, watch-fors per terrain type |
| `TrendEngine` | 14-day rolling trends (mood, sleep, digestion, stress, energy, headache, cramps, stiffness) + routine effectiveness + terrain-aware prioritization, healthy zones, activity minutes, terrain pulse insights |
| `ContentPackService` | JSON → DTO → SwiftData models (version-gated reload via UserDefaults) |
| `SuggestionEngine` | Terrain-aware ingredient and routine suggestions |
| `SupabaseSyncService` | Bidirectional sync (all SwiftData user fields): `user_profiles`, `daily_logs`, `progress_records`, `user_cabinets`, `program_enrollments`. Full column parity with SwiftData models as of Feb 2026 audit. |
| `NotificationService` | 7-day rolling schedule, terrain-aware micro-actions, deep-link bridge via `@AppStorage` |
| `HealthService` | HealthKit step count → cached on DailyLog |
| `WeatherService` | WeatherKit location-based weather data |
| `TerrainLogger` | Structured `os.log` by category: persistence, sync, navigation, contentPack, weather, health, notifications |

## Common Pitfalls

- **`.do` tab requires backticks**: `Tab.do` is a Swift reserved keyword. Always write `` Tab.`do` `` or you'll get a cryptic compiler error.
- **SwiftData migrations — know when you need one**: Adding a new **optional** property to an `@Model` does NOT require a versioned migration — SwiftData handles it automatically (existing rows get `nil`). A new schema version in `TerrainSchemaV1.swift` is only needed for renaming/deleting columns or custom data transforms. **Important**: each `VersionedSchema` must contain distinct model type definitions (nested typealias or separate classes). If two versions both reference the same live `.self` class, SwiftData crashes with "Duplicate version checksums."
- **Content pack version gating**: `ContentPackService.loadBundledContentPackIfNeeded()` compares the JSON version against UserDefaults. If you edit `base-content-pack.json` but don't bump the version number, your changes won't load on existing installs.
- **Localized string wrapping**: Every user-facing string in `base-content-pack.json` must be an object: `{ "en-US": "..." }`. A bare string will crash the DTO parser.
- **Content pack startup ordering**: Content must load before Supabase sync runs, otherwise sync may try to reference SwiftData models that don't exist yet. `TerrainApp.loadContentPack()` enforces this sequence.
- **DayPhase 5AM/5PM split**: `Features/Do/DayPhase.swift` defines `.morning` (5AM–5PM) and `.evening` (5PM–5AM). SuggestionEngine, DoView, and InsightEngine all key off this. If you add time-sensitive content, it must respect this boundary.
- **TerrainLogger categories**: Use `TerrainLogger.persistence`, `.sync`, `.navigation`, `.contentPack`, `.weather`, `.health`, `.notifications` for structured logging. Don't use `print()`.
- **Supabase project**: Project ref is `xsxiykrjwzayrhwxwxbv`. Credentials live in `Resources/Supabase.plist` (no fallback — sync is disabled if plist is missing). The 5 synced tables are: `user_profiles`, `daily_logs`, `progress_records`, `user_cabinets`, `program_enrollments` — all with RLS policies using `(select auth.uid()) = user_id` for optimal per-query caching. **MCP tools available**: `mcp__supabase__execute_sql`, `mcp__supabase__apply_migration`, `mcp__supabase__list_tables`, `mcp__supabase__get_logs` for direct database operations.
- **Supabase timestamp parsing**: PostgreSQL returns timestamps as `2026-02-05 06:54:06.536161+00` (space separator), but Swift's `ISO8601DateFormatter` expects a `T` separator. Always use `SyncDateFormatters.parseTimestamp()` (in `SupabaseSyncService.swift`) when parsing dates from Supabase `Row` — it handles both formats. All Row types store timestamps as `String` with computed `...Date` properties.

## Design System

Access via `@Environment(\.terrainTheme)`. Full token definitions in `DesignSystem/Theme/TerrainTheme.swift`.

```swift
@Environment(\.terrainTheme) private var theme
```

**Key tokens** (see `TerrainTheme.swift` for complete list):
- Colors: `theme.colors.background` (#FAFAF8), `.accent` (#8B7355 warm brown), `.textPrimary` (#1A1A1A), `.success`, `.warning`, `.terrainWarm/Cool/Neutral`
- Spacing (8pt base): `.xxs`(4) through `.xxxl`(64)
- Corner radius: `.small`(4), `.medium`(8), `.large`(12), `.xl`(16), `.full`(9999 pill)
- Typography: `displayLarge`/`Medium` (.black), `headlineLarge`/`Medium`/`Small` (.bold), `bodyLarge`/`Medium`/`Small` (.regular), `labelLarge`/`Medium`/`Small`, `caption`
- Animation: `.quick`(0.15s), `.standard`(0.3s), `.reveal`(0.5s), `.spring`(0.4/0.8)

**Reusable components** (`DesignSystem/Components/`): `TerrainPrimaryButton`, `TerrainSecondaryButton`, `TerrainTextButton`, `TerrainChip`, `TerrainIconButton` (all use `HapticManager.light()`), `TerrainCard`, `TerrainTextField`, `TerrainEmptyState`, `SkeletonLoader`, `TerrainPatternBackground`, `AmbientBackground` (phase-aware gradient with floating particles), `ParallaxHeroImage` (0.4x scroll parallax with AsyncImage), `StepJourneyConnector` (horizontal/vertical step progress), `SafariView` (SFSafariViewController wrapper for in-app legal links).

**Card shadow pattern**:
```swift
.shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
.shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
```

## Terrain Scoring System

The quiz produces a 5-axis vector mapping to 8 primary types x 5 modifiers. Engine: `Core/Engine/TerrainScoringEngine.swift`. Full algorithm details in `Terrain Scoring Table.rtf`.

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

## Content Pack

**File**: `Terrain/Resources/ContentPacks/base-content-pack.json` (relative to repo root)
**Current version**: 1.5.0 — bump this when editing content to trigger reload on existing installs.
**Counts**: 43 ingredients, 24 routines (8 per tier), 18 movements, 17 lessons, 8 programs, 8 terrain profiles.
**Routines** may include optional `hero_image_uri` for parallax hero images in detail sheets.

All localized strings must be objects: `{ "en-US": "..." }`. Full schema documented in `Content Schema JSON.rtf`.

Top-level arrays: `ingredients[]`, `routines[]`, `movements[]`, `lessons[]`, `terrain_profiles[]`, `programs[]`. Each content type has `id`, localized display fields, `tags[]`, `goals[]`, `terrain_fit[]` or `terrain_relevance[]`, and type-specific fields. IDs use kebab-case (`"ginger-honey-tea-lite"`) except terrain profiles which use snake_case (`"cold_deficient_low_flame"`).

## Code Conventions

```swift
// ALWAYS use theme tokens, never hardcode colors/spacing
@Environment(\.terrainTheme) private var theme

// SwiftData queries
@Query(sort: \Ingredient.id) private var ingredients: [Ingredient]

// Sheet presentation
@State private var selectedItem: Item?
.sheet(item: $selectedItem) { item in DetailSheet(item: item) }

// Coordinator access
@Environment(NavigationCoordinator.self) private var coordinator
```

**File naming**: Tab views → `[Feature]View.swift`, sub-components → `Features/[Tab]/Components/*.swift`, detail sheets → `[Feature]DetailSheet.swift`, models → PascalCase matching content type.

## Content Tone

- Muji-calm, chic, informational. Short sentences, gentle confidence.
- **Never say "diagnosis"** → use "profile," "terrain," "pattern"
- **Never say "treatment"** → use "routine," "ritual," "practice"
- Surface human-friendly terms; expand TCM vocabulary via tooltips

## Config Files

- `Resources/Supabase.plist` — Supabase project URL + anon key
- `Resources/PrivacyInfo.xcprivacy` — Apple privacy manifest (UserDefaults, email collection, no tracking)
- `Terrain.entitlements` — Sign in with Apple, WeatherKit, HealthKit
- `ExportOptions.plist` — App Store export (team ID `3HC23XC5KA`, automatic signing)
- `Core/Constants/LegalURLs.swift` — Centralized Terms, Privacy, and support email URLs
- `package.json` (repo root) — Prettier dev dependency only; not used for app builds

## Current Development Phase

**Phase 13 complete** (2026-02-05): Terrain Trends Tab reimagining + TCM diagnostic signals in daily check-in + sync reliability fix.

**Phase 14 planned** (TCM Personalization): Menstrual cycle phase, hydration/sweat patterns, symptom quality pickers, quarterly terrain check-in, HealthKit sleep/heart rate expansion.

**Phase 15 planned** (Home Tab Redesign): Co-Star-inspired editorial experience with punchy headlines, life area dot indicators, and expandable detail sheets.

See `TODO.md` for detailed task breakdown per phase.

## Reference Documents

- `PRD - TCM App.rtf` — Full product requirements
- `Content Schema JSON.rtf` — Complete JSON schema for content packs
- `Terrain Scoring Table.rtf` — Quiz scoring algorithm details
- `Copy for Terrain Types.rtf` — Copy templates for all terrain types
- `docs/notification-system.md` — Notification architecture and micro-action pools
- `docs/terrain-type-system-audit.md` — Terrain type system audit
