## 1. FilterHitCounterService (Shared with Extension)

- [x] 1.1 Create `FilterHitCounterServiceProtocol` with `incrementCount(for filterID: String)` and `counts() -> [String: Int]` methods
- [x] 1.2 Create `FilterHitCounterService` implementing the protocol, reading/writing `filterHitCounts` key in the App Group `UserDefaults` suite (`kAppGroupName`)
- [x] 1.3 Add both files to the "Shared with Extension" folder and include them in both the main app and Message Filter Extension targets in Xcode

## 2. MessageEvaluationManager

- [x] 2.1 Add `var hitCounterService: FilterHitCounterServiceProtocol` property to `MessageEvaluationManager`, defaulting to `FilterHitCounterService()`
- [x] 2.2 In `runUserFilters`, after each successful `.deny` match, call `hitCounterService.incrementCount(for: filter.objectID.uriRepresentation().absoluteString)`
- [x] 2.3 In `runUserFilters`, after each successful `.denyLanguage` match, call `hitCounterService.incrementCount(for: filter.objectID.uriRepresentation().absoluteString)`
- [x] 2.4 Add `setHitCounterService(_ service: FilterHitCounterServiceProtocol)` method (mirroring `setLogger`) for test injection, or inject via initializer parameter with default value

## 3. AppManager Wiring

- [x] 3.1 Add `hitCounterService: FilterHitCounterServiceProtocol` to `AppManagerProtocol`
- [x] 3.2 Add `var hitCounterService: FilterHitCounterServiceProtocol` to `AppManager`, instantiated as `FilterHitCounterService()` in `init`
- [x] 3.3 Update `MockAppManager` (in `Tests/Mocks/`) to add a `hitCounterService` property using a mock implementation

## 4. FilterListView.ViewModel

- [x] 4.1 Add `@Published private(set) var hitCounts: [String: Int]` to `FilterListView.ViewModel`
- [x] 4.2 Populate `hitCounts` in `init` by calling `appManager.hitCounterService.counts()`
- [x] 4.3 Refresh `hitCounts` inside the existing `refresh()` method
- [x] 4.4 Subscribe to `UIApplication.willEnterForegroundNotification` in `init` (store cancellable) and call `refresh()` when received

## 5. FilterListRowView Display

- [x] 5.1 Pass the filter's hit count into `FilterListRowView.ViewModel` (add a `hitCount: Int` parameter)
- [x] 5.2 Update `FilterListView` to supply `hitCount: model.hitCounts[filter.objectID.uriRepresentation().absoluteString] ?? 0` when constructing each `FilterListRowView.ViewModel`
- [x] 5.3 In `FilterListRowView`, add a trailing secondary text label showing the hit count, visible only when `hitCount > 0` (e.g., `"42"` in `.secondary` foreground style)

## 6. Tests

- [x] 6.1 Add unit tests for `FilterHitCounterService`: first increment creates entry with count 1, subsequent increments accumulate, unrelated keys are unaffected
- [x] 6.2 Add unit tests for `MessageEvaluationManager` verifying that a deny-filter match calls `hitCounterService.incrementCount` and an allow match or no-match does not
- [x] 6.3 Verify `FilterListView.ViewModel.hitCounts` reflects the mock service's returned counts after `refresh()`
