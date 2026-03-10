## Context

The app uses a three-layer clean architecture. The Message Filter Extension creates its own `MessageEvaluationManager` instance directly (not via `AppManager`), using a read-only CoreData store. The main app accesses managers through `AppManager.shared`. Both processes already share an App Group (`group.com.grizz.apps.dev.simply-filter-sms`) for CoreData/CloudKit syncing, so the shared `UserDefaults` suite requires no new entitlements.

Filters are identified by their CoreData `objectID.uriRepresentation().absoluteString` — stable for persisted objects across the lifetime of the device's store.

## Goals / Non-Goals

**Goals:**
- Increment a per-filter counter in shared `UserDefaults` when `runUserFilters` finds a match in the extension
- Expose counts to `FilterListView.ViewModel` for display
- Keep the service testable via a protocol

**Non-Goals:**
- Syncing counts to CloudKit or other devices
- Counting automatic-rule or language-filter matches
- Persisting counts across CoreData store migrations (counts orphan silently; acceptable)
- Resetting counts when a filter is deleted (stale key; acceptable)

## Decisions

### 1. New `FilterHitCounterService` in "Shared with Extension"

A dedicated `FilterHitCounterService` (+ `FilterHitCounterServiceProtocol`) is added to the `Simply Filter SMS/Framework Layer/Shared with Extension/` folder and compiled into both targets.

**Rationale**: The extension doesn't use `AppManager`, so any shared logic must live in the jointly-compiled source set. A service class keeps counter logic out of `MessageEvaluationManager` and makes it independently testable. A protocol makes it mockable.

**Alternative considered**: Embed counter logic directly in `MessageEvaluationManager`. Rejected — it conflates evaluation logic with persistence and makes testing harder.

**Interface:**
```swift
protocol FilterHitCounterServiceProtocol {
    func incrementCount(for filterID: String)
    func counts() -> [String: Int]
}

class FilterHitCounterService: FilterHitCounterServiceProtocol {
    private let defaults: UserDefaults
    private let key = "filterHitCounts"

    init(defaults: UserDefaults = UserDefaults(suiteName: kAppGroupName) ?? .standard) {
        self.defaults = defaults
    }

    func incrementCount(for filterID: String) {
        var current = defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
        current[filterID, default: 0] += 1
        defaults.set(current, forKey: key)
    }

    func counts() -> [String: Int] {
        return defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }
}
```

### 2. `MessageEvaluationManager` owns a `FilterHitCounterService` instance

`MessageEvaluationManager` gets a `hitCounterService: FilterHitCounterServiceProtocol` property, defaulting to `FilterHitCounterService()`. After `runUserFilters` finds a matching `.deny` or `.denyLanguage` filter, it calls `hitCounterService.incrementCount(for: filter.objectID.uriRepresentation().absoluteString)`.

**Rationale**: The extension doesn't go through `AppManager`, so injection at the manager level is the right seam. Using a default value keeps the existing `MessageFilterExtension` call site unchanged.

**Allow filters are NOT counted**: An allow match exits evaluation early and never reaches the counter call — intentional. Allow filters are not blockers and their hit count is less useful.

**Where in the call flow**: The increment happens inside `runUserFilters` immediately after `isMatching` returns `true`, before `break`. This is synchronous and non-blocking (a dictionary read + write to `UserDefaults`).

### 3. `FilterHitCounterService` added to `AppManager` / `AppManagerProtocol`

`AppManager` gains a `hitCounterService: FilterHitCounterServiceProtocol` property, wired up in `init`. `AppManagerProtocol` and the test mock are updated accordingly.

**Rationale**: `FilterListView.ViewModel` accesses all dependencies via `appManager`. Adding the service here follows the existing pattern.

### 4. `FilterListView.ViewModel` reads counts on `refresh()`

`ViewModel` gains a `@Published private(set) var hitCounts: [String: Int]` property, populated by calling `appManager.hitCounterService.counts()` in `init` and in `refresh()`.

The view retrieves a specific filter's count by: `model.hitCounts[filter.objectID.uriRepresentation().absoluteString] ?? 0`.

**Refresh on foreground**: The ViewModel subscribes to `UIApplication.willEnterForegroundNotification` in `init` using a `NotificationCenter` sink, calling `refresh()` so counts update when the user returns to the app after the extension has processed messages.

### 5. Display: secondary text in `FilterListRowView`

Hit count is shown as a small secondary label (e.g., `"42 hits"`) in the trailing area of each filter row, only when count > 0. Zero counts are hidden to keep the list clean for new users.

**Alternative considered**: SF Symbol badge. Rejected — harder to localize and less scannable for large numbers.

## Risks / Trade-offs

- **Stale keys on filter deletion**: Deleting a filter leaves its count key in `UserDefaults` indefinitely. The orphan dictionary entry is tiny (~50 bytes) and invisible to the user. → Acceptable; can be cleaned up in a future pass.
- **Lost increment on concurrent write**: If the extension and main app simultaneously read-modify-write the dictionary, one increment can be dropped. Given the app is typically in the background during extension execution, this is extremely rare. → Acceptable tradeoff vs. introducing a lock.
- **objectID URI instability after store re-creation**: If the user's CoreData store is deleted and rebuilt (e.g., after reinstall), all counts become orphaned. → Acceptable; counts are per-device and non-critical.
- **No iCloud backup by default**: `UserDefaults` in an App Group suite is **not** backed up to iCloud. Counts are lost on fresh device setup. → Documented in proposal as acceptable.

## Migration Plan

No migration needed. The `filterHitCounts` key is absent on first read; `FilterHitCounterService` treats a missing key as an empty dictionary. All existing installs upgrade transparently — counts start at zero and accumulate from the first extension invocation after update.

## Open Questions

*(none)*
