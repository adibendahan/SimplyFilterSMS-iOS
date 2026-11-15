# UI Test Suite Plan

A UI suite that walks the flows a user depends on, end to end through the screens. Logic stays in unit tests; UI tests prove the screens wire it up.

## Status (2026-11-15)

Done: each test passes on iPhone 18 Pro and iPad Pro 13-inch (M5), iOS 27.2, and was seen failing once against a deliberate break (reverted right after).

| Test | Features working together | Break that made it fail |
|---|---|---|
| `FilterScenarios/testAllowedSenderPassesWhenAllUnknownSendersAreBlocked` | Block all unknown + allow filter on the sender + Filter Tester | filter target saved as All |
| `FilterScenarios/testDenyFilterSendsMatchingMessagesToItsFolderUntilDeleted` | deny filter folder + case sensitivity + swipe delete | folder saved as Junk |
| `SmartFilterScenarios/testSmartFiltersJunkOnlyWhatTheyTarget` | links, numbers only, emojis on and off | toggle not saved |
| `AIFilteringScenarios/testLanguageListAppliesItsRulesOnlyWhileTheLanguageIsOn` | test catalog download + language toggle + deny, regex folder, allow | production catalog |
| `CommunityListScenarios/testCuratedAndSubscribedListsFilterUntilRemoved` | curated list on + Subscribe from URL + swipe remove | removal not deleting |
| `CommunityListScenarios/testSubscribeRefusesAFileThatIsNotAFilterListUntilTheLinkIsFixed` | link validation + recovery | (validation path; not broken separately) |
| `FilterTransferScenarios/testExportedFiltersComeBackWithTheirOptionsAfterImport` | export + Save to Files + delete + import from Files | export drops case |

Not done: Tip Jar, relaunch persistence (`-KeepData` was written and removed again unused), first run, Home counts.

**Layout:** the suite is its own target, `Scenario Tests`, with its own scheme of the same name. It shares nothing with the screenshot target and scheme, `Screenshots Automation`.
- `Support/`: `ScenarioTestCase` (`launchApp(remoteLists:)`), `SimplyFilterApp` (one property per screen, plus `expect(_:toBe:)`), `Screen` (the shared moves), `XCUIElementQuery+TestIdentifier` (`app.buttons[.addFilterButton]`), `Vocabulary` (`Message`, `Verdict`, `SmartFilter`, `Language`, the Add Filter options, `TestLists`).
- `Screens/`: one type per app screen. Every action starts on Home and ends on Home, and runs as a named step in the test report.
- `Scenarios/`: the tests, written only against `SimplyFilterApp`.

**Traps found while building:**
- The Xcode MCP can't set a UI test target's Target Application (`TEST_TARGET_NAME` is rejected) or add a target dependency. The suite launches the app by bundle identifier, and the `Scenario Tests` scheme builds the app and installs it before testing (checked by removing the app from the simulator first). Setting Target Application in Xcode would make this explicit.
- The only app file the target compiles is `SharedUITestsHelpers.swift`, for `TestIdentifier` (membership ticked by hand in Xcode). `Vocabulary` repeats the English labels the tests tap. The app is launched with `-AppleLanguages (en)`, so the labels hold whatever the simulator's language. A reworded label fails the test that taps it.
- The Filter Tester updates its result 1 s after the last keystroke, so the result for the body alone can show before the sender is typed. A verdict counts only if it's still there 1.5 s after it appears.
- iOS 27 drops identifiers on submenu buttons (known). Submenu items are tapped by their English label ("Test Your Filters", "Export Filters").
- `XCUIApplication.open(_:)` relaunches the app, so a deep link can't be used mid-scenario.
- A SwiftUI `Toggle` row is a `Switch` containing a smaller `Switch` (the knob). Tap the inner one; a coordinate near the trailing edge misses on iPad.
- `wait(for:toEqual:timeout:)` fails immediately on an element that doesn't exist yet; `waitForExistence` first.
- The swipe-to-delete button is a system "Delete" label outside the cell.
- Files: Save to Files uses `DOCPicker.filenameTextField` and `DOCPicker.actionButton`; the import picker's cells have `identifier` "`<name>.sfsfilters, sfsfilters`". Exports are saved under a unique name per run, so files left in "On My iPhone" never collide. On iPad, Save must be hittable before the tap.
- A Community List file needs `name`, `description`, `author`, an https `homepage` and `locale`, or the preview refuses it.

