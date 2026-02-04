# Review Log

> **Cleanup note (2026-02-05):** Senior review pass verified and removed 11 entries with no outstanding issues (Apple Sign In hardening, quiz label shortening x2, confirm button + heatmap editing, mood rating, tech debt cleanup, mood in heatmap + welcome bug + schema crash, per-ingredient emoji, 3-screen tutorial, ingredients UI polish, tutorial enhancements). Remaining entries below have unresolved manual verification or architectural significance.

> **Cleanup note (2026-02-05 09:30):** Removed 3 fully resolved entries: (1) InsightEngine test coverage + 7 tag fixes + September season fix — all verified by 47 automated tests; (2) DailyPractice/QuickFix contract tests + movement asset URI audit — all 192 tests pass, no placeholder URIs found; (3) hand-curated icon map — superseded by the 06:00 full icon audit. Updated resolved risk bullets in remaining entries.

---

## [2026-02-05 06:00] — Movement icon audit: 21 frame fixes across 10 movements

**Files touched:**
- `Terrain/Features/Today/MovementPlayerSheet.swift` — Updated 21 entries in `movementIconMap` across 10 movements; overhauled `sfSymbolFromCue` keyword fallback to eliminate `figure.flexibility`; updated 3 mock `MovementData.forLevel()` datasets

**What changed (plain English):**
A full 139-frame audit of all 18 movements found that 21 frames had physically misleading icons. The main offender was `figure.flexibility` — an SF Symbol showing a standing lunge — being used for seated twists, neck tilts, shoulder rolls, and half-lifts. Think of it like putting a "running" icon next to instructions that say "sit in a chair and turn your shoulders." The fix replaces every instance with position-accurate icons: `figure.taichi` for standing twists (grounded + rotational, TCM-native), `figure.yoga` for half-lifts and backbends, `figure.martial.arts` for horse stance, `figure.stand` for standing micro-movements, and `figure.mind.and.body` for seated poses. The keyword fallback was also rewritten so future content pack movements get better defaults.

**Why:**
Follow-up to the hand-curated icon map (Feb 5 02:45 entry). That pass got position accuracy right for base positions but still used `figure.flexibility` for twists and transitions. This audit reviewed every frame of every movement and systematically eliminated the symbol.

**Risks / watch-fors:**
- `figure.taichi`, `figure.yoga`, and `figure.martial.arts` are SF Symbols 5 (iOS 17+). The app requires iOS 17+ so this is safe. **Verified:** build succeeded.
- `figure.flexibility` has ZERO remaining uses in the icon map (only appears in a doc comment). If someone adds it back, they should check the audit.
- 23 frames across 8 pose types still have no ideal SF Symbol match (seated twist, neck tilt, half-lift, etc.) — these are documented as GAP candidates for custom SF Symbol assets in Phase 2.
- Some movements now have several consecutive identical icons (e.g., shoulder-neck-release has 5x `figure.stand`). This is physically correct but visually monotonous — a future custom icon pipeline would add variety.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass
- [ ] Manual verification needed: open each movement, swipe through frames — verify Hip Opening Stretch frames 3/5/6 show seated icon, Morning Qi Flow frames 7/8 show tai chi icon, Dynamic Tension frames 6/7 show martial arts icon

**Reviewer nudge:**
Check that `figure.flexibility` does NOT appear anywhere in the icon map (should only be in a doc comment). Then walk through Hip Opening Stretch — frames 3, 5, 6 should show the seated meditation icon, not a standing forward fold.

---

## [2026-02-05 04:00] — Add personalized notification system with terrain micro-actions

