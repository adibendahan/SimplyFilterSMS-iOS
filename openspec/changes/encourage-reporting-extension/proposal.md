## Why

Users are unaware of the Reporting Extension, missing an opportunity to contribute spam signals that improve AI automatic filtering for everyone. Since iOS provides no API to detect whether the extension is enabled, a `NotificationView` nudge (shown every third session when AI Filtering is on, auto-hiding after 10 seconds) guides users to the existing `EnableExtensionView` configured for the Reporting Extension path.

## What Changes

- New `EnableExtensionStepProtocol` — extracted protocol defining all step rendering properties (`stepNumber`, `title`, `description`, `symbolName`, `symbolColor`, `showsAppIcon`, `isToggle`, `isLast`)
- `EnableExtensionView` generalized — ViewModel accepts any steps array + `onDismiss`/`onCTA` callbacks; `interactiveDismissDisabled` becomes conditional; first-run logic moved to call sites
- `EnableExtensionStep` updated to conform to `EnableExtensionStepProtocol`
- `EnableExtensionStepView` updated to accept `any EnableExtensionStepProtocol`
- New `EnableReportingExtensionStep` enum — steps for Settings → Messages → Unknown & Spam → app path; conforms to `EnableExtensionStepProtocol`
- New `Screen.enableReportingExtension` case + `enable-reporting-extension` deep link
- New `NotificationView.Notification.enableReportingExtension` case — custom icon, title, subtitle, and button label ("Enable"), auto-hides after 10 seconds
- New `didDismissReportingExtensionNudge: Bool` in `DefaultsManager` — tracks permanent dismissal (replaces inability to detect extension state)
- `AppHomeView` updated to show the nudge every third session when AI Filtering is on and the user hasn't actively dismissed it; tapping the nudge opens the reporting extension screen and permanently sets the dismissal flag
- `LanguageListView` (`.automaticBlocking` mode) updated with a button at the bottom that opens the reporting extension screen as a sheet

## Capabilities

### New Capabilities
- `enable-reporting-extension-flow`: `EnableExtensionStepProtocol`, generalized `EnableExtensionView`, new `EnableReportingExtensionStep` enum, `Screen.enableReportingExtension` case, and `enable-reporting-extension` deep link
- `reporting-extension-nudge`: The `NotificationView.Notification.enableReportingExtension` case, `DefaultsManager.didDismissReportingExtensionNudge` flag, and `AppHomeView` + `LanguageListView` integration

### Modified Capabilities

## Impact

- **New files:** `EnableReportingExtensionStep.swift`
- **Modified files:** `EnableExtensionView.swift`, `EnableExtensionStep.swift`, `EnableExtensionStepView.swift`, `Screen.swift`, `NotificationView.swift`, `DefaultsManagerProtocol.swift`, `DefaultsManager.swift`, `AppHomeView.swift`, `LanguageListView.swift`, `mock_DefaultsManager.swift`
- **Localization:** New strings required for the new screen, nudge notification, and steps
