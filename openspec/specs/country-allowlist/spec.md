## ADDED Requirements

### Requirement: Rule can be enabled and disabled
The system SHALL provide a `countryAllowlist` automatic filter rule that the user can toggle on or off. The rule's enabled state SHALL be persisted in the `AutomaticFiltersRule` CoreData entity (`isActive` attribute) and synced across devices via CloudKit.

#### Scenario: User enables the rule
- **WHEN** the user toggles the country allowlist rule on
- **THEN** `AutomaticFiltersRule.isActive` is set to `true` for `.countryAllowlist` and a disclosure row appears below the toggle row

#### Scenario: User disables the rule
- **WHEN** the user toggles the country allowlist rule off
- **THEN** `AutomaticFiltersRule.isActive` is set to `false` and the disclosure row is hidden; previously selected countries are retained in storage

#### Scenario: Rule with no countries selected is treated as inactive
- **WHEN** the rule is enabled but `selectedCountries` is empty or nil
- **THEN** the rule SHALL be skipped during evaluation as if it were disabled

---

### Requirement: User can select allowed countries
The system SHALL provide a `CountryListView` screen where the user can select one or more calling-code groups to allow. The selected set SHALL be stored as a JSON-encoded array of calling-code strings (e.g. `["+1", "+972"]`) in the `selectedCountries` attribute on `AutomaticFiltersRule` and synced via CloudKit.

#### Scenario: User opens the country picker
- **WHEN** the user taps the disclosure row beneath the enabled rule toggle
- **THEN** the system navigates to `CountryListView` showing all available calling-code entries

#### Scenario: Country list displays calling-code entries
- **WHEN** `CountryListView` is presented
- **THEN** each entry SHALL display a flag emoji, a display name, and the calling code (e.g. "🇮🇱 Israel +972"); entries for shared calling codes SHALL display a grouped name (e.g. "🌎 North America +1")

#### Scenario: User selects a country
- **WHEN** the user taps an entry in `CountryListView`
- **THEN** a checkmark appears on the entry and the calling code is added to `selectedCountries` immediately — no Save button required

#### Scenario: User deselects a country
- **WHEN** the user taps a checked entry in `CountryListView`
- **THEN** the checkmark is removed and the calling code is removed from `selectedCountries` immediately

#### Scenario: User can search the country list
- **WHEN** the user types in the search field in `CountryListView`
- **THEN** the list filters to entries whose display name or calling code contains the search text

---

### Requirement: Disclosure row shows selection summary
The system SHALL display a tappable disclosure row directly below the rule toggle row when the rule is enabled. The row SHALL show a human-readable summary of the currently selected countries.

#### Scenario: Countries are selected
- **WHEN** one or more countries are selected
- **THEN** the disclosure row shows a comma-separated list of display names (truncated with "+ N more" if needed)

#### Scenario: No countries are selected
- **WHEN** the rule is enabled but no countries have been selected
- **THEN** the disclosure row shows a placeholder such as "No countries selected"

#### Scenario: Disclosure row is hidden when rule is off
- **WHEN** the rule toggle is off
- **THEN** the disclosure row SHALL NOT be visible

---

### Requirement: Sender country is detected from E.164 prefix
The system SHALL identify a sender's country by normalizing the raw sender string and performing a longest-prefix match against a hardcoded calling-code map defined in `CallingCodes.swift` (compiled into both app and extension targets).

#### Scenario: Sender in E.164 format is matched
- **WHEN** a sender string normalizes to a string starting with `+` and a prefix matches an entry in the calling-code map
- **THEN** the system identifies the sender's calling-code group using the longest matching prefix

#### Scenario: Sender with formatting characters is normalized
- **WHEN** a sender string contains spaces, dashes, parentheses, or dots alongside digits and a leading `+`
- **THEN** the system strips those characters before attempting prefix matching

#### Scenario: Sender without `+` prefix is skipped
- **WHEN** the normalized sender string does not start with `+` (alphanumeric, short code, or local-format number)
- **THEN** the rule is skipped entirely and evaluation falls through to the next rule

#### Scenario: Sender with unrecognized `+` prefix is skipped
- **WHEN** the sender starts with `+` but no prefix matches any entry in the calling-code map
- **THEN** the rule is skipped entirely and evaluation falls through to the next rule

---

### Requirement: Messages from non-allowed countries are blocked
The system SHALL block messages whose sender's detected calling-code group is not in the user's selected set, routing them to the junk folder.

#### Scenario: Sender is from an allowed country
- **WHEN** the rule is active, countries are selected, and the sender's calling code matches an entry in `selectedCountries`
- **THEN** the rule returns no result and evaluation continues to the next rule

#### Scenario: Sender is from a non-allowed country
- **WHEN** the rule is active, countries are selected, and the sender's calling code does not match any entry in `selectedCountries`
- **THEN** the system returns a `.junk` action with the rule name as the reason

---

### Requirement: Calling-code map handles shared calling codes as groups
The system SHALL group countries that share a calling code into a single `CallingCodeEntry`, preventing the user from being misled into thinking they can select individual countries within a shared-code region.

#### Scenario: NANP countries are presented as one group
- **WHEN** the country list is displayed
- **THEN** the US, Canada, and all other NANP nations sharing `+1` SHALL appear as a single entry (e.g. "North America (+1)"), never as separate countries

#### Scenario: Other shared-code countries are grouped
- **WHEN** the country list is displayed
- **THEN** any other calling codes shared by multiple nations (e.g. `+7` for Russia and Kazakhstan) SHALL appear as a single grouped entry

---

### Requirement: Country allowlist state syncs across devices
The system SHALL store both the enabled state and the selected country list in CoreData so they are synced to all the user's devices via CloudKit.

#### Scenario: Settings sync to another device
- **WHEN** the user enables the rule and selects countries on one device
- **THEN** the rule state and country selection appear on the user's other devices after CloudKit sync completes

#### Scenario: Schema migration preserves existing data
- **WHEN** the app is updated and the CoreData schema migrates from v3 to v4
- **THEN** existing `AutomaticFiltersRule` records are preserved with `selectedCountries` defaulting to nil, and no messages are accidentally blocked
