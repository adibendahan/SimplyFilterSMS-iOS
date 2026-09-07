## ADDED Requirements

### Requirement: Remind monthly without opening when AI Filtering is on
When AI Filtering is on and the user has allowed alerts, the system SHALL keep a single repeating local notification that first fires one calendar month after the last scene-active refresh, then monthly until they open the app or turn AI Filtering off. Refresh of that clock SHALL be `SchedulingManager.refreshInactivityReminder()` (cancel, then maybe schedule) — not a one-line lifecycle alias.

#### Scenario: User opens the app with AI Filtering on
- **WHEN** the app’s scene becomes active and AI Filtering is on and alert permission is granted
- **THEN** the system SHALL cancel any pending inactivity reminder
- **AND** the system SHALL schedule a repeating monthly notification starting one month from that moment

#### Scenario: User opens the app with AI Filtering off
- **WHEN** the app’s scene becomes active and AI Filtering is off
- **THEN** the system SHALL cancel any pending inactivity reminder
- **AND** the system SHALL NOT schedule a new one

#### Scenario: User ignores the banner
- **WHEN** a month passes without the app becoming active
- **THEN** the system SHALL show the inactivity reminder notification
- **AND** if another month passes without the app becoming active, the system SHALL show it again

#### Scenario: Background processing runs
- **WHEN** a background automatic-filter processing task completes
- **THEN** the inactivity reminder schedule SHALL NOT be cancelled or moved

### Requirement: Turning AI Filtering off stops reminders
The system SHALL cancel the inactivity reminder when AI Filtering changes from on to off (via `.filtersStateChanged` observed inside `SchedulingManager`). Turning AI Filtering on mid-session SHALL NOT restart the monthly clock; the next scene-active refresh schedules the reminder if AI Filtering is still on and alerts are allowed.

#### Scenario: Last language turned off
- **WHEN** the user turns off the last active automatic-filter language
- **THEN** the system SHALL cancel the inactivity reminder

#### Scenario: AI Filtering turned on mid-session
- **WHEN** the user turns on automatic filtering for a language so that AI Filtering becomes on
- **THEN** the system SHALL NOT schedule or reschedule the inactivity reminder until the next scene-active refresh (or until Continue grants alerts from the inactivity notification)

### Requirement: Explain before the system notification prompt
The system SHALL NOT call the iOS notification authorization prompt unless the user has continued from an in-app Home alert (not a full screen) that asks for notification permission so the app can remind them to open it, and that states AI filters may go stale if the app is never opened, and that iOS may offload the app if it is never opened.

Home SHALL separate permission bookkeeping from presentation: call `syncInactivityNotificationPermission()` first, then `shouldShowInactivityNotificationAlert()` (read-only). Those MUST NOT be one combined method.

#### Scenario: Existing user opens this version with AI Filtering on
- **WHEN** App Home is shown, AI Filtering is on, `shouldShowInactivityNotificationAlert` is true, and alert permission is not already granted
- **THEN** the system SHALL enable the inactivity notification in `FlowManager`
- **AND** the inactivity notification SHALL wait behind first-run, launch, and What’s New
- **AND** when `FlowManager.next()` returns `.inactivityNotification`, App Home SHALL show the inactivity notification alert (not a sheet)
- **AND** the system SHALL NOT show the iOS notification prompt until they tap Continue

#### Scenario: User turns AI Filtering on then returns to Home
- **WHEN** the user turns AI Filtering on from the language list, asks remain available, and alert permission is not already granted
- **THEN** the system SHALL NOT present the inactivity notification on that screen
- **AND WHEN** App Home is shown after that (same session pop, or a later launch)
- **THEN** the system SHALL enable the inactivity notification in `FlowManager` and present it when the queue is free
- **AND** the system SHALL NOT show the iOS notification prompt until they tap Continue

#### Scenario: Alert permission already granted
- **WHEN** App Home runs `syncInactivityNotificationPermission` and alert permission is already granted
- **THEN** the system SHALL record that permission was granted
- **AND** the system SHALL refresh the inactivity reminder
- **AND WHEN** Home then asks `shouldShowInactivityNotificationAlert`
- **THEN** it SHALL be false
- **AND** the system SHALL NOT show the inactivity notification alert or the iOS notification prompt

#### Scenario: AI Filtering turned off then on after permission already granted
- **WHEN** the user turns AI Filtering off and then on again, and notification alert permission is already granted
- **THEN** the system SHALL NOT show the inactivity notification alert or the iOS notification prompt

#### Scenario: Another Home sheet is already up
- **WHEN** the inactivity notification is enabled while a first-run, launch, or What’s New sheet is active
- **THEN** `FlowManager.next()` SHALL return nil until that sheet is completed
- **AND** the inactivity notification SHALL show after `complete` of the earlier screen

#### Scenario: Continue
- **WHEN** the user taps Continue on the inactivity notification
- **THEN** the system SHALL call `inactivityNotificationContinued`
- **AND** that SHALL request notification authorization with alerts (no badge, no sound)
- **AND WHEN** the system grants alerts
- **THEN** the system SHALL remember permission was granted, refresh the inactivity reminder, and SHALL NOT show the inactivity notification again while alerts remain allowed
- **AND WHEN** the system denies alerts
- **THEN** the system SHALL record a decline for that ask (same as Not Now / Stop Asking)

#### Scenario: Not Now on ask 1 or 2
- **WHEN** the user taps Not Now on ask 1 or 2
- **THEN** the system SHALL call `inactivityNotificationDeclined`
- **AND** the system SHALL NOT request notification authorization
- **AND** the system SHALL increment the ask count and store the current `sessionCounter`
- **AND** the system SHALL NOT show the inactivity notification again until `sessionCounter` has advanced by at least `kInactivityNotificationMinSessionsBetweenAsks`

#### Scenario: Stop Asking on ask 3
- **WHEN** the user is on ask 3
- **THEN** `inactivityNotificationDismissTitle` SHALL be Stop Asking (not Not Now)
- **AND WHEN** the user taps Stop Asking
- **THEN** the system SHALL call `inactivityNotificationDeclined`
- **AND** the system SHALL NOT request notification authorization
- **AND** the system SHALL NOT show the inactivity notification again unless notification permission is later revoked after having been granted

#### Scenario: Max asks reached
- **WHEN** the inactivity notification has been declined 3 times
- **THEN** the system SHALL NOT present it again
- **AND** the system SHALL NOT call the iOS notification prompt from launch or from an AI Filtering toggle

#### Scenario: Permission revoked after grant
- **WHEN** the system previously recorded that alerts were granted
- **AND** `syncInactivityNotificationPermission` sees alert permission is no longer allowed
- **THEN** the system SHALL reset the ask count and last-declined session
- **AND** the system MAY show the inactivity notification again from ask 1 when `shouldShowInactivityNotificationAlert` is later true

#### Scenario: User denied alerts with no further asks
- **WHEN** the user has denied notification permission and asks are exhausted (or Stop Asking)
- **THEN** the system SHALL NOT schedule the inactivity reminder
- **AND** background refresh scheduling SHALL still be attempted

### Requirement: Monthly banner matches the inactivity notification alert
The inactivity reminder notification SHALL say that AI filters may be out of date and that the user can open the app to refresh. Tapping it SHALL open the app to the normal Home launch.

#### Scenario: Notification is delivered
- **WHEN** the inactivity reminder notification is shown
- **THEN** its text SHALL mention that AI filters may be out of date
- **AND** tapping it SHALL open the app without a special deep-link screen
