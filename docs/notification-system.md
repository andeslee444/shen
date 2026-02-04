# Notification System

## User-Facing Feature Summary

Terrain sends personalized daily notifications that double as **micro-rituals** — tiny 10-second actions matched to the user's terrain type. Users can complete the action directly from the notification (via "Did This") or tap "Start Ritual" to open the full Do tab.

**Key behaviors:**
- **Morning** notification at the user's chosen time (default 8:00 AM)
- **Evening** notification at the user's chosen time (default 8:00 PM)
- Content rotates daily — 7 unique actions per pool before repeating
- Streaks > 3 days add a "Day N" prefix to the title
- Users can enable/disable or change times in You > Preferences

## Notification Anatomy

```
┌─────────────────────────────────────────────┐
│  Terrain                            7:00 AM │
│ Your Low Flame body thrives with warmth      │
│ ─────────────────────────────────────────── │
│ Drink a glass of warm water (10 sec)         │
│                                              │
│  [ Did This ✓ ]        [ Start Ritual → ]    │
└─────────────────────────────────────────────┘
```

### Title

Varies by phase and streak:

| Phase   | Streak ≤ 3                                         | Streak > 3                           |
|---------|-----------------------------------------------------|--------------------------------------|
| Morning | "Your {nickname} body thrives with {principle}"     | "Day {N} — your {nickname} rhythm"   |
| Evening | "Time to settle your {nickname} pattern"            | "Day {N} — wind-down time"           |

Where `{principle}` maps from terrain group:
- **Cold** terrains → "warmth"
- **Warm** terrains → "calm"
- **Neutral** terrains → "balance"

### Body

The micro-action text followed by duration in parentheses: `"Drink a glass of warm water (10 sec)"`

### Action Buttons

| Button         | Behavior                                                    |
|----------------|-------------------------------------------------------------|
| **Did This ✓** | Background action — logs `microActionCompletedAt` to DailyLog without opening the app |
| **Start Ritual →** | Foreground action — opens the app and navigates to the Do tab |

Tapping the notification body itself (not a button) also opens the Do tab.

## Micro-Action Pool

42 actions total: 7 per pool, 6 pools (3 terrain groups x 2 phases).

### Cold Terrains (cold_deficient, cold_balanced)

**Morning:**
1. Drink a glass of warm water (10 sec)
2. Rub your palms together briskly for 10 seconds (10 sec)
3. Place your warm palms over your lower back (15 sec)
4. Stretch your arms overhead and take 3 deep breaths (15 sec)
5. Roll your ankles slowly — 5 circles each direction (20 sec)
6. Press your thumb into the center of your palm for 5 seconds (10 sec)
7. Gently massage your earlobes for 10 seconds (10 sec)

**Evening:**
1. Place your hands on your lower belly and breathe deeply (15 sec)
2. Sip warm water before bed (10 sec)
3. Rub the soles of your feet gently for 15 seconds (15 sec)
4. Take 3 slow breaths, imagining warmth spreading inward (15 sec)
5. Gently press the space between your eyebrows for 5 seconds (10 sec)
6. Roll your shoulders backward slowly 5 times (15 sec)
7. Cup your palms over your closed eyes and relax your jaw (15 sec)

### Warm Terrains (warm_excess, warm_deficient, warm_balanced)

**Morning:**
1. Drink room-temperature water with a slow exhale (10 sec)
2. Splash cool water on your wrists and inner elbows (10 sec)
3. Take 3 breaths — inhale 4 counts, exhale 6 counts (20 sec)
4. Gently press your temples with your fingertips for 5 seconds (10 sec)
5. Open a window and take 3 deep breaths of fresh air (15 sec)
6. Close your eyes and unclench your jaw for 10 seconds (10 sec)
7. Roll your neck slowly — 3 circles each direction (20 sec)

**Evening:**
1. Take 3 slow exhales through your mouth (15 sec)
2. Press your thumbs into your temples gently for 10 seconds (10 sec)
3. Place a cool cloth on the back of your neck (15 sec)
4. Close your eyes and count 5 slow breaths (20 sec)
5. Gently shake out your hands for 10 seconds to release tension (10 sec)
6. Rest your palms face-up on your knees and breathe (15 sec)
7. Soften your forehead and relax your tongue from the roof of your mouth (10 sec)