**Files touched:**
- `Core/Services/NotificationService.swift` — NEW: Centralized notification service with micro-action pools (42 actions across 6 terrain/phase groups), scheduling (7-day rolling window), delegate for action handling, deep-link bridge
- `Core/Services/TerrainLogger.swift` — Added `notifications` logger category
- `Core/Models/User/DailyLog.swift` — Added optional `microActionCompletedAt: Date?` field for tracking notification micro-action completions
- `App/TerrainApp.swift` — Wired NotificationDelegate in init(), added foreground reschedule in scenePhase handler
- `App/MainTabView.swift` — Added @AppStorage deep-link consumption for "Start Ritual" notification action -> Do tab
- `Features/You/Components/PreferencesSafetyView.swift` — Fixed bug: notification toggle and time pickers now actually reschedule with UNUserNotificationCenter
- `Features/Onboarding/NotificationsView.swift` — Added TERRAIN_RITUAL categoryIdentifier to onboarding placeholder notifications
- `Terrain.xcodeproj/project.pbxproj` — Added NotificationService.swift to build
- `docs/notification-system.md` — NEW: Full documentation for onboarding engineers

**What changed (plain English):**
Previously, notifications were static reminders. Now each notification is a personalized micro-ritual: a 10-second action matched to the user's terrain type (like "Drink warm water" for Cold terrains or "Splash cool water on your wrists" for Warm terrains). Users can complete the action right from the notification without opening the app, or tap to go straight to their daily routine. Also fixed a bug where changing notification settings in the You tab updated the database but never told iOS to actually reschedule.

**Why:**
User request for personalized, actionable notifications that deliver value without requiring app launch.

**Risks / watch-fors:**
- The NotificationDelegate must be retained as a stored property in TerrainApp — if it gets deallocated, notification actions silently stop working (UNCenter holds a weak reference). **Verified:** correctly stored at line 19 of TerrainApp.swift.
- @AppStorage("pendingNotificationAction") is a lightweight deep-link bridge; if NavigationCoordinator is ever lifted to app level, this can be simplified
- MicroAction pool has 7 items per group — rotation uses `pool.count` (no hardcoded 7)
- New DailyLog field `microActionCompletedAt` is optional — no SwiftData migration needed
- **Scheduling window clarification:** with explicit user times -> 7-day window (up to 14 notifications); without explicit times -> only today's notifications using defaults. Re-called on every foreground resume.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass
- [ ] Manual verification needed: test "Did This" and "Start Ritual" button actions, verify deep-link to Do tab, verify rescheduling on settings change

**Reviewer nudge:**
Manual test the notification flow end-to-end: trigger a notification, tap "Did This", verify `microActionCompletedAt` is set. Then tap "Start Ritual" and verify it lands on the Do tab.

---

## [2026-02-05 01:30] — Add tier-based movement selection to Do tab

**Files touched:**
- `Terrain/Core/Models/Content/Movement.swift` — Added `tier: String?` property and `durationDisplay` computed property
- `Terrain/Core/Services/ContentPackService.swift` — Added `let tier: String?` to `MovementDTO`, passes through to `toModel()`
- `Terrain/Features/Do/DoView.swift` — `selectedMovement` now filters by tier before scoring; movement card uses `durationDisplay`
- `Terrain/Resources/ContentPacks/base-content-pack.json` — Added `tier` field to all 9 existing movements; created 9 new movements; bumped version 1.3.0 -> 1.4.0
- `Terrain/Tests/ContentPackValidationTests.swift` — Added 3 new tests: tier sufficiency, terrain x tier coverage, duration ranges
- `Terrain/Tests/ContentPackServiceTests.swift` — Updated DTO test to include tier; added backward compat test

**What changed (plain English):**
Previously, switching tiers only changed the food routine, not the movement. Now movements have tiers too: Full (~10 min), Medium (~5 min), and Lite (~90 sec). The content pack grew from 9 to 18 movements, and the scoring engine filters by tier first, then scores by terrain fit + time-of-day phase + intensity match.

**Why:**
User identified that movement selection didn't change across tiers, breaking the promise of time-appropriate daily practice.

