## ADDED Requirements

### Requirement: Toast notifications SHALL be announced to VoiceOver
When `NotificationView` becomes visible, the system SHALL post a `UIAccessibility.Notification.announcement` with the toast's title and subtitle text concatenated.

#### Scenario: Toast appears while VoiceOver is active
- **WHEN** a notification toast slides into view (e.g., "Automatic filters updated", "Copied to clipboard")
- **AND** VoiceOver is running
- **THEN** VoiceOver announces the toast content without moving focus away from the user's current element

#### Scenario: Toast is not announced when VoiceOver is inactive
- **WHEN** a notification toast slides into view
- **AND** VoiceOver is not running
- **THEN** no announcement is posted (standard visual behavior only)

### Requirement: Filter test results SHALL be announced to VoiceOver
When the user taps the test button in `TestFiltersView` and results appear, the system SHALL announce the result to VoiceOver.

#### Scenario: Filter test produces a result
- **WHEN** the user activates the test button in TestFiltersView
- **AND** VoiceOver is running
- **THEN** VoiceOver announces the filter evaluation result (e.g., "Message would be moved to junk" or "Message would not be filtered")

### Requirement: State changes on toggle controls SHALL be announced
When a smart filter toggle or automatic filter toggle changes state, VoiceOver SHALL announce the new state through the standard toggle accessibility value (no custom announcement needed — SwiftUI handles this if labels are properly set).

#### Scenario: Smart filter toggled on
- **WHEN** VoiceOver user activates a smart filter toggle
- **THEN** VoiceOver reads the updated state (e.g., "Block links, on")

#### Scenario: Smart filter toggled off
- **WHEN** VoiceOver user deactivates a smart filter toggle
- **THEN** VoiceOver reads the updated state (e.g., "Block links, off")
