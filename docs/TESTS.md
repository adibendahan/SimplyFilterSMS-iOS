# Testing

How tests are written here and the traps around them. The test names say what each test covers.

**Zero flaky or broken tests:** a failing test is fixed or deleted the day it's found, never documented as "known".

---

## Running

- Unit tests: the `Tests` target, through the app scheme with Xcode's MCP.
- From the command line, use the `Tests` scheme. Running the app scheme's test action can fail to load an unsigned `Tests.xctest`.
- UI scenarios: the `Scenario Tests` scheme, only before a release or when asked.
- App Store screenshots: `Extras/screenshots.sh` captures to `Extras/Screenshots/<version>/`, `Extras/store-screenshots.sh` frames them into `Extras/Screenshots/<version>-store/`, and `cd Extras && fastlane upload_screenshots path:Screenshots/<version>-store` uploads the framed set (fastlane runs from `Extras/`, where its folder is). Upload the `-store` folder, never the raw captures.
- **Apple's device frames are never committed.** Their license forbids redistributing them and the repo is public: they live in the git-ignored `Extras/local/bezels/` (`store-screenshots.sh --list` names the files). Apple's marketing guidelines require them as-is: no added shadow, reflection or tint.
- Each frame's screen opening is exactly the capture's size, and `frame.html`'s `screenOrigin` and `screenRadii` are measured from the frame's transparent pixels. A new frame is measured the same way; a guessed radius lets the background or the capture's corners show around the screen.

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
- `-DebugData` (with `-Testing`) also loads the debug data set (`DebugDataManager`) without the screenshot setup. Scenarios that only need existing filters launch with it (`startingData: .debug`) instead of adding them through the UI.
- **iOS 27 drops identifiers on submenu items:** `openFilterTool` taps the item's SF Symbol (`FilterTool`), which keeps its identifier and works in every language.
- A SwiftUI `Toggle` is a `Switch` containing an unlabeled `Switch`: count switches by identifier, never with `app.switches.count`.
- SwiftUI lists don't create off-screen rows; an element below the fold doesn't exist until it's scrolled to.

## Screenshots (`Screenshots Automation`)

- **Temporary workaround, re-check on every new Xcode:** XCUITest captures the unfolded iPhone Duo one pixel short (2852 × 2006, Xcode 27.2), while App Store Connect requires exactly 2853 × 2007, so `ShotDevice.stretchedPixelSize` stretches it. After each Xcode update, run one unfolded Duo shot with the stretch removed; once it comes out 2853 × 2007, delete the stretch.
- `Extras/screenshots.sh` sets each simulator's **system** language and reboots it, so the status bar and right-to-left layout match a real device. An app-only language (`-AppleLanguages`, test plan languages) leaves the status bar left-to-right.
- One test per shot in `AppStoreShots`, each from a fresh launch with `-Testing -ScreenshotData`, finding elements by identifier only: the shots run in 11 languages. A new shot is a test, a `Shot` case and a row in the script's `SHOTS`.
- `-ScreenshotData` (debug only) loads the sample data, downloads the production catalog and drops every toast. The seeded lists are marked a week old, or the download is skipped as already done today. Without the fed lists, the seeded AI lists are empty, so a shot of them waits for the download, or it shows no rule counts.
- The test itself writes each shot to the folder in `SCREENSHOT_DELIVERY_FOLDER` (passed as `TEST_RUNNER_SCREENSHOT_DELIVERY_FOLDER`), only after the test passes; run without it, a shot exists only as an `.xcresult` attachment.
- The script downloads the production catalog and its lists once per run and passes the folder as `TEST_RUNNER_SCREENSHOT_FILTER_LISTS`; the app seeds them instead of downloading. The script's `CATALOG_URL` must match `URL.filterListCatalogURL`.
- Shot 09 subscribes to two made-up lists per language from `simply-filter-sms/screenshots/<language>/` on S3, rebuilt from `Extras/test-data/screenshots/`.
- The keyboard closes with Return (`"\n"`); tapping elsewhere doesn't.
- iPadOS 26+ simulators start in windowed mode (a resize grabber, the app name in the status bar). The script turns off `SBChamoisWindowingEnabled` and `SBMedusaMultitaskingEnabled` on the iPad.
- Never pass a date to `simctl status_bar --time`: the status bar then shows that date in English in every language, and it sticks until `status_bar clear`. The script clears it and sets only `9:41`, so the date is the day of the run, in the simulator's language.
- On the iPad simulator, `app.keyboards` doesn't see the on-screen keyboard. Close it by pressing Return in the focused field and checking the field lost focus (`hideKeyboard(from:)`), never by looking for the keyboard.
- A tap that lands while a view animates in can be dropped and leave the field without focus. `type(_:into:)` waits for focus and taps again; on Test Your Filters, wait for the verdict before moving to the next field.
- On the iPad, a field that still has focus when its sheet scrolls it out of view keeps the app from ever reporting idle, and every later step waits 60 seconds. Subscribe from URL does this once the list loads, so shot 09 types the address with Return (`url + "\n"`) to drop focus first.
- **The iPhone Duo is never rotated.** Its orientation follows the folded phone, and unfolding opens it sideways like a book: folded gives the outer display tall (1398 × 2034), unfolded gives the inner display wide (2853 × 2007) with the sidebar beside the detail. Unfolded "landscape" makes the inner display tall and hides the sidebar.
- **Only `hinge` folds the Duo** (Homebrew `artemnovichkov/tap/hinge`). Nothing in `simctl`, `devicectl` or XCUITest can. It sends Device Hub's private hinge event, so an Xcode update can break it; check one fold after each update. The script folds only between two test runs, never mid-run.
- **A Duo reboot resets it:** it always boots folded, and its displays get new IDs. Pick a display by size or through `hinge posture`, never by a stored ID.
- On the unfolded Duo, `XCUIScreen.main` is the outer display, black while unfolded. The shot comes from the largest `XCUIScreen` instead.
- The Duo's runtime is its own build (`iOS-27-2-iPhone19-4`), so a runtime lookup by plain iOS version skips it; each device row in the script says how its runtime is found.
- fastlane 2.241.2 uploads both Duo sizes under one display type, `APP_IPHONE_DUO`. Not yet checked: that App Store Connect sorts them into its outer and inner categories.
- On the iPhone Duo, gestures at screen coordinates (`app.coordinate(…)`, `app.swipeUp()`) go to the folded display even while it's unfolded, and do nothing. Gesture on an element instead. Both Duo displays are short enough that Home's lower links are off screen: reach them with `reveal(_:)`, which swipes the Home list itself along its left margin. An element's own `swipeUp()` starts below its center, which lands on the short-sender row's "Change" button in some languages; that button takes the drag and the list never scrolls.
