## 1. Constants, plist, defaults

- [x] 1.1 Add processing task identifier and inactivity notification request id (and monthly calendar trigger) to `Constants.swift`
- [x] 1.2 Add `processing` to `UIBackgroundModes` and `BGTaskSchedulerPermittedIdentifiers` in the app Info.plist
- [x] 1.3 Add ask-count / last-declined-session / was-granted defaults (and max/gap constants); remove one-shot `didShow…` bool

## 2. Inactivity notification alert then permission

- [x] 2.1 Append `Screen.inactivityNotification` (fake screen: `EmptyView` `build()`, no deep link) and `FlowManager.enableInactivityNotification()`; `next()` returns that case after What’s New and before user `request`
- [x] 2.2 English source strings for title, message (stale filters + offload), Continue, Not Now, Stop Asking — then localize
- [x] 2.3 Add `UserNotificationCenterServiceProtocol` + `UserNotificationCenterService` in Services Layer (authorize alerts only, add, remove pending by id, read authorization status)
- [x] 2.4 Add `mock_UserNotificationCenterService` for tests
- [x] 2.5 Continue → system alert prompt; Not Now / Stop Asking / system deny record decline via `SchedulingManager`; never call `requestAuthorization` from launch or from a toggle
- [x] 2.6 Home calls `shouldShowInactivityNotification`; on `.show` enable FlowManager + present (Stop Asking on final ask); grant/revoke handled in `SchedulingManager`
- [x] 2.7 On Continue / dismiss, `complete` the token and `presentNextFlow()`; do not present from the language toggle or `LanguageListView`
- [x] 2.8 Update `FlowManagerProtocol`, `mock_FlowManager`, and `FlowManagerTests` for the new slot and queue order

## 3. Notification scheduling

- [x] 3.1 Implement schedule / cancel of the repeating monthly inactivity notification (stable id; English source: AI filters may be out of date, open to refresh)
- [x] 3.2 Cancel on AI Filtering off; schedule on startup when AI Filtering is on and alerts are allowed; schedule after Continue grants auth; do **not** reset the clock from processing wakes, filter edits, or return-to-Home
- [x] 3.3 Add English (then localized) strings for the monthly banner title and body

## 4. Background processing

- [x] 4.1 Register the `BGProcessingTask` handler in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- [x] 4.2 Submit one processing request with `requiresNetworkConnectivity` and `earliestBeginDate` = now + `kUpdateAutomaticFiltersMinDays` from `onAppLaunch` and again after the handler finishes
- [x] 4.3 Handler calls `updateAutomaticFiltersIfNeeded()`, then `setTaskCompleted`, then reschedules; no second fetch pipeline
- [x] 4.4 Add `SchedulingManager` (+ protocol + mock); AppManager composes it; AppDelegate handler forwards to `schedulingManager`

## 5. Tests

- [x] 5.1 Tests: reminder schedule/cancel; inactivity notification evaluate cadence (gap, final ask, max, grant, revoke); Home wires evaluate/dismiss/continue
- [x] 5.2 Tests that updating automatic filters does not cancel the reminder
- [x] 5.3 Tests for next `earliestBeginDate` using `kUpdateAutomaticFiltersMinDays`

## 6. Verify on device / simulator

- [x] 6.1 Existing AI-on install: inactivity notification first, then system prompt only on Continue; Not Now never shows the system dialog
- [x] 6.2 Turning AI Filtering on does not show the alert; it appears the first time they are on Home after that
- [x] 6.3 Device confirmed `BGProcessingTask` wake fetches a stale cache
- [ ] 6.4 Confirm the reminder is pending after open, gone when AI is off, and that a debug-fired notification opens Home