**Risks / watch-fors:**
- `tier: String?` is optional — no migration needed. Version bump forces content pack reload.
- ~~9 new movements reference placeholder SVG asset URIs — need actual assets before release.~~ **Resolved:** Feb 5 09:00 audit confirmed all 158 frames across 18 movements have concrete `movements/[name]-[frame]` URIs.
- Backward compatibility: nil tier falls back to scoring all movements unfiltered.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass (127 tests, 0 failures)
- [x] New tests added: 3 in ContentPackValidationTests, 1 in ContentPackServiceTests
- [ ] Manual verification needed: fresh install -> quiz -> Do tab -> Full shows ~10 min movement -> Medium shows ~5 min -> Lite shows ~90 sec; verify terrain-appropriate movements per tier

**Reviewer nudge:**
Run `testEveryTerrainTypeHasMovementPerTier` — it checks all 8 terrain types x 3 tiers. Spot-check cold_deficient on Lite gets "Standing Warm-Up" (not "Cool-Down Exhale").

---

## [2026-02-04 23:00] — Add morning/evening phases to Do tab + fix per-level completion bug

**Files touched:**
- `Terrain/Features/Do/DayPhase.swift` — New file: `DayPhase` enum (.morning/.evening) with 5AM/5PM boundary, tag-based affinity scoring, intensity shifting
- `Terrain/Features/Do/DoView.swift` — Phase-aware routine/movement selection, per-level completion fix (checkmarks now track specific routine ID), phase-aware capsule header
- `Terrain/Tests/DayPhaseTests.swift` — New file: 22 tests covering boundaries, scoring, intensity, display
- `Terrain/Terrain.xcodeproj/project.pbxproj` — Registered both new files

**What changed (plain English):**
The Do tab now shows different practices depending on the time of day (5PM boundary from TCM Kidney hour). Morning shows activating routines; evening shifts to calming practices. Also fixed a bug where completing any routine showed checkmarks on ALL level cards — now each card only shows completed when its specific routine has been done.

**Why:**
TCM fundamentally distinguishes morning (yang-rising) from evening (yin-settling) practices. The per-level bug created false completion signals.

**Risks / watch-fors:**
- Scoring weights (+10 terrain, +2 phase affinity, -3 anti-affinity) mean terrain fit is always the dominant signal — correct fallback when no phase-matched alternative exists.
- `DayPhase` is view-layer only — no SwiftData dependency.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass
- [x] New tests added: `DayPhaseTests` — 22 tests
- [ ] Manual verification needed: before 5PM verify morning header + warming routines; after 5PM verify evening header + calming routines; complete Full -> switch to Medium -> verify Medium is NOT checked

**Reviewer nudge:**
Verify scoring with actual content: after 5PM, does a cold-deficient user see chrysanthemum tea (calms_shen + cooling = +4 affinity, +0 terrain) instead of warm-start congee (+10 terrain - 9 anti-affinity = +1)?

---

## [2026-02-04 20:45] — Add permissions priming screen to onboarding

**Files touched:**
- `Terrain/Features/Onboarding/PermissionsView.swift` — New file: Two benefit cards (weather + activity), sequential async permission requests, double-tap prevention, accessibility support
- `Terrain/Features/Onboarding/OnboardingCoordinatorView.swift` — Added `.permissions` case between `.notifications` and `.account`
- `Terrain/Terrain.xcodeproj/project.pbxproj` — Registered PermissionsView.swift

**What changed (plain English):**
Previously, location and health permission dialogs popped up lazily on the home screen — two system dialogs stacked with zero context. Now there's a dedicated "Personalize with real-world data" screen during onboarding that explains the value exchange before triggering system dialogs one at a time. Users can skip with "Not now."

**Why:**
Permission priming screens increase opt-in rates. Identified as a gap in the onboarding flow.

**Risks / watch-fors:**
- LocationPermissionHelper uses a shared singleton with a stored continuation. Double-tap prevention (`isRequesting` guard) makes orphaned continuation extremely unlikely. **Verified:** `@MainActor` annotation + `Task { @MainActor in }` delegate dispatch prevents races.
- Onboarding step count increased — progress bar adjusts dynamically via `allCases.count`.

