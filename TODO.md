# TODO - Terrain iOS App

Last updated: 2026-01-30

## Tab Structure (Updated Phase 3)

| Tab | View | Purpose |
|-----|------|---------|
| **Home** | HomeView | Insight + meaning + direction (Co-Star style) |
| **Do** | DoView | Execution (capsule + quick fixes combined) |
| **Ingredients** | IngredientsView | Cabinet management and discovery |
| **Learn** | LearnView | Field Guide educational content |
| **You** | YouView | Progress tracking + settings combined |

**Deprecated Views** (content moved):
- `TodayView.swift` → HomeView (check-in) + DoView (capsule)
- `RightNowView.swift` → DoView (quick fixes)
- `ProgressView.swift` → YouView
- `SettingsView.swift` → YouView

## Remaining Work

### Do Tab - Quick Suggestions Engine
**File**: `Terrain/Features/Do/DoView.swift`
**Status**: Capsule + terrain filtering + avoid timer all wired; quick fixes use basic tag matching
**Task**:
- Create more sophisticated suggestion engine based on terrain + time of day + symptoms

### Content Pack Quality Pass
**File**: `Terrain/Resources/ContentPacks/base-content-pack.json`
**Current**: 43 ingredients, 24 routines (8 per tier), 9 movements, 17 lessons, 5 programs, 8 terrain profiles
**Task**:
- Review TCM accuracy of all ingredient descriptions with a practitioner
- Ensure all routine steps have correct timer values
- Add more swap options between routines
- Verify terrain_fit coverage (every terrain type should have content at every tier)

### You Tab - Density Reduction
**File**: `Terrain/Features/You/YouView.swift`
**Status**: ✅ Implemented with DisclosureGroups
**Details**: Progressive disclosure via collapsible sections + Daily Brief card on terrain sub-tab

## Blocked by External Dependencies

### Weather Integration
**Blocker**: Requires Apple Developer Program ($99/year)
**Task**:
- Integrate Apple WeatherKit
- Cache weather in DailyLog
- Adjust recommendations based on weather (cold day → warming routines)

### TestFlight Deployment
**Blocker**: Requires Apple Developer Program ($99/year)
**Task**:
- Configure signing & capabilities in Xcode
- Create App Store Connect record
- Archive and upload to TestFlight
- Set up internal testing group

## Completed (Phase 6 - 2026-01-30) - Auth UI + Documentation + Polish

- [x] Wire AuthView into Settings (Account section: sign in/out, sync status, email display)
- [x] Add `.account` step to onboarding flow (after notifications, before completion)
- [x] Add `currentUserEmail` to SupabaseSyncService for display in settings
- [x] You tab density reduction: DisclosureGroups for progressive disclosure + Daily Brief card
- [x] Update TODO.md, README.md, CLAUDE.md to reflect actual completion state

## Completed (Phase 5 - 2026-01-30) - Backend + Persistence + Visualization

- [x] Supabase integration: SupabaseSyncService with bidirectional sync (5 tables, RLS, last-write-wins)
- [x] AuthView: email/password + Apple Sign In + "Continue without account"
- [x] Programs enrollment persistence (ProgramEnrollment SwiftData model)
- [x] Ingredients cabinet fully wired (add/remove, detail sheet toggle, tab badge)
- [x] Do tab avoid timer (60s countdown, persisted to DailyLog, survives restart)
- [x] Historical data visualization: trend sparklines, symptom heatmap, routine effectiveness cards
- [x] Content validation tests (7+ tests verifying schema, terrain coverage, content integrity)
- [x] Accessibility pass: VoiceOver labels, header traits, @ScaledMetric across views
- [x] Content pack version-gated reload (UserDefaults version check instead of existence check)
- [x] RoutineDetailSheet reads SwiftData model only (legacy RoutineData fallback removed)
- [x] Content pack v1.1.0 (43 ingredients)

## Completed (Phase 4 - 2026-01-30) - TCM Expert Improvements

### Phase 1: Content Foundation + Modifier Wiring
- [x] Persist `terrainModifier` on UserProfile (no longer recomputed every view load)
- [x] Expand content pack: 42 ingredients, 24 routines (8 per tier), 9 movements, 17 lessons, 5 programs
- [x] Add `tier` field ("full"/"medium"/"lite") to all routines in content pack