**Ground rule:** app behavior is never changed to make a failing test pass. A test that fails on correct-looking code is reported to the maintainer as a possible bug, with the failure and the screen state; the test is fixed only if the test itself is wrong. Test-only launch arguments (below) are allowed; they never change what a user sees.

---

## Scope

**In:** what the user does in the app and what they see as a result, against seeded test data on S3.

**Out:**
- Real message filtering by iOS. The extension can't be driven from a UI test; the Filter Tester runs the same evaluation in the app.
- Report Message. It posts to the live backend, which writes to DynamoDB.
- Help, About, accent color.

---

## Test data

- **S3 path:** `grizz-apps-dev/simply-filter-sms/ui-tests/`. Test data only, never user data: the bucket is world-readable.
- **Source in the repo:** `ui-test-data/`, committed (unlike `ai/`), so the files on S3 can always be rebuilt and reviewed.
- **Contents:**
  - `catalog.json`: catalog version 2, shaped like `4.0.0/catalog.json`, listing only test lists.
  - `ai-en.sfsfilters`, `ai-he.sfsfilters`: AI Filtering lists with a few known records each: a deny on the body, an allow on the sender, one regex.
  - Two curated Community Lists in the catalog with known names: one deny list, one allow list.
  - `subscribe.sfsfilters`: a list that isn't in the catalog, for Subscribe from URL.
  - `invalid.sfsfilters`: a file the app must refuse, for the error case.
- Every record and expected verdict is listed in `ui-test-data/README.md`, so a test's expectation can be traced to the record that causes it.
- Lists are uploaded before the catalog that points to them.

**Wiring:** a DEBUG-only `-UITestData` launch argument, passed by the new suites with `-Testing`:
- `URL.filterListCatalogURL` points to `ui-tests/catalog.json`. List URLs resolve against it, so they follow.
- `AppManager` still resets defaults and the store, but doesn't seed the empty AI lists.
- `FilterListManager.updateFilterListsWhenOnline()` runs the real refresh instead of skipping it.
- `-Testing` alone is unchanged, so the screenshot test keeps its current state.
- **Trap:** the switch lives in the app process only. The extension still reads the production catalog URL, so a message delivered to the extension during a UI test would be evaluated against lists keyed by the wrong URLs. Nothing in the suite does that; the Filter Tester evaluates in the app.

**Relaunch without reset:** a DEBUG-only `-KeepData` argument skips the reset, for the second launch of a persistence test.

---

## Suites

One app launch per test, from a fresh state: isolation is worth the run time. Identifiers only; no localized text typed or matched except screen titles through `~`.

### P1 — `FiltersTestCase` (the lists)
1. Add an allow filter → it's in the allow list. *(done)*
2. Add a deny filter with a folder → it's in the deny list with that folder.
3. Add a language filter → the language is in the language list.
4. A duplicate filter → the Add button is disabled and the duplicate badge shows.
5. An invalid regex → the Add button is disabled; a valid regex lands in the regex section.
6. Edit a filter's text inline → the new text is in the list after leaving the screen and coming back.
7. Swipe to delete → the filter is gone.
8. Edit mode, select several, delete → they're gone.

### P1 — `FilterTesterTestCase` (verdicts through the UI)
1. A deny filter on the body → the tester shows Junk.
2. The same deny filter plus an allow filter on the sender → Allowed (allow wins).
3. Each smart filter (links, numbers only, short sender, email, emojis) on → its message is Junk; off → Allowed.
4. Block all unknown senders on → the deny rows on Home are disabled and an unknown sender is Junk; an allowed sender still passes.
5. Country allowlist: pick a country → a sender from it passes, one from another country is Junk.

