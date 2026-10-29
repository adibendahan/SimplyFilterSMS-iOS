# Screens

One sentence per screen on what it's for and how it's reached, plus the traps that aren't obvious from the code. MVVM conventions are in `CLAUDE.md`.

---

## AppHomeView
The main screen: AI Filtering, the smart rules, and the three user filter lists; everything else opens from its `•••` menu.
- `refresh()` reloads everything from the managers, and runs on every pop, sheet dismiss and relevant notification.
- `startMonitoring()` compares the store fingerprint with the UI once on its own, in case a CloudKit import finished before the observers were registered.
- Notifications that arrive while a sheet is up wait in `pendingNotification`.
- The What's New sheet is marked seen on any user dismiss, swipe included, but not when a file or deep link replaces it (`isReplacingSheetForLaunch`).

## EnableExtensionView
A generic step-by-step setup sheet, built with different steps for first-run onboarding, enabling the message filter, and enabling the Reporting Extension (`EnableReportingExtensionStep`).
- The steps animate in a loop; with VoiceOver on, all steps show at once and the loop doesn't run.
- `EnableExtensionStepView` uses `.task(id: isActive)` for its toggle, so a fast loop can't race an earlier activation.

## HelpView
FAQ, setup shortcuts and contact, as a sheet from the menu.
- It's a `List` with one `DisclosureGroup` open at a time. A custom accordion in a `ScrollView` made the scroll position jump when a question opened.
- The "Get Started" rows ask Home (`onRequestScreen`) to present the setup sheet after Help dismisses.

## AboutView
App info, links and credits, as a sheet from the menu.
- Email opens the Mail composer, or copies the address with a toast when Mail isn't set up (always on the simulator). Help does the same.
- A screen that shows toasts owns its own `EmbeddedNotificationView`; About's is separate from Home's.

## ChooseAccentColorView
The app tint picker, as a sheet from the Home menu only.
- Home builds it in the sheet content with `onAccentChanged`, so Home's tint changes live while the sheet is up. `Screen.chooseAccentColor.build()` has no callback.
- Home's `refresh()` doesn't reload the tint while this sheet is up, or it would overwrite the live change.

## CountryListView
Picks the countries allowed by the "country allowlist" rule, as a sheet from that rule's row on Home.

## TestFiltersView
Type a sender and a message and see the verdict live, as a sheet from the menu.
- A `ScrollView`, not a `Form`: a `Form` can't animate the row height when the result changes.
- A blank sender means "test the body only": the view model evaluates with a numeric stand-in sender that isn't itself filtered.

## LanguageListView
One screen, two modes: `.automaticBlocking` (pushed from Home; toggles AI Filtering per language) and `.blockLanguage` (a sheet; adds a "deny language" filter).
- Only `.blockLanguage` wraps itself in a `NavigationView`; the pushed mode uses Home's.
- Pull-to-refresh is only offered when the cache is at least a day old.
- The view model is `@unchecked Sendable` because `.refreshable` needs a `@Sendable` action.

## AddFilterView
The add-filter sheet for allow and deny filters.
- The duplicate warning is computed live against Core Data; `didAddFilter` hides it right after adding, when the new filter would otherwise match itself.
- The "More/Less" state of the advanced options is remembered across launches.

## FilterListView
The list of one filter type (allow, deny or language), pushed from Home, with inline editing, swipe and bulk delete.
- Regex filters get their own section.
- **`EditableText` crash trap:** after Return, ending the session, clearing focus and the business `onCommit` are deferred to the next main-loop turn. Return's `triggerPrimaryAction` still writes to the text field after `onCommit` returns, so rebuilding the `List` inside that callback crashes with `EXC_BAD_ACCESS`.
- In `EditableText`, the idle `TextField` stays in the layout at opacity 0, which keeps right-to-left text from shifting.

## ReportMessageView
Reports a message as junk or not junk to the backend, as a sheet from the menu; shows a loading overlay, then a checkmark, and closes itself.
- The view model is `@unchecked Sendable` for its async report `Task`.

## WhatsNewView
The release notes sheet, shown automatically once per What's New version (never in the first session) or from the menu.
- An actionable entry closes the sheet and lets the presenting screen open something, e.g. the Tip Jar via `pendingScreenAfterDismiss`.

## FilterTransferPreviewView
The shared picker for importing and exporting filters (`.filterImport` / `.filterExport`).
- Export presents the share sheet on top of the picker; the temp file is deleted when the picker closes.

## TipJarView
Optional tips through StoreKit, as a sheet from the menu, About, or a What's New entry; shows confetti after a purchase and closes after the thank-you toast.
