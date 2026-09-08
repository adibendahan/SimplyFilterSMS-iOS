## 1. Foundations

- [x] 1.1 Constants: `kAutomaticFiltersProcessingTaskIdentifier`, `kInactivityReminderNotificationIdentifier`, `kInactivityReminderHour`, `kInactivityNotificationMaxAsks`, `kInactivityNotificationMinSessionsBetweenAsks`.
- [x] 1.2 Defaults: `inactivityNotificationDeclineCount`, `inactivityNotificationLastDeclineSession`, `inactivityNotificationWasGranted` — manager, protocol, DEBUG reset keys, mock.
- [x] 1.3 `updateAutomaticFiltersIfNeeded()` becomes `async` so the background handler can await it; call sites in `AppManager` and `LanguageListView` updated.
- [x] 1.4 Info.plist: `processing` background mode + `BGTaskSchedulerPermittedIdentifiers`.

## 2. UserNotificationCenterService

- [x] 2.1 Async gateway with its protocol in the same file, matching `AmazonS3Service`.
- [x] 2.2 `UNAuthorizationStatus.allowsAlerts` extension — platform mapping only, mirroring `NWPath.Status.networkStatus`.
- [x] 2.3 `mock_UserNotificationCenterService`.

## 3. SchedulingManager

- [x] 3.1 Protocol: six methods and one property, each mapping to a real event.
- [x] 3.2 `scheduleAutomaticFiltersProcessing()`.
- [x] 3.3 `handleAutomaticFiltersProcessing(task:)` — reschedules first, honours `expirationHandler`.
- [x] 3.4 `refreshInactivityReminder()` — cancel, reconcile permission, schedule a repeating interval trigger a month out.
- [x] 3.5 `shouldShowInactivityNotificationAlert()` — read-only cadence.
- [x] 3.6 `requestInactivityNotificationPermission()` / `recordInactivityNotificationDecline()` / `isFinalInactivityNotificationAsk`.
- [x] 3.7 Observe `.filtersStateChanged` internally; cancel when AI Filtering goes off.
- [x] 3.8 `#if DEBUG reset()`.
- [x] 3.9 Compose into `AppManager` + protocol + `mock_AppManager`; schedule from `onAppLaunch()`; reset in DEBUG.

## 4. Home and app lifecycle

- [x] 4.1 `showInactivityNotificationAlert` + `.alert` on `AppHomeView`, following `showNothingToImportAlert`. No `Screen` case, no `FlowManager` change.
- [x] 4.2 `tryShowInactivityNotification()` raised from `presentNextFlow()`'s empty branch; `isHomeUnobstructed` covers both Home alerts.
- [x] 4.3 Register the BG handler in `AppDelegate.didFinishLaunching`; refresh the reminder on scene `.active` only.
- [x] 4.4 Max out the decline count under `isInTestingMode` so UI snapshots are not interrupted.

## 5. Localization

- [x] 5.1 English source keys, then BartyCrouch.
- [x] 5.2 Translated into he, ar, es, fr, pt-BR, de, ja, ko, it, zh-Hans using each locale's Apple term for "Offload App"; `bartycrouch lint` clean.

## 6. Tests

- [x] 6.1 `mock_SchedulingManager`, assigned as the protocol property.
- [x] 6.2 `SchedulingManagerTests` — 16 tests: cadence, session gap, final ask, grant/revoke, reminder trigger shape, AI-off cancel.
- [x] 6.3 `xcodebuild` build + full `Tests` scheme green on iPhone 17 Pro.

## 7. Documentation

- [x] 7.1 `CLAUDE.md`, `ARCHITECTURE.md`, `docs/FRAMEWORK.md`.
- [x] 7.2 Spec deltas rewritten to describe behavior; design.md carries an implementation-notes section for the four departures.
