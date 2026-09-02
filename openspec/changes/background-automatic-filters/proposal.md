## Why

AI filter lists only download when the user opens the app. People who leave AI Filtering on and never come back keep an old list. iOS will not promise a wake, so the app needs a quiet refresh when the phone allows it, and a monthly banner if they still have not opened the app.

## What Changes

- Background processing: after a real open (and after each wake), ask iOS not to run the task for at least 3 days via `BGProcessingTask` (`requiresNetworkConnectivity`). When iOS does wake it, run the existing “fetch if the cache is 3+ days old” path and write the shared store so the Message Filter Extension sees the new list on the next SMS.
- Local notification monthly when AI Filtering is on and the user has not opened the app. Opening the app resets the monthly clock. Turning AI Filtering off cancels the reminder. A silent refresh does **not** reset the clock.
- Never call the iOS notification prompt on its own. Always show a standard alert first that explains why, then the system dialog only if they continue. Not a full screen.
- Show that alert once, on **App Home only**, the first time Home is shown while AI Filtering is on, the explainer has never been shown, **and** alert permission is not already granted. If they already allowed notifications, never ask again — including after they turn AI Filtering off and back on. Do **not** show it on the language toggle or on the AI Filtering screen.
- Explainer reasons (English source): ask for notifications so we can remind them to open the app; AI filters may go stale if they never open; iOS may offload the app if they never open.
- No silent server push. No fetch from the Message Filter Extension.

## Capabilities

### New Capabilities
- `background-automatic-filter-refresh`: Schedule and handle `BGProcessingTask` so automatic filter lists can update without a foreground open.
- `inactivity-local-notification`: Explainer alert, then system permission, then a monthly repeating local reminder if AI Filtering is on and they have not opened the app.

### Modified Capabilities

## Impact

- **App launch / AppDelegate:** register the processing task; schedule on launch; handle the wake.
- **AutomaticFilterManager:** same fetch/cache rules; callable from the processing handler.
- **Defaults / language toggles:** schedule or cancel the monthly reminder when AI Filtering turns on or off; persist that the explainer alert was shown.
- **FlowManager + Home:** same launch queue as What’s New. Home enables the explainer slot when Home is shown and AI Filtering is on; `next()` returns `Screen.notificationPermission` (fake screen, not a sheet); Home shows an alert and `complete`s when it goes away.
- **Info.plist:** add `processing` to `UIBackgroundModes`; add the processing task identifier.
- **Localization:** explainer alert, Continue / Not Now, and the monthly banner (English source first).
- **Extension:** unchanged (still read-only, offline).
- **Tests:** manager/scheduling hooks with mocks; no live BackgroundTasks or APNs.
