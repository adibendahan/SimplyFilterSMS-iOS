## Context

The app has no accessibility support beyond `.accessibilityIdentifier` calls used for Fastlane UI test automation. VoiceOver users encounter unlabeled icon buttons, unannounced toasts, and composite rows that expose a confusing pile of individual controls. Dynamic Type is partially broken by 16 hardcoded `Font.system(size:)` calls and fixed-dimension frames. All changes are confined to the View Layer — no data model, API, or framework layer changes are needed.

## Goals / Non-Goals

**Goals:**
- Make every screen fully navigable and usable with VoiceOver
- Support Dynamic Type at all size categories including accessibility sizes
- Announce dynamic content changes (toasts, filter test results) to assistive technology
- Follow Apple HIG accessibility guidelines using only built-in SwiftUI APIs
- Localize all accessibility strings in English and Hebrew
- **Zero visual change at default text size** — the app must look pixel-identical at the standard content size category

**Non-Goals:**
- Full WCAG 2.1 AA audit (color contrast ratios, touch target sizes beyond what Apple provides)
- Accessibility-specific unit/UI tests (can be a future change)
- Support for Switch Control or other assistive technologies beyond VoiceOver + Dynamic Type
- Refactoring view architecture — changes are additive modifiers only
- Changing any default font sizes, icon sizes, frame dimensions, or image sizes

## Decisions

### 1. Use the `~` postfix operator for accessibility label localization

**Decision:** Accessibility label strings will use the existing `~` postfix operator pattern (`"key"~`) and be added to the existing `.strings` files.

**Rationale:** This is the project's established localization pattern. Creating a separate accessibility strings file or using a different mechanism would be inconsistent. BartyCrouch will normalize the new keys across English and Hebrew.

**Alternative considered:** Inline English-only strings via `.accessibilityLabel("Close")` — rejected because the app supports Hebrew and all user-facing strings must be localized.

### 2. `@ScaledMetric` for all dimensions — preserve exact default sizes

**Decision:** Wrap hardcoded font sizes and frame dimensions in `@ScaledMetric` properties initialized to their **current exact values**. For example, `Font.system(size: 20)` becomes `@ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 20` and then `Font.system(size: fontSize)`. Similarly, `.frame(width: 44, height: 20)` becomes `@ScaledMetric` properties defaulting to 44 and 20.

**Rationale:** `@ScaledMetric` defaults to its initial value at the standard content size category, so the app looks pixel-identical at default settings. It only scales when the user changes their preferred text size. This preserves the current design while enabling Dynamic Type scaling.

**Alternative considered:** Replacing `Font.system(size:)` with semantic font styles (`.caption`, `.body`, etc.) — rejected because semantic fonts may not match the current visual design exactly (e.g., the 8pt badge font in `FilterListRowView` has no semantic equivalent). Using `@ScaledMetric` with the exact current size values guarantees zero visual change at default.

### 3. Group `FilterListRowView` as a single accessibility element

**Decision:** Apply `.accessibilityElement(children: .combine)` to the row's outer `HStack`, then add a computed `.accessibilityLabel` that reads the full filter description (e.g., "Block sender containing 'spam', exact match, case sensitive, junk folder"). Add `.accessibilityAdjustableAction` or custom actions for the menu controls.

**Rationale:** The row currently has 3-4 separate `Menu` controls rendered as tiny icon buttons. VoiceOver would navigate each as an unlabeled element. Combining them into a single element with a descriptive label and custom actions provides a coherent experience.

**Alternative considered:** Labeling each `Menu` individually — rejected because navigating 4+ controls per row is tedious, and the controls are meaningless without the context of the filter text.

### 4. `UIAccessibility.post(notification:argument:)` for toast announcements

**Decision:** When `NotificationView` becomes visible (in the `setShow` method), post a `.announcement` notification with the toast's title and subtitle text.

**Rationale:** VoiceOver cannot detect offset-based animations — the toast slides in via `offset(y:)` changes, which don't trigger accessibility focus. An explicit announcement is the standard approach for transient, non-modal alerts.

**Alternative considered:** Using `AccessibilityFocusState` to move focus to the toast — rejected because stealing focus from the user's current position is disruptive, especially for a transient notification.

### 5. Decorative vs. functional image labeling strategy

**Decision:**
- Decorative images (app logo, placeholder icons, section header icons) → `.accessibilityHidden(true)`
- Functional named images (`caseSensitive`, social icons) → `.accessibilityLabel("key"~)`
- SF Symbols used as icon-only buttons → explicit `.accessibilityLabel("key"~)` to override the auto-generated symbol name
- SF Symbols next to text (e.g., in `Label`) → no additional label needed (text provides context)

**Rationale:** Apple HIG recommends hiding purely decorative elements from VoiceOver and providing explicit labels for functional elements. SF Symbol auto-labels are inconsistent across iOS versions and often read as technical names.

### 6. Flexible TextEditor heights

**Decision:** Replace `.frame(height: 80)` with `.frame(minHeight: 80, idealHeight: 80)` on TextEditor in `TestFiltersView` and `ReportMessageView`. The `idealHeight: 80` ensures the default layout is identical; `minHeight` prevents shrinking while allowing growth at larger text sizes.

**Rationale:** Fixed height clips content at larger text sizes. Using `minHeight` + `idealHeight` preserves the exact visual design at standard sizes while allowing the editor to grow when needed.

## Risks / Trade-offs

- **Layout shifts at non-default text sizes** → Some screens (particularly `FilterListRowView` badges and `TipCardView`) may need layout adjustments at very large accessibility sizes. Mitigate by testing at the largest accessibility size during implementation. At default text size, no layout changes will occur since all `@ScaledMetric` values resolve to their initial values.
- **Localization overhead** → Adding ~50-70 new localization keys across English and Hebrew. Mitigate by using descriptive, consistent key naming (`a11y_<screen>_<element>`) and running BartyCrouch after all keys are added.
- **VoiceOver custom actions on filter rows** → `accessibilityAdjustableAction` may not fully replace the menu-based interaction for changing filter target/matching/case. Mitigate by using `.accessibilityAction(named:)` to expose each menu as a named action (e.g., "Change filter target", "Toggle case sensitivity").
- **No automated testing** → Without accessibility tests, regressions can creep in with future UI changes. This is explicitly a non-goal for this change but should be tracked as follow-up work.

## Open Questions

_(none — the scope is well-defined and uses standard SwiftUI accessibility APIs)_
