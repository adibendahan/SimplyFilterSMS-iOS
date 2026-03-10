## ADDED Requirements

### Requirement: Filter hit counts are persisted in shared UserDefaults
The system SHALL store a `[String: Int]` dictionary under the key `filterHitCounts` in the App Group `UserDefaults` suite (`group.com.grizz.apps.dev.simply-filter-sms`). Each entry maps a filter's `objectID.uriRepresentation().absoluteString` to its total match count. This storage MUST be accessible from both the Message Filter Extension and the main app.

#### Scenario: Counter is initialised on first match
- **WHEN** a filter matches for the first time and no entry exists for its ID
- **THEN** the system SHALL write a count of `1` for that filter ID

#### Scenario: Counter increments on subsequent matches
- **WHEN** a filter that already has a stored count matches again
- **THEN** the system SHALL increment the existing count by `1`

#### Scenario: Other filters are unaffected
- **WHEN** filter A matches a message
- **THEN** the counts for all other filters SHALL remain unchanged

### Requirement: Extension increments counter after a filter match
When `MessageEvaluationManager` evaluates a message and a user-defined `Filter` entity matches — regardless of whether the action is allow, deny, or denyLanguage — the system SHALL increment that filter's hit count via `FilterHitCounterService`. The increment operation MUST NOT block the evaluation result or introduce observable latency.

#### Scenario: Matched deny filter count is incremented
- **WHEN** the extension evaluates a message and a deny filter matches
- **THEN** the system SHALL increment the matched filter's counter in shared UserDefaults

#### Scenario: Matched allow filter count is incremented
- **WHEN** the extension evaluates a message and an allow filter matches
- **THEN** the system SHALL increment the matched allow filter's counter in shared UserDefaults

#### Scenario: No match produces no counter change
- **WHEN** the extension evaluates a message and no user filter matches
- **THEN** no hit counters SHALL be modified

#### Scenario: Automatic-rule matches do not affect filter counters
- **WHEN** a message is blocked by an automatic rule (not a user-defined `Filter`)
- **THEN** no user filter hit counters SHALL be modified

### Requirement: Main app reads hit counts for display
The main app's `FilterListView.ViewModel` SHALL expose hit counts read from `FilterHitCounterService` so that each filter row can display how many times that filter has matched.

#### Scenario: Hit count visible for a filter with matches
- **WHEN** a filter has a stored count greater than zero
- **THEN** `FilterListView` SHALL display that count alongside the filter row

#### Scenario: Zero count for a filter with no matches
- **WHEN** a filter has no stored count (or a count of zero)
- **THEN** `FilterListView` SHALL display `0` (or omit the count — implementation choice)

#### Scenario: Counts refresh when app becomes active
- **WHEN** the user returns to `FilterListView` after the extension has processed messages
- **THEN** the displayed counts SHALL reflect the latest values from shared UserDefaults

### Requirement: Hit counts are not synced via CloudKit
Filter hit counts SHALL reside only in local `UserDefaults` and MUST NOT be written to CoreData or synced through CloudKit. Counts are per-device and intentionally ephemeral across device migrations.

#### Scenario: CoreData entities are not modified by the extension
- **WHEN** the extension increments a hit counter
- **THEN** no CoreData save or write SHALL occur in the extension process

#### Scenario: iCloud does not receive count data
- **WHEN** hit counts are updated
- **THEN** no CloudKit record SHALL be created or modified as a result
