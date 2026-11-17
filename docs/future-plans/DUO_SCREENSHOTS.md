# iPhone Duo Screenshots

Add iPhone Duo shots to `Extras/screenshots.sh`: the folded (outer) display and the unfolded (inner) display, in every language.

## Why

- App Store Connect lists two iPhone Duo screenshot categories: outer 1398 × 2034 and inner 2007 × 2853, each in either orientation.
- From April 2027 they're required for apps built with the iOS 27.1 SDK or later. We build with 27.2.
- Submitting them shows a "made for iPhone Duo" badge on the product page.

## Decided

- **Outer (folded): portrait**, 1398 × 2034, the same shots and steps as iPhone, Home included.
- **Inner (unfolded): wide**, 2853 × 2007, the same shots and steps as iPad: Home is skipped and the sidebar sits next to the detail.
- **The phone is never rotated.** Its orientation follows the folded phone, and unfolding opens it sideways like a book. Held in portrait, folded shows the outer display tall and unfolded shows the inner display wide. "Landscape" while unfolded makes the inner display tall, which hides the sidebar.
- **Folding uses [hinge](https://github.com/artemnovichkov/hinge)** (Homebrew `artemnovichkov/tap/hinge`, MIT). Nothing in `simctl`, `devicectl` or XCUITest folds the Duo. `hinge` sends Device Hub's own hinge event from inside the simulator and waits until the phone reports the new angle. It's a private interface, verified here on Xcode 27.2 with the iOS 27.2 Duo runtime, and an Xcode update can break it.

## Verified by hand (2026-11-17)

- `hinge -d <udid> open` and `close` switch the active display within about a second. `hinge posture` reports which one is active.
- Fold state does not survive a reboot. A booted Duo always starts folded.
- After a reboot the displays get new IDs, so a display is chosen by size or by `hinge`, never by a stored ID.
- The status bar override works on the Duo.
- Capturing both displays with `simctl io <udid> screenshot --display=<id>` gives exactly Apple's sizes. This is not the XCUITest capture the script uses (see Open).

## Script

1. **A third device row, `duo`,** using the type `com.apple.CoreSimulator.SimDeviceType.iPhone-Duo`. Its runtime is a separate build, `com.apple.CoreSimulator.SimRuntime.iOS-27-2-iPhone19-4`. The current runtime lookup (`iOS-[0-9-]+$`) skips it, so each device row names how its runtime is found.
2. **Preflight:** when the Duo is selected, check that `hinge` is installed, and stop with the `brew install` line if not.
3. **Per language:** prepare and reboot the Duo like the other two. Then `hinge close`, run the outer shots, `hinge open`, run the inner shots. Two test runs per language for the Duo, each with its own result bundle, after the iPhone and iPad run. Whether it can run alongside that run is in Open.
4. **Device keys and files:** `duo-outer` and `duo-inner`, so the files are `duo-outer-01-home.png` … in the same language folder. `-d duo` captures both. `--list` shows them.
5. **Shot counts:** outer 9 and inner 8, checked per key like today.

## Tests (as built)

Departure from the first draft: no environment variable from the script. The tests tell the devices apart themselves.

- **Layout:** `XCUIApplication.hasWideWindow` (UI Test Kit). A wide window means the split layout (iPad in landscape, unfolded Duo): Home is skipped and `backToHome()` does nothing. It replaces `isPad`; the Scenario Tests behave as before.
- **File names:** `ShotDevice` (Screenshots Automation) reads the simulator model (`SIMULATOR_MODEL_IDENTIFIER` `iPhone19,4` is the Duo) and the window shape: `iphone`, `ipad`, `duo-outer`, `duo-inner`.
- **Capture:** on the unfolded Duo the shot comes from the largest `XCUIScreen` (`XCUIScreen.main` is the outer display, black while unfolded), redrawn upright at its exact pixel size.
- **Behind sheets:** in the split layout, Test Your Filters and Countries open AI Filtering in the detail pane first (`ScreenshotStudio.fillDetailPane()`).
- **One-pixel stretch:** see the temporary workaround in `docs/TESTS.md`.

## Open, to prove one case before building

- **Does `XCUIScreen.main.screenshot()` capture the active display on a Duo**, at the right size and the right way up? If not, `capture(_:)` picks the screen from `XCUIScreen.screens` by size. The iPad already needs an upright redraw, and the inner display may too.
- **Does the test runner survive a fold?** The plan avoids folding mid-run: each fold happens between two `xcodebuild` runs. If the app keeps a state from the previous run, the second run relaunches it anyway (`ScreenshotStudio` launches fresh).
- **Can the Duo runs overlap the iPhone and iPad run?** Running all three at once in one `xcodebuild` would need the fold to happen mid-run, so the Duo likely runs after them. That adds about two test runs per language to a full run.
- **The blank menu button in folded landscape** (`BUGS_AND_GAPS.md`) doesn't affect these shots, which are folded portrait.

## Uploading

fastlane 2.241.2 already maps 1398 × 2034 and 2853 × 2007 to its `APP_IPHONE_DUO` display type, so `upload_screenshots` needs no change. Not yet checked: how fastlane sends both Duo sizes under that one type, and how App Store Connect sorts them into its outer and inner categories.

## Order

1. Prove the capture on one shot: Countries on `duo-outer` and `duo-inner`, English.
2. Script: device row, runtime, `hinge` preflight, two Duo runs per language.
3. Tests: the device variable, the split-layout check, names.
4. One language end to end, then all 11.
5. `docs/TESTS.md`: the Duo traps (orientation follows the folded phone, fold state resets on boot, display IDs change on boot, `hinge` is required). Then delete this plan.
