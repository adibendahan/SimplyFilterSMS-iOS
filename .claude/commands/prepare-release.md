---
name: "Prepare Release"
description: Bump version & build number, archive, and open Xcode Organizer
category: Release
tags: [release, archive, version]
---

Prepare a release build: bump version, update build number, archive, and open Xcode Organizer.

**Steps**

1. **Read current version**

   Use Grep to find `MARKETING_VERSION` in `Simply Filter SMS.xcodeproj/project.pbxproj`. Identify the current app version (the one matching `X.Y.Z` format like `2.2.0`, NOT the `1.0` used by test targets).

   Parse the version into major, minor, and patch components.

2. **Ask for version bump**

   Use the **AskUserQuestion tool** to ask what version to release. Calculate the bumped values from the current version and present these options:

   - **Patch** (e.g., `X.Y.Z` → `X.Y.Z+1`)
   - **Minor** (e.g., `X.Y.Z` → `X.Y+1.0`)
   - **Major** (e.g., `X.Y.Z` → `X+1.0.0`)
   - User can also type a custom version via "Other"

   Show the current version in the question text so the user knows what they're bumping from.

3. **Confirm the change**

   Display a clear summary to the user:

   ```
   Current version: X.Y.Z → New version: A.B.C
   ```

   Ask for confirmation before proceeding. If the user declines, stop.

4. **Update MARKETING_VERSION in pbxproj**

   Use the **Edit tool** with `replace_all: true` to replace `MARKETING_VERSION = <old>;` with `MARKETING_VERSION = <new>;` in the pbxproj file.

   **IMPORTANT:** Only replace the app/extension version (e.g., `MARKETING_VERSION = 2.2.0;`). Do NOT replace `MARKETING_VERSION = 1.0;` — those belong to test targets. The old version will be in `X.Y.Z` format (3 components) so it won't match `1.0` (2 components).

   Verify with Grep that exactly 4 occurrences were updated (Debug + Release for both app and extension targets).

5. **Generate and set CURRENT_PROJECT_VERSION**

   Generate a timestamp build number using the format `YYYYMMDDHHmm` (e.g., `202602171430`). Do NOT include seconds.

   Use Grep to find the current `CURRENT_PROJECT_VERSION` value for the app/extension targets (the one with a long numeric timestamp, NOT the `1` used by test targets).

   Use the **Edit tool** with `replace_all: true` to replace `CURRENT_PROJECT_VERSION = <old>;` with `CURRENT_PROJECT_VERSION = <new>;` in the pbxproj file.

   Verify with Grep that exactly 4 occurrences were updated.

6. **Archive the build**

   Use the build number generated in step 5 to create a unique archive name. The archive path format is:

   `~/Library/Developer/Xcode/Archives/YYYY-MM-DD/Simply Filter SMS <version> (<build>).xcarchive`

   For example: `Simply Filter SMS 2.2.0 (202602170118).xcarchive`

   Run `xcodebuild archive` via **Bash tool** with a 10-minute timeout:

   ```bash
   xcodebuild archive \
     -project "Simply Filter SMS.xcodeproj" \
     -scheme "Simply Filter SMS" \
     -destination "generic/platform=iOS" \
     -archivePath "$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Simply Filter SMS <version> (<build>).xcarchive"
   ```

   Replace `<version>` and `<build>` with the actual values from earlier steps.

   If the archive fails, show the error output to the user and stop.

7. **Open Xcode Organizer**

   Run via **Bash tool**, using the same archive path from step 6:

   ```bash
   open "$HOME/Library/Developer/Xcode/Archives/YYYY-MM-DD/Simply Filter SMS <version> (<build>).xcarchive"
   ```

   This opens the archive in Xcode's Organizer window where the user can distribute to App Store Connect.

8. **Generate "What's New" text**

   Run `git log develop..HEAD --oneline` via **Bash tool** to get all commits on the current branch since it diverged from `develop`.

   Based on the commit messages, write a user-facing "What's New" summary for App Store Connect in **both English and Hebrew**. Guidelines:

   - Write from the user's perspective — focus on what changed for them, not internal/technical details.
   - Keep it concise: a short bullet list or 2-3 sentences.
   - Skip commits that are purely internal (planning, CI, refactoring) unless they resulted in a user-visible change.
   - Hebrew text should be natural, right-to-left friendly, and not a word-for-word translation.

9. **Show summary**

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
- Always confirm version change before modifying files
- Never modify test target versions (`MARKETING_VERSION = 1.0` and `CURRENT_PROJECT_VERSION = 1`)
- Verify correct number of replacements (4 each) after editing pbxproj
- Use 10-minute timeout for the archive command
- If archive fails, do NOT retry — show the error and stop
- Do NOT commit or push — the user will do that after verifying
