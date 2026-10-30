# Design Rules

The decisions behind the UI. Sizes, fonts, radii and colors are in the code (`ButtonStyles.swift`, `ViewModfiers.swift`, each type's `color`).

---

## Principles

1. **Feel like iOS Settings.** System list styles (`.insetGrouped`), standard toggles, segmented pickers and navigation.
2. **Adaptive colors only.** No hex values; light and dark mode must both work. For card or surface backgrounds, use `.gray.opacity(…)`, not `Color(.systemGray6)`, which disappears into the dark-mode background.
3. **Sheets for creating and input, pushes for lists and details.**
4. **Primary actions** use `FilledButton`; secondary and inline actions are text links in `.tint`.
5. **Overlays** use system materials, and Liquid Glass on iOS 26+.
6. **One icon style.** SF Symbols in a 20pt frame, colored by meaning. The emojis rule is the only exception: a random emoji, tap to change.
7. **Explain in place.** Short gray text in or under a section explains a feature, with key terms in bold.
8. **Localize every user-facing string** with `~`.

---

## The accent color

The user can pick the app's tint (`ChooseAccentColorView`). Getting this wrong makes controls jump color, so:

- **Chrome that should follow the pick uses `.tint` (`ShapeStyle.tint`), never `Color.accentColor`.**
- **Toolbar `•••` menus and the close X pin `.tint(.primary)`.** They were never accent-colored and shouldn't start following the pick.
- **Meaning colors never follow the tint:** deny red, allow green, language cyan, AI Filtering indigo, the smart rule icons, delete red, and the red "block all unknown" toggle.
- `.optionalTint(nil)` sets `Color.accentColor` instead of no tint, so a `UISwitch` resets to the default color.
- Dimmed navigation chevrons use `.accentColor(Color.primary.opacity(0.35))`.

---

## Smaller rules

- **Filter option chips** in a filter row are tinted only when the option differs from the default (exact match, case-sensitive, a target other than "all"); the folder chip is always tinted. Tapping a chip opens a `Menu` holding a `Picker`, so the current value gets the system checkmark.
- **Toasts** (`NotificationView`) sit outside `NavigationView`, or they appear below the navigation bar.
- **The footer** (version and copyright, tap for About) is on Home only.
