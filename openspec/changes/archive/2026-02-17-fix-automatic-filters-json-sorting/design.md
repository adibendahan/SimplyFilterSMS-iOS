## Context

`AutomaticFilterListsResponse.encoded` uses a plain `JSONEncoder()` to serialize a struct containing `filterLists: [String: LanguageFilterListResponse]`. Swift dictionaries have no guaranteed iteration order, so each encoding can produce different JSON byte sequences for identical content. The resulting base64 string is used for cache staleness comparison in `PersistanceManager.isCacheStale(comparedTo:)` and in `test_saveCache`.

## Goals / Non-Goals

**Goals:**
- Ensure `AutomaticFilterListsResponse.encoded` produces deterministic output for identical content
- Fix `test_saveCache` flakiness
- Eliminate false `.automaticFiltersUpdated` notifications

**Non-Goals:**
- Changing the cache comparison strategy (e.g., switching to hash-based or decoded comparison)
- Modifying the `LanguageFilterListResponse` arrays or their ordering
- Altering the CoreData model or CloudKit sync behavior

## Decisions

**Use `JSONEncoder.OutputFormatting.sortedKeys`**

`JSONEncoder` supports a `.sortedKeys` output formatting option (available since iOS 11) that sorts dictionary keys alphabetically before encoding. This is the simplest fix — a one-line change to the `encoded` computed property.

Alternatives considered:
- **Custom `Encodable` with sorted keys:** Manually encode `filterLists` by sorting keys in a custom `encode(to:)`. More code, same result, unnecessary complexity.
- **Hash-based comparison instead of string comparison:** Change `isCacheStale` to decode and compare semantically. More robust but a larger change, and `.sortedKeys` is sufficient since the array contents within each language list come from a fixed S3 source in consistent order.
- **Sort arrays too:** The `allowSenders`, `allowBody`, `denySender`, `denyBody` arrays come from S3 in a stable order. Sorting them would add safety but is unnecessary overhead for this fix.

## Risks / Trade-offs

- **Minimal performance impact** — `.sortedKeys` adds a dictionary key sort during encoding. The `filterLists` dictionary is small (a handful of language keys), so the overhead is negligible.
- **Existing cached data** — Users with an existing cache will see a one-time "filters updated" notification on the first launch after this fix, because the newly sorted encoding will differ from the previously unsorted cached string. After that, comparisons become stable. This is acceptable since it's a one-time occurrence and the notification is informational, not disruptive.
