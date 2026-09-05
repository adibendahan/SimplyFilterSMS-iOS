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
- A full inactivity notification flow token or What’s New entry (too much chrome for two sentences)

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
- **AI Filtering turns on:** do not present the inactivity notification on the toggle. Do not restart the monthly clock mid-session; next startup schedules if needed. Schedule immediately only after the Home inactivity notification Continue grants alerts.
- **Background processing / filter edits / return to Home:** do not cancel or reschedule the reminder.

**Why:** “Did not open the app” is the rule. Startup is the open. In-session navigation and edits must not push the banner out. A calendar month matches “once a month” better than a fixed day count.

### 5. Alert first — never a naked system prompt, never a full sheet

A raw `requestAuthorization` gets declined. Two reasons do not need a full screen. They do go through `FlowManager`, same occupancy rules as everything else on Home.

`SchedulingManager` owns when to show the inactivity notification (ask count, session gap, grant/revoke). Defaults store ask count, last declined `sessionCounter`, and whether alerts were previously granted.

**Queue (mirror What’s New, not `request`):**
- `FlowManager.enableInactivityNotification()` — session flag, like `enableWhatsNew()`.
- `next()` order stays: first run → launch → What’s New → **inactivity notification** → user `request`. A dedicated slot so a later `request(.help)` does not overwrite the inactivity notification.
- Add `Screen.inactivityNotification` at the **end** of the enum so existing `Int` raw values do not shift. `next()` / `complete()` keep returning `Screen?`. This case is a fake screen: no deep link, and `build()` is `EmptyView` (never shown).
- `presentNextFlow()`: if `next()` is `.inactivityNotification`, set the Home alert flag and **do not** assign `sheetScreen`. On Continue / dismiss: `complete(.inactivityNotification)`, `presentNextFlow()` again.

**When Home enables the slot, App Home only:**
- Home asks `SchedulingManager.shouldShowInactivityNotification`. On `.show`, enable FlowManager + present. Dismiss / Continue go back to the manager.
- Ask up to 3 times; after a decline wait until `sessionCounter` advanced by ≥ 3. Asks 1–2 dismiss with Not Now; ask 3 with Stop Asking.
- If alerts are already allowed: mark granted, sync reminder, no explainer. If later revoked: reset ask state and may ask again from #1.
- `next()` still waits if a sheet is already up.

**Never:** show the alert on `LanguageListView` or from the language toggle. Never call `requestAuthorization` from launch or from the toggle. Do not use `request()` for this — that slot is one pending user sheet and gets overwritten.

**Continue** → then `requestAuthorization` for `.alert` only. **Not Now** / **Stop Asking** → no system prompt. System deny after Continue counts as a decline for that ask.

**English source (do not translate in the draft):**
- Title: Keep AI Filtering working
- Message: Allow notifications so we can remind you to open the app. If you never open it, AI filters may go stale and iOS may offload the app - then filtering can stop until you come back.
- Continue / Not Now / Stop Asking (ask 3 only)

Reason 1 is an intentional stretch. Say it anyway.

Refresh can still run when alerts are denied.

### 6. `SchedulingManager` owns BG + reminder + inactivity-notification ask cadence; notifications stay a dumb pipe

`SchedulingManager` (+ protocol + mock) owns: schedule/handle `BGProcessingTask`, sync/cancel the monthly inactivity reminder, inactivity notification evaluate / decline / request alerts, and grant/revoke tracking. It holds `AutomaticFilterManager`, `DefaultsManager`, and `UserNotificationCenterService` (authorize / pending / add / remove only).

`AppManager` composes `schedulingManager` and calls `scheduleAutomaticFiltersProcessing()` from `onAppLaunch()`. `AppDelegate` registers the handler and forwards to `AppManager.shared.schedulingManager.handleAutomaticFiltersProcessing`. `FlowManager` stays queue-only (explainer token). `AutomaticFilterManager` stays S3/cache fetch.

**Why:** Scheduling policy is not AppManager’s job and not a forever-thin notification adapter. Matches existing manager + protocol + `mock_*` layout. BackgroundTasks itself is awkward to unit-test; test reminder decisions and next `earliestBeginDate` on `SchedulingManager`.

### 7. monthly banner matches the inactivity notification alert

English source: AI filters may be out of date — open the app to refresh. Tap opens Home (default launch). No deep link.

**Why:** Same story as the permission sheet. Do not surprise them with a different reason a month later.

## Risks / Trade-offs

- **iOS never runs the refresh** → Expected for people who never open the app. Mitigation: monthly banner (if they allowed alerts).
- **User denies notifications** → No banner. Mitigation: refresh still tries; opening the app still fetches.
- **Repeating engagement banner** → App Review may dislike “come back” mail. Mitigation: only if AI Filtering is on; alert + banner talk about filters and offload, not “we miss you”; no sound/badge.
- **Naked system prompt** → High decline rate. Mitigation: sheet always first; system dialog only on Continue.
- **Handler registered too late** → Refresh never runs. Mitigation: register in `didFinishLaunching` before any async work.
- **User leaves Background App Refresh off** → Same as iOS never waking. Banner still applies.

## Migration Plan

- Existing installs: next time Home is shown with AI Filtering on, show the inactivity notification alert once (after What’s New if that also shows). Continue → system prompt → schedule reminder if allowed. Not Now → flag set, no system prompt, no nag.
- New enable: they turn AI on, stay on the language list with no alert; first time they see Home after that, same alert.
- No data migration. Cache format unchanged.
- Rollback: remove `processing` mode, task identifier, reminder scheduling, inactivity notification flow token; fetch-on-open remains.

## Open Questions

None. 3-day hint, monthly repeating banner, alert-then-system-permission, existing AI-on users on first open of this version.
