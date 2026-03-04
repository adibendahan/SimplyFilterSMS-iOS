## 1. Persistence — `didTip` flag

- [ ] 1.1 Add `var didTip: Bool { get set }` to `DefaultsManagerProtocol.swift`
- [ ] 1.2 Add `@StoredDefault("didTip", defaultValue: false) var didTip: Bool` to `DefaultsManager.swift`
- [ ] 1.3 Add `"didTip"` to the `keysToRemove` array in `DefaultsManager.reset()` (DEBUG block)

## 2. `TipJarManager` — set flag on successful purchase

- [ ] 2.1 In `TipJarManager.purchase(_:)`, after `await transaction.finish()` on a verified transaction, call `AppManager.shared.defaultsManager.didTip = true`

## 3. `NotificationView` — `.tipPromotion` case

- [ ] 3.1 Add `.tipPromotion` to the `NotificationView.Notification` enum case list
- [ ] 3.2 Add `.tipPromotion` to `icon` — return `"heart.fill"`
- [ ] 3.3 Add `.tipPromotion` to `iconColor` — return `.pink.opacity(0.8)` (matching `tipSuccessful`)
- [ ] 3.4 Add `.tipPromotion` to `title` — return `"notification_tipPromotion_title"~`
- [ ] 3.5 Add `.tipPromotion` to `subtitle` — return `"notification_tipPromotion_subtitle"~`
- [ ] 3.6 Add `.tipPromotion` to `timeout` — return `10`

## 4. `AppHomeView` — `tryShowTipPromotion()`

- [ ] 4.1 Add `tryShowTipPromotion()` method to `AppHomeView.ViewModel`:
  - Guard: `appManager.defaultsManager.sessionCounter % 5 == 0 && appManager.defaultsManager.sessionCounter > 0 && !appManager.defaultsManager.didTip`
  - Guard: `!notification.show && sheetScreen == nil && modalFullScreen == nil`
  - Call `notification.setNotification(.tipPromotion)`
  - Call `notification.setOnButtonTap { self.sheetScreen = .tipJar }`
  - Schedule `notification.show = true` after 1-second delay via `DispatchQueue.main.asyncAfter`
- [ ] 4.2 Call `tryShowTipPromotion()` at the end of `startMonitoring()`

## 5. Localization

- [ ] 5.1 Add to English `Localizable.strings`:
  - `"notification_tipPromotion_title"` = `"Enjoying the app?"`
  - `"notification_tipPromotion_subtitle"` = `"Consider leaving a tip to support development."`
- [ ] 5.2 Add to Hebrew `Localizable.strings`:
  - `"notification_tipPromotion_title"` = `"נהנים מהאפליקציה?"`
  - `"notification_tipPromotion_subtitle"` = `"שקלו להשאיר טיפ כדי לתמוך בפיתוח."`

## 6. Verification

- [ ] 6.1 Build project — verify zero compiler errors
- [ ] 6.2 Run on simulator: set `sessionCounter` to 4 via debug reset, relaunch — confirm notification appears on 5th session
- [ ] 6.3 Confirm notification does NOT appear when `didTip = true`
- [ ] 6.4 Confirm tapping "Tip Jar" button opens `TipJarView` as a sheet
- [ ] 6.5 Confirm notification auto-dismisses after ~10 seconds
