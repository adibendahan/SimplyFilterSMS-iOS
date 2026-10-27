## ADDED Requirements

### Requirement: Sequence tracking via stored default
The system SHALL store a `lastSeenWhatsNewSequence` integer in `DefaultsManager` (via `UserDefaults`) that records the last What's New sequence the user has seen. The value SHALL start at `0`.

#### Scenario: Fresh install — value is zero
- **WHEN** the app is installed for the first time
- **THEN** `lastSeenWhatsNewSequence` SHALL be `0`

#### Scenario: Value is set on any dismissal
- **WHEN** the What's New sheet is dismissed (Continue button, X button, or swipe-to-dismiss)
- **THEN** `lastSeenWhatsNewSequence` SHALL be set to `whatsNewSequence`

#### Scenario: Value persists across launches
- **WHEN** the user has dismissed the What's New sheet and `whatsNewSequence` is `2`
- **THEN** `lastSeenWhatsNewSequence` SHALL remain `2` across app launches until overwritten

---

### Requirement: Sheet display conditions
The system SHALL present the What's New sheet on `AppHomeView` load when all of the following conditions are met: (1) `isAppFirstRun` is `false`, (2) `whatsNewEntries` is not empty, and (3) `whatsNewSequence` is greater than `lastSeenWhatsNewSequence`.

#### Scenario: First run — sheet is suppressed
- **WHEN** the app launches for the first time (`isAppFirstRun` is `true`)
- **THEN** the What's New sheet SHALL NOT be presented (onboarding takes priority)

#### Scenario: Second run — sheet is shown
- **WHEN** the app launches for the second time (`isAppFirstRun` is `false`) and `lastSeenWhatsNewSequence` is `0` and `whatsNewEntries` is not empty
- **THEN** the What's New sheet SHALL be presented

#### Scenario: Same sequence after dismissal — sheet is suppressed
- **WHEN** the app launches and `lastSeenWhatsNewSequence` equals `whatsNewSequence`
- **THEN** the What's New sheet SHALL NOT be presented

#### Scenario: Sequence bumped — sheet is shown
- **WHEN** `whatsNewSequence` has been incremented beyond `lastSeenWhatsNewSequence` and `whatsNewEntries` is not empty
- **THEN** the What's New sheet SHALL be presented

#### Scenario: Empty entries — sheet is suppressed
- **WHEN** `whatsNewEntries` is empty
- **THEN** the What's New sheet SHALL NOT be presented, regardless of `whatsNewSequence` and `lastSeenWhatsNewSequence`

---

### Requirement: Sheet presentation integration
The system SHALL present the What's New sheet via the existing `sheetScreen` mechanism in `AppHomeView.ViewModel`, triggered in the `.onReceive($navigationScreen)` block as an `else` branch after the `isAppFirstRun` / onboarding check.

#### Scenario: Onboarding and What's New are mutually exclusive
- **WHEN** `isAppFirstRun` is `true`
- **THEN** only the onboarding sheet SHALL be presented; the What's New check SHALL be skipped entirely

#### Scenario: What's New uses existing sheet mechanism
- **WHEN** the What's New conditions are met
- **THEN** the system SHALL set `sheetScreen = .whatsNew` to present the sheet

---

### Requirement: Screen enum routing
The `Screen` enum SHALL include a `.whatsNew` case whose `build()` method returns `WhatsNewView(model: WhatsNewView.ViewModel())`.

#### Scenario: Screen.whatsNew builds correctly
- **WHEN** `Screen.whatsNew.build()` is called
- **THEN** it SHALL return a `WhatsNewView` with a default-initialized ViewModel

---

### Requirement: Data model
The system SHALL define a `WhatsNewEntry` struct with the following properties: `symbolName` (String — SF Symbol name), `symbolColor` (Color), `titleKey` (String — localization key), and `descriptionKey` (String — localization key, supports inline markdown after localization). Two top-level constants SHALL be defined in `Constsants.swift`: `whatsNewSequence: Int` (hardcoded, manually incremented when entries change) and `whatsNewEntries: [WhatsNewEntry]` (the current entries). Old entries can be freely deleted since the sequence is a standalone constant.

#### Scenario: Entries and sequence are defined
- **WHEN** `whatsNewEntries` contains entries and `whatsNewSequence` is set
- **THEN** `whatsNewEntries` SHALL return the current array of entries and `whatsNewSequence` SHALL return the current sequence number

#### Scenario: Entries can be replaced without affecting sequence
- **WHEN** old entries are deleted and new entries are added with an incremented `whatsNewSequence`
- **THEN** `whatsNewSequence` SHALL reflect the new value independent of array contents

