# Xcode and Test Rules

- **Drive Xcode only through Apple's Xcode MCP.** Never shell out to `xcodebuild` and never hand-edit `project.pbxproj`. Open the workspace first (`XcodeOpenWorkspace`); create files with `XcodeWrite` so they join their targets, rename with `XcodeMV`, remove with `XcodeRM`. If the MCP isn't connected, stop and ask; don't fall back to `xcodebuild`.
- **Long runs go in the background** with a log, and progress is reported from that log. Never block silently in the foreground.
- **Never run tests on a real device.** Before any test run or build-for-testing, check the run destination and switch to a simulator.
- **Run unit tests with `RunSomeTests` on the `Tests` target.** Never run `UI Tests` as testing.
- **Report test counts from the run's `.xcresult`** (`xcrun xcresulttool get test-results summary --path <bundle>`), not the MCP summary, which lists stale renamed or deleted tests.
- **Never drive the simulator without approval.** No install, run, device-interaction session or tap-through agent unless approved for that change; end the session when the check is done. Report UI work as "builds, not seen on screen" and ask.
