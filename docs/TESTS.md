# Testing

Testing patterns, unit tests, UI tests, mocks, and test infrastructure.

---

## Test Structure

```
Tests/
├── MessageEvaluationManagerTests.swift   # Core filtering logic + hit counter integration
├── AutomaticFilterManagerTests.swift     # Cloud filter management
├── PersistanceManagerTests.swift         # CoreData operations
├── FilterListViewModelTests.swift        # ViewModel integration
├── FilterHitCounterServiceTests.swift    # Hit counter persistence
├── AmazonS3ServiceTests.swift            # HTTP service
└── Mocks/
    ├── mock_AppManager.swift
    ├── mock_PersistanceManager.swift
    ├── mock_MessageEvaluationManager.swift
    ├── mock_AutomaticFilterManager.swift
    ├── mock_DefaultsManager.swift
    ├── mock_NetworkSyncManager.swift
    ├── mock_AmazonS3Service.swift
    ├── mock_HTTPService.swift
    ├── mock_ReportMessageService.swift
    └── mock_FilterHitCounterService.swift

UI Tests/
├── ApplicationTestCase.swift             # Base XCTestCase
├── TestApplication.swift                 # XCUIApplication wrapper
├── SnapshotsTestCase.swift              # Full UI flow + screenshots (iPhone & iPad)
├── UITestsHelpers.swift                 # Localization + XCUIElement helpers
└── SnapshotHelper.swift                 # Fastlane snapshot integration

fastlane/
└── Fastfile                              # Screenshot lanes (iphone/ipad/both)
```

---

## Unit Tests

### MessageEvaluationManagerTests

**Tests:** `MessageEvaluationManager` — the core filtering engine.

**Setup:** In-memory CoreData (`MessageEvaluationManager(inMemory: true)`). Each test flushes all entities (`Filter`, `AutomaticFiltersCache`, `AutomaticFiltersLanguage`, `AutomaticFiltersRule`) and re-populates with specific test data.

**Test approach:** Uses a `MessageTestCase` struct with `sender`, `body`, `expectedAction` fields. Iterates over arrays of test cases and asserts each result.

**Coverage areas:**
- Allow/deny filter matching with various target/matching/case combinations
- Language detection and blocking (Hebrew, English, Arabic)
- Automatic filter lists (allow senders, deny body, etc.)
- Smart rules (links, numbers-only senders, short senders, emails, emojis, all-unknown)
- Priority ordering (allow takes precedence over deny)
- Edge cases (empty body/sender, combined targets)
- Hit counter incremented on allow match, deny match, and not incremented on no match

**Multi-language test data:** Tests include Hebrew, English, and Arabic text to verify NLLanguageRecognizer integration.

### AutomaticFilterManagerTests

**Tests:** `AutomaticFilterManager` — cloud filter management.

**Setup:** Mock dependencies (`mock_PersistanceManager`, `mock_AmazonS3Service`). Configures closures on mocks to return specific data for each test.

**Coverage areas:**
- `isAutomaticFilteringOn` — on/off states based on cache + language records
- `activeAutomaticFiltersTitle` — localized comma-separated language names
- `automaticFiltersCacheAge` — timestamp propagation
- `languages(for:)` — both `.blockLanguage` and `.automaticBlocking` modes
- Language state get/set with context commits
- Rule state get/set with `ensureAutomaticFiltersRuleRecord`
- `selectedChoice` get/set for configurable rules
- `forceUpdateAutomaticFilters` — async fetch + save cache flow

**Verifies call counts** on mocks to ensure correct manager interactions.

### PersistanceManagerTests

**Tests:** `PersistanceManager` — CoreData CRUD operations.

**Setup:** In-memory CoreData (`PersistanceManager(inMemory: true)`). Observes `NSManagedObjectContextDidSave` notifications to verify writes.

**Coverage areas:**
- Fetch all filters / fetch by type
- Fetch automatic filter language/rule/cache records
- Fetch single language/rule records
- `isDuplicateFilter` — false before add, true after
- Add filter (deny and allow) — verifies notification fires
- Delete filters by IndexSet and by Set
- Update filter properties (folder, matching, case, target, text)
- Save/update cache — hash, data, age verification
- `isCacheStale` — same data = false, different data = true

**Notification testing pattern:**
```swift
func expectingSaveContext() {
    let expectASave = expectation(description: "expectASave")
    waitForSavedNotification { _ in expectASave.fulfill() }
}
// Then: waitForExpectations(timeout: 1)
```

### FilterListViewModelTests

**Tests:** `FilterListView.ViewModel` — view model integration with mocked managers.

**Setup:** Injects `mock_AppManager` with mock sub-managers.

**Coverage:**
- `refresh()` — verifies it fetches records, checks allUnknown state, checks language availability, and reads hit counts
- `deleteFilters(withOffsets:)` — verifies PersistanceManager called + refresh
- `deleteFilters(_:)` — verifies PersistanceManager called + refresh

### FilterHitCounterServiceTests

**Tests:** `FilterHitCounterService` — App Group UserDefaults persistence for filter match counts.

**Setup:** Creates an in-memory `UserDefaults` suite with a unique `suiteName` per test. Tears down by calling `removePersistentDomain(forName:)`.

**Coverage:**
- `counts()` returns empty dictionary when no data stored
- First `incrementCount` writes a count of 1
- Subsequent increments accumulate correctly
- Incrementing one filter ID does not affect other filter IDs

