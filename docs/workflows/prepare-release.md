Prepare a release build: run the UI scenarios, bump version, update build number, archive, and open Xcode Organizer.

**Steps**

1. **Run the UI scenarios**

   Run every test in the `Scenario Tests` scheme through the Xcode MCP (`RunAllTests`, in the background) on the iPhone 18 Pro simulator, then on the iPad Pro 13-inch (M5) simulator. Never on a real device: check the run destination before each run.

   Report the counts from each run's `.xcresult`. If any test fails, stop: show the failures and don't change anything. A failure is a possible bug to report, never a reason to change the app or loosen the test.

2. **Read current version**

   Every target carries the app's version. List the targets with the Xcode MCP's `XcodeListTargets`, then read `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for each with `GetTargetBuildSettings`. Show the values.

   Parse the version into major, minor, and patch components.

3. **Ask for version bump**

   Use the **AskUserQuestion tool** to ask what version to release. Calculate the bumped values from the current version and present these options:

   - **Patch** (e.g., `X.Y.Z` → `X.Y.Z+1`)
   - **Minor** (e.g., `X.Y.Z` → `X.Y+1.0`)
   - **Major** (e.g., `X.Y.Z` → `X+1.0.0`)
   - User can also type a custom version via "Other"

   Show the current version in the question text so the user knows what they're bumping from.

4. **Confirm the change**

   Display a clear summary to the user:

   ```
   Current version: X.Y.Z → New version: A.B.C
   ```

   Ask for confirmation before proceeding. If the user declines, stop.

5. **Set MARKETING_VERSION**

   Set `MARKETING_VERSION` to the new version with the Xcode MCP's `UpdateTargetBuildSetting` on every target from step 2. Never edit `project.pbxproj` by hand.

   Verify with `GetTargetBuildSettings` that every target reports the new version.

6. **Generate and set CURRENT_PROJECT_VERSION**

   Generate a timestamp build number using the format `YYYYMMDDHHmm` (e.g., `202602171430`). Do NOT include seconds.

   Set `CURRENT_PROJECT_VERSION` to it with `UpdateTargetBuildSetting` on every target, then verify each with `GetTargetBuildSettings`.

7. **Archive the build**

   Use the build number generated in step 6 to create a unique archive name. The archive path format is:

   `~/Library/Developer/Xcode/Archives/YYYY-MM-DD/Simply Filter SMS <version> (<build>).xcarchive`

   For example: `Simply Filter SMS 2.2.0 (202602170118).xcarchive`

   Run `xcodebuild archive` via **Bash tool** with a 10-minute timeout. This is one of the two allowed uses of `xcodebuild` (see `docs/rules/XCODE_AND_TESTS.md`); the Xcode MCP has no archive action:

   ```bash
   xcodebuild archive \
     -project "Simply Filter SMS.xcodeproj" \
     -scheme "Simply Filter SMS" \
     -destination "generic/platform=iOS" \
     -archivePath "$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Simply Filter SMS <version> (<build>).xcarchive"
   ```

   Replace `<version>` and `<build>` with the actual values from earlier steps.

   If the archive fails, show the error output to the user and stop.

8. **Open Xcode Organizer**

   Run via **Bash tool**, using the same archive path from step 7:

   ```bash
   open "$HOME/Library/Developer/Xcode/Archives/YYYY-MM-DD/Simply Filter SMS <version> (<build>).xcarchive"
   ```

   This opens the archive in Xcode's Organizer window where the user can distribute to App Store Connect.

9. **Generate "What's New" text**

   Run `git log develop..HEAD --oneline` via **Bash tool** to get all commits on the current branch since it diverged from `develop`.

   Based on the commit messages, write a user-facing "What's New" summary for App Store Connect in **both English and Hebrew**. Guidelines:

   - Write from the user's perspective — focus on what changed for them, not internal/technical details.
   - Keep it concise: a short bullet list or 2-3 sentences.
   - Skip commits that are purely internal (planning, CI, refactoring) unless they resulted in a user-visible change.
   - Hebrew text should be natural, right-to-left friendly, and not a word-for-word translation.

10. **Show summary**

   Display a clear summary:

   ```
   ## Release Prepared

   **Version:** A.B.C
   **Build:** YYYYMMDDHHmm
   **Archive:** ~/Library/Developer/Xcode/Archives/YYYY-MM-DD/Simply Filter SMS A.B.C (YYYYMMDDHHmm).xcarchive

   Xcode Organizer is open — distribute to App Store Connect when ready.

   ---

   ### What's New (English)
   <english text>

   ### What's New (Hebrew)
   <hebrew text>
   ```

**Guardrails**
- Run the UI scenarios on iPhone and iPad first; a failure stops the release
- Always confirm version change before modifying files
- Set versions only through the Xcode MCP, on every target, and verify each after the change
- Use 10-minute timeout for the archive command
- If archive fails, do NOT retry — show the error and stop
- Do NOT commit or push — the user will do that after verifying
