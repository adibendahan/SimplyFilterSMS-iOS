## ADDED Requirements

### Requirement: Regex matching option available
The system SHALL provide a "Regex" option in the filter matching picker (`FilterMatching.regex`, raw value `2`) alongside the existing "Contains" and "Exact" options.

#### Scenario: Regex appears in matching picker
- **WHEN** the user opens `AddFilterView` and expands advanced options
- **THEN** the matching picker displays three options: Contains, Exact, and Regex

#### Scenario: Regex option available for both deny and allow filter types
- **WHEN** the user opens `AddFilterView` for a deny filter
- **THEN** the Regex option is available in the matching picker
- **WHEN** the user opens `AddFilterView` for an allow filter
- **THEN** the Regex option is available in the matching picker

---

### Requirement: Case picker hidden for regex
The system SHALL hide the Case (case sensitivity) picker when `FilterMatching.regex` is selected, as case sensitivity is expressed directly in the pattern (e.g., `(?i)`).

#### Scenario: Case picker hidden when regex selected
- **WHEN** the user selects "Regex" in the matching picker
- **THEN** the Case picker is no longer visible

#### Scenario: Case picker visible for non-regex modes
- **WHEN** the user selects "Contains" or "Exact" in the matching picker
- **THEN** the Case picker is visible

---

### Requirement: Regex filter evaluation
The system SHALL evaluate regex-typed filters using Swift `Regex`. A message matches if the pattern produces at least one match anywhere in the evaluated string (sender or body, per `FilterTarget`). The evaluation string is NOT pre-lowercased; case sensitivity is controlled by the pattern itself.

#### Scenario: Pattern matches message body
- **WHEN** a deny filter has matching `.regex` and pattern `\d{5}`
- **THEN** a message body containing "Your code is 12345" is classified as junk

#### Scenario: Pattern does not match message body
- **WHEN** a deny filter has matching `.regex` and pattern `\d{5}`
- **THEN** a message body containing "Hello world" is NOT matched

#### Scenario: Invalid pattern at evaluation time returns no match
- **WHEN** a filter exists with matching `.regex` and a syntactically invalid pattern
- **THEN** the filter does not match any message (evaluates as false)

#### Scenario: Case-sensitive match respects pattern
- **WHEN** a deny filter has matching `.regex` and pattern `[A-Z]{3}` (no `(?i)`)
- **THEN** a message body "ABC" matches but "abc" does not

#### Scenario: Case-insensitive match via inline flag
- **WHEN** a deny filter has matching `.regex` and pattern `(?i)[a-z]{3}`
- **THEN** both "abc" and "ABC" match

#### Scenario: Regex evaluation precedes lowercasing
- **WHEN** a regex filter is evaluated
- **THEN** the message string is passed to `Regex` without pre-lowercasing

---

### Requirement: Invalid regex blocked at save time
The system SHALL prevent the user from saving a filter whose text is not a valid Swift `Regex` pattern when matching is set to `.regex`.

#### Scenario: Add button disabled for invalid pattern
- **WHEN** the user enters an invalid regex pattern (e.g., `[unclosed`)
- **THEN** the Add button is disabled

#### Scenario: Add button enabled for valid pattern
- **WHEN** the user enters a valid regex pattern (e.g., `\d+`)
- **THEN** the Add button is enabled (assuming no duplicate)

#### Scenario: Inline error shown for invalid pattern
- **WHEN** the user has selected regex matching, entered a non-empty pattern, and the pattern is invalid
- **THEN** an inline error badge is shown next to the text field

#### Scenario: No error shown for valid pattern
- **WHEN** the pattern is valid
- **THEN** no error badge is shown

#### Scenario: No error shown for empty field
- **WHEN** the pattern field is empty and regex is selected
- **THEN** no error badge is shown (length guard handles the empty state)

---

### Requirement: Inline live-preview test field
The system SHALL display a "Test text" input field in the expanded section of `AddFilterView` when `FilterMatching.regex` is selected. As the user types in both the pattern and the test field, the system SHALL show a real-time match indicator.

#### Scenario: Test field appears when regex selected
- **WHEN** the user selects "Regex" in the matching picker and the advanced section is expanded
- **THEN** a "Test text" field is visible

#### Scenario: Test field hidden for non-regex modes
- **WHEN** the user selects "Contains" or "Exact"
- **THEN** no "Test text" field is shown

#### Scenario: Green indicator on match
- **WHEN** the pattern is valid and the test text matches the pattern
- **THEN** a green checkmark indicator is shown next to the test field

#### Scenario: Red indicator on no match
- **WHEN** the pattern is valid and the test text does not match the pattern
- **THEN** a red X indicator is shown next to the test field

#### Scenario: No indicator when test field is empty
- **WHEN** the test field is empty
- **THEN** no match indicator is shown

#### Scenario: No indicator when pattern is invalid
- **WHEN** the pattern is invalid
- **THEN** no match indicator is shown (the invalid-pattern error badge handles feedback)

---

### Requirement: Regex filters persist without migration
The system SHALL store regex filters in CoreData using `FilterMatching` raw value `2`. No CoreData model migration is required.

#### Scenario: Regex filter survives app restart
- **WHEN** the user saves a regex filter and restarts the app
- **THEN** the filter is still present with matching type Regex

#### Scenario: Regex filter syncs via CloudKit
- **WHEN** the user saves a regex filter on one device
- **THEN** the filter appears on other signed-in devices with matching type Regex

---

### Requirement: Regex filters included in duplicate detection
The system SHALL consider two filters duplicates if they have the same text, target, matching type (`.regex`), and case setting. Since FilterCase is hidden for regex, two regex filters with the same pattern and target are always duplicates.

#### Scenario: Duplicate regex filter blocked
- **WHEN** a regex filter with pattern `\d+` and target "Body" already exists
- **THEN** saving another filter with pattern `\d+`, target "Body", and matching Regex is blocked
