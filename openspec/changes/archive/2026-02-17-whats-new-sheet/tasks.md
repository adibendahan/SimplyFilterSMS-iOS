## 1. Data Model & Constants

- [x] 1.1 Add `WhatsNewEntry` struct to `Constsants.swift` with `symbolName`, `symbolColor`, `titleKey`, `descriptionKey` properties
- [x] 1.2 Add `whatsNewSequence` integer constant (set to `1`) and `whatsNewEntries` array with initial entries to `Constsants.swift`

## 2. Framework Layer — DefaultsManager

- [x] 2.1 Add `lastSeenWhatsNewSequence: Int` property to `DefaultsManagerProtocol` (get/set, default `0`)
- [x] 2.2 Add `@StoredDefault("lastSeenWhatsNewSequence", defaultValue: 0)` to `DefaultsManager`
- [x] 2.3 Update `mock_DefaultsManager` with `lastSeenWhatsNewSequence` property, counter, and closure
- [x] 2.4 Add `"lastSeenWhatsNewSequence"` to the `reset()` method's `keysToRemove` in `DefaultsManager`

## 3. Screen Routing

- [x] 3.1 Add `.whatsNew` case to `Screen` enum
- [x] 3.2 Add `WhatsNewView(model: WhatsNewView.ViewModel())` to `Screen.build()`
- [x] 3.3 Add `"whatsNew"` to `Screen.tag` computed property

## 4. WhatsNewView + ViewModel

- [x] 4.1 Create `WhatsNewView.swift` in `View Layer/Screens/` with `NavigationView`, `ScrollView`, large bold centered title, feature rows (icon + title + description), and toolbar X button
- [x] 4.2 Render each entry's description via `AttributedString(markdown:)` with plain text fallback (matching `AboutView` pattern)
- [x] 4.3 Add pinned "Continue" button at bottom using `FilledButton` style, outside the scroll area
- [x] 4.4 Create nested `WhatsNewView.ViewModel` subclassing `BaseViewModel`, conforming to `ObservableObject`, with `let entries: [WhatsNewEntry]` populated from `whatsNewEntries` and `markAsSeen()` method
- [x] 4.5 Wire all three dismissal paths (Continue button, X button, swipe-to-dismiss via `.onDisappear` or sheet dismiss callback) to call `markAsSeen()`
- [x] 4.6 Add SwiftUI preview using `AppManager.previews`

## 5. AppHomeView Integration

- [x] 5.1 Add What's New check in `.onReceive($navigationScreen)` block as `else` after the `isAppFirstRun` check: `!isAppFirstRun && !whatsNewEntries.isEmpty && whatsNewSequence > lastSeenWhatsNewSequence` → `sheetScreen = .whatsNew`
- [x] 5.2 Add "What's New" menu item to `NavigationBarTrailingItem()` menu, conditionally visible when `!whatsNewEntries.isEmpty`, setting `sheetScreen = .whatsNew`

## 6. Localization

- [x] 6.1 Add English `.strings` keys: sheet title, Continue button label, and all entry `titleKey`/`descriptionKey` values
- [x] 6.2 Add Hebrew `.strings` keys for all the same entries

## 7. Xcode Project

- [x] 7.1 Add `WhatsNewView.swift` to the Xcode project's `Simply Filter SMS` target (ensure it's in the correct file group under `View Layer/Screens/`)

## 8. Testing

- [x] 8.1 Build and verify no compilation errors
- [x] 8.2 Run existing unit tests to confirm no regressions
