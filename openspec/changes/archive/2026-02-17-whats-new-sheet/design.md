## Context

The app currently has no mechanism to communicate changes after an update. The onboarding sheet (`EnableExtensionVideoView`) handles first-run guidance. We need a complementary "What's New" sheet that appears on subsequent launches when new release notes are available. The visual reference is an Apple-style feature list: large centered title, icon + title + description rows, and a full-width "Continue" button pinned to the bottom.

## Goals / Non-Goals

**Goals:**
- Show a "What's New" sheet once per new release notes, starting from the second app launch (never on first run).
- Match the Apple-style feature list layout: centered title, colored icon rows, bottom CTA button.
- Keep release notes as hardcoded constants in code (not fetched remotely). All user-facing strings MUST be localized via the `~` operator.
- Decouple release notes from app version — tracked by a hardcoded sequence integer.
- Follow all existing MVVM, navigation, and design patterns.

**Non-Goals:**
- Remote/dynamic release notes fetched from a server.
- Deep linking to the What's New sheet.

## Decisions

### 1. Data model: `WhatsNewEntry` struct with hardcoded sequence

Each entry has an SF Symbol name, icon color, and localization keys for title and description. Two constants in `Constsants.swift`:

```swift
struct WhatsNewEntry {
    let symbolName: String
    let symbolColor: Color
    let titleKey: String       // localization key, resolved via ~
    let descriptionKey: String // localization key, resolved via ~
}

let whatsNewSequence = 1
let whatsNewEntries: [WhatsNewEntry] = [ ... ]
```

**To add new release notes:** replace the entries array and increment `whatsNewSequence`. Old entries can be freely deleted since the sequence is a standalone constant.

**Why a hardcoded sequence instead of array count or version string?** Decouples from app version entirely. Unlike array count, the sequence doesn't change when old entries are pruned. Simple to manage — bump the number, replace the entries.

**Location:** Added directly to `Constsants.swift` in `Framework Layer/Shared with Extension/`.

### 2. Sequence tracking: `lastSeenWhatsNewSequence` in DefaultsManager

A new `Int` stored default. Starts at `0`. On any dismissal, set to `whatsNewSequence`.

**Show-condition logic (in AppHomeView.ViewModel):**
```
!isAppFirstRun
&& !whatsNewEntries.isEmpty
&& whatsNewSequence > lastSeenWhatsNewSequence
```

This ensures:
- First run → onboarding only (skip What's New).
- Second run → `lastSeenWhatsNewSequence` is `0`, `whatsNewSequence` is ≥ 1, so the sheet shows.
- After dismissal → `lastSeenWhatsNewSequence` == `whatsNewSequence`, sheet won't show again until the sequence is bumped.
- New release notes → `whatsNewSequence` incremented beyond `lastSeenWhatsNewSequence`, sheet shows.

### 3. Screen integration: `.whatsNew` case in Screen enum

Add a new case to `Screen` with `build()` returning `WhatsNewView(model: WhatsNewView.ViewModel())`.

**Presentation trigger:** In the `AppHomeView` `.onReceive(self.model.$navigationScreen)` block, after the existing `isAppFirstRun` check, add the What's New check. The What's New sheet is presented via `sheetScreen` (same mechanism as all other sheets). The check only fires when `navigationScreen` becomes `nil` (i.e., on initial load or returning from navigation).

**Why not `.onAppear`?** The existing pattern uses `.onReceive($navigationScreen)` for sheet triggers (see the `isAppFirstRun` check). Following the same pattern keeps behavior consistent.

### 4. View layout: Apple-style feature list

**WhatsNewView** structure:
- **NavigationView** with `.inline` title display mode and toolbar X button (consistent with other sheets in the app like AboutView, HelpView).
- **ScrollView** wrapping a VStack:
  - Large bold centered title (localized via `~`).
  - For each `WhatsNewEntry`: HStack with icon (SF Symbol in colored circle background) + VStack (bold title + secondary description rendered via `AttributedString(markdown:)`).
  - Spacer to push content up.
- **Bottom "Continue" button** — pinned outside the ScrollView using a VStack or `.safeAreaInset(edge: .bottom)`. Full-width `FilledButton` style.
- **Any dismissal marks as seen** — whether the user taps Continue, taps X, or swipes down, `lastSeenWhatsNewSequence` is set to `whatsNewSequence`. The sheet is shown once per sequence and won't reappear regardless of how it's dismissed.

### 5. ViewModel: minimal, follows BaseViewModel pattern

```swift
extension WhatsNewView {
    class ViewModel: BaseViewModel, ObservableObject {
        let entries: [WhatsNewEntry]

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.entries = whatsNewEntries
            super.init(appManager: appManager)
        }

        func markAsSeen() {
            appManager.defaultsManager.lastSeenWhatsNewSequence = whatsNewSequence
        }
    }
}
```

The view owns the `@Environment(\.dismiss)` call; the ViewModel handles the data write.

### 6. Menu item for re-viewing What's New

A "What's New" button in `AppHomeView`'s trailing navigation bar menu, setting `sheetScreen = .whatsNew`. The item is only visible when `whatsNewEntries` is not empty. This lets users re-view the latest release notes at any time.

## Risks / Trade-offs

**[Developer must remember to bump sequence]** → Simple convention: increment `whatsNewSequence` whenever entries are replaced. Low risk since the constant is right next to the entries.

**[Sheet conflicts with other launch sheets]** → The existing `.onReceive($navigationScreen)` block already handles the `isAppFirstRun` check. The What's New check goes in an `else` branch, so only one sheet presents at a time. If the onboarding is showing, What's New is skipped entirely (first run).

**[One-shot auto-display]** → Any dismissal marks the sequence as seen. The user can always re-view via the menu item.
