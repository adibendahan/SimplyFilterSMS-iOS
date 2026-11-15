# Testing

How tests are written here and the traps around them. The test names say what each test covers.

**Zero flaky or broken tests:** a failing test is fixed or deleted the day it's found, never documented as "known".

---

## Running

- Unit tests: the `Tests` target, through the app scheme with Xcode's MCP.
- From the command line, use the `Tests` scheme. Running the app scheme's test action can fail to load an unsigned `Tests.xctest`.
- UI scenarios: the `Scenario Tests` scheme, only before a release or when asked.
- App Store screenshots: `./screenshots.sh`; `fastlane upload_screenshots` uploads `.screenshots/`.

---

## Unit tests

- **One mock per protocol** in `Tests/Mocks/` (`mock_*`). Each method has a call counter and an optional closure for its result; `resetCounters()` clears them. Tests assert both the result and the call counts.
- `mock_PersistenceManager` and `mock_MessageEvaluationManager` wrap a real in-memory store, so tests can create real Core Data objects through `context`.
- **In-memory stores never sync** (`cloudKitContainerOptions = nil`). With CloudKit mirroring on, a save in an isolated test run throws `No eligible connection available`.
- `MessageEvaluationManagerTests` use `MessageEvaluationManager(inMemory: true)` and flush every entity before each test.
- `FilterListsFlowTests` is the one end-to-end AI Filtering test: real refresh, real store, real evaluation, with only the download mocked. It's what catches the refresh and the extension disagreeing on how lists are stored (e.g. their URL keys).
- `HTTPServiceTests` stub `URLSession.shared` with a `URLProtocol` that only answers `filters.example.com`, registered in `setUp` and removed in `tearDown`, so nothing else in the run is intercepted.

---

## UI targets

- `UI Test Kit/` is compiled into `Scenario Tests` and `Screenshots Automation` (membership set by hand): identifiers, waits, the launch, the shared `Screen` moves and the menu items. Each target keeps its own screens.
- The `-Testing` launch argument makes `AppManager` reset defaults and the store, seed empty AI lists for all 10 languages, and silence the inactivity notification ask.
- **iOS 27 drops identifiers on submenu items:** `openFilterTool` taps the item's SF Symbol (`FilterTool`), which keeps its identifier and works in every language.
- A SwiftUI `Toggle` is a `Switch` containing an unlabeled `Switch`: count switches by identifier, never with `app.switches.count`.
- SwiftUI lists don't create off-screen rows; an element below the fold doesn't exist until it's scrolled to.

## Screenshots (`Screenshots Automation`)

- `./screenshots.sh` sets each simulator's **system** language and reboots it, so the status bar and right-to-left layout match a real device. An app-only language (`-AppleLanguages`, test plan languages) leaves the status bar left-to-right.
- One test per shot in `AppStoreShots`, each from a fresh launch with `-Testing -ScreenshotData`, finding elements by identifier only: the shots run in 11 languages. A new shot is a test, a `Shot` case and a row in the script's `SHOTS`.
- `-ScreenshotData` (debug only) loads the sample data, downloads the production catalog and drops every toast. The seeded lists are marked a week old, or the download is skipped as already done today.
- Shot 09 subscribes to two made-up lists per language from `simply-filter-sms/screenshots/<language>/` on S3, rebuilt from `screenshot-data/`.
- The keyboard closes with Return (`"\n"`); tapping elsewhere doesn't.
- iPadOS 26+ simulators start in windowed mode (a resize grabber, the app name in the status bar). The script turns off `SBChamoisWindowingEnabled` and `SBMedusaMultitaskingEnabled` on the iPad.
- `simctl status_bar --time` takes a date only as ISO with milliseconds, and the weekday shown is always the day of the run.
