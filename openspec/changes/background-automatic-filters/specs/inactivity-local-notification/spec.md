## ADDED Requirements

### Requirement: Remind monthly without opening when AI Filtering is on
When AI Filtering is on and the user has allowed alerts, the system SHALL keep a single repeating local notification that first fires one calendar month after the last startup, then monthly until they open the app or turn AI Filtering off.

#### Scenario: User opens the app with AI Filtering on
- **WHEN** the app becomes active and AI Filtering is on and alert permission is granted
- **THEN** the system SHALL cancel any pending inactivity notification
- **AND** the system SHALL schedule a repeating monthly notification starting one month from that moment

#### Scenario: User opens the app with AI Filtering off
- **WHEN** the app becomes active and AI Filtering is off
- **THEN** the system SHALL cancel any pending inactivity notification
- **AND** the system SHALL NOT schedule a new one

#### Scenario: User ignores the banner
- **WHEN** a month passes without the app becoming active
- **THEN** the system SHALL show the inactivity notification
- **AND** if another month passes without the app becoming active, the system SHALL show it again

#### Scenario: Background processing runs
- **WHEN** a background automatic-filter processing task completes
- **THEN** the inactivity notification schedule SHALL NOT be cancelled or moved

### Requirement: Turning AI Filtering off stops reminders
The system SHALL cancel the inactivity notification when AI Filtering changes from on to off. Turning AI Filtering on mid-session SHALL NOT restart the monthly clock; the next app startup schedules the reminder if AI Filtering is still on and alerts are allowed.

#### Scenario: Last language turned off
- **WHEN** the user turns off the last active automatic-filter language
- **THEN** the system SHALL cancel the inactivity notification

#### Scenario: AI Filtering turned on mid-session
- **WHEN** the user turns on automatic filtering for a language so that AI Filtering becomes on
- **THEN** the system SHALL NOT schedule or reschedule the inactivity notification until the next app startup (or until Continue grants alerts from the explainer)

### Requirement: Explain before the system notification prompt
The system SHALL NOT call the iOS notification authorization prompt unless the user has continued from an in-app alert (not a full screen) that asks for notification permission so the app can remind them to open it, and that states AI filters may go stale if the app is never opened, and that iOS may offload the app if it is never opened.

#### Scenario: Existing user opens this version with AI Filtering on
- **WHEN** App Home is shown, AI Filtering is on, the explainer has never been shown, and alert permission is not already granted
- **THEN** the system SHALL enable the explainer in `FlowManager`
- **AND** the explainer SHALL wait behind first-run, launch, and What’s New
- **AND** when `FlowManager.next()` returns `.notificationPermission`, App Home SHALL show the explainer alert (not a sheet)
- **AND** the system SHALL NOT show the iOS notification prompt until they tap Continue

#### Scenario: User turns AI Filtering on then returns to Home
- **WHEN** the user turns AI Filtering on from the language list, the explainer has never been shown, and alert permission is not already granted
- **THEN** the system SHALL NOT present the explainer on that screen
- **AND WHEN** App Home is shown after that (same session pop, or a later launch)
- **THEN** the system SHALL enable the explainer in `FlowManager` and present it when the queue is free
- **AND** the system SHALL NOT show the iOS notification prompt until they tap Continue

#### Scenario: Alert permission already granted
- **WHEN** App Home is shown, AI Filtering is on, and notification alert permission is already granted
- **THEN** the system SHALL NOT enable the explainer
- **AND** the system SHALL NOT show the explainer alert or the iOS notification prompt
- **AND** the system SHALL record that the explainer was handled so it does not appear later

#### Scenario: AI Filtering turned off then on after permission already granted
- **WHEN** the user turns AI Filtering off and then on again, and notification alert permission is already granted
- **THEN** the system SHALL NOT show the explainer alert or the iOS notification prompt

#### Scenario: Another Home sheet is already up
- **WHEN** the explainer is enabled while a first-run, launch, or What’s New sheet is active
- **THEN** `FlowManager.next()` SHALL return nil until that sheet is completed
- **AND** the explainer SHALL show after `complete` of the earlier screen

#### Scenario: Continue
- **WHEN** the user taps Continue on the explainer
- **THEN** the system SHALL request notification authorization with alerts (no badge, no sound)

#### Scenario: Not Now
- **WHEN** the user taps Not Now on the explainer
- **THEN** the system SHALL NOT request notification authorization
- **AND** the system SHALL NOT show the explainer again on later launches

#### Scenario: Explainer already shown
- **WHEN** the explainer has already been shown
- **THEN** the system SHALL NOT present it again
- **AND** the system SHALL NOT call the iOS notification prompt from launch or from an AI Filtering toggle

#### Scenario: User denied alerts
- **WHEN** the user has denied notification permission
- **THEN** the system SHALL NOT schedule the inactivity notification
- **AND** background refresh scheduling SHALL still be attempted

### Requirement: Monthly banner matches the explainer
The inactivity notification SHALL say that AI filters may be out of date and that the user can open the app to refresh. Tapping it SHALL open the app to the normal Home launch.

#### Scenario: Notification is delivered
- **WHEN** the inactivity notification is shown
- **THEN** its text SHALL mention that AI filters may be out of date
- **AND** tapping it SHALL open the app without a special deep-link screen
