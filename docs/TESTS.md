# Testing

How tests are written here and the traps around them. The test names say what each test covers.

**Zero flaky or broken tests:** a failing test is fixed or deleted the day it's found, never documented as "known".

---

## Running

- Unit tests: the `Tests` target, through the app scheme with Xcode's MCP.
- From the command line, use the `Tests` scheme. Running the app scheme's test action can fail to load an unsigned `Tests.xctest`.
- UI scenarios: the `Scenario Tests` scheme, only before a release or when asked.
- App Store screenshots: `Extras/screenshots.sh` writes to `Extras/Screenshots/<version>/`; `fastlane upload_screenshots path:Extras/Screenshots/<version>` uploads it.

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

- **Temporary workaround, re-check on every new Xcode:** XCUITest captures the unfolded iPhone Duo one pixel short (2852 × 2006, Xcode 27.2), while App Store Connect requires exactly 2853 × 2007, so `ShotDevice.stretchedPixelSize` stretches it. After each Xcode update, run one unfolded Duo shot with the stretch removed; once it comes out 2853 × 2007, delete the stretch.
- `Extras/screenshots.sh` sets each simulator's **system** language and reboots it, so the status bar and right-to-left layout match a real device. An app-only language (`-AppleLanguages`, test plan languages) leaves the status bar left-to-right.
- One test per shot in `AppStoreShots`, each from a fresh launch with `-Testing -ScreenshotData`, finding elements by identifier only: the shots run in 11 languages. A new shot is a test, a `Shot` case and a row in the script's `SHOTS`.
- `-ScreenshotData` (debug only) loads the sample data, downloads the production catalog and drops every toast. The seeded lists are marked a week old, or the download is skipped as already done today.
- Shot 09 subscribes to two made-up lists per language from `simply-filter-sms/screenshots/<language>/` on S3, rebuilt from `Extras/test-data/screenshots/`.
- The keyboard closes with Return (`"\n"`); tapping elsewhere doesn't.
- iPadOS 26+ simulators start in windowed mode (a resize grabber, the app name in the status bar). The script turns off `SBChamoisWindowingEnabled` and `SBMedusaMultitaskingEnabled` on the iPad.
- Never pass a date to `simctl status_bar --time`: the status bar then shows that date in English in every language, and it sticks until `status_bar clear`. The script clears it and sets only `9:41`, so the date is the day of the run, in the simulator's language.
- On the iPad simulator, `app.keyboards` doesn't see the on-screen keyboard. Close it by pressing Return in the focused field and checking the field lost focus (`hideKeyboard(from:)`), never by looking for the keyboard.
- A tap that lands while a view animates in can be dropped and leave the field without focus. `type(_:into:)` waits for focus and taps again; on Test Your Filters, wait for the verdict before moving to the next field.
- The iPad simulator sometimes never reports the app idle while the keyboard is up, and every such step then waits 60 seconds. That's why a shot is allowed 5 minutes.
