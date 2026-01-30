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

### Content Pack — Future Expansion
**File**: `Terrain/Resources/ContentPacks/base-content-pack.json`
**Current**: 43 ingredients, 24 routines (8 per tier), 9 movements, 17 lessons, 8 programs, 8 terrain profiles (v1.3.0)
**Task**:
- Add more swap options between routines
- Add more routines per tier for warm/neutral terrain types
- Ensure all routine steps have correct timer values

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

## Completed (Phase 9 - 2026-01-30) - Content Pack Gap-Filling Expansion (v1.2.0 → v1.3.0)

- [x] Add 3 new programs: `5-day-cool-release` (warm_excess), `5-day-steady-flame` (warm_balanced), `5-day-gentle-warmth` (cold_balanced)
- [x] Populate `terrain_relevance` on all 17 lessons (3–5 terrain profile IDs each)
- [x] Add `terrainRelevance: [String]` property to `Lesson.swift` SwiftData model
- [x] Add `terrain_relevance` to `LessonDTO` in `ContentPackService.swift`
- [x] Add +5 terrain_relevance scoring boost to `InsightEngine.rankLessons()`
- [x] Incorporate 2 previously unused routines (`cooling-water-ritual-lite`, `cucumber-mint-water-medium`) into programs
- [x] Add content validation tests: 8 programs count, terrain_relevance non-empty, ref integrity, coverage
- [x] Bump content pack version to 1.3.0

## Completed (Phase 8 - 2026-01-30) - Content Pack Quality Pass (v1.1.0 → v1.2.0)

- [x] Fix Hanzi errors: `jobs-tears` 藏苡仁→薏苡仁, `rosemary` 迷跌香→迷迭香
- [x] Fix thermal tags: remove incorrect `cooling` from `lotus-seed` (neutral), add `warming` to `citrus-peel`, add `cooling` to `lily-bulb` and `adzuki-bean`
- [x] Add proper word spacing to pinyin for 31 ingredients (e.g., `huanggua`→`huáng guā`, `bājiǎohúxiāng`→`bā jiǎo huí xiāng`)
- [x] Normalize region tags: `taiwaneseHomeStyle`→`taiwanese_home_style`, `cantonese_soup`→`cantonese_home_soups`
- [x] Fix phantom tag: add `reduces_excess` to 5 ingredients (`mung-bean`, `bitter-melon`, `green-tea`, `corn-silk`, `celery`) so `warm_excess_overclocked` terrain profile recommendations match actual content
- [x] Populate `ingredient_refs` for 17 routines (was empty despite steps referencing specific ingredients); 4 water/breath-only rituals correctly left empty
- [x] Bump content pack version to 1.2.0 (triggers version-gated reload on next launch)
- [x] All tests passing: ContentPackServiceTests, SuggestionEngineTests

## Completed (Phase 7 - 2026-01-30) - Suggestion Engine + UX Polish

- [x] SuggestionEngine: multi-factor scoring (terrain, symptoms, time of day, season, goals, cabinet, completed, avoid tags, routine effectiveness)
- [x] Quick Fixes "?" personalization explainer tooltip on Do tab
- [x] Marked suggestion engine TODO as complete — all planned factors implemented

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
