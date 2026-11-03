# App-wide notifications

One notification slot and one toast for the whole app, instead of a toast per screen.

## Where it stands

- `be1eda2` (on `feature/automatic-filter-records`) ranks Home's notifications by `NotificationView.Notification.priority` (0 is most urgent) in one slot, no queue.
- This branch's first commit moves that slot into `FlowManager` (`requestNotification` / `nextNotification` / `completeNotification` / `cancelNotification`), following the `request` / `next` / `complete` shape it uses for sheets. The six existing methods are unchanged; `resetSession()` also clears the slot. Not device-tested.

## Today

- Home, Help, About and Tip Jar each own a `NotificationView.ViewModel` and attach `EmbeddedNotificationView`.
- A toast lives in its screen's view, so a sheet covers Home's toast. Home holds a notification in the pending slot until it's unobstructed.
- Help and About both observe the app-wide `.onClipboardSet`, so a copy on one shows on both if both are alive, and they duplicate `showNotification`.

## The idea

A transparent overlay `UIWindow` above the app's window in the same window scene, hosting one SwiftUI toast. It passes touches through except on the toast (`hitTest`). Every screen sends its notification to the `FlowManager` slot; the window shows the winner.

## Decide first

- **Toasts over sheets, or behind them?** Over sheets removes Home's obstruction check for toasts; "iCloud synced" could then appear over first run or What's New. Some notifications may still need to wait.
- Whether the slot API stays as in this branch's first commit once Help, About and Tip Jar use it.

## Check

- iPad multiple scenes: one overlay window per scene.
- VoiceOver announcements, safe areas, keyboard.
- Tip Jar dismisses its sheet in `onHide`; the thank-you toast would outlive the sheet.
- Device testing: window behavior isn't covered by unit tests.
