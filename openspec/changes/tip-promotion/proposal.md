## Why

The tip jar exists but most users never discover it — it's buried in the toolbar menu and About screen. Adding a periodic, non-intrusive in-app notification on every 5th session surfaces the tip jar to users who are clearly engaged with the app (they've opened it many times) without spamming first-time or occasional users. The nudge is skipped permanently once the user has already tipped.

## What Changes

- Add `didTip: Bool` stored default to `DefaultsManager` and `DefaultsManagerProtocol` — persisted flag set to `true` after any successful tip purchase
- Set `didTip = true` in `TipJarManager` upon successful purchase (alongside existing confetti + toast logic)
- Add `.tipPromotion` case to `NotificationView.Notification` — icon, title, subtitle, button label, and no auto-timeout (user must dismiss)
- Add `tryShowTipPromotion()` to `AppHomeView.ViewModel` — called on `onAppear`, shows the `.tipPromotion` notification when `sessionCounter % 5 == 0 && sessionCounter > 0 && !defaultsManager.didTip`
- The notification's button tap dismisses the notification and opens `TipJarView` as a sheet via `sheetScreen = .tipJar`
- Add localization keys for the new notification strings (English + Hebrew)

## Capabilities

### New Capabilities
- `tip-promotion`: Periodic session-based nudge that surfaces the tip jar to engaged users who have not yet tipped

### Modified Capabilities
- `tip-jar`: Extended to set `didTip = true` on successful purchase so the promotion is suppressed thereafter

## Impact

- **Modified files:**
  - `DefaultsManager.swift` — new `didTip` stored default
  - `DefaultsManagerProtocol.swift` — new `didTip` property
  - `TipJarManager.swift` — set `didTip = true` on successful purchase
  - `TipJarManagerProtocol.swift` — expose `didTip` if needed for testability
  - `NotificationView.swift` — new `.tipPromotion` notification case
  - `AppHomeView.swift` — `tryShowTipPromotion()` in ViewModel
  - `Localizable.strings` (en + he) — new notification string keys
- **No new files** — builds entirely on existing notification and navigation infrastructure
- **No new dependencies** — uses `sessionCounter` (already tracked), `EmbeddedNotificationView` (already in AppHomeView), and `Screen.tipJar` (already exists)
