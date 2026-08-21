# Design Language Reference

Visual design system, color palette, typography, spacing, and component patterns for Simply Filter SMS.

---

## Color System

### Adaptive Colors

The app supports **Dark and Light mode** via `@Environment(\.colorScheme)` and iOS adaptive system colors. No hardcoded hex values — all colors use SwiftUI's built-in adaptive palette.

**Background:**
```swift
// AppExtensions.swift
static func listBackgroundColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .light
        ? Color(uiColor: UIColor.secondarySystemBackground)
        : Color(uiColor: UIColor.systemBackground)
}
```

**Accent color:** One environment tint on Home (`.optionalTint`). Toolbar `•••` menus **and toolbar close X** pin `.tint(.primary)` so those controls stay label-colored (they were never accent). `borderedProminent` actions (Import) keep the environment tint. Chrome that should follow the pick uses `ShapeStyle.tint`. Do **not** paint those with `Color.accentColor`. Dim NavigationLink chevrons still use `.accentColor(Color.primary.opacity(0.35))`. Semantic colors (deny red, allow green icons, delete red, smart-filter icons, indigo bolt) do not follow the custom tint. Help/About envelope icons use `.foregroundStyle(.tint)`. `.optionalTint(nil)` uses `Color.accentColor` so UISwitch resets.

### Semantic Color Assignments

| Context | Color | Usage |
|---------|-------|-------|
| Primary action / selected chrome | Environment `.tint` | FilledButton, OutlineButton, option chips, ON badge, active toggles, links |
| Deny / error | `.red` | FilterType.deny icon, allUnknown toggle tint, OFF badge |
| Allow / success | `.green` | FilterType.allow icon, ON badge when no custom accent |
| Language filters | `.cyan` | FilterType.denyLanguage icon |
| Automatic filtering | `.indigo` | Lightning bolt icon, notification icon |
| Secondary text | `.secondary` | Subtitles, captions, close button, form labels |
| Primary text | `.primary` | Titles, body text, footer |
| Disabled state | any color `.opacity(0.5)` | Applied universally to disabled elements |

### Smart Filter Icon Colors

| Rule | Color |
|------|-------|
| `allUnknown` | `.red` |
| `links` | `.blue` |
| `numbersOnly` | `.purple.opacity(0.8)` |
| `shortSender` | `.orange` |
| `email` | `.brown` |
| `emojis` | `.orange` (text emoji icon, not SF Symbol) |

### Toggle Tint Colors

| Rule | Tint |
|------|------|
| `allUnknown` | `.red` (destructive) |
| All others | Environment `.tint` |

### Opacity Scale

| Value | Usage |
|-------|-------|
| `0.05` | Separator lines (`.primary.opacity(0.05)`) |
| `0.1` | Badge backgrounds (`.secondary.opacity(0.1)`), ON/OFF badge tint backgrounds |
| `0.2` | Pre-iOS 26 notification action chip (`.secondary.opacity(0.2)`) |
| `0.35` | NavigationLink chevron tint (`.primary.opacity(0.35)`) |
| `0.4–0.6` | Notification icon colors (e.g. `.red.opacity(0.4)`, `.green.opacity(0.6)`) |
| `0.5` | Disabled state |
| `0.8` | Purple rule icon (`.purple.opacity(0.8)`) |

---

## Typography

### Hierarchy

| Level | Font | Usage |
|-------|------|-------|
| Screen title | `.largeTitle.bold()` | AboutView app name |
| Section title | `.system(size: 20, weight: .bold, design: .rounded)` | Automatic filtering card title |
| Status badge | `.system(size: 16, weight: .heavy)` | ON/OFF badges |
| Body | `.body` | Standard content, toggle labels, picker options |
| Form label | `.footnote.bold().italic()` | "Select a target:", "Select matching type:", etc. |
| Supporting text | `.caption` | Notification subtitle, supporting info |
| Small caption | `.caption2` | Filter counts ("16 FILTERS"), subtitles, timestamps |
| Footer | `.footnote` | App version and copyright |

### Patterns

- **Large titles** use default iOS navigation bar large title style (`.navigationTitle()`)
- **Inline titles** use `.navigationBarTitleDisplayMode(.inline)` for detail/list screens
- **Bold keywords** in explanatory text use markdown-style inline emphasis (e.g. "locally", "dominant language" in LanguageListView)

---

## Spacing & Layout

### Corner Radii

| Value | Usage |
|-------|-------|
| 4pt | Small badges, filter option buttons |
| 8pt | Primary buttons (FilledButton, OutlineButton), logo clipping, tip price badge |
| 12pt | Video thumbnails |
| 16pt | Tip cards |
| 24pt | Notification toast (pill shape) |

