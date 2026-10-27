## ADDED Requirements

### Requirement: All font sizes SHALL scale with Dynamic Type while preserving default appearance
Every hardcoded `Font.system(size:)` call SHALL be replaced with a `@ScaledMetric` property initialized to the current exact size value. At the default content size category, the rendered font size SHALL be identical to the current hardcoded value.

#### Scenario: Font scales up at larger text sizes
- **WHEN** the user sets their preferred content size to `.accessibilityExtraExtraExtraLarge`
- **THEN** all text rendered with previously-hardcoded sizes scales proportionally larger

#### Scenario: Font is identical at default text size
- **WHEN** the user has the default content size category (`.large`)
- **THEN** all text renders at the exact same size as before (e.g., 8pt badge, 20pt title, 16pt body)

### Requirement: Icon frame dimensions SHALL scale with Dynamic Type while preserving default appearance
All hardcoded `.frame(width:height:)` values on icons and icon containers SHALL be wrapped in `@ScaledMetric` properties initialized to their current exact values. At the default content size category, icon dimensions SHALL be identical to current values.

#### Scenario: Icon frames scale up at larger text sizes
- **WHEN** the user sets a larger content size category
- **THEN** icon frames (e.g., FilterListRowView 18x18 matching icon, 20x20 case icon, 44x20 target badge) grow proportionally

#### Scenario: Icon frames are identical at default text size
- **WHEN** the user has the default content size category
- **THEN** all icon frames render at the exact same pixel dimensions as before

### Requirement: TextEditor height SHALL be flexible while preserving default appearance
TextEditor instances in `TestFiltersView` and `ReportMessageView` SHALL use `.frame(minHeight:idealHeight:)` instead of `.frame(height:)`. The `idealHeight` SHALL match the current fixed height (80pt). The `minHeight` SHALL also be set to preserve the minimum usable area.

#### Scenario: TextEditor height is identical at default text size
- **WHEN** the user has the default content size category
- **THEN** the TextEditor renders at exactly 80pt height, identical to the current appearance

#### Scenario: TextEditor grows at larger text sizes
- **WHEN** the user sets a larger content size category
- **THEN** the TextEditor can grow beyond 80pt to accommodate larger text without clipping

### Requirement: @ScaledMetric properties SHALL use appropriate relativeTo text styles
Each `@ScaledMetric` property SHALL specify a `relativeTo` text style that best matches the context of the scaled element (e.g., `.caption` for small badges, `.body` for standard text, `.title2` for heading-size elements).

#### Scenario: Small badge scales relative to caption
- **WHEN** the 8pt filter target badge font in FilterListRowView scales
- **THEN** it scales relative to `.caption` or `.caption2` text style, keeping proportional to surrounding small text

#### Scenario: Title-size element scales relative to title
- **WHEN** a 20pt title element scales
- **THEN** it scales relative to `.title3` or `.headline` text style
