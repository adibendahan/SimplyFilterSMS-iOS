## Why

The app has zero genuine accessibility support. VoiceOver users cannot meaningfully navigate or use the app — there are no accessibility labels, hints, or traits on any element. Dynamic Type is partially broken due to 16 hardcoded font sizes and fixed icon/frame dimensions. All named asset images lack accessibility labels or decorative marking. This change brings the app to a baseline level of accessibility compliance, making it usable for people with visual impairments and those who rely on larger text sizes.

## What Changes

- Add `accessibilityLabel`, `accessibilityHint`, and `accessibilityValue` to all interactive elements across all screens and components
- Add `accessibilityElement(children: .combine)` to composite rows (e.g., `FilterListRowView`) so VoiceOver reads them as coherent items
- Mark decorative images with `.accessibilityHidden(true)` (app logo, placeholder icons)
- Add proper labels to all named asset images (`GitHub`, `Twitter`, `Instagram`, `caseSensitive`)
- Wrap all 16 hardcoded `Font.system(size:)` values in `@ScaledMetric` properties (preserving exact current sizes at default text size)
- Wrap fixed icon frame dimensions in `@ScaledMetric` (preserving exact current sizes at default text size)
- Replace fixed-height `TextEditor` frames (80pt) with `minHeight` + `idealHeight` for flexible sizing at larger text sizes
- Announce `NotificationView` toast banners to VoiceOver via `UIAccessibility.post(notification:)`
- Add `.accessibilityAddTraits(.isHeader)` to section headers throughout the app

## Capabilities

### New Capabilities
- `voiceover-support`: Accessibility labels, hints, values, traits, and element grouping for all screens and components
- `dynamic-type-support`: Scaled fonts, `@ScaledMetric` icon sizing, and flexible frame dimensions for all text sizes
- `accessibility-announcements`: VoiceOver announcements for dynamic content changes (toast notifications, filter results, state changes)

### Modified Capabilities
_(none — no existing specs have requirement-level changes)_

## Impact

- **View Layer (all 11 screens + 15 components):** Every SwiftUI view file will be modified to add accessibility modifiers
- **Key files with significant changes:** `FilterListRowView.swift` (row grouping + labels for 3 menu controls), `AppHomeView.swift` (hardcoded fonts + icon labels), `TipCardView.swift` (scaled fonts + sizes), `QuestionView.swift` (scaled fonts), `NotificationView.swift` (announcements)
- **ViewModfiers.swift:** Dismiss button label standardization
- **No API or data model changes** — this is purely a view-layer change
- **No dependency additions** — uses only built-in SwiftUI accessibility APIs
- **Localization:** New accessibility label strings will need entries in `.strings` files for English and Hebrew
