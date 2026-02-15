## 1. Data Model & Constants

- [ ] 1.1 Add `WhatsNewEntry` struct to `Constsants.swift` with `symbolName`, `symbolColor`, `titleKey`, `descriptionKey` properties
- [ ] 1.2 Add `whatsNewSequence` integer constant (set to `1`) and `whatsNewEntries` array with initial entries to `Constsants.swift`

## 2. Framework Layer — DefaultsManager

- [ ] 2.1 Add `lastSeenWhatsNewSequence: Int` property to `DefaultsManagerProtocol` (get/set, default `0`)
- [ ] 2.2 Add `@StoredDefault("lastSeenWhatsNewSequence", defaultValue: 0)` to `DefaultsManager`
- [ ] 2.3 Update `mock_DefaultsManager` with `lastSeenWhatsNewSequence` property, counter, and closure
- [ ] 2.4 Add `"lastSeenWhatsNewSequence"` to the `reset()` method's `keysToRemove` in `DefaultsManager`

## 3. Screen Routing

- [ ] 3.1 Add `.whatsNew` case to `Screen` enum
- [ ] 3.2 Add `WhatsNewView(model: WhatsNewView.ViewModel())` to `Screen.build()`
- [ ] 3.3 Add `"whatsNew"` to `Screen.tag` computed property

## 4. WhatsNewView + ViewModel

- [ ] 4.1 Create `WhatsNewView.swift` in `View Layer/Screens/` with `NavigationView`, `ScrollView`, large bold centered title, feature rows (icon + title + description), and toolbar X button
- [ ] 4.2 Render each entry's description via `AttributedString(markdown:)` with plain text fallback (matching `AboutView` pattern)
- [ ] 4.3 Add pinned "Continue" button at bottom using `FilledButton` style, outside the scroll area
- [ ] 4.4 Create nested `WhatsNewView.ViewModel` subclassing `BaseViewModel`, conforming to `ObservableObject`, with `let entries: [WhatsNewEntry]` populated from `whatsNewEntries` and `markAsSeen()` method
- [ ] 4.5 Wire all three dismissal paths (Continue button, X button, swipe-to-dismiss via `.onDisappear` or sheet dismiss callback) to call `markAsSeen()`
- [ ] 4.6 Add SwiftUI preview using `AppManager.previews`

## 5. AppHomeView Integration

- [ ] 5.1 Add What's New check in `.onReceive($navigationScreen)` block as `else` after the `isAppFirstRun` check: `!isAppFirstRun && !whatsNewEntries.isEmpty && whatsNewSequence > lastSeenWhatsNewSequence` → `sheetScreen = .whatsNew`
- [ ] 5.2 Add "What's New" menu item to `NavigationBarTrailingItem()` menu, conditionally visible when `!whatsNewEntries.isEmpty`, setting `sheetScreen = .whatsNew`

## 6. Localization

- [ ] 6.1 Add English `.strings` keys: sheet title, Continue button label, and all entry `titleKey`/`descriptionKey` values
- [ ] 6.2 Add Hebrew `.strings` keys for all the same entries

## 7. Xcode Project

- [ ] 7.1 Add `WhatsNewView.swift` to the Xcode project's `Simply Filter SMS` target (ensure it's in the correct file group under `View Layer/Screens/`)

## 8. Testing

- [ ] 8.1 Build and verify no compilation errors
- [ ] 8.2 Run existing unit tests to confirm no regressions
