## Context

`sessionCounter` is already incremented in `AppManager.onNewUserSession()` on every app open and persisted via `@StoredDefault`. The existing `NotificationView` / `EmbeddedNotificationView` system in `AppHomeView` supports custom button tap handlers via `notification.setOnButtonTap(_:)`. However, `AppHomeView.ViewModel.showNotification(_:)` currently hardcodes the button tap to set `lastOfflineNotificationDismiss` — this is offline-specific logic that cannot be reused for tip promotion. All changes are confined to the View and Framework layers.

## Goals / Non-Goals

**Goals:**
- Show a tip promotion notification on sessions 5, 10, 15, … (`sessionCounter % 5 == 0`)
- Never show the prompt to a user who has already tipped
- Never show the prompt when another notification is already visible or a sheet/modal is open
- Tapping the notification button opens TipJarView as a sheet
- Zero changes to the visual appearance of AppHomeView at default conditions

**Non-Goals:**
- Frequency capping beyond the every-5th-session rule (no cooldown period, no max show count)
- A/B testing or analytics for the promotion
- Showing the prompt in any screen other than AppHomeView

## Decisions

### 1. `didTip` flag lives in `DefaultsManager`, set by `TipJarManager`

**Decision:** Add `didTip: Bool` as a `@StoredDefault` in `DefaultsManager` (key `"didTip"`, default `false`). Set it to `true` inside `TipJarManager.purchase(_:)` immediately after a verified transaction finishes. Expose it on `DefaultsManagerProtocol` and `TipJarManagerProtocol` is not required — the ViewModel reads it directly from `appManager.defaultsManager.didTip`.

**Rationale:** `DefaultsManager` already owns all persistence flags (`didPromptForReview`, `lastSeenWhatsNewVersion`, etc.). `TipJarManager` is the authoritative source for purchase outcomes and is the correct place to set the flag. The ViewModel only needs to read it, so no protocol change is needed on `TipJarManagerProtocol`.

**Alternative considered:** Storing `didTip` on `TipJarManager` in memory — rejected because it wouldn't survive app restarts, defeating the purpose.

### 2. Bypass `showNotification(_:)` with a dedicated `showTipPromotion()` method

**Decision:** Add a new `showTipPromotion()` method to `AppHomeView.ViewModel` that sets up the notification and button handler directly on `self.notification`, without going through `showNotification(_:)`. This method:
1. Checks `sessionCounter % 5 == 0 && sessionCounter > 0 && !appManager.defaultsManager.didTip`
2. Guards that `!notification.show && sheetScreen == nil && modalFullScreen == nil`
3. Calls `notification.setNotification(.tipPromotion)`
4. Calls `notification.setOnButtonTap { self.sheetScreen = .tipJar }`
5. Schedules `notification.show = true` after a 1-second delay (matching `showNotification` behavior)

**Rationale:** `showNotification(_:)` hardcodes an offline-specific button tap handler (`lastOfflineNotificationDismiss`). Modifying it to handle multiple cases would add complexity and branching. A dedicated method is self-contained, easier to test, and makes the intent explicit. The `pendingNotification` queue in `showNotification` is not needed here — if a sheet is open, the tip promotion is simply skipped for this session (it will appear again in 5 more sessions).

**Alternative considered:** Modifying `showNotification(_:)` to accept an optional `onButtonTap` closure — rejected because it would require touching the offline notification call sites and adds unnecessary generality to a method that works fine as-is.

### 3. `tryShowTipPromotion()` called from `startMonitoring()`

**Decision:** Call `tryShowTipPromotion()` at the end of `startMonitoring()`, which is already invoked from `.onAppear` on AppHomeView. This ensures it runs once per view appearance, after all other monitoring setup (offline check, CloudKit observers) is complete.

**Rationale:** `startMonitoring()` is the established hook for session-start side effects. Calling `tryShowTipPromotion()` last ensures the offline notification (if any) takes priority — `showTipPromotion()` guards on `!notification.show`, so if the offline prompt already fired, the tip promotion is silently skipped.

**Alternative considered:** Calling from `ViewModel.init` via `Task {}` — rejected because it could fire before the view is mounted and the `EmbeddedNotificationView` is ready.

### 4. `.tipPromotion` notification auto-dismisses after 10 seconds

**Decision:** The `.tipPromotion` case returns `10` from `NotificationView.Notification.timeout`, matching the auto-hide behavior of `cloudSyncOperationComplete` and `automaticFiltersUpdated` (which use 6 seconds).

**Rationale:** 10 seconds is enough time for the user to read and act on the prompt without requiring deliberate dismissal. A non-dismissing tip promotion would feel more intrusive than system notifications.

### 5. `.tipPromotion` notification content

**Decision:**
- Icon: `"heart.fill"`, color: `.pink` (consistent with `tipSuccessful` case — same visual language)
- Title: localized `"notification_tipPromotion_title"`
- Subtitle: localized `"notification_tipPromotion_subtitle"`
- Button title: localized `"notification_tipPromotion_button"`

English strings: "Enjoying the app?" / "Consider leaving a tip to support development." / "Tip Jar"
Hebrew strings: "נהנים מהאפליקציה?" / "שקלו להשאיר טיפ כדי לתמוך בפיתוח." / "צנצנת טיפים"

## Risks / Trade-offs

- **Notification conflict:** If the offline notification is showing when the user opens the app on a 5th session, the tip promotion is silently skipped. This is acceptable — offline is more critical, and the user will see the tip prompt again in 5 more sessions.
- **No cap:** A user who never tips will see the prompt indefinitely every 5 sessions. This is intentional — the app is free and the prompt is the only monetization mechanism. If it becomes too aggressive, a max show count can be added later via a separate `tipPromotionShowCount` default.