### Phase 2: Terrain-Aware Filtering + "Why For You"
- [x] Wire Do tab to SwiftData: routines filtered by `terrainFit` + `tier`, movements by `terrainFit` + intensity
- [x] RoutineDetailSheet accepts actual `Routine` model — shows correct steps/ingredients/why per terrain
- [x] "Why for your terrain" section in RoutineDetailSheet and IngredientDetailSheet
- [x] Do/Don't items have expandable `whyForYou` explanations via InsightEngine

### Phase 3: Personalized Learn + Expanded Symptoms
- [x] Learn tab "Recommended for You" section ranked by terrain relevance
- [x] InsightEngine handles all 8 QuickSymptom types (added headache, cramps, stiff)
- [x] InlineCheckInView sorts symptoms by terrain relevance
- [x] TrendEngine computes 7 categories (added headache, cramps, stiffness)

### Phase 4: Post-Routine Feedback + Seasonal Awareness
- [x] Created PostRoutineFeedbackSheet (Better/Same/Not sure → DailyLog.routineFeedback)
- [x] Wired feedback into RoutineDetailSheet and MovementPlayerSheet completion flows
- [x] Created SeasonalCardView on Home tab (Spring/Summer/Late Summer/Autumn/Winter)
- [x] TrendEngine `computeRoutineEffectiveness()` method correlating feedback with symptom trends

### Phase 5: Level Coaching + Community Normalization
- [x] Level coaching note below Do tab tier selector (terrain-specific + modifier-specific guidance)
- [x] Created CommunityStats with static prevalence percentages per terrain type
- [x] Community normalization text on TerrainRevealView and TerrainHeroHeaderView

### Bug Fixes
- [x] Fixed all routines having `tier=NONE` — set correct tier values from routine ID suffixes
- [x] Replaced "Balanced Breath" (breath exercise misclassified as eat_drink) with "Mint Cool Water"
- [x] Fixed RoutineDetailSheet showing hardcoded congee for all terrain types — now reads actual Routine model

## Completed (Phase 3 - 2025-01-29) - Tab Restructure

- [x] Create InsightEngine for terrain-based content generation (headlines, do/don'ts, areas, theme)
- [x] Create HomeInsightModels (QuickSymptom, DailyTone, HeadlineContent, AreaOfLife types)
- [x] Create HomeView with 8 components (DateBar, Headline, InlineCheckIn, TypeBlock, DoDont, AreasOfLife, ThemeToday, CapsuleStartCTA)
- [x] Create DoView combining capsule + quick fixes sections
- [x] Create YouView combining progress + settings sections
- [x] Update NavigationCoordinator with new Tab enum (.home, .do, .you)
- [x] Add cross-tab navigation for capsule CTA (Home → Do)
- [x] Add `quickSymptoms` property to DailyLog model
- [x] Update MainTabView with new 5-tab structure
- [x] Update README.md with new tab documentation
- [x] Update CLAUDE.md with InsightEngine and tab references

## Completed (Phase 2 - 2025-01-29)

- [x] Fix quiz wording for clarity (Q3 night sweating, Q5 energy timing, Q6 environmental sensitivity)
- [x] Add "I'm not sure" neutral options to quiz questions
- [x] Add 5 missing terrain profiles (Cold+Balanced, Warm+Deficient, Warm+Balanced, Neutral+Deficient, Neutral+Excess)
- [x] Update typography for bolder modern look (display: .black, headlines: .bold)
- [x] Enhance TerrainRevealView with mystical animations (radial pulse, floating particles, glow effects)
- [x] Create TerrainPatternBackground component (animated patterns by terrain type)
- [x] Create Programs feature UI (ProgramsView, ProgramDetailSheet, ProgramDayView)
- [x] Add new quiz question for stress response (now 13 questions total)

## Completed (Phase 1 - 2025-01-28)

- [x] Fix compilation errors (ProgressView rename, LocalizedString DTO, MediaType)
- [x] Implement "Retake Quiz" button with confirmation dialog
- [x] Add smooth animations to Movement Player (frame transitions, pulsing play button)
- [x] Persist notification preferences to UserProfile
- [x] Expand content pack (8 new ingredients, 5 new lessons)
- [x] Create Xcode project for simulator builds
- [x] Update CLAUDE.md with current project status
- [x] Create this TODO.md

## Reference Files

- `PRD - TCM App.rtf` - Full product requirements
- `Content Schema JSON.rtf` - JSON schema for content packs
- `Terrain Scoring Table.rtf` - Quiz scoring algorithm
- `Copy for Terrain Types.rtf` - Copy for all terrain types