### Padding

| Value | Usage |
|-------|-------|
| 16pt | Default button padding (`.padding()`), horizontal screen margins |
| 12pt | List row vertical padding |
| 8pt | Inter-element spacing, icon-to-text leading padding, separator-to-content |
| 4–6pt | Tight spacing within badges and compact elements |

### Common EdgeInsets

```swift
// Notification icon
EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 0)

// Notification text
EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 4)

// Notification button
EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
```

---

## Components

### Buttons

**FilledButton** (`ButtonStyles.swift`):
- Background: `.tint`, `.gray` when disabled
- Text: white, gray when pressed
- Corner radius: 8pt
- Full default padding
- Used for: "Test", "Add", "Report", "Settings"

**OutlineButton** (`ButtonStyles.swift`):
- Border: `.tint` stroke on `RoundedRectangle(cornerRadius: 8, style: .continuous)`
- Text: `.tint`, gray when pressed
- No fill

### Close Button

Applied via `EmbeddedCloseButton` modifier (`ViewModfiers.swift`) or a toolbar `xmark`:
- SF Symbol: `xmark`
- Toolbar / overlay close: `.tint(.primary)` so the control does not follow the custom accent
- Overlay close also uses `.secondary` on the glyph
- `contentShape(Rectangle())` for expanded tap target

### Footer

Applied via `EmbeddedFooterView` modifier (`ViewModfiers.swift`):
- Pinned to bottom of screen via ZStack alignment
- Background: `.ultraThinMaterial` (iOS 26+: `.glassEffect(.regular)`)
- Top separator: 1px `Rectangle`, `.primary.opacity(0.05)`
- Text: `.footnote`, `.primary`, centered, multiline (version + copyright)
- Ignores keyboard safe area
- Tappable (triggers About screen)

### Notification Toast

`NotificationView` — slides in from top:
- Background: iOS 26+ `.glassEffect(.clear.interactive())` in a 24pt continuous rounded rect; older iOS `.ultraThinMaterial`
- Action chip: iOS 26+ clear interactive glass `Capsule`; older iOS `.secondary.opacity(0.2)` fill
- Shape: `RoundedRectangle(cornerRadius: 24, style: .continuous)` (pill)
- Animation: `.interpolatingSpring(mass: 1, stiffness: 200, damping: 30)`
- Offset: -200 (hidden) to 25 (shown)
- Dismiss: tap, swipe up, or button
- Contains: icon + title/subtitle VStack + action button
- Types: offline (red icon), cloudSync (green), automaticFiltersUpdated (indigo), clipboard (primary), tipSuccessful (pink), reporting nudge (green), import/export (green/red)
- Timeout: nil (offline stays), 6s (sync / filters / import-export / tip success), 3s (clipboard), 10s (tip promotion / reporting nudge)

### Toggle Rows (Smart Filters)

Each row in the smart filters section:
- Icon: 20pt frame, color-coded per rule type (SF Symbol or emoji text)
- Title: `.primary` (`.red` when destructive rule is active)
- Optional subtitle: `.caption2`, `.secondary` color
- Optional action link: `.caption2`, `.tint` (e.g. "Tap to change")
- Toggle: inherit environment tint (`.red` for allUnknown only)
- Disabled: 0.5 opacity when `allUnknown` is active (except the allUnknown toggle itself)
- Leading padding between icon and text: 8pt

### Navigation Rows (Your Filters)

- Icon: SF Symbol, 20pt frame, color-coded per filter type
- Title: `.primary`, 8pt leading padding
- Count badge: `.caption2`, `.secondary`, uppercase ("16 FILTERS")
- Chevron: `.primary.opacity(0.35)`

### Filter row option chips (FilterListRowView)

Icon chips (`OptionButton`, ~15pt, ultra-thin material, 8pt continuous rounded rect):
- `.tint` when the option is non-default (exact match, case sensitive, target ≠ all); folder chip always tinted
- `.secondary` otherwise
- Tap opens a `Menu` whose body is a `Picker` so the current value gets the system checkmark
- Regex rows hide matching/case chips; target chip stays

### Segmented Pickers

Used in AddFilterView and ReportMessageView:
- Label above: `.footnote.bold().italic()`, `.secondary` color
- Picker style: `.segmented` (iOS native)
- Option text: `.body`
- Spacing between label and picker: 8pt

### Text Input Cards

Used in TestFiltersView, ReportMessageView, AddFilterView:
- Grouped card background (Test Filters uses ScrollView + `secondarySystemGroupedBackground`; Report uses Form)
- Labeled text fields with placeholder text
- Separator lines between fields within the same card

