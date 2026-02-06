# TODO - Terrain iOS App

Last updated: 2026-02-06 (Post-audit sync fixes — 330 tests passing)

## Tab Structure (Updated Phase 3)

| Tab | View | Purpose |
|-----|------|---------|
| **Home** | HomeView | Insight + meaning + direction (Co-Star style) |
| **Do** | DoView | Execution (capsule + quick fixes combined) |
| **Ingredients** | IngredientsView | Cabinet management and discovery |
| **Learn** | LearnView | Field Guide educational content |
| **You** | YouView | Progress tracking + settings combined |

**Deprecated Views** (deleted — content moved):
- ~~`TodayView.swift`~~ → HomeView (check-in) + DoView (capsule) — **deleted**
- ~~`RightNowView.swift`~~ → DoView (quick fixes) — **deleted**
- ~~`ProgressView.swift`~~ → YouView — **deleted**
- ~~`SettingsView.swift`~~ → YouView — **deleted**

## Completed (Phase 10 - 2026-01-30) - Comprehensive UX/UI Audit

### Tier 1: High Impact (New User Retention)
- [x] Phase terrain reveal into 2 screens: emotional (nickname + superpower) → practical (trap, ritual, truths, ingredients)
- [x] Move CTA from position 9 to position 5 in HomeView (after check-in and type block)
- [x] Rename "Start Your Capsule" → "Start Today's Practice" (CapsuleStartCTA)
- [x] Rename "Your Daily Capsule" → "Today's Practice" (DoView)
- [x] Replace TypeBlockView raw axis labels (cold/low/shen) with nickname ("Low Flame" / "Restless")
- [x] Fix invalid SF Symbols: `stomach` → `fork.knife`, `brain.head.profile` → `eye` (QuickNeed)
- [x] Fix invalid SF Symbols: `stomach` → `wind` (QuickSymptom bloating), `head.profile` → `exclamationmark.circle` (QuickSymptom headache), `stomach` → `fork.knife` (AreaOfLifeType digestion)
- [x] Fix misleading goal icons: `heart.fill` (Stress) → `wind`, `waveform.path` (Menstrual Comfort) → `drop.fill`
- [x] Add completion screen after onboarding ("You're all set, Welcome [nickname]")
- [x] Change quiz final button "See My Terrain" → "Reveal My Type"

### Tier 2: Medium Impact (Clarity)
- [x] Simplify Welcome screen: remove 3 feature rows, replace with single poetic subtitle
- [x] Group quiz questions into named sections (Temperature, Energy, Body, Cravings, Mind)
- [x] Restyle Safety screen: friendlier title, grouped checkboxes (Pregnancy, Medications, Dietary)
- [x] Remove Daily Tone pill from DateBarView (unexplained jargon for new users)
- [x] Elevate coaching note: bodySmall/secondary with background card
- [x] Convert Quick Fixes from vertical VStack to compact 2-column grid
- [x] Remove check-in header `hand.wave` icon (text question alone is cleaner)
- [x] Add duration inline to level selector ("Full · 10-15 min")

### Tier 3: Polish & Delight
- [x] Auto-expand first Area of Life by default (AreasOfLifeView)
- [x] Change Do tab icon from `play.circle.fill` → `figure.mind.and.body`
- [x] Add plain-language axis labels to Pattern Map ("Temperature tendency (cold ← → warm)", etc.)
- [x] Add dismissible Trends intro card with legend (green=improving, orange=watch, gray=no data)
- [x] Increase completion overlay auto-dismiss from 1.5s → 2.0s (more ceremony)
- [x] Add modifier explanation on reveal Phase 2 ("Your modifier adds nuance...")
- [x] Clean up unused FeatureRow struct from WelcomeView

### Reverted After User Testing
- Auto-expand first Do/Don't "why" explanation — reverted (all items start collapsed)
- Replace info.circle with "Why?" text label — reverted (info.circle kept, looks cleaner)
- Hide Trends sub-tab for <3 days of data — reverted (all 3 sub-tabs always visible)

### Not Changed (Intentionally Preserved)
- Color palette (warm off-white + brown accent) — on-brand and distinctive
- Typography scale (black/bold hierarchy) — editorial voice works well
- Tab count (5) — each tab has clear purpose
- SwiftData architecture — sound, no structural changes needed
- InsightEngine copy quality — "why for you" explanations are best feature

