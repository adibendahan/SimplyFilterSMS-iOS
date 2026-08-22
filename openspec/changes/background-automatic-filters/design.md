## Context

Automatic filter lists live on S3. The app downloads them in `AutomaticFilterManager.updateAutomaticFiltersIfNeeded()` (skip if the cache is younger than `kUpdateAutomaticFiltersMinDays`, currently 3) and `forceUpdateAutomaticFilters()`. That path only runs from a user session: `AppManager.onAppLaunch` → `onNewUserSession` when online.

The Message Filter Extension reads `AutomaticFiltersCache` from the App Group store and stays offline. A background update must happen in the **main app** and write that same cache.

The app already calls `registerForRemoteNotifications()` for CloudKit. That is silent sync, not an alert. There is no `UNUserNotificationCenter` usage and no Background Tasks usage.

## Goals / Non-Goals

**Goals:**
- When iOS is willing, refresh the automatic filter cache without a foreground open, using the existing 3-day stale rule.
- If AI Filtering is on and the user has not opened the app for 30 days, show a system banner. Keep repeating every 30 days until they open or turn AI Filtering off.
- Never show the iOS notification prompt without an in-app alert that explains why.
- Show that alert once on App Home the first time Home is shown while AI Filtering is on (existing users on this version, or after they enable AI and come back to Home).

**Non-Goals:**
- Silent server push / APNs of our own
- Fetching lists inside the Message Filter Extension
- Guaranteeing a refresh on a calendar
- Resetting the 30-day clock because a silent refresh ran
- Badges or sounds
- Changing how cache hash / stale comparison works
- A full explainer screen or What’s New entry (too much chrome for two sentences)

## Decisions

### 1. One refresh task, 3-day “wait at least”

Use `BGAppRefreshTask` (Info.plist `fetch` + permitted identifier). `earliestBeginDate` is `now + kUpdateAutomaticFiltersMinDays` days.

**Why:** Apple does not give a timer. The date is only “don’t start before this.” Matching the existing 3-day cache rule avoids extra S3 calls. The handler still calls `updateAutomaticFiltersIfNeeded()`, so an early wake no-ops.

**Rejected:** Daily hint (more wakes for the same download rule). `BGProcessingTask` (meant for long idle/charging work; this is a small JSON).

**Limit:** Only one refresh request can be pending. Submit again after every successful handle and every real app open so the next request exists.

### 2. Reuse the existing fetch, do not add a second pipeline

The refresh handler: check network if cheap, call `updateAutomaticFiltersIfNeeded()`, then schedule the next refresh. Cache writes stay on the MainActor as they do today.

**Why:** Same stale check, same S3 client, same App Group store. The extension keeps working without changes.

### 3. Register the task at launch, schedule from `onAppLaunch`

`BGTaskScheduler.register` runs in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` before return. Scheduling runs from `AppManager.onAppLaunch()` (and again at the end of the refresh handler).

**Why:** Apple requires the handler registered during launch. `onAppLaunch` is already the “app came to life” hook.

Identifier constant in `Constants.swift`, e.g. `com.grizz.apps.dev.simply-filter-sms.refresh-automatic-filters`.

### 4. 30-day reminder is a repeating local notification, clock = last open

One `UNNotificationRequest` with a 30-day `UNTimeIntervalNotificationTrigger` (`repeats: true`) and a stable identifier.

- **Foreground / open** (`scenePhase` becoming `.active`, including first launch): cancel, then if AI Filtering is on and alerts are allowed, schedule again from now.
- **AI Filtering turns off:** cancel and do not reschedule.
- **AI Filtering turns on:** do not present the explainer on the toggle. Schedule the reminder only after alerts are allowed (usually later, after Home + Continue).
- **Background refresh:** do not cancel or reschedule the reminder.

**Why:** “Did not open” is the rule, not “cache is stale.” A repeating interval matches “every 30 days” if they keep ignoring it. Cancel + schedule on open restarts the 30 days.

`sessionAge` is in-memory only, so it is not last-open. Use scene becoming active, not that flag.

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
- If alert permission is already granted: do not enable the slot, set `didShowAutomaticFiltersNotificationExplainer` so we never ask later, and still schedule the 30-day reminder. Turning AI Filtering off and on again does not bring the explainer back.
- That includes first open of this version if AI is already on, and the first return to Home after they turn AI on from the language list.
- `next()` still waits if a sheet is already up.

**Never:** show the alert on `LanguageListView` or from the language toggle. Never call `requestAuthorization` from launch or from the toggle. Do not use `request()` for this — that slot is one pending user sheet and gets overwritten.

**Continue** → then `requestAuthorization` for `.alert` only. **Not Now** → no system prompt. Set the flag when the alert is dismissed either way so it does not return.

**English source (do not translate in the draft):**
- Title: Keep AI Filtering working
- Message: AI filters may go stale if you never open the app. iOS may also offload the app if you never open it, and filtering can stop until you come back.
- Continue / Not Now

Reason 1 is an intentional stretch. Say it anyway.

If they deny the system dialog, stay quiet. Refresh can still run.

### 6. Thin wrappers, not a new coordinator

Keep work on `AppManager` + `AutomaticFilterManager`. Add a small `UserNotificationScheduling` protocol (real `UNUserNotificationCenter` in the app, mock in tests) for authorize / pending / add / remove. Do not add a second “maintenance manager.”

**Why:** Matches existing manager + protocol + `mock_*` layout. BackgroundTasks itself is awkward to unit-test; test the decision helpers (should show explainer, should schedule reminder, next `earliestBeginDate`).

### 7. 30-day banner matches the explainer

English source: AI filters may be out of date — open the app to refresh. Tap opens Home (default launch). No deep link.

**Why:** Same story as the permission sheet. Do not surprise them with a different reason a month later.

## Risks / Trade-offs

- **iOS never runs the refresh** → Expected for people who never open the app. Mitigation: 30-day banner (if they allowed alerts).
- **User denies notifications** → No banner. Mitigation: refresh still tries; opening the app still fetches.
- **Repeating engagement banner** → App Review may dislike “come back” mail. Mitigation: only if AI Filtering is on; explainer + banner talk about filters and offload, not “we miss you”; no sound/badge.
- **Naked system prompt** → High decline rate. Mitigation: sheet always first; system dialog only on Continue.
- **Handler registered too late** → Refresh never runs. Mitigation: register in `didFinishLaunching` before any async work.
- **User leaves Background App Refresh off** → Same as iOS never waking. Banner still applies.

## Migration Plan

- Existing installs: next time Home is shown with AI Filtering on, show the explainer alert once (after What’s New if that also shows). Continue → system prompt → schedule reminder if allowed. Not Now → flag set, no system prompt, no nag.
- New enable: they turn AI on, stay on the language list with no alert; first time they see Home after that, same alert.
- No data migration. Cache format unchanged.
- Rollback: remove `fetch` mode, task identifier, reminder scheduling, explainer screen; fetch-on-open remains.

## Open Questions

None. 3-day hint, 30-day repeating banner, explainer-then-prompt, existing AI-on users on first open of this version.