### Accordion (FAQ)

Used in HelpView (`DisclosureGroup` in an inset grouped List):
- Question text only; system chevron
- One question open at a time
- Answer aligned with the question (`.padding(.leading, -20)`, same as About)
- Question is `.subheadline.weight(.semibold)`; answer is `.footnote.weight(.regular)` / `.primary` with markdown bold

### Tip Cards (TipJarView)

Card-based IAP buttons arranged in an `HStack`:
- Background: `RoundedRectangle(cornerRadius: 16, style: .continuous)`, `.gray.opacity(0.1)`
- Emoji icon: tier-specific (☕️/🍕/🍸), large size
- Title: `.system(size: 15, weight: .semibold)`, `.primary`
- Description: `.system(size: 11)`, `.secondary`, centered, fixed height for alignment
- Price badge: `.subheadline.bold()`, `.tint`, with `.tint.opacity(0.1)` background pill (`RoundedRectangle(cornerRadius: 8)`)
- Press effect: `TipCardButtonStyle` scales to 0.95 and dims to 0.7 opacity with 0.15s ease-in-out
- Purchasing state: price badge replaced with `ProgressView` spinner on the tapped card
- Disabled during purchase (all cards)
- Landscape-aware: reduces font sizes and padding when `verticalSizeClass == .compact`

### Confetti (TipJarView)

`ConfettiView` — `UIViewRepresentable` wrapping `CAEmitterLayer`:
- Emits from top edge, full width
- Cell shapes: circle, triangle, star (custom `CGPath`)
- Colors: red, blue, green, yellow, purple, orange, cyan
- Intensity scales with tip tier: small (low birthRate/velocity), medium, large (high birthRate/velocity)
- Auto-stops emission after 0.3s; particles fall and fade naturally

### Collapsible Options

Used in AddFilterView:
- "See more options" / "See less" toggle with radio icon
- Persisted state via `DefaultsManager.isExpandedAddFilter`
- Hides/shows the three option pickers (target, matching, case)

---

## Screen Presentation Patterns

### Sheets (modal)

Used for: creation, input, info, and onboarding screens.
- Close button: X (top-right) via `EmbeddedCloseButton` or toolbar
- Large bold title: left-aligned
- Screens: AddFilterView, TestFiltersView, ReportMessageView, HelpView, AboutView, ChooseAccentColorView, EnableExtensionView, WhatsNewView, TipJarView, FilterTransferPreviewView (import and export)

### Push Navigation

Used for: drill-down lists and detail screens.
- Back chevron: left (system default)
- Title: `.inline` display mode, centered
- Optional menu button: `ellipsis.circle` (top-right)
- Screens: FilterListView, LanguageListView (both modes)

### Root

- AppHomeView: large title, `.insetGrouped` list, trailing menu button (`ellipsis.circle`)

---

## List Style

All lists use `.insetGrouped` — the iOS standard grouped card appearance with rounded section backgrounds and inset margins. No custom cell backgrounds or separators are applied; the system default handles dark/light mode automatically.

---

## Iconography

- **SF Symbols** throughout (no custom icon assets except the app icon)
- Smart filter emojis: `emojis` rule uses a text emoji rendered via `EmojiGenerator.randomEmoji()` (tappable to regenerate)
- Consistent icon frame: `maxWidth: 20` for alignment in list rows
- Icon-to-text spacing: 8pt leading padding

---

## Design Principles for New Features

1. **Follow iOS conventions** — use system list styles, standard toggles, segmented pickers, navigation patterns. The app feels like an extension of iOS Settings.
2. **Adaptive colors only** — use SwiftUI adaptive colors (`.primary`, `.secondary`, `.accentColor`, named colors like `.red`, `.green`). Never hardcode hex values. Both dark and light mode must work.
3. **Grouped sections** — new content areas should use `Section` within `.insetGrouped` lists with localized text headers (no custom header styling).
4. **Consistent actions** — primary actions use `FilledButton` (environment tint, full-width). Secondary/inline actions use text links in `.tint`.
5. **Flat hierarchy** — sheets for creation/input, push navigation for lists/details. No nested modals.
6. **Minimal decoration** — no gradients, shadows, or decorative elements. Rely on system materials (`.ultraThinMaterial`) for overlays.
7. **Consistent icon pattern** — SF Symbols at 20pt frame width with semantic color coding. One emoji exception for the emojis rule.
8. **Explanatory text** — use gray body text inside sections or below lists to explain features. Bold key terms for emphasis.
9. **Footer on all scrollable screens** — apply `EmbeddedFooterView` modifier.
10. **Localize everything** — use the `~` postfix operator for all user-facing strings.
