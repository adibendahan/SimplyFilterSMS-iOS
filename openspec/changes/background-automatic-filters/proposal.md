## Why

AI filter lists only download when the user opens the app. People who leave AI Filtering on and never come back keep an old list. iOS will not promise a wake, so the app needs a quiet refresh when the phone allows it, and a monthly banner if they still have not opened the app.

## What Changes

- Background processing: after a real open (and after each wake), ask iOS not to run the task for at least 3 days via `BGProcessingTask` (`requiresNetworkConnectivity`). When iOS does wake it, run the existing “fetch if the cache is 3+ days old” path and write the shared store so the Message Filter Extension sees the new list on the next SMS.
- Local notification monthly when AI Filtering is on and the user has allowed alerts and has not opened the app. Opening the app (scene active) resets the monthly clock. Turning AI Filtering off cancels the pending reminder. A silent refresh does **not** reset the clock. Turning AI Filtering on mid-session does **not** restart the clock.
- Never call the iOS notification prompt on its own. Always show a standard Home alert first that explains why, then the system dialog only if they Continue. Not a full screen / sheet.
- That alert is owned by ask cadence (not a one-shot flag): up to 3 asks; ≥3 `sessionCounter` gap after a decline; asks 1–2 dismiss with Not Now; ask 3 with Stop Asking; grant remembered while still allowed; revoke after grant resets asks from #1. App Home only — never on the language toggle or AI Filtering screen.
- Alert reasons (English source): ask for notifications so we can remind them to open the app; AI filters may go stale if they never open; iOS may offload the app if they never open.
- `SchedulingManager` owns BG processing, monthly reminder clock, and inactivity-notification ask/permission policy. `UserNotificationCenterService` is a dumb UN gateway only. FlowManager stays queue-only (fake `Screen.inactivityNotification` token).
- No silent server push. No fetch from the Message Filter Extension.

## Capabilities

### New Capabilities
- `background-automatic-filter-refresh`: Schedule and handle `BGProcessingTask` so automatic filter lists can update without a foreground open.
- `inactivity-local-notification`: Home inactivity notification alert, then system permission, then a monthly repeating local reminder if AI Filtering is on and they have not opened the app.

### Modified Capabilities

## Impact

- **App launch / AppDelegate:** register the processing task; schedule on launch; handle the wake via `SchedulingManager`.
- **AutomaticFilterManager:** same fetch/cache rules; callable from the processing handler.
- **Defaults:** ask count, last declined session, was-granted; max/gap constants.
- **FlowManager + Home:** same launch queue as What’s New. Home enables the inactivity notification slot when Home decides to ask; `next()` returns `Screen.inactivityNotification` (fake screen, not a sheet); Home shows an alert and `complete`s when it goes away. Scene `.active` refreshes the monthly reminder.
- **Info.plist:** add `processing` to `UIBackgroundModes`; add the processing task identifier.
- **Localization:** inactivity notification alert, Continue / Not Now / Stop Asking, and the monthly banner (English source first).
- **Extension:** unchanged (still read-only, offline).
- **Tests:** manager/scheduling hooks with mocks; no live BackgroundTasks or APNs.