### Neutral Terrains (neutral_balanced, neutral_deficient, neutral_excess)

**Morning:**
1. Take 3 deep breaths by a window (15 sec)
2. Roll your shoulders back 5 times (15 sec)
3. Stand tall and press your feet into the floor for 10 seconds (10 sec)
4. Tap the top of your head lightly with your fingertips (10 sec)
5. Stretch your arms wide and take one big breath (10 sec)
6. Rub your hands together and place them over your eyes (15 sec)
7. Interlace your fingers overhead and lean gently to each side (15 sec)

**Evening:**
1. Drop your shoulders away from your ears (10 sec)
2. Close your eyes and count 5 breaths (20 sec)
3. Place one hand on your chest and one on your belly — breathe slowly (15 sec)
4. Gently massage the web between your thumb and index finger (15 sec)
5. Relax your tongue and soften the muscles around your eyes (10 sec)
6. Take a slow sip of warm water and notice the warmth (10 sec)
7. Rock gently from your heels to your toes 5 times (15 sec)

## Rotation Logic

```swift
let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date())!
let index = (dayOfYear + dayOffset) % pool.count  // pool.count = 7
```

For 7-day scheduling, `dayOffset` is 0–6, so each scheduled notification gets a unique action.

## Settings Behavior

| User Action | System Response |
|-------------|-----------------|
| Toggle notifications OFF in You tab | All pending notifications cleared via `removeAllPendingNotificationRequests()` |
| Toggle notifications ON in You tab | Full 7-day window scheduled with terrain-personalized content |
| Change morning/evening time | All notifications cleared and rescheduled with new times |
| App comes to foreground | 7-day window refilled (handles expired notifications) |

**Bug fix note:** Prior to this implementation, the You > Preferences toggles and time pickers updated the UserProfile model but never called `UNUserNotificationCenter`. This has been fixed — every setter now triggers a reschedule.

## Deep-Link Flow

```
User taps "Start Ritual →"
  → NotificationDelegate.didReceive()
  → Writes "open_do" to UserDefaults key "pendingNotificationAction"
  → App opens (foreground action)
  → MainTabView reads @AppStorage("pendingNotificationAction")
  → Switches coordinator.selectedTab to .do
  → Clears the pending action
```

**Why @AppStorage?** The `NavigationCoordinator` is scoped as `@State` in `MainTabView`, not app-level. The notification delegate runs outside the SwiftUI view hierarchy. `@AppStorage` bridges the two reliably — it persists across app restart and triggers SwiftUI updates via `onChange`.

## Streak Integration

When `ProgressRecord.currentStreak > 3`, notification titles include the streak count:
- Morning: "Day 7 — your Low Flame rhythm"
- Evening: "Day 7 — wind-down time"

Streak count is fetched fresh during each scheduling call (on foreground return), so it stays current.

## Onboarding Flow

During onboarding (before quiz completion), `NotificationsView` schedules **placeholder** notifications with generic copy ("Good morning" / "Your daily routine is ready."). These use the same `TERRAIN_RITUAL` category so action buttons work immediately.

Once the user completes onboarding and the app comes to foreground, `TerrainApp`'s `scenePhase` handler replaces these placeholders with terrain-personalized notifications.

## Tutorial Talking Points

Suggested copy for the onboarding tutorial screen:

> "Your notifications aren't just reminders — they're personalized micro-rituals. Each morning, you'll get a 10-second action matched to your terrain type. Try it right from the notification, or tap to see your full daily practice."

## Technical Details

| Aspect | Detail |
|--------|--------|
| iOS notification limit | 64 pending; we schedule max 14 (7 days x 2 phases) |
| Category ID | `TERRAIN_RITUAL` |
| Trigger type | `UNCalendarNotificationTrigger` (non-repeating, specific date) |
| Delegate retention | Stored as `private let` in `TerrainApp` (UNCenter holds weak ref) |
| Background write | `ModelContext(modelContainer)` in delegate (no `@Environment` available) |
| New DailyLog field | `microActionCompletedAt: Date?` — optional, no migration needed |
