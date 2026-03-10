## Why

Users have no visibility into which of their filters are actually working. Adding hit counters lets users see at a glance which filters are active and which may be redundant, making the filter list more informative and actionable.

## What Changes

- `MessageEvaluationManager` increments a per-filter counter in the shared App Group `UserDefaults` whenever a user-defined filter matches an incoming message in the extension
- A new `FilterHitCounterService` encapsulates read/write access to the shared `[String: Int]` dictionary keyed by filter object ID URI string
- `FilterListView` displays each filter's hit count inline (e.g., a badge or secondary label), reading counts from the service via the ViewModel
- No CoreData writes occur in the extension — counts live entirely in `UserDefaults`
- No CloudKit sync for counts (acceptable tradeoff; counts are per-device)

## Capabilities

### New Capabilities
- `filter-hit-counters`: Per-filter match count tracking stored in shared UserDefaults, surfaced in FilterListView

### Modified Capabilities
*(none — no existing spec-level behavior changes)*

## Impact

- **`MessageEvaluationManager`**: Gains a `FilterHitCounterService` dependency; writes a count increment after a filter match
- **`FilterListView` / `FilterListView.ViewModel`**: Reads hit counts from the service and exposes them for display
- **App Group UserDefaults** (`group.com.grizz.apps.dev.simply-filter-sms`): New key `filterHitCounts` storing `[String: Int]`
- **Extension target**: No new entitlements needed (App Group already in use for CoreData)
- **No new CoreData model version** required
