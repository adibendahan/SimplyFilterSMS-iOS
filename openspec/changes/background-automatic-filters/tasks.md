## 1. Constants, plist, defaults

- [ ] 1.1 Add refresh task identifier and inactivity notification request id (and 30-day interval) to `Constants.swift`
- [ ] 1.2 Add `fetch` to `UIBackgroundModes` and `BGTaskSchedulerPermittedIdentifiers` in the app Info.plist
- [ ] 1.3 Add `didShowAutomaticFiltersNotificationExplainer` to `DefaultsManagerProtocol`, `DefaultsManager`, reset keys, and `mock_DefaultsManager`

## 2. Explainer alert then permission

- [ ] 2.1 Append `Screen.notificationPermission` (fake screen: `EmptyView` `build()`, no deep link) and `FlowManager.enableNotificationPermissionExplainer()`; `next()` returns that case after What’s New and before user `request`
- [ ] 2.2 English source strings for title, message (stale filters + offload), Continue, Not Now — then localize
- [ ] 2.3 Add a `UserNotificationScheduling` protocol (authorize alerts only, add, remove pending by id, read authorization status) and a `UNUserNotificationCenter` adapter
- [ ] 2.4 Add `mock_UserNotificationScheduling` for tests
- [ ] 2.5 Continue → system alert prompt; Not Now → no system prompt; set `didShowAutomaticFiltersNotificationExplainer` so the alert never returns; never call `requestAuthorization` from launch or from a toggle
- [ ] 2.6 When App Home is shown, if AI Filtering is on, the explainer has not been shown, and alerts are not already allowed, call `enableNotificationPermissionExplainer()` then `presentNextFlow()`; if `next()` is the token, show the Home `.alert` (not `sheetScreen`). If alerts are already allowed, set the shown flag and skip — including after AI Filtering is turned off and on again.
- [ ] 2.7 On Continue / Not Now, `complete` the token and `presentNextFlow()`; do not present from the language toggle or `LanguageListView`
- [ ] 2.8 Update `FlowManagerProtocol`, `mock_FlowManager`, and `FlowManagerTests` for the new slot and queue order

## 3. Notification scheduling

- [ ] 3.1 Implement schedule / cancel of the repeating 30-day inactivity notification (stable id; English source: AI filters may be out of date, open to refresh)
- [ ] 3.2 Cancel on AI Filtering off; schedule when AI Filtering is on and alerts are allowed; cancel+reschedule on scene `.active` / open; do **not** touch the reminder from the refresh handler
- [ ] 3.3 Add English (then localized) strings for the 30-day banner title and body

## 4. Background refresh

- [ ] 4.1 Register the `BGAppRefreshTask` handler in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
- [ ] 4.2 Submit one refresh request with `earliestBeginDate` = now + `kUpdateAutomaticFiltersMinDays` from `onAppLaunch` and again after the handler finishes
- [ ] 4.3 Handler calls `updateAutomaticFiltersIfNeeded()`, then `setTaskCompleted`, then reschedules; no second fetch pipeline
- [ ] 4.4 Expose any new AppManager hooks on `AppManagerProtocol` and the mock

## 5. Tests

- [ ] 5.1 Tests: AI on + allowed → schedule; AI off → cancel; already authorized → no explainer even after AI off/on; explainer already shown → no second alert; Not Now → no `requestAuthorization`; deny → no schedule
- [ ] 5.2 Tests that a simulated refresh path calls `updateAutomaticFiltersIfNeeded` and does not cancel the reminder
- [ ] 5.3 Tests for next `earliestBeginDate` using `kUpdateAutomaticFiltersMinDays`

## 6. Verify on device / simulator

- [ ] 6.1 Existing AI-on install: explainer first, then system prompt only on Continue; Not Now never shows the system dialog
- [ ] 6.2 Turning AI Filtering on does not show the alert; it appears the first time they are on Home after that
- [ ] 6.3 Debug-trigger the refresh task and confirm a stale cache fetches and a fresh cache skips S3
- [ ] 6.4 Confirm the reminder is pending after open, gone when AI is off, and that a debug-fired notification opens Home
