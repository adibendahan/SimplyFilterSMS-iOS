## ADDED Requirements

### Requirement: Version tracking via stored default
The system SHALL store a `lastSeenWhatsNewVersion` integer in `DefaultsManager` (via `UserDefaults`) that records the last What's New version the user has seen. The value SHALL start at `0`.

#### Scenario: Fresh install — value is zero
- **WHEN** the app is installed for the first time
- **THEN** `lastSeenWhatsNewVersion` SHALL be `0`

#### Scenario: Value is set on any dismissal
- **WHEN** the What's New sheet is dismissed (Continue button, X button, swipe-to-dismiss, or actionable entry tap)
- **THEN** `lastSeenWhatsNewVersion` SHALL be set to `currentWhatsNewVersion`

#### Scenario: Value persists across launches
- **WHEN** the user has dismissed the What's New sheet and `currentWhatsNewVersion` is `2`
- **THEN** `lastSeenWhatsNewVersion` SHALL remain `2` across app launches until overwritten

---

### Requirement: Sheet display conditions
The system SHALL present the What's New sheet on `AppHomeView` load when all of the following conditions are met: (1) `wasFirstRunOnInit` is `false` (the app was NOT first launched in this session), (2) `isAppFirstRun` is `false`, (3) `WhatsNewEntry.allCases` is not empty, and (4) `currentWhatsNewVersion` is greater than `lastSeenWhatsNewVersion`.

#### Scenario: First run — sheet is suppressed
- **WHEN** the app launches for the first time (`isAppFirstRun` is `true`)
- **THEN** the What's New sheet SHALL NOT be presented (onboarding takes priority)

#### Scenario: First session after first run — sheet is suppressed even after onboarding
- **WHEN** the user dismisses the onboarding sheet during their first session (`wasFirstRunOnInit` is `true`, `isAppFirstRun` becomes `false`)
- **THEN** the What's New sheet SHALL NOT be presented because `wasFirstRunOnInit` is still `true` for the lifetime of the ViewModel

#### Scenario: Second run — sheet is shown
- **WHEN** the app launches for the second time (`wasFirstRunOnInit` is `false`, `isAppFirstRun` is `false`) and `lastSeenWhatsNewVersion` is `0` and `WhatsNewEntry.allCases` is not empty
- **THEN** the What's New sheet SHALL be presented

#### Scenario: Same version after dismissal — sheet is suppressed
- **WHEN** the app launches and `lastSeenWhatsNewVersion` equals `currentWhatsNewVersion`
- **THEN** the What's New sheet SHALL NOT be presented

#### Scenario: Version bumped — sheet is shown
- **WHEN** `currentWhatsNewVersion` has been incremented beyond `lastSeenWhatsNewVersion` and `WhatsNewEntry.allCases` is not empty
- **THEN** the What's New sheet SHALL be presented

#### Scenario: Empty entries — sheet is suppressed
- **WHEN** `WhatsNewEntry.allCases` is empty
- **THEN** the What's New sheet SHALL NOT be presented, regardless of version values

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
The `Screen` enum SHALL include a `.whatsNew` case. When presented from `AppHomeView`, the view is constructed inline (not via `build()`) to pass the `onActionnableEntryTapped` closure.

#### Scenario: Screen.whatsNew from AppHomeView
- **WHEN** `sheetScreen == .whatsNew` in AppHomeView
- **THEN** the sheet content SHALL construct `WhatsNewView` with an `onActionnableEntryTapped` closure that handles actionable entry navigation

---

### Requirement: Data model
The system SHALL define a `WhatsNewEntry` enum conforming to `CaseIterable` in `Constsants.swift` with computed properties for: `emoji` (String), `title` (localized String via `~`), `description` (localized String via `~`), `order` (Int for sorting), and `isActionnable` (Bool). A top-level constant `currentWhatsNewVersion: Int` SHALL be defined in `Constsants.swift` and manually incremented when entries change.

#### Scenario: Entries are enumerable
- **WHEN** the app accesses `WhatsNewEntry.allCases`
- **THEN** all entries SHALL be available, sorted by `order` in the ViewModel

#### Scenario: Entries can be replaced without affecting version tracking
- **WHEN** old cases are removed and new cases are added with an incremented `currentWhatsNewVersion`
- **THEN** `currentWhatsNewVersion` SHALL reflect the new value independent of enum cases

---

### Requirement: Actionable entries
`WhatsNewEntry` cases MAY be actionable, indicated by `isActionnable` returning `true`. Actionable entries are rendered as tappable buttons in the sheet. When tapped, the entry calls `markAsSeen()`, invokes the `onActionnableEntryTapped` closure, and dismisses the sheet. The presenting screen handles the resulting navigation.

#### Scenario: Actionable entry is tappable
- **WHEN** an entry has `isActionnable == true` and `onActionnableEntryTapped` is provided
- **THEN** the entry row SHALL be wrapped in a `Button` that is visually distinct (e.g., accent-colored chevron)

