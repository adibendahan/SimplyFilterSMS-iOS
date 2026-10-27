## ADDED Requirements

### Requirement: All interactive elements SHALL have accessibility labels
Every `Button`, `Toggle`, `Menu`, `NavigationLink`, `TextField`, and `TextEditor` across all screens SHALL have a localized `.accessibilityLabel` that describes the element's purpose. Labels SHALL use the `~` postfix operator for localization.

#### Scenario: Icon-only button has descriptive label
- **WHEN** VoiceOver focuses on an icon-only button (e.g., xmark dismiss, ellipsis menu, emoji randomizer)
- **THEN** VoiceOver reads a descriptive label (e.g., "Close", "More options", "Change emoji") instead of the SF Symbol name

#### Scenario: Toggle has contextual label
- **WHEN** VoiceOver focuses on a smart filter Toggle in AppHomeView
- **THEN** VoiceOver reads the filter name and current state (e.g., "Block links, on")

#### Scenario: Menu control has descriptive label
- **WHEN** VoiceOver focuses on a Menu control (e.g., filter target, filter matching, filter case)
- **THEN** VoiceOver reads the menu's purpose and current selection

### Requirement: All functional images SHALL have accessibility labels
Named asset images used as functional controls (`caseSensitive`, `GitHub`, `Twitter`, `Instagram`) SHALL have localized `.accessibilityLabel` values describing their purpose.

#### Scenario: Social media icon has label
- **WHEN** VoiceOver focuses on a social media link button in AboutView (GitHub, Twitter, Instagram)
- **THEN** VoiceOver reads the platform name (e.g., "GitHub", "Twitter", "Instagram")

#### Scenario: Case sensitivity icon has label
- **WHEN** VoiceOver focuses on the case sensitivity toggle icon in FilterListRowView
- **THEN** VoiceOver reads "Case sensitive" or "Case insensitive" based on current state

### Requirement: Decorative images SHALL be hidden from VoiceOver
Images that serve no functional purpose (app logo, placeholder icons, section header decorative icons) SHALL have `.accessibilityHidden(true)`.

#### Scenario: App logo is hidden
- **WHEN** VoiceOver navigates through AboutView
- **THEN** the app logo image is skipped entirely

#### Scenario: Placeholder icon is hidden
- **WHEN** VoiceOver navigates through an empty filter list with CustomPlaceholderView
- **THEN** the large placeholder SF Symbol icon is skipped, but the placeholder text is read

### Requirement: Filter list rows SHALL be grouped as single accessibility elements
Each `FilterListRowView` SHALL use `.accessibilityElement(children: .combine)` on the outer HStack to present as a single VoiceOver element with a computed label describing the full filter configuration.

#### Scenario: Filter row reads as combined element
- **WHEN** VoiceOver focuses on a deny filter row with text "spam"
- **THEN** VoiceOver reads the filter text and its current settings as a single element (e.g., "'spam', sender and body, contains, case insensitive, junk")

#### Scenario: Filter row exposes menu actions as custom actions
- **WHEN** VoiceOver user performs the actions rotor on a filter row
- **THEN** named actions are available for "Change filter target", "Toggle match type", "Toggle case sensitivity", and "Change folder" (when applicable)

### Requirement: Section headers SHALL have header traits
Section headers throughout the app (e.g., "Automatic Filters", filter type section headers in AppHomeView) SHALL have `.accessibilityAddTraits(.isHeader)`.

#### Scenario: Section header identified in rotor
- **WHEN** VoiceOver user navigates by headers using the rotor
- **THEN** section headers in AppHomeView and FilterListView are navigable as header elements

### Requirement: Accessibility hints SHALL describe interactive element actions
Interactive elements that perform non-obvious actions SHALL have `.accessibilityHint` describing what happens on activation.

#### Scenario: Expand button has hint
- **WHEN** VoiceOver focuses on the expand/collapse button in AddFilterView
- **THEN** VoiceOver reads a hint like "Double tap to show advanced options" or "Double tap to hide advanced options"

#### Scenario: Test filters button has hint
- **WHEN** VoiceOver focuses on the test button in TestFiltersView
- **THEN** VoiceOver reads a hint like "Double tap to test this message against your filters"