**Testing status:**
- [x] Builds cleanly
- [ ] Manual verification needed: fresh install -> onboarding -> permissions screen appears after notifications, "Allow Access" triggers location then health sequentially, "Not now" skips to account

**Reviewer nudge:**
Test the "Allow Access" flow on a real device — simulator may auto-grant location permissions.

---

## [2026-02-04 14:30] — Do Tab deep polish: shadows, TCM accuracy, dynamic coaching, movement wiring

**Files touched:**
- `Terrain/Features/Do/DoView.swift` — Added daily progress indicator, terrain-contradictory quick need filtering, dynamic coaching note with TCM organ clock, quick fix "why for your terrain" via InsightEngine, enhanced completion overlay with TCM post-practice guidance, movement model passthrough to sheet
- `Terrain/Core/Models/Shared/QuickNeed.swift` — Added card shadows, changed selected state to light tint + accent border, removed dead "Save as go-to" button, added `whyForYou` parameter
- `Terrain/Features/Today/TodayView.swift` — Renamed "Eat/Drink" to "Nourish", added type-specific tintColor, added card shadow
- `Terrain/Features/Today/MovementPlayerSheet.swift` — Added optional `movementModel: Movement?` parameter, uses real SwiftData frame data when available
- `Terrain/Features/RightNow/RightNowView.swift` — Removed `onSaveGoTo` parameter from deprecated call site

**What changed (plain English):**
Nine changes to make the Do tab feel polished and TCM-accurate. Cards now have shadows. Nourish/Move modules use warm amber and cool blue-gray tints. Quick need selection uses a gentle tint. Warm-type users no longer see "Warmth" as a quick fix. Coaching note rotates based on symptoms and TCM organ clock. Quick fix cards show terrain-specific "why." Completion overlay shows post-practice TCM guidance. Movement player uses real content pack data when available.

**Why:**
The Do tab visually and experientially lagged behind the recently polished Ingredients and Home tabs.

**Risks / watch-fors:**
- Dynamic coaching depends on `Calendar.current.component(.hour)` — wrong device clock = inaccurate organ clock text
- ~~`sfSymbolForAsset()` keyword matching was later replaced by hand-curated map (see Feb 5 02:45 entry)~~ **Resolved:** replaced by hand-curated `movementIconMap` + audited in Feb 5 06:00 entry.
- `orderedNeeds` filtering may produce 5 items in a LazyVGrid — standard SwiftUI 2-column behavior, not a bug.
- ~~`generateQuickFixWhy` delegates to `InsightEngine.generateWhyForYou(routineTags:)` which may return `nil` for some tag combinations~~ **Resolved:** InsightEngineTests (37 tests) confirm all nil paths are intentional — no matching branch for that terrain+tag combo.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass (102 tests, 0 failures)
- [ ] Manual verification needed — visual: card shadows, Nourish/Move tint colors, progress dots, filtered quick needs, dynamic coaching text, terrain "why" callout, completion overlay, movement player with real data

**Reviewer nudge:**
Visual spot-check: verify card shadows render on device, Nourish/Move tint colors are distinguishable, and completion overlay appears after marking a routine done.

---

## [2026-02-04 12:01] — Onboarding redesign: How It Works, Daily Practice, Quick Fixes

**Files touched:**
- `Features/Onboarding/OnboardingCoordinatorView.swift` — Added `.howItWorks` step, updated progress math for 5 tutorial pages
- `Features/Onboarding/HowItWorksView.swift` — New screen explaining 5-axis assessment before the quiz
- `Features/Onboarding/WelcomeView.swift` — Replaced generic subtitle with differentiated value prop copy
- `Features/Onboarding/TutorialPreviewView.swift` — Replaced starterKit with dailyPractice page, added combination preview, added quickFixes page (page 5), totalPages 4->5
- `Features/Onboarding/OnboardingCompleteView.swift` — Updated guidance copy
- `Terrain.xcodeproj/project.pbxproj` — Added HowItWorksView.swift

