## Context

Automatic filter lists live on S3. The app downloads them in `AutomaticFilterManager.updateAutomaticFiltersIfNeeded()` (skip if the cache is younger than `kUpdateAutomaticFiltersMinDays`, currently 3) and `forceUpdateAutomaticFilters()`. That path only runs from a user session: `AppManager.onAppLaunch` → `onNewUserSession` when online.

The Message Filter Extension reads `AutomaticFiltersCache` from the App Group store and stays offline. A background update must happen in the **main app** and write that same cache.

The app already calls `registerForRemoteNotifications()` for CloudKit. That is silent sync, not an alert. There is no `UNUserNotificationCenter` usage and no Background Tasks usage.

## Goals / Non-Goals

**Goals:**
- When iOS is willing, refresh the automatic filter cache without a foreground open, using the existing 3-day stale rule.
- If AI Filtering is on and the user has not opened the app for a month, show a system banner. Keep repeating monthly until they open or turn AI Filtering off.
- Never show the iOS notification prompt without an in-app alert that explains why.
- Show that alert once on App Home the first time Home is shown while AI Filtering is on (existing users on this version, or after they enable AI and come back to Home).

**Non-Goals:**
- Silent server push / APNs of our own
- Fetching lists inside the Message Filter Extension
- Guaranteeing a refresh on a calendar
- Resetting the monthly reminder clock because a silent refresh ran
- Badges or sounds
- Changing how cache hash / stale comparison works
- A full explainer screen or What’s New entry (too much chrome for two sentences)

## Decisions

### 1. One processing task, 3-day “wait at least”

Use `BGProcessingTask` only (`processing`, `requiresNetworkConnectivity`). `earliestBeginDate` is `now + kUpdateAutomaticFiltersMinDays` days.

**Why:** This app is rarely opened. Refresh (`BGAppRefreshTask`) is usage-weighted toward frequent apps; processing targets idle/overnight windows, which matches “AI Filtering on, person never opens the app.” Same handler body: `updateAutomaticFiltersIfNeeded()`.

**Rejected:** `BGAppRefreshTask` (poor fit for low-usage apps). Daily hint. Dual refresh+processing (unnecessary complexity after choosing the idle queue).

**Limit:** One pending processing request. Submit again after every successful handle and every real app open. Still best-effort; still blocked after force-quit.

### 2. Reuse the existing fetch, do not add a second pipeline

The processing handler: check network if cheap, call `updateAutomaticFiltersIfNeeded()`, then schedule the next processing task. Cache writes stay on the MainActor as they do today.

**Why:** Same stale check, same S3 client, same App Group store. The extension keeps working without changes.

### 3. Register the task at launch, schedule from `onAppLaunch`

