# Testing

How tests are written here and the traps around them. The test names say what each test covers.

**Zero flaky or broken tests:** a failing test is fixed or deleted the day it's found, never documented as "known".

---

## Running

- Unit tests: the `Tests` target. Through Xcode's MCP, run the test classes with `RunSomeTests`; `RunAllTests` would also pick up the UI target.
- From the command line, use the `Tests` scheme. Running the app scheme's test action can fail to load an unsigned `Tests.xctest`.
- The UI target is not a test suite: it's the App Store screenshot generator, run only through Fastlane (`fastlane screenshots`, or the `iphone_` / `ipad_` lanes).

---

## Unit tests

- **One mock per protocol** in `Tests/Mocks/` (`mock_*`). Each method has a call counter and an optional closure for its result; `resetCounters()` clears them. Tests assert both the result and the call counts.
- `mock_PersistanceManager` and `mock_MessageEvaluationManager` wrap a real in-memory store, so tests can create real Core Data objects through `context`.
- **In-memory stores never sync** (`cloudKitContainerOptions = nil`). With CloudKit mirroring on, a save in an isolated test run throws `No eligible connection available`.
- `MessageEvaluationManagerTests` use `MessageEvaluationManager(inMemory: true)` and flush every entity before each test.
- `FilterListsFlowTests` is the one end-to-end AI Filtering test: real refresh, real store, real evaluation, with only the download mocked. It's what catches the refresh and the extension disagreeing on how lists are stored (e.g. their URL keys).
- `HTTPServiceTests` stub `URLSession.shared` with a `URLProtocol` that only answers `filters.example.com`, registered in `setUp` and removed in `tearDown`, so nothing else in the run is intercepted.

---

## Screenshots (UI target)

- `SnapshotsTestCase/testCreateSnapshots` walks the app and captures Fastlane screenshots. It's disabled in the test plan.
- The `-Testing` launch argument makes `AppManager` reset defaults and the store, seed empty AI lists for all 10 languages, and silence the inactivity notification ask.
- In the UI target, `~` loads strings from the **test bundle** for the current locale, not the app bundle.
- `forceTap()` taps by coordinate where `isHittable` is unreliable for some SwiftUI controls.
- On iPad, the flow skips back-button taps and swipes that split view doesn't need, and runs in landscape.
