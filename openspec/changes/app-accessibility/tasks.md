## 1. Core Components — VoiceOver Labels + Dynamic Type

- [ ] 1.1 Add `@ScaledMetric` properties and accessibility labels/hints to `FilterListRowView.swift` — group row with `.accessibilityElement(children: .combine)`, add computed label describing full filter config, add `.accessibilityAction(named:)` for each menu control, wrap 8pt/18pt/20pt/16pt/44x20 sizes in `@ScaledMetric`
- [ ] 1.2 Add VoiceOver announcement to `NotificationView.swift` — post `UIAccessibility.Notification.announcement` in `setShow` when toast becomes visible, add `.accessibilityLabel` to dismiss button
- [ ] 1.3 Add accessibility label to dismiss button in `ViewModfiers.swift` — label the xmark button, wrap 20pt icon size in `@ScaledMetric`
- [ ] 1.4 Add `@ScaledMetric` and `.accessibilityHidden(true)` to `CustomPlaceholderView.swift` — hide decorative 60pt icon from VoiceOver, wrap size in `@ScaledMetric`
- [ ] 1.5 Add `@ScaledMetric` properties to `QuestionView.swift` — wrap 16pt font sizes and 16x16 chevron frame in `@ScaledMetric`
- [ ] 1.6 Add `@ScaledMetric` properties to `TipCardView.swift` — wrap 20pt/28pt emoji, 13pt/15pt name, 10pt/11pt description, and 14-30pt frame heights in `@ScaledMetric`

## 2. Main Screens — VoiceOver Labels + Dynamic Type

- [ ] 2.1 Add accessibility to `AppHomeView.swift` — label ellipsis menu button, emoji randomizer button, ON/OFF badges; add `.isHeader` traits to section headers; hide decorative shield icon; wrap 30pt/20pt/16pt font sizes in `@ScaledMetric`
- [ ] 2.2 Add accessibility to `FilterListView.swift` — label add-filter footer button, globe language button; add `.isHeader` to section headers; wrap 20pt icon sizes in `@ScaledMetric`
- [ ] 2.3 Add accessibility to `AddFilterView.swift` — label expand/collapse button with hint, add filter button hint; remove no-op `.accessibility(hidden: false)`
- [ ] 2.4 Add accessibility to `TestFiltersView.swift` — add hint to test button, announce filter test result to VoiceOver; replace `.frame(height: 80)` with `.frame(minHeight: 80, idealHeight: 80)` on TextEditor
- [ ] 2.5 Add accessibility to `ReportMessageView.swift` — add hint to submit button; replace `.frame(height: 80)` with `.frame(minHeight: 80, idealHeight: 80)` on TextEditor; remove no-op `.accessibility(hidden: false)`
- [ ] 2.6 Add accessibility to `AboutView.swift` — label GitHub/Twitter/Instagram asset images, hide decorative app logo, label close button; wrap 90pt logo width and 22-26pt social icon sizes in `@ScaledMetric`
- [ ] 2.7 Add accessibility to `HelpView.swift` — label GitHub asset image, label envelope icon; wrap 25x20/26x26 icon sizes in `@ScaledMetric`
- [ ] 2.8 Add accessibility to `TipJarView.swift` — label close button; wrap 32pt/56pt heart emoji size in `@ScaledMetric`
- [ ] 2.9 Add accessibility to `WhatsNewView.swift` — label continue/close buttons; wrap 44x44 icon container in `@ScaledMetric`
- [ ] 2.10 Add accessibility to `LanguageListView.swift` — label close button; hide decorative Wi-Fi error icon or add label; wrap 30pt icon size in `@ScaledMetric`
- [ ] 2.11 Add accessibility to `EnableExtensionVideoView.swift` — label CTA and cancel buttons with hints

## 3. Localization

- [ ] 3.1 Add all new `a11y_*` localization keys to English `.strings` file
- [ ] 3.2 Add all new `a11y_*` localization keys to Hebrew `.strings` file
- [ ] 3.3 Run BartyCrouch to normalize `.strings` files

## 4. Verification

- [ ] 4.1 Build project and verify zero compiler errors
- [ ] 4.2 Run existing unit tests — confirm no regressions
- [ ] 4.3 Visual spot-check at default text size — confirm pixel-identical appearance on key screens (AppHomeView, FilterListView, AboutView, TipJarView)
