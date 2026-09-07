## Context

Automatic filter lists live on S3. The app downloads them in `AutomaticFilterManager.updateAutomaticFiltersIfNeeded()` (skip if the cache is younger than `kUpdateAutomaticFiltersMinDays`, currently 3) and `forceUpdateAutomaticFilters()`. That path only runs from a user session: `AppManager.onAppLaunch` → `onNewUserSession` when online.

The Message Filter Extension reads `AutomaticFiltersCache` from the App Group store and stays offline. A background update must happen in the **main app** and write that same cache.

The app already calls `registerForRemoteNotifications()` for CloudKit. That is silent sync, not an alert. There is no `UNUserNotificationCenter` usage and no Background Tasks usage on `develop` before this change.

## Goals / Non-Goals

**Goals:**
- When iOS is willing, refresh the automatic filter cache without a foreground open, using the existing 3-day stale rule.
- If AI Filtering is on and the user has allowed alerts and has not opened the app for a month, show a system banner. Keep repeating monthly until they open or turn AI Filtering off.
- Never show the iOS notification prompt without an in-app Home alert that explains why.
- Ask for that permission with bounded re-ask cadence (not a single forever flag), only on App Home while AI Filtering is on.

**Non-Goals:**
- Silent server push / APNs of our own
- Fetching lists inside the Message Filter Extension
- Guaranteeing a refresh on a calendar
- Resetting the monthly reminder clock because a silent refresh ran
- Badges or sounds
- Changing how cache hash / stale comparison works
- A What’s New entry or full-screen permission flow (too much chrome for two sentences)
- One-line public wrappers that only forward to another public method (`appBecameActive` → `refresh…`, `markGranted` → fake lifecycle, etc.)
- Combining “reconcile OS permission into defaults” and “should we show the alert?” in one method

## Decisions

### 1. One processing task, 3-day “wait at least”

Use `BGProcessingTask` only (`processing`, `requiresNetworkConnectivity`). `earliestBeginDate` is `now + kUpdateAutomaticFiltersMinDays` days.

**Why:** This app is rarely opened. Refresh (`BGAppRefreshTask`) is usage-weighted toward frequent apps; processing targets idle/overnight windows, which matches “AI Filtering on, person never opens the app.” Same handler body: `updateAutomaticFiltersIfNeeded()`.

**Rejected:** `BGAppRefreshTask` alone (poor fit for low-usage apps). Daily hint. Dual refresh+processing (unnecessary after choosing the idle queue).

**Limit (Apple):** Force-quit / swipe-away can prevent wakes until the user opens the app again. Document honestly; the monthly banner is the mitigation when alerts are allowed. Still best-effort; one pending processing request. Submit again after every successful handle and every real app open.

Identifier constant in `Constants.swift`: `com.grizz.apps.dev.simply-filter-sms.process-automatic-filters`.

### 2. Reuse the existing fetch, do not add a second pipeline

The processing handler: check network if cheap, call `updateAutomaticFiltersIfNeeded()`, then schedule the next processing task. Cache writes stay on the MainActor as they do today.

**Why:** Same stale check, same S3 client, same App Group store. The extension keeps working without changes.

### 3. Register the task at launch, schedule from `onAppLaunch`