## Completed (Phase 11 - 2026-02-01) - App Store Readiness (Pre-Signing)

- [x] Create `Assets.xcassets` with AppIcon placeholder (1024x1024 slot) + AccentColor (#8B7355 warm brown with dark mode variant)
- [x] Create `PrivacyInfo.xcprivacy` declaring UserDefaults API (CA92.1), email collection (app functionality), no tracking
- [x] Create `Terrain.entitlements` with Sign in with Apple capability
- [x] Register all new files in `project.pbxproj` (PBXFileReference, PBXBuildFile, PBXGroup, PBXResourcesBuildPhase)
- [x] Lock orientation to portrait-only (removed landscape from iPhone, removed iPad orientations entirely)
- [x] Set `TARGETED_DEVICE_FAMILY = 1` (iPhone-only) for both app and test targets
- [x] Add `CODE_SIGN_ENTITLEMENTS = Terrain.entitlements` to Debug + Release
- [x] Add notification usage description for daily ritual reminders
- [x] Build succeeds, all tests pass

### Completed (Apple Developer Program acquired)
- [x] Add actual 1024x1024 app icon PNG (216KB, exists at `Resources/Assets.xcassets/AppIcon.appiconset/`)
- [x] Set `DEVELOPMENT_TEAM = 3HC23XC5KA` in project.pbxproj
- [x] WeatherKit integration (WeatherService.swift) — weather data cached on DailyLog
- [x] HealthKit step count integration (HealthService.swift) — steps cached on DailyLog
- [x] Demographics collection (DemographicsView.swift) — age, gender, ethnicity collected during onboarding

### Still Deferred
- [ ] App Store Connect metadata (screenshots, description, privacy policy URL)
- [ ] TestFlight upload

## Completed (Phase 12 - 2026-02-04) - Supabase Schema Audit & Sync Fix

- [x] Diagnosed Apple Sign In failure: provider not enabled in Supabase (error: `provider_disabled`)
- [x] Added 17 missing columns to `user_profiles` (terrain vector, quiz flags, safety, lifestyle)
- [x] Added 6 missing columns to `daily_logs` (symptom_onset, mood_rating, weather, steps, micro_action)
- [x] Added 2 missing columns to `progress_records` (last_completion_date, monthly_completions)
- [x] Added 2 missing columns to `user_cabinets` (is_staple, last_used_at)
- [x] Added missing UPDATE RLS policy on `user_cabinets`
- [x] Added performance indexes on mood_rating and terrain vector columns
- [x] Updated `UserProfileRow` to sync displayName, alcoholFrequency, smokingStatus
- [x] Updated `DailyLogRow` to sync moodRating, weatherCondition, temperatureCelsius, stepCount, microActionCompletedAt
- [x] Updated `UserCabinetRow` to sync isStaple, lastUsedAt
- [x] Updated all `toRow()`, `apply()`, `toModel()` methods for new fields
- [x] Build succeeds, all tests pass

## Completed (Phase 13 - 2026-02-05) — Terrain Trends Tab Reimagining + TCM Check-In Enrichment

### Part A: Terrain Trends Tab Reimagining
**Goal**: Transform generic analytics into a personalized TCM health narrative that interprets data through the user's terrain lens.

- [x] TrendEngine: `prioritizeTrends()` — terrain-aware category ordering for all 8 types
- [x] TrendEngine: `healthyZone()` — terrain-specific healthy ranges with context copy
- [x] TrendEngine: `computeActivityMinutes()` — track routine vs movement minutes (user-requested)
- [x] TrendEngine: `generateTerrainPulse()` — personalized daily insight generation
- [x] TerrainPulseCard: Hero card with terrain glow colors, pulse animation, urgent indicator
- [x] AnnotatedTrendCard: Trend cards with priority indicator, watch-for badge, terrain note
- [x] ActivityLogCard: Stacked bar chart showing 14-day routine vs movement minutes
- [x] YouViewModels: New types (AnnotatedTrendResult, TerrainHealthyZone, ActivityMinutesResult, TerrainPulseInsight)
- [x] EvolutionTrendsView: Updated to show new components conditionally
- [x] YouView: Compute and pass terrain-aware data to EvolutionTrendsView
- [x] TrendEngineTests: 26 comprehensive tests for all new methods
- [x] Build succeeds, all tests pass (200+ total)

### Part B: TCM Diagnostic Signals in Daily Check-In
**Goal**: Add high-value TCM diagnostic signals to the daily check-in flow.

- [x] `sleepQuality: SleepQuality?` — enum: `fellAsleepEasily`, `hardToFallAsleep`, `wokeMiddleOfNight`, `wokeEarly`, `unrefreshing`
- [x] `dominantEmotion: DominantEmotion?` — enum: `calm`, `irritable`, `worried`, `anxious`, `sad`, `restless`, `overwhelmed`
- [x] `thermalFeeling: ThermalFeeling?` — enum: `cold`, `cool`, `comfortable`, `warm`, `hot`
- [x] `digestiveState: DigestiveState?` — enum with appetite and stool quality
- [x] InlineCheckInView: Optional secondary pickers collapsed by default
- [x] InsightEngine: Uses TCM diagnostic signals to generate terrain-specific guidance
- [x] DailyLog model + Supabase sync: All 4 new columns added and syncing

### Part C: Sync Reliability Fix
- [x] Fixed PostgreSQL timestamp parsing in SupabaseSyncService — sync was failing because PostgreSQL returns `2026-02-05 06:54:06.536161+00` format which Swift's default Codable Date decoder couldn't parse
- [x] Added `SyncDateFormatters.parseTimestamp()` supporting both PostgreSQL and ISO8601 formats
- [x] Changed all Row types to use `String` for timestamp fields with computed `...Date` properties
- [x] Enhanced Apple Sign In error handling with user-friendly messages for all error cases

## Completed (Phase 14 - 2026-02-05) — TCM Personalization: Cycle Phase, Profile Enrichment, HealthKit Expansion & Quarterly Check-In

**Goal**: Add the remaining high-value TCM personalization dimensions that don't fit into daily check-in — menstrual cycle phase (the single strongest content modifier for ~50% of users), hydration/thirst patterns, and sweat patterns. Also build a lightweight "terrain check-in" that re-evaluates key indicators without requiring a full quiz retake.

### Data Foundation & Sync
- [x] Add `cyclePhase: CyclePhase?` to DailyLog — enum: `menstrual`, `follicular`, `ovulatory`, `luteal`, `notApplicable` with TCM context
- [x] Add `symptomQuality: SymptomQuality?` to DailyLog — enum: `dull`, `sharp`, `heavy`, `burning`, `migrating` with TCM patterns
- [x] Add `sleepDurationMinutes: Double?`, `sleepInBedMinutes: Double?`, `restingHeartRate: Int?` to DailyLog (HealthKit cache)
- [x] Add `hydrationPattern: HydrationPattern?` to UserProfile — 4 cases with TCM signals
- [x] Add `sweatPattern: SweatPattern?` to UserProfile — 5 cases with TCM signals
- [x] Add `lastPulseCheckInDate: Date?` to UserProfile
- [x] Supabase: Add cycle_phase, symptom_quality, sleep/HR columns to daily_logs
- [x] Supabase: Add hydration_pattern, sweat_pattern, last_pulse_check_in_date to user_profiles
- [x] SupabaseSyncService: Full bidirectional sync for all new fields (DailyLogRow + UserProfileRow)
- [x] SyncFieldsRoundTripTests: 13 tests verifying enum rawValue round-trips for data integrity

### HealthKit Expansion
- [x] Read step count from HealthKit — implemented in `HealthService.swift`, cached on DailyLog.stepCount
- [x] Read sleep analysis from HealthKit (in-bed time, asleep time, stages on Apple Watch)
- [x] Read resting heart rate from HealthKit (elevated = heat/shen; low = cold/deficient)
- [x] Feed sleep/heart rate into TrendEngine: Sleep Duration trend + Resting HR trend
- [x] Updated terrainPriorityMap, terrainWatchForCategories, healthyZone, terrainNoteForTrend for 2 new categories
- [x] HealthTrendTests: 9 tests for sleep duration and resting heart rate trends

### Quarterly Terrain Check-In
- [x] Build lightweight "Terrain Pulse" check-in (5 questions, not full 13-question quiz)
- [x] TerrainDriftDetector: builds mini TerrainVector, classifies via TerrainScoringEngine, compares against current profile
- [x] PulseCheckInView: 5-step sheet with radio options, progress dots, and drift result screen
- [x] Wired into YouView Terrain sub-tab: "Terrain Pulse" card with 90-day prominence logic
- [x] TerrainDriftDetectorTests: 9 tests covering no-change, minor-shift, significant-drift, engine consistency

### Post-Audit Sync Fixes (2026-02-06)
- [x] Dropped 3 orphaned RPC functions (get_mood_analytics, get_streak_analytics, get_activity_duration_analytics) — security vulnerability, never called from app
- [x] RoutineFeedbackDTO: added startedAt, actualDurationSeconds, activityType to sync (previously lost on device-switch)
- [x] UserProfileRow.apply(): restore quizResponses from Supabase (was push-only, never pulled down)
- [x] UserProfileRow.apply(): restore morningNotificationTime and eveningNotificationTime from NotificationPrefsDTO (was push-only)

### Remaining (Phase 14b — Content Integration)
- [ ] InsightEngine: shift all content by cycle phase ("Luteal phase — warming, grounding foods.")
- [ ] SuggestionEngine: boost warming ingredients during luteal, blood-building during follicular
- [ ] SuggestionEngine: use pain quality to differentiate warming vs cooling ingredient recommendations
- [ ] UI: Add cycle phase picker and symptom quality secondary picker to check-in flow

## Phase 15 — Home Tab Redesign (Co-Star Inspired)

**Goal**: Transform the Home tab into a Co-Star-style editorial experience with punchy headlines, flowing paragraphs, and expandable life areas with personalized TCM readings.

### Home Tab Structure
- [x] Header: Date · Weather · Steps (simple inline)
- [x] Punchy headline (2-5 words, changes daily based on terrain + symptoms + weather)
- [x] Flowing paragraph (multiple impactful sentences: what to stop, what to do, rhetorical questions)
- [x] Do/Don't section (clean two-column, no info buttons)
- [x] Small CTA button: "Begin Today's Practice" → Do tab
- [x] Life Areas section with dot indicators and expandable detail sheets

### Life Areas (5 Core)
- [x] **Energy** — Vital fire, focus, metabolic warmth
- [x] **Digestion** — Earth center, transformation, absorption
- [x] **Sleep** — Spirit rest, Shen settling, restoration
- [x] **Mood** — Emotional flow, Liver qi, stress response
- [x] **Seasonality** — Living in harmony with nature's cycles

### Life Area Features
- [x] Dot indicator: ○ empty (neutral), ◐ half (moderate focus), ● full (priority)
- [x] Personalized description: how you feel + how you balance it
- [x] Tappable → detail sheet slides in from right
- [x] Detail sheet: description + accuracy buttons + reasons (image deferred)

### Accuracy Feedback System
- [x] "Not Accurate" / "Accurate" buttons on detail sheet
- [ ] Info popup explaining how feedback customizes the experience
- [x] Store feedback via TerrainLogger for future personalization
- [x] Feedback is data collection only (doesn't change content immediately)

### Modifier Areas (Appear When Relevant)
- [x] **Inner Climate** — when temperature imbalance detected (cold terrain + cold weather + cold symptom)
- [x] **Fluid Balance** — when damp/dry modifier active + matching weather/symptoms
- [x] **Qi Movement** — when stagnation detected (low steps + stiffness + stagnation modifier)
- [x] Rendered in HomeView below life areas with "Conditions in play" header
- [x] Tappable → ModifierAreaDetailSheet with reading, balance advice, accuracy feedback, reasons

### Daily Check-In Popup (Future)
- [ ] Move daily symptom/mood check-in from inline HomeView to modal popup
- [ ] Trigger popup on first Home tab visit of the day
- [ ] Make it dismissible but gently persistent
- [ ] Keep current inline version as fallback until popup is polished

## Remaining Work

### Content Pack — Future Expansion
**File**: `Terrain/Resources/ContentPacks/base-content-pack.json`
**Current**: 43 ingredients, 24 routines (8 per tier), 18 movements (9 + tier variants), 17 lessons, 8 programs, 8 terrain profiles (v1.5.0)
**Task**:
- Add more swap options between routines
- Add more routines per tier for warm/neutral terrain types
- Ensure all routine steps have correct timer values

### You Tab - Density Reduction
**File**: `Terrain/Features/You/YouView.swift`
**Status**: ✅ Implemented with DisclosureGroups
**Details**: Progressive disclosure via collapsible sections + Daily Brief card on terrain sub-tab

## Pre-Launch Manual QA Checklist

Consolidated from REVIEW_LOG.md — all features with unverified manual testing.

### Home Tab
- [ ] Life areas: 5 rows with dot indicators (○ ◐ ●) → tap one → detail sheet with reading, advice, accuracy buttons, reasons
- [ ] Modifier areas: Cold+Damp user sees "Conditions in play" (Fluid Balance); Neutral+Balanced sees nothing
- [ ] Headline: flowing paragraph style (not bullet points)
- [ ] Header: date, temperature (°F), step count displayed; graceful when weather/health unavailable
- [ ] Check-in: "More details" drawer → select sleep quality + emotion → kill/relaunch → verify persisted
- [ ] Check-in TCM signals: digestiveState JSONB round-trips correctly through Supabase sync

### Do Tab
- [ ] Tier selection: Full (~10 min movement), Medium (~5 min), Lite (~90 sec) — different routines per tier
- [ ] Phase awareness: before 5PM → morning header + warming routines; after 5PM → evening + calming
- [ ] Per-level completion: complete Full → switch to Medium → Medium is NOT checked
- [ ] Detail sheet: parallax hero image scrolls at ~40% speed; ambient background warm AM / cool PM
- [ ] Duration tracking: complete routine → check Supabase `routine_feedback` has `actualDurationSeconds`
- [ ] Card shadows, Nourish/Move tint colors, coaching note, completion overlay visible

### You Tab
- [ ] Trends: TerrainPulseCard shows terrain-specific copy; trend cards reordered by priority per type
- [ ] Trends: ActivityLogCard shows correct routine vs movement minutes
- [ ] Trends: compare two terrain types → different priority order + different pulse copy
- [ ] Pattern map: 5 colorful gradient bars with emojis matching onboarding HowItWorksView style
- [ ] Timer leak: open/close routine detail sheet repeatedly → no memory growth
- [ ] Headache and Cramps category icons visible (not blank)

### Onboarding
- [ ] Full flow: Welcome → HowItWorks → Goals → Demographics → Quiz → Reveal → Tutorial → Safety → Notifications → Permissions → Account → Complete
- [ ] Demographics: age wheel + gender chips + ethnicity list → "Welcome to the wisdom of Traditional Chinese Medicine"
- [ ] Permissions: "Allow Access" triggers location then health sequentially (test on real device); "Not now" skips
- [ ] Walk through for 2 terrain types (cold-deficient + warm-excess) → verify tutorial content matches type

### Sync & Auth
- [ ] Sign in → verify sync succeeds without "sync issue" message
- [ ] Apple Sign In on simulator → verify helpful error message
- [ ] Sign out → local data cleared → sign back in → data re-syncs from cloud
- [ ] Two-device sync: log mood + mark ingredient as staple on device A → verify on device B
- [ ] Two-device sync: verify notification times, quiz responses, and routine feedback duration all round-trip

### Legal & Settings
- [ ] Welcome screen: tap "Terms" / "Privacy Policy" → SafariView opens with correct URL and warm brown tint
- [ ] You tab → Settings → About → Terms/Privacy → SafariView; Contact Support → Mail app
- [ ] Notifications: toggle settings → verify iOS actually reschedules (not just database update)
- [ ] Notification actions: "Did This" sets `microActionCompletedAt`; "Start Ritual" → Do tab

### Ingredients
- [ ] Filter by Headache: tofu, lettuce, adzuki-bean should NOT appear
- [ ] Filter by Stiffness: different results from Cramps
- [ ] In Season toggle: August/September → `late_summer` season

### Movements
- [ ] Hip Opening Stretch frames 3/5/6 → seated icon (not standing)
- [ ] Morning Qi Flow frames 7/8 → tai chi icon
- [ ] `figure.flexibility` does NOT appear in any movement icon

## Pending External Steps

### TestFlight Deployment
**Status**: Apple Developer Program acquired, code signing configured
**Remaining tasks**:
- [ ] Create App Store Connect record
- [ ] Archive and upload to TestFlight
- [ ] Set up internal testing group
- [ ] Prepare App Store metadata (screenshots, description, privacy policy URL)

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
