## 1. Protocol & Step Generalization

- [x] 1.1 Define `EnableExtensionStepProtocol` in a new file with all required computed properties: `stepNumber`, `title`, `description`, `symbolName`, `symbolColor`, `showsAppIcon`, `isToggle`, `isLast`
- [x] 1.2 Update `EnableExtensionStep` to declare conformance to `EnableExtensionStepProtocol` (no logic changes)
- [x] 1.3 Update `EnableExtensionStepView` to accept `any EnableExtensionStepProtocol` instead of the concrete `EnableExtensionStep` type
- [x] 1.4 Update `EnableExtensionView.ViewModel` to store `steps: [any EnableExtensionStepProtocol]`, replace `isAppFirstRun` with `isInteractiveDismissDisabled: Bool`, `onDismiss: () -> Void`, and `onCTA: () -> Void`
- [x] 1.5 Update `EnableExtensionView` body to iterate steps via `.indices`, apply `interactiveDismissDisabled` conditionally from the ViewModel
- [x] 1.6 Update the onboarding call site in `AppHomeView` (and `Screen.onboarding` / `Screen.enableExtension` build methods) to pass `EnableExtensionStep.allCases`, `isInteractiveDismissDisabled: true`, and callbacks that set `isAppFirstRun = false` and open Settings

## 2. EnableReportingExtensionStep

- [x] 2.1 Create `EnableReportingExtensionStep.swift` with 4 cases: `settings`, `phone`, `smsCallReporting`, `simplyFilterSMS` conforming to `EnableExtensionStepProtocol`
- [x] 2.2 Add localization strings for all 4 steps (title + description) via `/add-localized-text` skill

## 3. Screen & Deep Link

- [x] 3.1 Add `Screen.enableReportingExtension` case to `Screen.swift` with `build()` returning `EnableExtensionView` initialized with `EnableReportingExtensionStep.allCases`, `isInteractiveDismissDisabled: false`, and no-op first-run callbacks
- [x] 3.2 Add `"enable-reporting-extension"` case to `Screen.fromDeepLink` mapping to `.enableReportingExtension`

## 4. DefaultsManager

- [x] 4.1 Add `didDismissReportingExtensionNudge: Bool` to `DefaultsManagerProtocol`
- [x] 4.2 Add `@StoredDefault("didDismissReportingExtensionNudge", defaultValue: false)` to `DefaultsManager`
- [x] 4.3 Add `didDismissReportingExtensionNudge` to the mock in `mock_DefaultsManager.swift`

## 5. NotificationView

- [x] 5.1 Add `.enableReportingExtension` case to `NotificationView.Notification` with `timeout: 10`, icon, icon color, and custom button title
- [x] 5.2 Add localization strings for title ("Report Spam"), subtitle ("Help improve AI filtering"), and button ("Enable") via `/add-localized-text` skill — enforce max English length + 5 chars per translation

## 6. AppHomeView Nudge

- [x] 6.1 Add `private var didShowNotificationThisSession = false` to `AppHomeView.ViewModel` and set it to `true` inside `showNotification(_:)`
- [x] 6.2 Implement `tryShowReportingExtensionNudge()` in `AppHomeView.ViewModel` gated on: `!isAppFirstRun`, `!didDismissReportingExtensionNudge`, `isAutomaticFilteringOn`, `sessionCounter > 0 && sessionCounter % 3 == 0`, `!didShowNotificationThisSession`
- [x] 6.3 Set `notification.onTap` in `tryShowReportingExtensionNudge()` to: set `didDismissReportingExtensionNudge = true`, hide notification, set `sheetScreen = .enableReportingExtension`
- [x] 6.4 Call `tryShowReportingExtensionNudge()` at the end of `startMonitoring()`, after `tryShowTipPromotion()`

## 7. LanguageListView Entry Points

- [x] 7.1 Add `@Published var sheetScreen: Screen? = nil` to `LanguageListView.ViewModel`
- [x] 7.2 Add `.sheet(item: $model.sheetScreen) { $0.build() }` to `LanguageListView` body
- [x] 7.3 Add bottom list button in its own trailing `Section` (`.automaticBlocking` mode only): full-width centered `HStack`, `exclamationmark.bubble` icon, localized label, plain style, `.contentShape(Rectangle())`, `.padding(.bottom, 40)`
- [x] 7.4 Add `ToolbarItem(placement: .topBarTrailing)` with `Menu { ... } label: { Image(systemName: "ellipsis.circle") }` (`.automaticBlocking` mode only) containing a single item using the same label and icon
- [x] 7.5 Add localization string for the button/menu item label via `/add-localized-text` skill
