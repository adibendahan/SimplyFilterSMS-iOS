## 1. Persistence — `didTip` flag

- [x] 1.1 Add `var didTip: Bool { get set }` to `DefaultsManagerProtocol.swift`
- [x] 1.2 Add `@StoredDefault("didTip", defaultValue: false) var didTip: Bool` to `DefaultsManager.swift`
- [x] 1.3 Add `"didTip"` to the `keysToRemove` array in `DefaultsManager.reset()` (DEBUG block)

## 2. `TipJarManager` — dependency injection + set flag on successful purchase

- [x] 2.1 Add `init(defaultsManager: DefaultsManagerProtocol = AppManager.shared.defaultsManager)` to `TipJarManager` — store as `private var defaultsManager`
- [x] 2.2 Update `AppManager` to pass `defaultsManager` explicitly: `TipJarManager(defaultsManager: defaultsManager)`
- [x] 2.3 In `TipJarManager.purchase(_:)`, after `await transaction.finish()` on a verified transaction, set `self.defaultsManager.didTip = true`

## 3. `NotificationView` — `.tipPromotion` case + `onTap` support

- [x] 3.1 Add `.tipPromotion` to the `NotificationView.Notification` enum case list
- [x] 3.2 Add `.tipPromotion` to `icon` — return `"heart.fill"`
- [x] 3.3 Add `.tipPromotion` to `iconColor` — return `.pink.opacity(0.8)` (matching `tipSuccessful`)
- [x] 3.4 Add `.tipPromotion` to `title` — return `"notification_tipPromotion_title"~`
- [x] 3.5 Add `.tipPromotion` to `subtitle` — return `"notification_tipPromotion_subtitle"~`
- [x] 3.6 Add `.tipPromotion` to `timeout` — return `10`
- [x] 3.7 Add `var onTap: (() -> Void)?` to `NotificationView.ViewModel` — called when the user taps the notification body (not the button)
- [x] 3.8 Update `onTapGesture` to call `onTap?()` if set, otherwise fall back to `onButtonTap?()` (existing hide behavior)

## 4. `AppHomeView` — `tryShowTipPromotion()`

- [x] 4.1 Add `tryShowTipPromotion()` method to `AppHomeView.ViewModel`:
  - Guard: `sessionCounter % 5 == 0 && sessionCounter > 0 && !defaultsManager.didTip`
  - Guard: `!notification.show && sheetScreen == nil && modalFullScreen == nil`
  - Call `notification.setNotification(.tipPromotion)`
  - Set `notification.onTap = { withAnimation { show = false }; sheetScreen = .tipJar }` — tapping the body opens TipJarView
  - Button shows "Hide" and dismisses only (default behavior, no `setOnButtonTap` override needed)
  - Schedule `notification.show = true` after 1-second delay via `DispatchQueue.main.asyncAfter`
- [x] 4.2 Call `tryShowTipPromotion()` at the end of `startMonitoring()`

## 5. Localization

- [x] 5.1 Add to English `Localizable.strings`:
  - `"notification_tipPromotion_title"` = `"Enjoying the app?"`
  - `"notification_tipPromotion_subtitle"` = `"Tap to leave a tip"`
- [x] 5.2 Add to Hebrew `Localizable.strings`:
  - `"notification_tipPromotion_title"` = `"נהנים מהאפליקציה?"`
  - `"notification_tipPromotion_subtitle"` = `"לחצו להשארת טיפ"`

## 6. Verification

- [x] 6.1 Build project — `BUILD SUCCEEDED`, zero compiler errors
- [ ] 6.2 Run on simulator: set `sessionCounter` to 4 via debug reset, relaunch — confirm notification appears on 5th session
- [ ] 6.3 Confirm notification does NOT appear when `didTip = true`
- [ ] 6.4 Confirm tapping notification body opens `TipJarView` as a sheet
- [ ] 6.5 Confirm "Hide" button dismisses without opening TipJarView
- [ ] 6.6 Confirm notification auto-dismisses after ~10 seconds
