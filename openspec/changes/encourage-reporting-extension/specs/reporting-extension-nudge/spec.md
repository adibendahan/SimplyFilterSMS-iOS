## ADDED Requirements

### Requirement: NotificationView supports an enableReportingExtension notification case
A new `NotificationView.Notification.enableReportingExtension` case SHALL be added with: a relevant SF Symbol icon, accent-colored icon tint, `timeout: 10` (auto-hides after 10 seconds). Auto-hiding SHALL NOT count as an active dismissal.

All three text fields MUST fit on a single line within the `NotificationView` layout and MUST be as short as possible. Suggested English strings:
- **Title:** "Report Spam" (11 chars)
- **Subtitle:** "Help improve AI filtering" (25 chars)
- **Button:** "Enable" (6 chars)

Localization constraint: no translation of any of these three strings SHALL exceed the English character count by more than 5 characters. Translators MUST prioritize brevity over literal accuracy.

#### Scenario: Notification displays correct content
- **WHEN** `NotificationView` is shown with `.enableReportingExtension`
- **THEN** title, subtitle, and button each render on a single line without truncation

#### Scenario: Notification auto-hides after 10 seconds
- **WHEN** the `.enableReportingExtension` notification is shown and the user does not interact with it
- **THEN** it hides automatically after 10 seconds without setting `didDismissReportingExtensionNudge`

### Requirement: DefaultsManager tracks permanent dismissal of the reporting extension nudge
`DefaultsManagerProtocol` and `DefaultsManager` SHALL expose `didDismissReportingExtensionNudge: Bool` (stored in `UserDefaults`, default `false`). Once set to `true` it SHALL remain `true` across app launches.

#### Scenario: First launch — flag is false
- **WHEN** the app is launched for the first time
- **THEN** `didDismissReportingExtensionNudge` returns `false`

#### Scenario: Flag persists across launches
- **WHEN** `didDismissReportingExtensionNudge` is set to `true` and the app is relaunched
- **THEN** `didDismissReportingExtensionNudge` still returns `true`

### Requirement: AppHomeView shows the nudge every third session until actively dismissed
`AppHomeView.ViewModel` SHALL call `tryShowReportingExtensionNudge()` from `startMonitoring()`. The nudge SHALL only be shown when ALL of the following are true: `!isAppFirstRun`, `!didDismissReportingExtensionNudge`, `isAutomaticFilteringOn`, `sessionCounter > 0 && sessionCounter % 3 == 0`, and `!notification.show`. Tapping the notification (body or button) SHALL open `Screen.enableReportingExtension` as a sheet and hide the notification. Auto-hide (timeout expiry) SHALL NOT set `didDismissReportingExtensionNudge`.

#### Scenario: Nudge shown on eligible session (multiple of 3)
- **WHEN** `sessionCounter` is a non-zero multiple of 3, AI Filtering is on, onboarding is complete, and the nudge has not been actively dismissed
- **THEN** the `.enableReportingExtension` notification appears shortly after `startMonitoring()` is called

#### Scenario: Nudge not shown on non-eligible session
- **WHEN** `sessionCounter` is not a multiple of 3
- **THEN** `tryShowReportingExtensionNudge()` returns without showing the notification

#### Scenario: Nudge suppressed when AI Filtering is off
- **WHEN** `isAutomaticFilteringOn` is `false`
- **THEN** `tryShowReportingExtensionNudge()` returns without showing the notification

#### Scenario: Nudge suppressed during first run
- **WHEN** `isAppFirstRun` is `true`
- **THEN** `tryShowReportingExtensionNudge()` returns without showing the notification

#### Scenario: Nudge suppressed when another notification was shown this session
- **WHEN** any other notification was shown earlier this session (even if it has since hidden)
- **THEN** `tryShowReportingExtensionNudge()` returns without showing the notification

#### Scenario: Auto-hide does not count as active dismissal
- **WHEN** the notification auto-hides after 10 seconds without user interaction
- **THEN** `didDismissReportingExtensionNudge` remains `false` and the nudge will appear again on the next eligible session

#### Scenario: Tapping nudge opens the reporting extension guide and marks active dismissal
- **WHEN** the user taps the notification body or the "Enable" button
- **THEN** the notification hides, `sheetScreen` is set to `.enableReportingExtension`, and `didDismissReportingExtensionNudge` is set to `true`

#### Scenario: Nudge not shown after active dismissal
- **WHEN** `didDismissReportingExtensionNudge` is `true`
- **THEN** `tryShowReportingExtensionNudge()` returns without showing the notification

### Requirement: Reporting extension nudge has lower priority than all other notifications
`AppHomeView.ViewModel` SHALL maintain a private session-only `didShowNotificationThisSession: Bool` (not persisted, resets each launch) that is set to `true` whenever `showNotification(_:)` is called. `tryShowReportingExtensionNudge()` SHALL be called last in `startMonitoring()` and SHALL be suppressed if `didShowNotificationThisSession` is `true`. This prevents the reporting nudge from appearing in any session where another notification has already been shown — even if that notification has since auto-hidden.

#### Scenario: Reporting nudge suppressed when another notification was already shown this session
- **WHEN** any notification (offline, cloud sync, tip promotion, etc.) was shown earlier in the same session
- **THEN** `didShowNotificationThisSession` is `true` and the reporting nudge is not shown

#### Scenario: Reporting nudge shown when no other notification was shown this session
- **WHEN** no other notification has been shown this session and all other guards pass
- **THEN** the reporting nudge is shown