#### Scenario: Non-actionable entry is static
- **WHEN** an entry has `isActionnable == false`
- **THEN** the entry row SHALL be a plain, non-interactive display row

#### Scenario: Tapping actionable entry navigates
- **WHEN** the user taps an actionable entry
- **THEN** the system SHALL call `markAsSeen()`, invoke `onActionnableEntryTapped(entry)`, and dismiss the sheet

#### Scenario: Presenting screen handles navigation
- **WHEN** `onActionnableEntryTapped` is called with an entry (e.g., `.tipJar`)
- **THEN** the presenting screen SHALL set `pendingScreenAfterDismiss` to the appropriate `Screen` case, which is presented after the sheet dismiss completes

---

### Requirement: View layout
`WhatsNewView` SHALL be presented as a sheet with the following structure: a `NavigationView` containing a `ScrollView` with a large bold centered title, followed by a list of feature rows. Each row SHALL display an emoji icon leading a VStack with a bold title and a secondary description. A full-width "Continue" button (using `FilledButton` style) SHALL be pinned to the bottom of the screen outside the scroll area. A toolbar X button SHALL be provided for dismissal. Actionable entries SHALL display an accent-colored chevron and be tappable.

#### Scenario: Title is displayed
- **WHEN** the What's New sheet is presented
- **THEN** a large bold centered title SHALL be visible at the top of the content

#### Scenario: Feature rows are rendered from entries
- **WHEN** `WhatsNewEntry.allCases` has N entries
- **THEN** N feature rows SHALL be displayed sorted by `order`, each with the entry's emoji, title, and description

#### Scenario: Continue button is always visible
- **WHEN** the content is long enough to scroll
- **THEN** the Continue button SHALL remain pinned at the bottom and not scroll with the content

---

### Requirement: ViewModel pattern
`WhatsNewView.ViewModel` SHALL subclass `BaseViewModel`, conform to `ObservableObject`, and expose: `entries: [WhatsNewEntry]` (sorted by `order`), and `onActionnableEntryTapped: ((WhatsNewEntry) -> Void)?` (optional closure). It SHALL provide a `markAsSeen()` method that sets `lastSeenWhatsNewVersion` to `currentWhatsNewVersion` via `DefaultsManager`.

#### Scenario: ViewModel loads entries
- **WHEN** the ViewModel is initialized
- **THEN** `entries` SHALL contain `WhatsNewEntry.allCases` sorted by `order`

#### Scenario: markAsSeen writes version
- **WHEN** `markAsSeen()` is called
- **THEN** `DefaultsManager.lastSeenWhatsNewVersion` SHALL be set to `currentWhatsNewVersion`

---

### Requirement: Menu item for re-viewing What's New
The `AppHomeView` trailing navigation bar menu SHALL include a "What's New" menu item that presents the What's New sheet when tapped. The menu item SHALL only be visible when `WhatsNewEntry.allCases` is not empty.

#### Scenario: Menu item is visible when entries exist
- **WHEN** `WhatsNewEntry.allCases` is not empty
- **THEN** a "What's New" item SHALL appear in the AppHomeView trailing menu

#### Scenario: Menu item is hidden when no entries
- **WHEN** `WhatsNewEntry.allCases` is empty
- **THEN** the "What's New" item SHALL NOT appear in the AppHomeView trailing menu

#### Scenario: Tapping menu item opens the sheet
- **WHEN** the user taps the "What's New" menu item
- **THEN** the What's New sheet SHALL be presented via `sheetScreen = .whatsNew`

---

### Requirement: All strings must be localized
Every user-facing string in the What's New feature MUST be localized via the `~` postfix operator. This includes the sheet title, Continue button label, and all entry titles and descriptions. Corresponding keys MUST be added to all `.strings` files (English and Hebrew).

#### Scenario: All text uses localization operator
- **WHEN** the What's New sheet is presented
- **THEN** the title, button label, and all entry titles and descriptions SHALL be resolved from localized `.strings` keys via the `~` operator

---

### Requirement: Dismissal behavior
Any method of dismissing the What's New sheet (Continue button, X button, swipe-to-dismiss, or actionable entry tap) SHALL invoke `markAsSeen()` to record the current version, ensuring the sheet auto-displays only once per version.

#### Scenario: Dismiss via Continue button
- **WHEN** the user taps the Continue button
- **THEN** `markAsSeen()` SHALL be called and the sheet SHALL be dismissed

#### Scenario: Dismiss via X button
- **WHEN** the user taps the X toolbar button
- **THEN** `markAsSeen()` SHALL be called and the sheet SHALL be dismissed

#### Scenario: Dismiss via swipe
- **WHEN** the user swipes down to dismiss the sheet
- **THEN** `markAsSeen()` SHALL be called

#### Scenario: Dismiss via actionable entry
- **WHEN** the user taps an actionable entry
- **THEN** `markAsSeen()` SHALL be called and the sheet SHALL be dismissed, followed by navigation to the entry's target screen
