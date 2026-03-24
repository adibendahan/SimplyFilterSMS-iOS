## ADDED Requirements

### Requirement: EnableExtensionStepProtocol defines the step rendering contract
The system SHALL define an `EnableExtensionStepProtocol` with the following computed properties: `stepNumber: Int`, `title: String`, `description: String`, `symbolName: String?`, `symbolColor: Color?`, `showsAppIcon: Bool`, `isToggle: Bool`, `isLast: Bool`. Both `EnableExtensionStep` and `EnableReportingExtensionStep` SHALL conform to this protocol.

#### Scenario: Existing step enum conforms without behavior change
- **WHEN** `EnableExtensionStep` is updated to declare conformance to `EnableExtensionStepProtocol`
- **THEN** all existing computed properties satisfy the protocol and the onboarding flow behaves identically to before

#### Scenario: New step enum conforms to the same protocol
- **WHEN** `EnableReportingExtensionStep` declares conformance to `EnableExtensionStepProtocol`
- **THEN** its cases can be passed to `EnableExtensionView` without any view-layer changes

### Requirement: EnableExtensionView accepts steps and callbacks via its ViewModel
`EnableExtensionView.ViewModel` SHALL be initialized with: `steps: [any EnableExtensionStepProtocol]`, `isInteractiveDismissDisabled: Bool`, `onDismiss: () -> Void`, and `onCTA: () -> Void`. The ViewModel SHALL NOT contain `isAppFirstRun` or any first-run logic — call sites are responsible for those side effects via the callbacks.

#### Scenario: Onboarding call site preserves first-run behavior
- **WHEN** `AppHomeView` presents `EnableExtensionView` for onboarding
- **THEN** the ViewModel is initialized with `isInteractiveDismissDisabled: true`, `onDismiss` sets `isAppFirstRun = false`, and `onCTA` sets `isAppFirstRun = false` then opens Settings

#### Scenario: Reporting extension call site has no first-run side effects
- **WHEN** `AppHomeView` or `LanguageListView` presents `EnableExtensionView` for the Reporting Extension
- **THEN** the ViewModel is initialized with `isInteractiveDismissDisabled: false`, and the callbacks contain no first-run logic

### Requirement: EnableExtensionStepView accepts any step conforming to the protocol
`EnableExtensionStepView` SHALL accept a parameter of type `any EnableExtensionStepProtocol` instead of the concrete `EnableExtensionStep` type.

#### Scenario: Step view renders both step types identically
- **WHEN** `EnableExtensionStepView` is passed an `EnableReportingExtensionStep` value
- **THEN** it renders title, description, icon, and active state using the protocol properties

### Requirement: EnableReportingExtensionStep defines the reporting extension setup path
`EnableReportingExtensionStep` SHALL be a `CaseIterable`, `Hashable` enum conforming to `EnableExtensionStepProtocol` with exactly 4 cases representing the iOS Settings path to enable SMS/Call Reporting. Titles, descriptions, and icon style SHALL match the conventions of `EnableExtensionStep` (see existing `enableExtension_step*` strings for reference).

| Case | stepNumber | title key | description key | symbolName | symbolColor | isToggle | isLast | showsAppIcon |
|---|---|---|---|---|---|---|---|---|
| `settings` | 1 | `enableReportingExtension_step1_title` | `enableReportingExtension_step1_desc` | `gearshape.fill` | `.gray` | false | false | false |
| `phone` | 2 | `enableReportingExtension_step2_title` | `enableReportingExtension_step2_desc` | `phone.fill` | `.green` | false | false | false |
| `smsCallReporting` | 3 | `enableReportingExtension_step3_title` | `enableReportingExtension_step3_desc` | nil | nil | false | false | false |
| `simplyFilterSMS` | 4 | `enableReportingExtension_step4_title` | `enableReportingExtension_step4_desc` | nil | nil | false | true | true |

English strings:
- Step 1 title: `"Open iOS Settings"` / desc: `"Open iOS Settings, scroll down and tap 'Apps'."`
- Step 2 title: `"Tap on Phone"` / desc: `"Scroll down to find 'Phone' and tap on it."`
- Step 3 title: `"SMS/Call Reporting"` / desc: `"Scroll down and tap 'SMS/Call Reporting'."`
- Step 4 title: `"Choose 'Simply Filter SMS'"` / desc: `"Select 'Simply Filter SMS' to enable reporting."`

#### Scenario: Steps animate in sequence
- **WHEN** `EnableExtensionView` is presented with `EnableReportingExtensionStep.allCases` as steps
- **THEN** steps animate in `stepNumber` order with the existing cycle timing

### Requirement: Screen.enableReportingExtension routes to the reporting extension guide
A new `Screen.enableReportingExtension` case SHALL be added to the `Screen` enum. Its `build()` method SHALL return `EnableExtensionView` initialized with `EnableReportingExtensionStep.allCases` and appropriate callbacks (no first-run side effects, non-interactive dismiss disabled).

#### Scenario: Sheet presentation via Screen enum
- **WHEN** `sheetScreen = .enableReportingExtension` is set
- **THEN** `EnableExtensionView` is presented as a sheet showing the Reporting Extension steps

### Requirement: Deep link opens the reporting extension guide
The URL scheme `simplyfiltersms://enable-reporting-extension` SHALL open `Screen.enableReportingExtension` via the existing `handleDeepLink` mechanism in `AppHomeView`.

#### Scenario: Deep link while no sheet is open
- **WHEN** `AppHomeView` receives `simplyfiltersms://enable-reporting-extension` and no sheet is active
- **THEN** `sheetScreen` is set to `.enableReportingExtension` immediately

#### Scenario: Deep link while another sheet is open
- **WHEN** `AppHomeView` receives the deep link while a sheet is already presented
- **THEN** the current sheet is dismissed and `.enableReportingExtension` is presented after a short delay

### Requirement: LanguageListView (automaticBlocking) has a button to open the reporting extension guide
`LanguageListView` in `.automaticBlocking` mode SHALL provide the reporting extension entry point in two places:

1. **Bottom list button** — a button at the bottom of the list in its own trailing `Section`, matching the look and feel of `FilterListView`'s `AddFilterButton`: a full-width centered `HStack` with `Spacer + Icon + Text + Spacer`, plain button style, `.contentShape(Rectangle())`, and `.padding(.bottom, 40)`. The icon SHALL be `exclamationmark.bubble`.

2. **Top-right menu** — a `ToolbarItem(placement: .topBarTrailing)` containing a `Menu` with `Image(systemName: "ellipsis.circle")` as its label (same pattern as `AppHomeView`'s menu). The menu SHALL contain a single item for enabling the Reporting Extension, using the same localized string and `exclamationmark.bubble` icon as the bottom button.

Both entry points SHALL set `sheetScreen = .enableReportingExtension`. The ViewModel SHALL expose `@Published var sheetScreen: Screen?` to drive sheet presentation via `.sheet(item: $model.sheetScreen) { $0.build() }`.

#### Scenario: User taps the bottom list button
- **WHEN** the user taps the reporting extension button at the bottom of the AI Filtering list
- **THEN** `EnableExtensionView` is presented as a sheet with `EnableReportingExtensionStep.allCases`

#### Scenario: User taps the menu item
- **WHEN** the user opens the `...` menu and taps the reporting extension item
- **THEN** `EnableExtensionView` is presented as a sheet with `EnableReportingExtensionStep.allCases`

#### Scenario: Sheet is dismissed
- **WHEN** the user dismisses the sheet from `LanguageListView`
- **THEN** `sheetScreen` is set back to `nil` and no first-run side effects occur
