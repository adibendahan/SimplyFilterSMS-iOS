# Framework & Services Layer

What the code doesn't tell you: ordering, rules and the reasons behind them. For signatures and file layout, read the code.

---

## MessageEvaluationManager

### Evaluation pipeline (first match wins)

1. **Allow filters** → `.allow`.
2. **All Unknown** rule → `.junk`. An absolute gate: only the user's own allows beat it.
3. **AI list allow records** → `.allow`. Before the rules, so an allow-listed sender (e.g. a bank) isn't blocked by "links".
4. **Smart rules** (links, numbers-only, short sender, email, emojis, country allowlist).
5. **Deny filters** → the filter's folder.
6. **Language deny** (dominant body language via `NLLanguageRecognizer`).
7. **AI list deny records** → the record's folder. Records are checked in file order and the first match wins, so list files keep `promotion` / `transaction` records after `junk` ones.
8. **No match** → `.allow`.

- The cache row is read once per message, before step 3, and only the lists whose language is on are decoded (`ActiveFilterLists`). Step 7 reuses it.
- A list record whose settings don't convert is skipped; a regex that doesn't compile doesn't match. Lists are stored as downloaded, so this is the only validation they get.
- If the extension's store fails to load, the message is allowed with `storeUnavailable`: never block on our own failure.

### Two ways to build it

- **App:** `init(persistanceManager:)` reads `PersistanceManager.context` on every call, so it keeps working across `reloadContainer()`.
- **Extension / tests:** `init(inMemory:)` owns a read-only container, loaded synchronously in `init` (`shouldAddStoreAsynchronously = false`).

---

## PersistanceManager

### Fingerprint

Filter UUIDs + rule states + language rows. It deliberately **excludes** `AutomaticFiltersCache`, so a list refresh never looks like a CloudKit change to `NetworkSyncManager`.

### Cache row

- `cachedFilterLists()` reads the newest row; a legacy base64 row (3.2 and earlier) reads as `nil`, and a `nil` cache is downloaded whatever its `age`.
- `saveCache(_:)` updates the newest row and deletes any others. Two devices can each create a row before they sync.

---

## AutomaticFilterManager

### Refresh

- Runs when the cache is older than `kUpdateAutomaticFiltersMinDays`; pull-to-refresh forces it and sends no ETags.
- Catalog first, then each list with its stored ETag: `304` keeps the section, `200` replaces it, a failure keeps the old one. Lists that left the catalog are dropped.
- Saves once if anything changed. Otherwise `touchCache()`, except when a list failed, so the next launch retries instead of waiting days.
- Runs on the **main actor** (Core Data view context). A second caller joins the running refresh (`refreshTask`), so pull-to-refresh waits for the real result.
- Posts `.automaticFiltersUpdated` only for a real change: a list added or removed, a higher `revision`, or different filters when there's no `revision`. Re-uploading the same file doesn't notify anyone.

---

## NetworkSyncManager

### Sync monitoring

- An import posts `.cloudSyncOperationComplete` (toast + refresh) only when the fingerprint changed.
- `AppHomeView.startMonitoring` compares fingerprints once on its own, in case the import finished before the observers were registered.

### Recovery

`reloadContainer()` runs only on a genuine reconnection: `NetworkStatus.isReconnection(from:)`, which is `.offline` → `.online` and nothing else. A failed setup is recorded as `syncStatus = .failed` for the UI and otherwise left alone.

**`.unknown` is not a network state.** It means the path monitor hasn't reported yet, so leaving it is a first report, never a reconnection. Treating it as one called `reloadContainer()` during CloudKit setup on a fresh install, tore down the store and aborted the initial import: no filters for the whole first session, and duplicates after relaunch. Present from 2022-02-09 until `dc22149`; pinned by `NetworkStatusTests`.

**Never retry a failed setup with `reloadContainer()`.** It destroys the `NSCloudKitMirroringDelegate` that is already running Core Data's own backoff, and **one** teardown is enough to lose the initial import on a fresh install. A setup retry was tried (`0ac0579`), disabled, then deleted. Core Data retries setup itself.

`reloadContainer()` resets the view context, which invalidates every managed object, then posts `.persistentStoreReloaded`. Any screen that holds Core Data objects applies `.modifier(persistentStoreReload)`.

---

## FilterTransferManager

### `.sfsfilters` rules

One format for exports, AI Filtering lists and (later) subscribed lists.

- **Compatibility:** changes are additive and optional only, so `version` stays `1` and 3.2 can still read new files.
- **Omitted fields:** regex records have no `case` (the pattern decides) and allow records have no `folder`. Import fills in `.caseInsensitive` / `.junk`. Older files that still have them import fine.
- **`name` / `revision`** are for published lists. Exports never write them; list creators add them by hand.
- **Validation:** `FilterTransferCandidate.init?(record:)` is the only path. It drops bad records one at a time.

### Sessions

- Import and export share one in-flight picker (`pendingPreview` / `pendingKind`).
- An import with nothing new still goes through `recordLaunch(.filterImport)`; Home then shows the "nothing to import" alert instead of the sheet.
- `deleteExportFile` only removes a `.sfsfilters` file inside the temp directory, so it can never delete a user's file.

---

## FlowManager

Order and occupancy are in `CLAUDE.md`. Beyond that:

- `recordLaunch(.enableExtension)` returns `false` during first run, since that sheet is already showing. The last successful launch wins.
- Automatic What's New is skipped when the session started as first run or a launch claimed it.

---

## SchedulingManager

### Background refresh

- One `BGProcessingTask`, not an app refresh task: processing targets idle and overnight windows, which suits an app that's rarely opened. `earliestBeginDate` is now + `kUpdateAutomaticFiltersMinDays`.
- Registered in `AppDelegate.didFinishLaunching` (iOS requires it before launch returns). Submitted from `onAppLaunch()` and again at the top of every wake.
- The Message Filter Extension never fetches; only the app does.

### Inactivity reminder

- One repeating notification, first firing a month out, then monthly. It's an interval trigger because a `UNCalendarNotificationTrigger` on today's day of month would fire again the same evening.
- **Only** `AppDelegate.applicationDidBecomeActive` moves the clock. iOS runs `didFinishLaunching` for background wakes too, so nothing on the launch path may touch it.
- Cancelled when AI Filtering goes off (`.filtersStateChanged`).

### When to ask

- AI Filtering is on, it's not the first session, alerts aren't already allowed, fewer than `kInactivityNotificationMaxAsks` declines, and at least `kInactivityNotificationMinSessionsBetweenAsks` sessions since the last one.
- A remembered grant is what lets a later revoke in Settings be noticed; then the decline history is wiped. A denial at the system prompt counts as a decline.

---

## Services

- **`fetchIfModified(request:)`** ignores the local URL cache (`.reloadIgnoringLocalCacheData`), so iOS's own cache can't hide a `304`. It sends `If-None-Match` only when there's an ETag.
- **`FilterListService`:** a catalog entry's `url` is relative to `URL.filterListCatalogURL` or absolute, so lists can live anywhere.
