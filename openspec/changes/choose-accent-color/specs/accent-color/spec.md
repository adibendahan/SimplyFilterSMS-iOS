## ADDED Requirements

### Requirement: Accent color is available only from the Home menu
The system SHALL provide a Home `•••` menu item (alongside Help, About, and Tip Jar — not inside Filter Tools, not in About) that presents the accent color sheet via the existing `requestSheet` / `FlowManager.request` path.

#### Scenario: Menu opens the picker sheet
- **WHEN** the user taps the accent color item in the Home `•••` menu
- **THEN** the system SHALL present `Screen.chooseAccentColor`

#### Scenario: First-run still wins
- **WHEN** first-run onboarding occupies the session
- **THEN** the accent color sheet SHALL wait behind it like other user-requested screens

#### Scenario: Not in About or Filter Tools
- **WHEN** the user opens About or Filter Tools
- **THEN** those screens SHALL NOT contain an accent color control

---

### Requirement: Native color picker sheet
The system SHALL present `ChooseAccentColorView` from `Screen.chooseAccentColor.build()` (`NavigationView`, inline title, X close). The sheet SHALL contain a full `UIColorPickerViewController` with alpha disabled and a control that resets to the system default.

#### Scenario: Picker writes a custom color
- **WHEN** the user selects a color in the picker
- **THEN** the system SHALL persist that color and apply it as the app tint

#### Scenario: Reset restores system accent
- **WHEN** the user activates Reset
- **THEN** the system SHALL remove the stored color and SHALL NOT apply a custom `.tint` (system accent)

#### Scenario: Opacity is not part of the pick
- **WHEN** the picker is shown
- **THEN** `supportsAlpha` SHALL be `false`

---

### Requirement: Persistence in UserDefaults.standard
The system SHALL store the custom accent as a `UserDefaults` dictionary (`accentColorRGB`) with `red`, `green`, and `blue` components. `kNoColorDict` SHALL mean system default. Debug `reset()` SHALL clear the stored accent.

#### Scenario: Color survives relaunch
- **WHEN** the user picked a custom color and relaunches the app
- **THEN** that color SHALL still be the tint

#### Scenario: Unset means system default
- **WHEN** no accent is stored
- **THEN** the UI SHALL use the system accent

#### Scenario: Debug reset
- **WHEN** debug reset runs
- **THEN** the stored accent SHALL be removed

---

### Requirement: Existing accent chrome follows the tint
The system SHALL apply `.optionalTint` with the stored color on `AppHomeView` so views using `ShapeStyle.tint` follow it. Semantic colors SHALL stay unchanged: deny red, allow green, delete red, dimmed NavigationLink chevrons, smart-filter icon colors. Toolbar ellipsis and close X SHALL stay `.tint(.primary)`.

#### Scenario: Filter list chips follow
- **WHEN** a custom accent is set
- **THEN** active filter option chips SHALL use that tint

#### Scenario: Semantic colors do not follow
- **WHEN** a custom accent is set
- **THEN** deny/allow/delete/chevron/smart-filter colors listed above SHALL keep their hardcoded colors