---

### Requirement: View layout
`WhatsNewView` SHALL be presented as a sheet with the following structure: a `NavigationView` containing a `ScrollView` with a large bold centered title, followed by a list of feature rows. Each row SHALL display an SF Symbol icon (colored, in a circular background) leading an HStack with a bold title and a secondary description (rendered via `AttributedString(markdown:)`). A full-width "Continue" button (using `FilledButton` style) SHALL be pinned to the bottom of the screen outside the scroll area. A toolbar X button SHALL be provided for dismissal.

#### Scenario: Title is displayed
- **WHEN** the What's New sheet is presented
- **THEN** a large bold centered title SHALL be visible at the top of the content

#### Scenario: Feature rows are rendered from entries
- **WHEN** `whatsNewEntries` has N entries
- **THEN** N feature rows SHALL be displayed, each with the entry's icon, title, and description

#### Scenario: Markdown descriptions are rendered
- **WHEN** an entry's localized description contains inline markdown (e.g., `**bold**`)
- **THEN** the description SHALL be rendered as an `AttributedString` with the markdown formatting applied

#### Scenario: Continue button is always visible
- **WHEN** the content is long enough to scroll
- **THEN** the Continue button SHALL remain pinned at the bottom and not scroll with the content

---

### Requirement: ViewModel pattern
`WhatsNewView.ViewModel` SHALL subclass `BaseViewModel`, conform to `ObservableObject`, and expose a `let entries: [WhatsNewEntry]` property populated from `whatsNewEntries` at init. It SHALL provide a `markAsSeen()` method that sets `lastSeenWhatsNewSequence` to `whatsNewSequence` via `DefaultsManager`.

#### Scenario: ViewModel loads entries
- **WHEN** the ViewModel is initialized
- **THEN** `entries` SHALL contain the values from `whatsNewEntries`

#### Scenario: markAsSeen writes sequence
- **WHEN** `markAsSeen()` is called
- **THEN** `DefaultsManager.lastSeenWhatsNewSequence` SHALL be set to `whatsNewSequence`

---

### Requirement: Menu item for re-viewing What's New
The `AppHomeView` trailing navigation bar menu SHALL include a "What's New" menu item that presents the What's New sheet when tapped. The menu item SHALL only be visible when `whatsNewEntries` is not empty.

#### Scenario: Menu item is visible when entries exist
- **WHEN** `whatsNewEntries` is not empty
- **THEN** a "What's New" item SHALL appear in the AppHomeView trailing menu

#### Scenario: Menu item is hidden when no entries
- **WHEN** `whatsNewEntries` is empty
- **THEN** the "What's New" item SHALL NOT appear in the AppHomeView trailing menu

#### Scenario: Tapping menu item opens the sheet
- **WHEN** the user taps the "What's New" menu item
- **THEN** the What's New sheet SHALL be presented via `sheetScreen = .whatsNew`

---

### Requirement: All strings must be localized
Every user-facing string in the What's New feature MUST be localized via the `~` postfix operator. This includes the sheet title, Continue button label, and all entry titles and descriptions. Corresponding keys MUST be added to all `.strings` files (English and Hebrew).

#### Scenario: Sheet title is localized
- **WHEN** the What's New sheet is presented
- **THEN** the title SHALL be rendered from a localized `.strings` key via the `~` operator

#### Scenario: Continue button is localized
- **WHEN** the What's New sheet is presented
- **THEN** the Continue button label SHALL be rendered from a localized `.strings` key via the `~` operator

#### Scenario: Entry titles and descriptions are localized
- **WHEN** the What's New sheet displays feature rows
- **THEN** each entry's title and description SHALL be resolved from localized `.strings` keys via the `~` operator

---

### Requirement: Dismissal behavior
Any method of dismissing the What's New sheet (Continue button, X button, or swipe-to-dismiss) SHALL invoke `markAsSeen()` to record the current sequence, ensuring the sheet auto-displays only once per sequence.

#### Scenario: Dismiss via Continue button
- **WHEN** the user taps the Continue button
- **THEN** `markAsSeen()` SHALL be called and the sheet SHALL be dismissed

#### Scenario: Dismiss via X button
- **WHEN** the user taps the X toolbar button
- **THEN** `markAsSeen()` SHALL be called and the sheet SHALL be dismissed

#### Scenario: Dismiss via swipe
- **WHEN** the user swipes down to dismiss the sheet
- **THEN** `markAsSeen()` SHALL be called
