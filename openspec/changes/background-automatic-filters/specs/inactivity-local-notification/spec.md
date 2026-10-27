## ADDED Requirements

### Requirement: Remind monthly without opening when AI Filtering is on
When AI Filtering is on and the user has allowed alerts, the system SHALL keep a single repeating local notification that first fires about a month after the app last came to the front, then monthly until they open it or turn AI Filtering off. Only the app entering the foreground SHALL move that clock.

#### Scenario: User opens the app with AI Filtering on
- **WHEN** the app's scene becomes active and AI Filtering is on and alert permission is granted
- **THEN** the system SHALL cancel any pending inactivity reminder
- **AND** the system SHALL schedule a repeating monthly notification starting about a month from that moment

#### Scenario: User opens the app with AI Filtering off
- **WHEN** the app's scene becomes active and AI Filtering is off
- **THEN** the system SHALL cancel any pending inactivity reminder
- **AND** the system SHALL NOT schedule a new one

#### Scenario: User ignores the banner
- **WHEN** a month passes without the app becoming active
- **THEN** the system SHALL show the inactivity reminder notification
- **AND** if another month passes without the app becoming active, the system SHALL show it again

#### Scenario: Background processing runs
- **WHEN** iOS wakes the app in the background for an automatic-filter processing task
- **THEN** the inactivity reminder schedule SHALL NOT be cancelled or moved
- **AND** this SHALL hold even though iOS also runs `didFinishLaunching` for that wake

### Requirement: Turning AI Filtering off stops reminders
The system SHALL cancel the inactivity reminder when AI Filtering changes from on to off. Turning AI Filtering on mid-session SHALL NOT restart the monthly clock; the next scene-active refresh schedules it if AI Filtering is still on and alerts are allowed.

#### Scenario: Last language turned off
- **WHEN** the user turns off the last active automatic-filter language
- **THEN** the system SHALL cancel the inactivity reminder

#### Scenario: Filters edited while AI Filtering stays on
- **WHEN** the user adds, edits or removes a filter and AI Filtering remains on
- **THEN** the system SHALL leave the inactivity reminder where it is

### Requirement: Explain before the system notification prompt
The system SHALL NOT call the iOS notification authorization prompt unless the user has continued from an in-app Home alert (not a full screen) that asks for notification permission so the app can remind them to open it, and that states AI filters may go stale if the app is never opened, and that iOS may offload the app if it is never opened.

Deciding whether to show that alert SHALL NOT change any stored state.

#### Scenario: Existing user returns to Home with AI Filtering on
- **WHEN** navigation returns to App Home from another screen, this is not the first session, AI Filtering is on, asks remain available, and alert permission is not already granted
- **THEN** App Home SHALL show the inactivity notification alert
- **AND** the system SHALL NOT show the iOS notification prompt until they tap Continue

#### Scenario: First session
- **WHEN** this is the user's first session
- **THEN** the system SHALL NOT show the inactivity notification alert, whatever else is true

#### Scenario: The app is merely opened
- **WHEN** the user opens the app and does not navigate away from Home
- **THEN** the system SHALL NOT show the inactivity notification alert

#### Scenario: A launch sheet was dismissed
- **WHEN** onboarding, a launch action or What's New is dismissed
- **THEN** the system SHALL NOT show the inactivity notification alert on that dismissal

#### Scenario: A review prompt is due on the same return to Home
- **WHEN** navigation returns to Home and the App Store review prompt is shown
- **THEN** the system SHALL NOT also show the inactivity notification alert

#### Scenario: User turns AI Filtering on then returns to Home
- **WHEN** the user turns AI Filtering on from the language list, asks remain available, and alert permission is not already granted
- **THEN** the system SHALL NOT present the alert on that screen
- **AND WHEN** they navigate back to App Home
- **THEN** the system SHALL present the alert

#### Scenario: Something else owns the screen
- **WHEN** a sheet is presenting
- **THEN** the system SHALL NOT show the inactivity notification alert

#### Scenario: Alert permission already granted
- **WHEN** alert permission is already granted
- **THEN** the system SHALL NOT show the inactivity notification alert or the iOS notification prompt
- **AND** the system SHALL record that permission was granted, so a later revoke can be noticed

#### Scenario: AI Filtering turned off then on after permission already granted
- **WHEN** the user turns AI Filtering off and then on again, and notification alert permission is already granted
- **THEN** the system SHALL NOT show the inactivity notification alert or the iOS notification prompt

#### Scenario: Continue
- **WHEN** the user taps Continue on the inactivity notification alert
- **THEN** the system SHALL request notification authorization with alerts (no badge, no sound)
- **AND WHEN** the system grants alerts
- **THEN** the system SHALL remember permission was granted, schedule the monthly reminder, and SHALL NOT show the alert again while alerts remain allowed
- **AND WHEN** the system denies alerts
- **THEN** the system SHALL record a decline, exactly as if the user had dismissed the alert

#### Scenario: Not Now on ask 1 or 2
- **WHEN** the user dismisses the alert on ask 1 or 2
- **THEN** the dismiss button SHALL read Not Now
- **AND** the system SHALL NOT request notification authorization
- **AND** the system SHALL record the decline against the current session
- **AND** the system SHALL NOT show the alert again until the session counter has advanced by at least `kInactivityNotificationMinSessionsBetweenAsks`

#### Scenario: Stop Asking on the final ask
- **WHEN** the user is on ask `kInactivityNotificationMaxAsks`
- **THEN** the dismiss button SHALL read Stop Asking
- **AND WHEN** the user dismisses it
- **THEN** the system SHALL NOT request notification authorization
- **AND** the system SHALL NOT show the alert again unless notification permission is later revoked after having been granted

#### Scenario: Permission revoked after grant
- **WHEN** the system previously recorded that alerts were granted
- **AND** it later observes that alert permission is no longer allowed
- **THEN** the system SHALL clear the decline history
- **AND** the system MAY show the inactivity notification alert again from the first ask

#### Scenario: User denied alerts with no further asks
- **WHEN** the user has denied notification permission and asks are exhausted
- **THEN** the system SHALL NOT schedule the inactivity reminder
- **AND** background refresh scheduling SHALL still be attempted

### Requirement: Monthly banner matches the inactivity notification alert
The inactivity reminder notification SHALL say that AI filters may be out of date and that the user can open the app to refresh. Tapping it SHALL open the app to the normal Home launch. It SHALL carry no sound and no badge.

#### Scenario: Notification is delivered
- **WHEN** the inactivity reminder notification is shown
- **THEN** its text SHALL mention that AI filters may be out of date
- **AND** tapping it SHALL open the app without a special deep-link screen