**What changed (plain English):**
Onboarding redesigned to communicate what Terrain actually does. "How It Works" screen explains the 5 body signals the quiz reads. Tutorial now has 5 pages: "Daily Practice" with morning/evening routines, ingredients with "How They Combine" card, and "Quick Fixes" showing the reactive system. Welcome screen names specific mechanisms (cold/warm/neutral).

**Why:**
Users learned their terrain type but didn't understand the value — they never saw food combinations, movement recommendations, or quick-fix system during onboarding.

**Risks / watch-fors:**
- Flow is now 10 steps (was 9). Progress bar math uses `allCases.count - 1`.
- ~~All 8 terrain types have hardcoded data in 3 new structs (TerrainTagInfo.combinations, TerrainDailyPractice, TerrainQuickFixInfo). Content accuracy should be spot-checked against the content pack.~~ **Resolved:** OnboardingDataConsistencyTests (10 tests) now cross-reference all 3 structs against the content pack automatically. 7 tag mismatches and 1 avoid-tag mismatch were fixed.

**Testing status:**
- [x] Builds cleanly
- [x] Content pack cross-reference: automated (OnboardingDataConsistencyTests — 10 tests)
- [ ] Manual verification needed: walk through full onboarding for at least 2 terrain types; verify visual flow feels coherent

**Reviewer nudge:**
Walk through onboarding as a cold-deficient and warm-excess user to verify the 5-page tutorial shows sensible type-specific content.

---

## [2026-02-04 10:00] — TCM filter audit: fix 4 benefit mapping issues + late_summer season

**Files touched:**
- `Terrain/Core/Models/Shared/Tags.swift` — Headache filter now requires BOTH `cooling` + `moves_qi` (AND logic via `requiresAllTags`); stiffness tags changed from `[moves_qi, warming]` to `[moves_qi, dries_damp]`; cold benefit narrowed from `[warming, supports_deficiency]` to `[warming]` only
- `Terrain/Features/Ingredients/IngredientsView.swift` — `currentSeason` returns `"late_summer"` for August; In Season filter carousel replaced with toggle button

**What changed (plain English):**
TCM specialist audit of all 43 ingredients x 9 benefit filters found four issues:

1. **Headache filter too broad** (24/43 ingredients) — now requires BOTH cooling AND moves_qi (AND logic), dropping to ~8 ingredients
2. **Cramps and Stiffness identical** — stiffness now matches `moves_qi` or `dries_damp` (not warming)
3. **Tofu in Cold filter** — cold now only matches `warming` tag (removed `supports_deficiency`)
4. **Missing late summer season** — August now maps to `late_summer` (TCM five-season model)

**Why:**
User requested a TCM specialist audit of all filter combinations.

**Risks / watch-fors:**
- Headache's `requiresAllTags` is a unique code path (only headache uses AND logic). New benefits with this flag need to understand the distinction.
- Cold benefit is narrower now — reduces result count but is TCM-correct.
- ~~`late_summer` only triggers in August.~~ **Resolved:** IngredientsView now maps August + September to `late_summer`, matching InsightEngine's TCM five-season model.

**Testing status:**
- [x] Builds cleanly
- [x] Existing tests pass
- [x] New tests added: `IngredientBenefitTests` — 18 tests covering headache AND logic, cramps vs stiffness differentiation, cold filter exclusion, goal-based matching, empty/irrelevant tags, and reachability of all benefits
- [ ] Manual verification needed — filter by each benefit and verify results make TCM sense; test In Season toggle in August/September vs other months

**Reviewer nudge:**
Filter by "Headache" and confirm tofu, lettuce, and adzuki-bean no longer appear. Filter by "Stiffness" and confirm it shows different results from "Cramps."