### AmazonS3ServiceTests

**Tests:** `AmazonS3Service` — HTTP request construction.

**Setup:** Mock HTTP service (`mock_HTTPService`).

**Verifies:** Correct URL, path, HTTP method, response type, and request task type for the S3 fetch.

---

## Mock Pattern

All mocks follow a consistent pattern with three components:

### 1. Call Counters

Every method and property getter/setter has a counter:
```swift
var fetchFilterRecordsCounter = 0
var addFilterCounter = 0
var isAutomaticFilteringOnGetCounter = 0  // separate get/set for properties
var isAutomaticFilteringOnSetCounter = 0
```

### 2. Closure Injection

Each method has an optional closure for configuring return values:
```swift
var fetchFilterRecordsClosure: (() -> [Filter])?
var isDuplicateFilterClosure: ((String, FilterTarget, FilterMatching, FilterCase) -> Bool)?
```

### 3. Reset

All mocks have `resetCounters()` to clear state between tests:
```swift
func resetCounters() {
    fetchFilterRecordsCounter = 0
    addFilterCounter = 0
    // ... all counters
}
```

### Usage in Tests

```swift
// Arrange — configure mock behavior
persistanceManager.isDuplicateFilterClosure = { text, target, matching, filterCase in
    return true
}

// Act
let result = testSubject.isDuplicateFilter

// Assert — verify behavior AND call count
XCTAssertTrue(result)
XCTAssertEqual(persistanceManager.isDuplicateFilterCounter, 1)
```

### Mock-Specific Notes

- **mock_PersistanceManager** — Largest mock (~41 counters). Wraps a real in-memory `PersistanceManager` for `context` access, allowing tests to create real CoreData objects.
- **mock_MessageEvaluationManager** — Also wraps a real in-memory instance for `context`.
- **mock_HTTPService** — Uses type-switching in `execute()` to return appropriate mock responses based on the generic type parameter.
- **mock_AppManager** — Pre-populated with all mock sub-managers. Tests replace individual managers as needed.

---

## UI Tests

### Infrastructure

- **ApplicationTestCase** — Base `XCTestCase` with `continueAfterFailure = false` and a `sleep(seconds:)` helper using inverted expectations.
- **TestApplication** — `XCUIApplication` wrapper. Adds `-Testing` launch argument (triggers data reset in AppManager). Sets up Fastlane snapshots.

### Test Mode Detection

The app detects testing mode via:
```swift
// SharedUITestsHelpers.swift (DEBUG only)
extension UIApplication {
    var isInTestingMode: Bool {
        return ProcessInfo.processInfo.arguments.contains("-Testing")
    }
}
```

When detected, `AppManager.init()` resets `DefaultsManager` and `PersistanceManager` for a clean slate.

### TestApplication Helpers

| Method | Purpose |
|--------|---------|
| `dismissCallToActionViewIfPresented()` | Dismiss onboarding overlay |
| `addFilter(type:text:denyFolderType:filterTarget:filterMatching:filterCase:)` | Complete filter creation flow via UI |
| `button(_ id: TestIdentifier)` | Find button by accessibility ID |
| `textField(_ id: TestIdentifier)` | Find text field by accessibility ID |
| `tap(_ id: TestIdentifier)` | Tap element by accessibility ID |
| `assertLabel(of:contains:)` | Verify button label content |
| `buttonContaining(_ label: String)` | Find button by label predicate |
| `switchContaining(_ label: String)` | Find switch by label predicate |

### SnapshotsTestCase

Single test method `testCreateSnapshots()` that runs a full UI flow:

1. Enable English + Hebrew automatic language filters
2. Add a deny filter (language-specific test text)
3. Enable all smart rules + load debug data
4. Navigate through deny/allow/language filter lists
5. Test filters with a sample message ("Your Apple ID Code is: 444291...")
6. Capture Fastlane screenshots at each step

**iPad support:** Uses an `isPad` computed property to skip back-button taps and swipe gestures that aren't needed in split view. Sets `XCUIDevice.shared.orientation = .landscapeRight` before app launch for landscape screenshots.

### Localization in UI Tests

The `~` postfix operator is redefined in `UITestsHelpers.swift` to load strings from the test bundle (not the app bundle):
```swift
postfix func ~ (string: String) -> String {
    guard let path = Bundle(for: SnapshotsTestCase.self)
            .path(forResource: Locale.current.languageCode, ofType: "lproj"),
          let bundle = Bundle(path: path) else { return "?" }
    return NSLocalizedString(string, tableName: nil, bundle: bundle, value: "", comment: "")
}
```

Also extends to `NLLanguage`:
```swift
postfix func ~ (lang: NLLanguage) -> String {
    return Locale.current.localizedString(forIdentifier: lang.rawValue) ?? "ERROR"
}
```

### XCUIElement Extension

`forceTap()` — Taps by coordinate when `isHittable` is unreliable (common with certain SwiftUI controls).

---

## Running Tests

```bash
# Unit tests
xcodebuild -project "Simply Filter SMS.xcodeproj" -scheme "Simply Filter SMS" \
  -destination 'platform=iOS Simulator,name=iPhone 16' test

# App Store screenshots (via Fastlane — configured in fastlane/Fastfile)
fastlane iphone_screenshots        # iPhone only
fastlane ipad_screenshots          # iPad only (landscape)
fastlane screenshots               # Both iPhone + iPad
```
