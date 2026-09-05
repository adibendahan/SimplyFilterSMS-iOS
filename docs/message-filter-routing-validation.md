# Saved-rule evaluation and iOS routing validation

## Implemented behavior

The tester now requires the actual sender and evaluates saved rules through the same independent read-only reader used by the Message Filter extension. It does not use the app's live edits. Clearing the sender clears the result, and results from obsolete asynchronous inputs cannot replace newer results.

Each production query opens a read-only SQLite container on a serial worker queue, creates a private context, pins its query generation, evaluates on that context's queue, then resets the context and closes the store. Reopening on each query provides freshness and retries completed load failures without retaining a failed container. This trades some opening overhead for a small, explicit lifecycle; device latency remains to be measured. There is no invented IdentityLookup timeout.

Load and read failures have separate statuses. Both retain the existing nonblocking `.allow` fallback; the tester presents them as unavailable, never as a successful Allow classification. Explicit allows, successful no-match, and failures remain distinguishable. Allow precedence, regex semantics, export format, and `.junk` mapping are unchanged.

Failed app saves return failure, roll back pending context changes, and present an error. The user must repeat the failed edit. Failed mutations do not post success notifications; automatic cache update notifications require a successful save. Imports count only successfully added records. Imports remain a sequence of saves, not an atomic transaction: earlier successful additions can remain if a later save fails. Opening an unavailable App Group no longer silently substitutes a temporary rules database.

Extension logs contain transient query IDs, version/build, result status, action, match category, and elapsed time. Error logs contain domain/code without userInfo or localized descriptions. Sender, body, and user rule text are excluded. The extension writes no shared diagnostic files and adds no network dependency. The unused example network manifest attributes were removed.

New UI copy uses the existing Localizable.strings mechanism. Non-English localizations currently contain explicit English fallback copy for these new messages, pending translation.

## Automated verification

Run from the repository root, selecting an available simulator if this UUID is not present:

```sh
xcodebuild test \
  -project 'Simply Filter SMS.xcodeproj' \
  -scheme Tests \
  -destination 'platform=iOS Simulator,id=C7F9D93D-B744-4A8B-9CFC-7645F2F1B148' \
  -derivedDataPath /tmp/simplyfiltersms-build \
  CODE_SIGNING_ALLOWED=NO

xcodebuild build \
  -project 'Simply Filter SMS.xcodeproj' \
  -scheme 'Simply Filter SMS' \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/simplyfiltersms-device-build \
  CODE_SIGNING_ALLOWED=NO
```

The Tests scheme enables `-com.apple.CoreData.ConcurrencyDebug 1`. New tests cover independent SQLite reader parity; sender allow precedence; unsaved edits; committed text, folder, matching-mode changes and deletion; actual importer additions; failed save rollback and persisted parity; missing-store recovery; concurrent asynchronous completions; malformed cache and injected fetch failures; response action mapping; blank sender; and accessible error text. Existing tests exercise the remaining evaluation priority and regex behavior.

Verified on September 5, 2026: all 112 unit/integration tests passed with zero failures, and the unsigned generic iOS device build succeeded. UI automation and real-device delivery were not run.

Validation environment: Xcode 26.6 (17F113), iPhone 17 Pro simulator running iOS 26.5. Unsigned simulator execution intentionally cannot establish App Group entitlement access; integration tests inject temporary SQLite URLs. Unsigned device compilation also does not verify provisioning, signed entitlements, extension registration, locked-device access, or OS routing.

## Real-device procedure

1. Build and install the containing app and embedded extension using your normal development signing. Record app and extension version/build, iOS version/build, and whether the device was restarted/unlocked. On the built signed product, inspect both entitlements separately:

   ```sh
   codesign -d --entitlements :- '/absolute/path/to/Simply Filter SMS.app'
   codesign -d --entitlements :- '/absolute/path/to/Simply Filter SMS.app/PlugIns/Message Filter Extension.appex'
   ```

   Substitute the actual archive/product paths and embedded `.appex` filename. Both should contain `group.com.grizz.apps.dev.simply-filter-sms`. Do not infer signed entitlements from source files or an unsigned build.

2. Confirm Simply Filter SMS is selected in Messages' text-message filtering settings. Record Apple's Filter Spam and unknown-sender screening settings separately. Use an authorized test sender outside Contacts and established/replied-to conversations. Record transport (SMS, MMS, RCS, or iMessage). Do not send messages without authorization.

3. Save a narrowly targeted test rule. Confirm no save error appears. Enter the exact sender and body in **Saved Rules Test**, and record its result. A test result does not establish sender eligibility or invoke the installed extension.

4. In macOS Console, select the connected iPhone and start a verified live capture. Include info/debug messages and filter by subsystem `com.grizz.apps.dev.Simply-Filter-SMS`, category `extension`. Request a **new** incoming message from the authorized sender. Record query ID, version/build, status, action, match kind, elapsed time, and the actual Messages folder. Do not share raw message content unless intentionally supplied for investigation.

5. Repeat after an extension cold start, with the containing app closed, after changing a saved rule, and after deleting/importing a rule. Compare each new delivery with an exact-input saved-rule test. Test the locked device after first unlock, and after reboot before first unlock where feasible; record accessibility failures without assuming that file protection caused them. Use iMessage as an ineligible control.

6. If status is unavailable/readFailed, inspect error domain/code and investigate store/configuration access. If status is success and match is an explicit allow, inspect sender and rule precedence. If it is successful no-match, compare exact inputs and committed rules. If the extension records `.junk` but Messages shows Unknown Senders, retain that evidence and investigate OS behavior separately. A missing query log alone does not prove non-invocation unless capture coverage is established.

These changes do not reclassify old messages. No device evidence has established a root cause for the three originally reported messages.

## API references

Apple's [IdentityLookup overview](https://developer.apple.com/documentation/identitylookup/sms-and-mms-message-filtering) documents the extension's inability to write shared containers or directly access the network. Its [Core Data background guide](https://developer.apple.com/documentation/coredata/using-core-data-in-the-background) describes queue confinement. The installed SDK retains `.junk` as the unwanted-message action. Apple's [iOS 26 filtering guide](https://support.apple.com/guide/iphone/screen-and-filter-texts-iph203ab0be4/26/ios/26) discusses text screening and filtering; it does not turn a local tester result into proof of delivery routing.