`BGTaskScheduler.register` runs in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` before return. Scheduling runs from `AppManager.onAppLaunch()` → `schedulingManager.scheduleAutomaticFiltersProcessing()` (and again at the end of the processing handler).

**Why:** Apple requires the handler registered during launch. `onAppLaunch` is already the “app came to life” hook.

### 4. Monthly reminder is a repeating local notification; clock resets on scene-active only

One `UNNotificationRequest` with a monthly `UNCalendarNotificationTrigger` (`repeats: true`) and a stable identifier.

| Trigger | Behavior |
|---|---|
| Scene becomes `.active` | `refreshInactivityReminder()` — cancel pending, then if AI Filtering is on **and** alerts are allowed, schedule again one calendar month from now |
| AI Filtering turns **off** | Cancel only (listen to `.filtersStateChanged`; do **not** restart the clock when AI turns on) |
| Continue grants alerts | Call `refreshInactivityReminder()` (first setup after permission) |
| Background processing / filter edits / return to Home / AI on mid-session | Do **not** cancel or reschedule |

**Why:** “Did not open the app” is the rule. Scene-active is the open. In-session navigation and edits must not push the banner out. A calendar month matches “once a month” better than a fixed day count.

**Rejected earlier:** Fixed `kAutomaticFiltersInactivityReminderDays` interval; syncing the clock on every return to Home.

### 5. Alert first — never a naked system prompt, never a full sheet

A raw `requestAuthorization` gets declined. Two reasons do not need a full screen. They do go through `FlowManager`, same occupancy rules as everything else on Home.

**Queue (mirror What’s New, not `request`):**
- `FlowManager.enableInactivityNotification()` — session flag, like `enableWhatsNew()`.
- `next()` order: first run → launch → What’s New → **inactivity notification** → user `request`. Dedicated slot so a later `request(.help)` does not overwrite it.
- Append `Screen.inactivityNotification` at the **end** of the enum so existing `Int` raw values do not shift. Fake screen: no deep link; `build()` is `EmptyView` (never shown).
- `presentNextFlow()`: if `next()` is `.inactivityNotification`, set the Home alert flag and **do not** assign `sheetScreen`. On Continue / dismiss: `complete(.inactivityNotification)`, `presentNextFlow()` again.

**Never:** show the alert on `LanguageListView` or from the language toggle. Never call `requestAuthorization` from launch or from the toggle. Do not use `request()` for this.

**Continue** → then `requestAuthorization` for `.alert` only. **Not Now** / **Stop Asking** → no system prompt. System deny after Continue counts as a decline for that ask.

**English source (do not translate in the draft):**
- Title: Keep AI Filtering working
- Message: Allow notifications so we can remind you to open the app. If you never open it, AI filters may go stale and iOS may offload the app - then filtering can stop until you come back.
- Continue / Not Now / Stop Asking (ask 3 only)

Reason 1 is an intentional stretch. Say it anyway.

Refresh can still run when alerts are denied.

### 6. Ask cadence (replaces one-shot “did show” flag)

Defaults / constants (names are part of the contract):

| Name | Role |
|---|---|
| `inactivityNotificationAskCount` | How many times they declined (or system-denied after Continue) |
| `inactivityNotificationDeclinedSession` | `sessionCounter` when last declined |
| `inactivityNotificationWasGranted` | Alerts were granted at least once while we tracked |
| `kInactivityNotificationMaxAsks` | `3` |
| `kInactivityNotificationMinSessionsBetweenAsks` | `3` |

Rules:
- Show only if AI Filtering is on, alerts not currently allowed, asks remain, and session gap is satisfied (first ask has no gap).
- Asks 1–2 dismiss title: Not Now. Ask 3: Stop Asking (final ask — after decline, do not show again unless permission was later revoked after having been granted).
- If alerts are already allowed: record was-granted, refresh reminder, **do not** show the alert.
- If was-granted and OS later revokes: clear ask count + declined session; may ask again from #1.

### 7. `SchedulingManager` owns policy; UN stays a dumb service

`SchedulingManager` (+ protocol + `mock_SchedulingManager`) owns: schedule/handle `BGProcessingTask`, monthly reminder refresh/cancel, inactivity notification permission bookkeeping, ask cadence, Continue / decline.

It holds `AutomaticFilterManager`, `DefaultsManager`, and `UserNotificationCenterService` (authorize / pending / add / remove / status only — **no** product policy).

`AppManager` composes `schedulingManager`. `AppDelegate` registers the BG handler and forwards to `schedulingManager.handleAutomaticFiltersProcessing`. `FlowManager` stays queue-only. `AutomaticFilterManager` stays S3/cache fetch.

**Why:** Scheduling policy is not AppManager’s job and not a forever-thin notification adapter. Matches existing manager + protocol + `mock_*` layout. Services are gateways to external APIs; managers own product rules.

**Rejected:** Dumping schedule/auth on `AppManager`. Putting policy on a “fat” notification scheduler. Splitting BG into AppManager and reminders into FlowManager.

### 8. Public API is event → work (no fake lifecycle, no multi-job methods)

Implementers MUST map real events to methods that do that event’s work only. Do not invent public wrappers that only call another public method.

| Real event | Public method | Does |
|---|---|---|
| App launch / processing done | `scheduleAutomaticFiltersProcessing()` | Submit one `BGProcessingTask` request |
| iOS delivers processing task | `handleAutomaticFiltersProcessing(task:)` | Fetch-if-stale, complete task, reschedule |
| Scene becomes `.active` | `refreshInactivityReminder()` | Cancel pending reminder; reschedule if AI on + alerts allowed |
| Home about to consider the alert | `syncInactivityNotificationPermission() async` | Grant/revoke bookkeeping only: if alerts allowed → set wasGranted + `refreshInactivityReminder()`; if revoked after wasGranted → clear ask state. **Does not** decide presentation |
| Home needs a yes/no for the alert | `shouldShowInactivityNotificationAlert() async -> Bool` | Read-only cadence (AI on, not allowed, asks left, session gap). **Does not** mutate grant/ask defaults |
| User taps Continue | `inactivityNotificationContinued` | System `requestAuthorization`; grant → wasGranted + refresh reminder; deny → same decline recording as Not Now |
| User taps Not Now / Stop Asking | `inactivityNotificationDeclined` | Increment ask / store session / max-out on final ask |
| (computed) | `inactivityNotificationDismissTitle` | Localized Not Now vs Stop Asking from current ask count |
| DEBUG AppManager reset | `#if DEBUG reset()` | Remove pending reminder (and any DEBUG-only cleanup needed) |