### P1 — `AIFilteringTestCase` (seeded lists)
1. The languages screen lists exactly the seeded languages.
2. Turn English on → after the refresh, Home shows AI Filtering on and the last-updated date.
3. English on → the seeded deny message is Junk, the seeded allow sender passes, the regex record matches.
4. English off → the same deny message is Allowed.
5. A user allow filter beats a seeded AI deny.

### P1 — `CommunityListsTestCase` (seeded catalog)
1. The screen shows the two seeded curated lists by name, both off.
2. Turn the seeded deny list on → its message is Junk in the Filter Tester, and Home's row shows it on.
3. Subscribe from URL with `subscribe.sfsfilters` → the preview shows its name and filter counts; Subscribe adds it to the screen.
4. Subscribe from `invalid.sfsfilters` and from a malformed link → the error (`communityListError`) shows and Subscribe stays disabled.
5. Swipe away a subscribed list → it's gone; a curated list can't be swiped away.

### P1 — `FilterTransferTestCase` (export and import round trip)
1. Add filters, export, Save to Files → the share sheet closes with the file saved.
2. Delete the filters, import that file from the Files picker → the preview lists them; confirming brings them back in their lists with their options.
3. Import a file with a filter that already exists → it isn't added twice.

### P2 — `TipJarTestCase` (simulator purchases, no real money)
1. Tip Jar shows the tip products.
2. Buy a tip → the thank-you state shows.

### P2 — `HomeTestCase`
1. The Home counts on the three filter rows change after adding and deleting.
2. Filters survive a relaunch (`-KeepData` on the second launch).

### P2 — `FirstRunTestCase`
1. First launch shows onboarding; dismissing it lands on Home and it doesn't come back on the next launch.

---

## Build order

1. **Helpers and identifiers.**
   - New tests use the element's own `tap()`, which waits and fails loudly. `TestApplication.tap(_:)` silently skips a missing button and stays for the screenshot test only; `forceTap()` only where a control is proven untappable.
   - A strict add-filter helper for tests: identifiers for each option, no sleeps, asserts the sheet closed. The screenshot helper `addFilter(...)` stays as is: its `label CONTAINS` taps can hit Home behind the sheet ("All" matches "Allow").
   - New `TestIdentifier` cases: each smart filter toggle (by `SmartFilterType`); the Filter Tester result with the verdict as its value; the filter list's Edit, menu and bulk delete buttons; each Add Filter option; each AI Filtering language toggle.
   - No fixed sleeps: wait on a state with `waitForExistence`, `waitForNonExistence`, `wait(for:toEqual:timeout:)`.
2. **`FiltersTestCase` and `FilterTesterTestCase`.** No network, no new launch arguments.
3. **Test data and `-UITestData`.** Write `ui-test-data/`, upload it, wire the argument, then `AIFilteringTestCase` and `CommunityListsTestCase`.
4. **One export/import round trip proven by hand-run first** (the share sheet and Files picker are system screens), then `FilterTransferTestCase`.
5. **`-KeepData`, then the P2 suites.**

Each test is seen failing once, by breaking the code it covers, before it's kept; the break is reverted right after.

---

## Running

- The shared `Scenario Tests` scheme runs the suite. Fastlane runs the screenshots through `Screenshots Automation`.
- iPhone simulator only at first (iPhone 18 Pro); iPad split view later as its own decision.
- About 35 tests at 15–25 s each, so a full run is 10–15 minutes: background run with a log, counts from the `.xcresult`.
- The AI and Community suites need S3. A failure names the URL it was loading, so a bug can be told from S3 being down.
- English only. The test bundle's `~` keeps titles correct in other languages, but other languages aren't part of the suite.

---

## Docs and rules to change when it lands

- `CLAUDE.md`, `docs/TESTS.md`, `docs/rules/XCODE_AND_TESTS.md`: they say `Screenshots Automation` is only the screenshot generator and must not be run as testing.
- `docs/TESTS.md`: how to run the UI suite, `-UITestData` and `-KeepData`, the identifier-only rule, the strict-tap rule, and the "seen failing once" rule.
- `docs/AWS_SETUP.md`: the `ui-tests/` path and that it's rebuilt from `ui-test-data/`.
