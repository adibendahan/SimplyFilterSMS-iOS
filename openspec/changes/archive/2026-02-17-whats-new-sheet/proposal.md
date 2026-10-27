## Why

Users have no way to know what changed after updating the app. A "What's New" sheet shown once per new release notes helps communicate new features, improvements, and fixes — improving feature discoverability and user engagement.

## What Changes

- Add a new `WhatsNewView` screen presented as a sheet on app launch when new release notes are available that the user hasn't seen yet.
- Store a `lastSeenWhatsNewSequence` integer in `DefaultsManager` (via `UserDefaults`) to track the last sequence the user has seen.
- Define `WhatsNewEntry` struct and two constants in `Constsants.swift`: `whatsNewSequence: Int` (hardcoded, manually bumped) and `whatsNewEntries: [WhatsNewEntry]` (the current entries). When adding new notes, replace the entries and increment the sequence. Old entries can be freely deleted.
- Add a `.whatsNew` case to the `Screen` enum for routing.
- Add a "What's New" menu item in `AppHomeView`'s trailing navigation bar menu so users can re-view the latest notes at any time.
- On `AppHomeView` appear, **skip on first run** (the onboarding flow already occupies that session). On subsequent launches, compare `whatsNewSequence` to `lastSeenWhatsNewSequence` — if the sequence has advanced, present the sheet. Since `lastSeenWhatsNewSequence` starts at `0`, the sheet will appear on the second run even without an app update.

## Capabilities

### New Capabilities
- `whats-new-sheet`: The "What's New" sheet UI, sequence-tracking logic, and static content data model.

### Modified Capabilities
_(none)_

## Impact

- **View Layer**: New `WhatsNewView` + ViewModel, new `Screen` case, launch logic in `AppHomeView.ViewModel`, menu item in AppHomeView.
- **Framework Layer**: New stored default `lastSeenWhatsNewSequence` in `DefaultsManager` / `DefaultsManagerProtocol`.
- **Shared Constants**: New `WhatsNewEntry` struct, `whatsNewSequence` integer, and `whatsNewEntries` array added to `Constsants.swift`.
- **Tests**: Mock updates for `DefaultsManagerProtocol`, unit tests for sequence-comparison logic.
- **Localization**: New `.strings` keys for sheet title, dismiss button, and all entry titles and descriptions. Every user-facing string MUST be localized via the `~` operator.