**Home wiring (required shape):**
```text
await syncInactivityNotificationPermission()
guard await shouldShowInactivityNotificationAlert(),
      navigationScreen == nil else { return }
enableInactivityNotification()
presentNextFlow()
```

Scene `.active` → `refreshInactivityReminder()` only (reminder clock). Do **not** invent `appBecameActive()` that only forwards.

**Rejected anti-patterns (learned from discarded WIP):**
- Public `appBecameActive` / `markGranted` that only call another public method
- One evaluate method that both mutates permission state **and** returns whether to show
- Exposing `isFinalAsk` on the protocol when dismiss title already encodes it
- `(schedulingManager as? mock_SchedulingManager)` in production/test call sites — mocks are assigned as the protocol property; counters live on the mock type used directly in tests
- XCTest/preview environment hacks inside ViewModels to skip product paths

AI-off cancel stays inside `SchedulingManager` (observe `.filtersStateChanged`); callers do not sprinkle `cancelInactivityReminder()` across the UI.

Private helpers may exist (`cancel` + `schedule` pieces inside `refreshInactivityReminder`, ask-state helpers). They stay private.

### 9. Naming: `inactivityNotification` everywhere

Drop earlier draft names (`notificationPermission`, `openAppNotification`, `notificationExplainer`, `autoFilter_notificationExplainer_*`).

**Localization (English source first):**
- Alert: `inactivityNotification_title`, `inactivityNotification_message`, `inactivityNotification_continue` (or reuse `general_continue` if already suitable), Not Now / Stop Asking keys under the same family
- Monthly banner: `inactivityNotification_reminder_title`, `inactivityNotification_reminder_body` — AI filters may be out of date; open the app to refresh. Tap opens Home (default launch). No deep link

**Flow / Screen:** `Screen.inactivityNotification`, `enableInactivityNotification()`.

### 10. Monthly banner matches the permission story

Same product reason as the alert. Do not surprise them with a different “we miss you” tone a month later. No sound / badge.

## Risks / Trade-offs

- **iOS never runs the refresh** → Expected for people who never open (and after force-quit). Mitigation: monthly banner if they allowed alerts; fetch still runs on open.
- **User denies notifications** → No banner. Mitigation: refresh still tries; opening the app still fetches; bounded re-asks before giving up.
- **Repeating engagement banner** → App Review may dislike “come back” mail. Mitigation: only if AI Filtering is on; alert + banner talk about filters and offload; no sound/badge.
- **Naked system prompt** → High decline rate. Mitigation: Home alert always first; system dialog only on Continue.
- **Handler registered too late** → Refresh never runs. Mitigation: register in `didFinishLaunching` before any async work.
- **User leaves Background App Refresh off** → Same as iOS never waking. Banner still applies.

## Migration Plan

- Existing installs: next time Home is shown with AI Filtering on and asks available, show the inactivity notification alert (after What’s New if that also shows). Continue → system prompt → schedule reminder if allowed. Not Now → record decline + session; no system prompt.
- New enable: they turn AI on, stay on the language list with no alert; first time they see Home after that, same evaluation.
- No data migration. Cache format unchanged.
- Rollback: remove `processing` mode, task identifier, reminder scheduling, inactivity notification flow token; fetch-on-open remains.

## Open Questions

None. 3-day processing hint, monthly repeating banner, alert-then-system-permission, re-ask cadence, `SchedulingManager` event surface above.
