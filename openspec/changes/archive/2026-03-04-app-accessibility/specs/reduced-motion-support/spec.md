## ADDED Requirements

### Requirement: Motion-heavy animations SHALL be disabled when Reduce Motion is enabled
When `@Environment(\.accessibilityReduceMotion)` is `true`, all rotation effects, spring-based slide animations, and path-draw animations SHALL be replaced with instant state changes. Opacity-only transitions are exempt and SHALL remain active.

#### Scenario: Notification toast appears with Reduce Motion enabled
- **WHEN** a notification toast becomes visible
- **AND** Reduce Motion is enabled
- **THEN** the toast appears instantly at its final position with no spring slide animation

#### Scenario: Notification toast appears with Reduce Motion disabled
- **WHEN** a notification toast becomes visible
- **AND** Reduce Motion is disabled
- **THEN** the toast slides in using the standard interpolating spring animation

### Requirement: Rotation effects SHALL be zeroed out when Reduce Motion is enabled
Chevron and arrow icons that rotate to indicate expand/collapse state SHALL stay at 0° when Reduce Motion is enabled. The expand/collapse state change itself SHALL still occur.

#### Scenario: QuestionView chevron with Reduce Motion enabled
- **WHEN** the user taps a question in HelpView
- **AND** Reduce Motion is enabled
- **THEN** the chevron stays at 0° and the answer appears instantly

#### Scenario: AddFilterView arrow with Reduce Motion enabled
- **WHEN** the user taps the expand/collapse button in AddFilterView
- **AND** Reduce Motion is enabled
- **THEN** the arrow stays at 0° and the advanced options appear or disappear instantly

### Requirement: Button press scale effects SHALL be disabled when Reduce Motion is enabled
`TipCardButtonStyle` applies a 0.95 scale effect on press. When Reduce Motion is enabled, the scale effect SHALL be skipped. Opacity feedback on press SHALL be retained regardless of Reduce Motion state.

#### Scenario: Tip card pressed with Reduce Motion enabled
- **WHEN** the user presses a tip card button
- **AND** Reduce Motion is enabled
- **THEN** the card dims to 70% opacity on press but does not scale down

#### Scenario: Tip card pressed with Reduce Motion disabled
- **WHEN** the user presses a tip card button
- **AND** Reduce Motion is disabled
- **THEN** the card scales to 95% and dims to 70% opacity on press

### Requirement: Checkmark draw animation SHALL be instant when Reduce Motion is enabled
`CheckView` draws its checkmark via an animated path trim. When Reduce Motion is enabled, the checkmark SHALL appear fully drawn at 100% trim without animation.

#### Scenario: CheckView appears with Reduce Motion enabled
- **WHEN** `CheckView` appears on screen
- **AND** Reduce Motion is enabled
- **THEN** the checkmark is immediately fully visible with no drawing animation

### Requirement: Opacity-only animations SHALL remain active regardless of Reduce Motion
`FadingTextView` fades text using opacity-only animation. Per Apple HIG, opacity transitions do not cause vestibular discomfort and SHALL NOT be disabled under Reduce Motion.
