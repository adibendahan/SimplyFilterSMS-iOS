### Requirement: Deterministic JSON encoding for cache comparison
The system SHALL produce identical encoded output for identical `AutomaticFilterListsResponse` content, regardless of dictionary iteration order.

#### Scenario: Same content encodes to same base64 string
- **WHEN** `AutomaticFilterListsResponse.encoded` is called multiple times on responses with identical `filterLists` content
- **THEN** the resulting base64 strings SHALL be identical every time

#### Scenario: Cache not marked stale for unchanged filters
- **WHEN** the fetched automatic filter list has the same content as the cached version
- **THEN** `isCacheStale(comparedTo:)` SHALL return `false`
- **AND** the `.automaticFiltersUpdated` notification SHALL NOT be posted
