## Context

The app has no custom AccentColor asset. SwiftUI `.accentColor` is the system tint (blue). Active filter-list chips now use that tint. Home already presents Help, About, and Tip Jar from the `•••` menu via `FlowManager.request` → `Screen.build()`. `DefaultsManager` uses `UserDefaults.standard`.

## Goals / Non-Goals

**Goals:**
- Let the user pick an accent from the Home `•••` menu
- Persist it in `UserDefaults.standard` like other defaults
- Apply `.tint` so chrome using `ShapeStyle.tint` follows; reset restores system default
- Live update while the picker is open (sheet chrome and Home)

**Non-Goals:**
- Not in About, Filter Tools, or a settings screen
- No free-form hex field, no palette-only UI (native picker is the control)
- No What's New bump unless the current What's New version already shipped
- No change to semantic colors (deny red, allow green, delete red, dim chevrons, smart-filter icons)
- No change to the Reporting Extension or Message Filter Extension
- Production `StoredDefault` stays on `UserDefaults.standard` (do not inject a store for tests)

## Decisions

### 1. Menu item opens a Screen sheet; picker is not inside the Menu

**Choice:** `•••` item next to About → `requestSheet(.chooseAccentColor)` → `ChooseAccentColorView` (`NavigationView`, **inline** title, X with `.tint(.primary)`). Full-screen `UIColorPickerViewController` (`supportsAlpha` false) plus Reset. Not a List, not SwiftUI `ColorPicker` (that fought ColorPickerUIService when embedded).

**Why:** `ColorPicker` does not work as a `Menu` control on iOS. The entry point is still only the menu.

**Alternative:** ColorPicker in About. Rejected. Palette of swatches. Rejected (native picker). SwiftUI ColorPicker in a List. Tried; replaced with the UIKit controller filling the sheet.

### 2. Persist RGB in UserDefaults.standard; DefaultsManager wraps it

**Choice:** `@StoredDefault("accentColorRGB", defaultValue: kNoColorDict)`. `Color` converts to and from that dictionary (`init?(accentRGB:)` / `accentRGB`). The picker is UIKit, so `UIColor(Color)` (or `Color(uiColor:)` the other way). Empty `kNoColorDict` means system default.

**Why:** Same store as first-run and What's New.

**Alternative considered:** App Group `UserDefaults` / plist. Rejected.

**Alternative:** `NSKeyedArchiver` of `UIColor`. Rejected; three doubles are enough with opacity off. `@AppStorage` only, skipping DefaultsManager. Rejected (mocks / `reset()`).

### 3. Apply `.tint` on Home and the picker sheet, not a new ObservableObject

**Choice:** Home presents `ChooseAccentColorView` like Help: `ViewModel(onAccentChanged:)` only. Managers default. Drag/reset writes `accentColorRGB` and calls the callback so Home’s tint updates while the sheet is up. Home uses `.optionalTint` (`tint(color ?? Color.accentColor)` — never `.tint(nil)`). Toolbar `•••` and close X pin `.tint(.primary)`. Chrome that should follow the pick uses `ShapeStyle.tint`, not `Color.accentColor`.

**Why:** Root `WindowGroup` is not an `ObservableObject`. A dedicated tint controller is extra type noise. The picker sheet is where live preview matters; Home catches up on dismiss.

**Alternative:** `ObservableObject` on `App`. Rejected.

### 5. Screen case `.chooseAccentColor`

**Choice:** New `Screen` case, `build()` like About. No associated values. Home menu uses existing `requestSheet`.

**Why:** Same occupancy as Help/About (first-run still wins).

## Risks / Trade-offs

- [Picked RGB is not a dynamic light/dark color] → Accepted; native picker gives a resolved color. Reset returns to system blue.
- [Contrast of a wild pick] → User’s problem; they can reset.
- [`.accentColor(...)` overrides on NavigationLink chevrons stay dim primary] → Intentional; do not “fix” them to the custom tint.

## Migration Plan

- Fresh installs: no key → system blue.
- No data migration.
- Debug reset removes `accentColorRGB`.

## Open Questions

None. Copy: EN first, then 10 locales after approval.