`BGTaskScheduler.register` runs in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` before return. Scheduling runs from `AppManager.onAppLaunch()` (and again at the end of the processing handler).

**Why:** Apple requires the handler registered during launch. `onAppLaunch` is already the “app came to life” hook.

Identifier constant in `Constants.swift`: `com.grizz.apps.dev.simply-filter-sms.process-automatic-filters`.

### 4. Monthly reminder is a repeating local notification; clock resets on startup only

One `UNNotificationRequest` with a monthly `UNCalendarNotificationTrigger` (`repeats: true`) and a stable identifier.

- **Startup** (scene becoming `.active`): cancel, then if AI Filtering is on and alerts are allowed, schedule again one calendar month from now.
- **AI Filtering turns off:** cancel and do not reschedule (in-session).
- **AI Filtering turns on:** do not present the explainer on the toggle. Do not restart the monthly clock mid-session; next startup schedules if needed. Schedule immediately only after the Home explainer Continue grants alerts.
- **Background processing / filter edits / return to Home:** do not cancel or reschedule the reminder.

**Why:** “Did not open the app” is the rule. Startup is the open. In-session navigation and edits must not push the banner out. A calendar month matches “once a month” better than a fixed day count.

### 5. Alert first — never a naked system prompt, never a full sheet

A raw `requestAuthorization` gets declined. Two reasons do not need a full screen. They do go through `FlowManager`, same occupancy rules as everything else on Home.

Store `didShowAutomaticFiltersNotificationExplainer` in `DefaultsManager` (alert was shown, including Not Now — or skipped because alerts were already allowed).

**Queue (mirror What’s New, not `request`):**
- `FlowManager.enableNotificationPermissionExplainer()` — session flag, like `enableWhatsNew()`.
- `next()` order stays: first run → launch → What’s New → **explainer** → user `request`. A dedicated slot so a later `request(.help)` does not overwrite the explainer.
- Add `Screen.notificationPermission` at the **end** of the enum so existing `Int` raw values do not shift. `next()` / `complete()` keep returning `Screen?`. This case is a fake screen: no deep link, and `build()` is `EmptyView` (never shown).
- `presentNextFlow()`: if `next()` is `.notificationPermission`, set the Home alert flag and **do not** assign `sheetScreen`. On Continue / Not Now: set the defaults flag, `complete(.notificationPermission)`, `presentNextFlow()` again.

**When Home enables the slot (once), App Home only:**
- Home is shown, AI Filtering is on, explainer flag is false, **and** alert permission is not already granted → `enableNotificationPermissionExplainer()` then `presentNextFlow()`.
- If alert permission is already granted: do not enable the slot, set `didShowAutomaticFiltersNotificationExplainer` so we never ask later, and still schedule the monthly reminder. Turning AI Filtering off and on again does not bring the explainer back.
- That includes first open of this version if AI is already on, and the first return to Home after they turn AI on from the language list.
- `next()` still waits if a sheet is already up.

**Never:** show the alert on `LanguageListView` or from the language toggle. Never call `requestAuthorization` from launch or from the toggle. Do not use `request()` for this — that slot is one pending user sheet and gets overwritten.

**Continue** → then `requestAuthorization` for `.alert` only. **Not Now** → no system prompt. Set the flag when the alert is dismissed either way so it does not return.

**English source (do not translate in the draft):**
- Title: Keep AI Filtering working
- Message: Allow notifications so we can remind you to open the app. If you never open it, AI filters may go stale and iOS may offload the app - then filtering can stop until you come back.
- Continue / Not Now

Reason 1 is an intentional stretch. Say it anyway.

If they deny the system dialog, stay quiet. Refresh can still run.

### 6. `SchedulingManager` owns BG + reminder policy; notifications stay a dumb pipe

`SchedulingManager` (+ protocol + mock) owns: schedule/handle `BGProcessingTask`, sync/cancel the monthly inactivity reminder, and explainer → request alerts → sync reminder. It holds `AutomaticFilterManager` for the fetch path and `UserNotificationCenterServiceProtocol` / `UserNotificationCenterService` (Services Layer) as an injectable UN collaborator (authorize / pending / add / remove only).

`AppManager` composes `schedulingManager` and calls `scheduleAutomaticFiltersProcessing()` from `onAppLaunch()`. `AppDelegate` registers the handler and forwards to `AppManager.shared.schedulingManager.handleAutomaticFiltersProcessing`. `FlowManager` stays queue-only (explainer token). `AutomaticFilterManager` stays S3/cache fetch.

**Why:** Scheduling policy is not AppManager’s job and not a forever-thin notification adapter. Matches existing manager + protocol + `mock_*` layout. BackgroundTasks itself is awkward to unit-test; test reminder decisions and next `earliestBeginDate` on `SchedulingManager`.

### 7. monthly banner matches the explainer

English source: AI filters may be out of date — open the app to refresh. Tap opens Home (default launch). No deep link.

**Why:** Same story as the permission sheet. Do not surprise them with a different reason a month later.

## Risks / Trade-offs

- **iOS never runs the refresh** → Expected for people who never open the app. Mitigation: monthly banner (if they allowed alerts).
- **User denies notifications** → No banner. Mitigation: refresh still tries; opening the app still fetches.
- **Repeating engagement banner** → App Review may dislike “come back” mail. Mitigation: only if AI Filtering is on; explainer + banner talk about filters and offload, not “we miss you”; no sound/badge.
- **Naked system prompt** → High decline rate. Mitigation: sheet always first; system dialog only on Continue.
- **Handler registered too late** → Refresh never runs. Mitigation: register in `didFinishLaunching` before any async work.
- **User leaves Background App Refresh off** → Same as iOS never waking. Banner still applies.

## Migration Plan

- Existing installs: next time Home is shown with AI Filtering on, show the explainer alert once (after What’s New if that also shows). Continue → system prompt → schedule reminder if allowed. Not Now → flag set, no system prompt, no nag.
- New enable: they turn AI on, stay on the language list with no alert; first time they see Home after that, same alert.
- No data migration. Cache format unchanged.
- Rollback: remove `processing` mode, task identifier, reminder scheduling, explainer screen; fetch-on-open remains.

## Open Questions

None. 3-day hint, monthly repeating banner, explainer-then-prompt, existing AI-on users on first open of this version.
