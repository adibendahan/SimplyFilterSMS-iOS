## Why

The `AutomaticFilterListsResponse.encoded` property produces non-deterministic JSON because `filterLists` is a `[String: LanguageFilterListResponse]` dictionary with no guaranteed key ordering. Each call to `JSONEncoder().encode()` can produce different byte sequences for identical content. This causes two problems:

1. **False "filters updated" notifications** — `PersistanceManager.isCacheStale(comparedTo:)` compares base64-encoded strings, so different key ordering makes identical content appear stale, triggering spurious `.automaticFiltersUpdated` notifications to the user.
2. **Flaky test** — `test_saveCache` compares base64-encoded strings directly, failing intermittently due to key ordering non-determinism.

## What Changes

- Sort the JSON output deterministically in `AutomaticFilterListsResponse.encoded` by using `JSONEncoder.OutputFormatting.sortedKeys`, ensuring identical content always produces identical base64 strings.
- No behavioral change to filtering logic, UI, or data model.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

_(none — this is an implementation-level fix to encoding determinism, not a spec-level behavior change)_

## Impact

- **`Simply Filter SMS/Services Layer/Responses/AutomaticFilterListsResponse.swift`** — `encoded` computed property: add `.sortedKeys` to the encoder.
- **`Simply Filter SMS/Framework Layer/Managers/PersistanceManager.swift`** — `isCacheStale(comparedTo:)`: no code change needed, but behavior improves (fewer false positives).
- **`Tests/PersistanceManagerTests.swift`** — `test_saveCache` becomes reliable.
- **User-facing:** Eliminates spurious "Automatic filters updated" toast notifications.
