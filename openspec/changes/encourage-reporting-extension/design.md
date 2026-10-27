## Context

The app already has a `NotificationView` toast system (used for offline status, cloud sync, tip promotion) and a step-by-step extension-enable screen (`EnableExtensionView`) for onboarding. The goal is to reuse both patterns: generalize `EnableExtensionView` to support both the Message Filter Extension and the Reporting Extension, and surface a recurring nudge encouraging users to enable the Reporting Extension.

iOS provides no API to query whether an `ILClassificationUIExtensionViewController` extension is enabled, so dismissal state must be owned by the app.

The existing `AppHomeView.ViewModel` already manages the single `NotificationView.ViewModel` instance, has an `onTap` hook per notification, and opens sheets via `sheetScreen`.

## Goals / Non-Goals

**Goals:**
- Show a `NotificationView` nudge every third session (when AI Filtering is on) that auto-hides after 10 seconds; recurs until the user actively taps it
- Generalize `EnableExtensionView` via `EnableExtensionStepProtocol` so it serves both onboarding and the Reporting Extension guide without duplication
- Record permanent dismissal via `DefaultsManager.didDismissReportingExtensionNudge` when the user taps the nudge
- Add `simplyfiltersms://enable-reporting-extension` deep link
- Add a button at the bottom of the AI Filtering screen (`LanguageListView` in `.automaticBlocking` mode) that opens `EnableExtensionView` configured for the Reporting Extension

**Non-Goals:**
- Detecting whether the Reporting Extension is actually enabled
- Re-showing the nudge after the user has actively dismissed it

## Decisions

### 1. Dismissal flag set on tap, not on sheet close
`didDismissReportingExtensionNudge` is set to `true` inside the `onTap` closure when the user taps the notification — before the sheet opens.

**Why:** Tapping the nudge is the active dismissal event. The user has engaged with the prompt; we don't need them to complete the Settings flow for the nudge to stop recurring. Setting the flag on sheet close instead would require tracking which sheet was dismissed, adding complexity for no behavioral gain.

### 2. Dismissal tracked in `onTap` closure, not in `sheetScreen.didSet`
The `onTap` closure in `tryShowReportingExtensionNudge()` sets `didDismissReportingExtensionNudge = true` and then sets `sheetScreen = .enableReportingExtension`.

**Why:** Clean, direct, and co-located with the action. No need to inspect `oldValue` in `sheetScreen.didSet` or add a separate tracking variable.

### 3. Nudge shown via `startMonitoring()`, gated on AI Filtering + session cadence
Add `tryShowReportingExtensionNudge()` called from `startMonitoring()` after all other notification logic, guarded by: `!isAppFirstRun`, `!didDismissReportingExtensionNudge`, `isAutomaticFilteringOn`, `sessionCounter > 0 && sessionCounter % 3 == 0`, and `!didShowNotificationThisSession`. `didShowNotificationThisSession` is a private session-only `Bool` on `AppHomeView.ViewModel` (not persisted) that is set to `true` whenever `showNotification(_:)` is called. This ensures the reporting nudge is never shown in any session where another notification has already appeared — even if that notification has since auto-hidden.

**Why:** `!notification.show` only catches currently-visible notifications. A tip promotion or offline alert that already appeared and dismissed would pass that guard. A session flag is the correct scope — it resets on next launch and accurately represents "something already competed for the user's attention this session."

### 4. `EnableExtensionView` is generalized via `EnableExtensionStepProtocol`
Extract a protocol defining all step rendering properties. Both `EnableExtensionStep` and the new `EnableReportingExtensionStep` conform to it. `EnableExtensionStepView` accepts `any EnableExtensionStepProtocol`. `EnableExtensionView.ViewModel` stores the steps array and accepts `onDismiss`/`onCTA` callbacks; `interactiveDismissDisabled` becomes a ViewModel property. First-run logic (`isAppFirstRun`) moves entirely to the `AppHomeView` call site.

**Why:** Eliminates duplication of the animation loop and step-rendering pattern. `EnableExtensionView` stays the single source of truth for the extension-enable UX. The refactor is contained to the three existing files (`EnableExtensionView`, `EnableExtensionStep`, `EnableExtensionStepView`) plus the new `EnableReportingExtensionStep`.

**SwiftUI generics note:** `EnableExtensionView` stays non-generic (avoids SwiftUI generic struct complications). The ViewModel stores steps as `[any EnableExtensionStepProtocol]` and `ForEach` iterates with `.indices` to avoid `Identifiable` constraints on the protocol.

### 5. `NotificationView.Notification.enableReportingExtension` uses a custom button title
Override `buttonTitle` to return a localized "Enable" label (distinct from the default "Hide") so the action is clear.

**Why:** "Hide" signals dismissal; "Enable" signals forward progress. The `NotificationView` already supports arbitrary `buttonTitle` per case.

### 6. AI Filtering screen exposes the reporting extension guide via two entry points
`LanguageListView` currently has no sheet presentation. Add `@Published var sheetScreen: Screen? = nil` to its ViewModel and a `.sheet(item: $model.sheetScreen) { $0.build() }` modifier in the view. Both entry points set `sheetScreen = .enableReportingExtension`:

- **Bottom list button** — matches `FilterListView.AddFilterButton`: full-width centered `HStack`, plain button style, `.contentShape(Rectangle())`, `.padding(.bottom, 40)`, icon `exclamationmark.bubble`.
- **Top-right `...` menu** — a `ToolbarItem(placement: .topBarTrailing)` with a `Menu { ... } label: { Image(systemName: "ellipsis.circle") }`, same pattern as `AppHomeView`. Contains a single item with the same label and icon as the bottom button.

**Why:** The bottom button is discoverable for users scrolling the list; the menu button follows the app-wide convention for screen-level actions and is always visible without scrolling.

## Risks / Trade-offs

- **Nudge recurs every third session until tapped** — If the user repeatedly ignores the nudge, it reappears. Mitigation: auto-hides after 10 seconds so it doesn't block the UI; once tapped it never returns.
- **No confirmation of extension enablement** — The nudge stops once the user taps, even if they don't complete the Settings flow. Acceptable: the user was informed; we can't do better without OS API support.
- **Single notification slot** — `AppHomeView` uses one shared `NotificationView.ViewModel`. The reporting nudge is the lowest-priority notification and will be suppressed whenever any other notification is active. This is by design — no mitigation needed.
