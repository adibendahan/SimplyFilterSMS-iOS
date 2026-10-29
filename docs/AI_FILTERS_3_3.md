# AI Filter Lists 3.3 — Plan

**Status:** in progress on `feature/automatic-filter-records` (release 3.3.0).

| Step | State |
|---|---|
| 1 Shared records | Done in `39eac8a`. |
| 1 Rework | Done in `4fe2625`: `revision`, allow records without `folder`, shared `.sfsfilters` decoder, in-memory-store iCloud fix. |
| 1 Catalog + `name` | Done in `a423168`: `FilterListCatalogResponse`, `name` on `FilterExportPayload` (no default on exports), local `ai/catalog.json`. |
| 2 Cache | Done in `4e1dd33`: `FilterListsCache`, `cachedFilterLists()`, `saveCache(_:)`, `touchCache()`. |
| 3 Refresh | Done in `8d690c9`: conditional GET per list, request types own their URL, `FilterListService`. |
| 4 Consumers | Done: the extension reads the new cache; `AutomaticFilterListsResponse` deleted. |
| 7 Tests | Done: `HTTPServiceTests` (stubbed `URLProtocol`), a 3.2-exported file still imports. The rest of the list was covered in steps 2–4. |
| 5–6 | Not started. |


## Context
Today the AI Filtering lists are `automatic_filters.json` at S3 `3.0.0`.

**How they work today:**
- **Format:** four plain word lists per language.
- **Matching** is hardcoded:
  - senders: equality, ignoring case
  - body: "contains", ignoring case
  - every block goes to junk
- **Cache:** one Core Data `AutomaticFiltersCache` row holding the whole file as base64.
- **Refresh:** downloads the full ~61 KB every time.

**Goals:**
1. **One file format for every filter list: `.sfsfilters`,** the same as Filter Tools → Export.
   - AI lists use it now.
   - Later, users subscribe to lists other people publish, e.g. [ooqua/simply-filter-rules](https://github.com/ooqua/simply-filter-rules), with the same code path.
2. **Each filter carries its own behavior:** type, folder, target, matching, case.
3. **Never download what hasn't changed.** The app asks the server "anything new since fingerprint X?" (ETag / conditional GET). Verified on S3 and on GitHub raw links: `304`, 0 bytes.

## How it works (plain version)

**Three ideas:**
- **List:** one `.sfsfilters` file at a URL, e.g. `…/3.3.0/ai/he.sfsfilters`.
- **Catalog:** a small file **we** publish, listing the lists we offer: `{ id, name, url }`. The app shows it on the AI Filtering screen. Think table of contents.
- **Subscription:** "this phone uses this list", meaning a URL plus on/off.
  - In 3.3 the subscriptions are the existing per-language on/off switches (`AutomaticFiltersLanguage`).
  - User-added URLs come later (§8).

**On S3:**
```
simply-filter-sms/3.3.0/ai/catalog.json   → [{ id: "ai-he", name: "Hebrew", url: "he.sfsfilters" }, …]
simply-filter-sms/3.3.0/ai/he.sfsfilters
simply-filter-sms/3.3.0/ai/en.sfsfilters  …
```

**On the phone:** one cache row (the same `AutomaticFiltersCache` row, in the same Core Data store), with one section per list, keyed by URL:
```
├─ …/ai/he.sfsfilters: fingerprint "xyz", the Hebrew filters
├─ …/ai/en.sfsfilters: fingerprint "abc", the English filters
└─ (later) https://raw.githubusercontent.com/ooqua/…: fingerprint "35fb…", its filters
```
The extension reads exactly as it does today: Core Data, read-only, one row. No network and no files.

**Refresh:** the app opens with an old cache, or the background task runs. For each list, the app asks "I have fingerprint X. Anything new?"
- **No change:** the server answers `304` and nothing is downloaded.
- **Changed:** the new file is downloaded, and only that list's section is replaced.
- **One list fails:** the others are untouched.

**Notes:**
- **Every AI list in the catalog is cached,** not only the ones turned on. That way, turning a language on works immediately, even offline.
- **The server makes the fingerprint automatically** whenever the file changes, so publishers don't do anything.
- **`revision`** (optional, in the file) tells a real content change from a re-upload. Without it, the app compares the filters themselves.

## 1. Schema (app + extension)
**In place now:**
- `FilterExportRecord`, `FilterTransferCandidate` and `init?(record:)` live in `FilterTransferManagerProtocol.swift`, which compiles into the app and the extension. `init?(record:)` is the single validation path, and invalid records are dropped one at a time.
- The `exportKey` mappings live in `SharedExtensions.swift`.
- `FilterExportPayload`:
  - `init(data:)` is the shared decoder.
  - `revision: Int?` is set by managed lists and left out of exports.
  - `version` stays `1`.
  - `exportedAt` and `appVersion` are still required, because 3.2 needs them.
- **Regex records leave out `case`:** `FilterMatching.definesOwnCase` plus `FilterCase.exportKey(for:)` / `init?(exportKey:for:)`. They store `.caseInsensitive` internally.
- **Allow records leave out `folder`:** the existing `FilterType.supportsFolders` plus `DenyFolderType.exportKey(for:)` / `init?(exportKey:for:)`. They store `.junk` internally.

**Catalog and name (done):**
- **`name` on `FilterExportPayload`:** the list's display name.
  - **Written by AI lists and published lists.**
  - **Exports never write `name`,** and there's no UI for it. Regular users don't need one. List creators who publish a list add `name` to the file by hand.
  - **Reading is tolerant:** a file without `name` (older exports, ooqua today) still loads, and the file name is shown instead. So it's `String?` in code, and 3.2 stays compatible.
- **`FilterListCatalogResponse`** (`Services Layer/Responses/`) replaced `AIFilterIndexResponse`:
  ```
  { "format": "simply-filter-sms-catalog", "version": 1,
    "lists": [ { "id": "ai-he", "name": "Hebrew", "url": "he.sfsfilters", "language": "he" } ] }
  ```
  - A `url` can be relative to the catalog or absolute.
  - `language` ties an AI list to its `AutomaticFiltersLanguage` switch.
- **Delete** `AutomaticFilterListsResponse` / `LanguageFilterListResponse` once the fetch moves over (step 3).

## 2. Cache (one Core Data row, sections per list)
- **What `AutomaticFiltersCache.filtersData` holds:** plain JSON of
  ```
  FilterListsCache {
    catalogETag: String?
    catalog: FilterListCatalogResponse
    lists: [ { url: String, etag: String?, payload: FilterExportPayload } ]
  }
  ```
- **Stored as downloaded.** The app saves each list exactly as the server sent it. The extension skips any record it can't use when it reads it (§4), so a newer app version can use records an older one couldn't, with no re-download.
- **Legacy rows.** A row in the old base64 format doesn't decode, so it counts as "no cache" and the next refresh does a full download.
- **`PersistanceManager`:**
  - `cachedFilterLists() -> FilterListsCache?`
  - `saveCache(_:) -> Bool` (sets `age`)
  - `touchCache()`
  - Drop `isCacheStale` and the "wipe all rows first" save.
    - **Done differently:** the old `saveCache(with:)` and `isCacheStale` stay until step 3 moves the fetch over, so every commit builds and the old refresh keeps working. In the mock, the old hooks are renamed `saveLegacyCache*`.
    - `saveCache(_:)` updates the newest row in place and deletes any extra rows, e.g. two devices that each created one before syncing.
- **Where it lives:** `Framework Layer/Shared with Extension/FilterListsCache.swift` (app + extension). `init?(encoded:)` / `encoded` use ISO 8601 dates, like `.sfsfilters`.
- **Sync:** as today (one row, newest wins). The `hashed` and `uuid` attributes stay unused.

## 3. Refresh (conditional GET, per list)
- **`HTTPService.fetchIfModified(request:)`** returns `.notModified` or `.modified(Data, etag:)`.
  - Sends `If-None-Match` only when an ETag is passed.
  - Uses `.reloadIgnoringLocalCacheData`, so iOS's own cache can't hide a 304.
- **`FilterListService`** (was `AmazonS3Service`) fetches the catalog and the lists. Fetching by full URL is ready for user lists later. `3.0.0/automatic_filters.json` stays live for older apps.
- **`AutomaticFilterManager.updateAutomaticFiltersIfNeeded` steps:**
  1. Fetch the catalog, sending its fingerprint only if the cache decodes.
     - A 304 means the cached catalog is used.
     - A failure means stop, with nothing changed.
  2. For each catalog list, fetch it, sending its fingerprint only if it's cached.
     - A 304 keeps the section.
     - A 200 replaces that section only.
     - A failure keeps the old section.
  3. Drop sections whose URL is no longer in the catalog. Later, user subscriptions are kept too (§8).
  4. If anything changed, save once. Otherwise call `touchCache()`.
  5. Post `.automaticFiltersUpdated` when a list was added or removed, or its content changed: a higher `revision`, or different filters when there's no `revision`.
- **`forceUpdateAutomaticFilters`** sends no fingerprints.
- **Out of scope:** `kUpdateAutomaticFiltersMinDays` stays as it is.
- **Done differently:**
  - `fetchIfModified(request:)` (planned as `executeConditional(baseURL:request:etag:)`). `URLRequestProtocol` now has a full `url` and `headers` instead of `path`, so no service passes a base URL; `execute(type:request:)` changed the same way. The requests are `FilterListCatalogRequest(etag:)` and `FilterListRequest(url:etag:)`, which set `If-None-Match`. It returns `FetchResult<Data>`; `FilterListService` decodes it into `FetchResult<FilterListCatalogResponse>` / `<FilterExportPayload>`, and `nil` means the fetch failed.
  - The catalog URL is `URL.filterListCatalogURL`. A catalog `url` resolves against it, and duplicate URLs are fetched once.
  - The refresh runs on the main actor, so its Core Data reads and writes are on `viewContext`'s thread. A second caller during a refresh joins it (`refreshTask`) instead of returning early, so pull-to-refresh waits for the real result. This replaces the old `AmazonS3Service.isFetching`, which wasn't thread-safe.
  - `AmazonS3Service` was renamed `FilterListService`: nothing in it is S3-specific, and lists can be hosted anywhere (e.g. GitHub raw links).
  - `touchCache()` is skipped when any list failed, so the next launch retries instead of waiting `kUpdateAutomaticFiltersMinDays`.
  - Deleted: `AutomaticFilterListsRequest`, `fetchAutomaticFilters()`, `saveCache(with:)`, `isCacheStale`. The UI-test seed in `AppManager` now writes a `FilterListsCache`.

## 4. Consumers
- **`MessageEvaluationManager`**
  - Extract `isMatching(filter:)` into `isMatching(text:target:matching:case:body:sender:)`.
  - Read the row **once per message**, shared by the allow and block steps (today it's decoded twice).
  - **Decode only the sections that are on:** those whose catalog `language` has an active `AutomaticFiltersLanguage`. Sections that are off are skipped during decoding.
  - **Check records as they're used:** convert each record's settings with `init?(exportKey:)`; skip the record if any is unknown. A regex that doesn't compile doesn't match. No separate validation pass, and the regex isn't compiled twice.
  - Allow step (#3), then block step (#7); the priority order is unchanged. A block uses the record's folder.
  - The match reason shows the list's `name` ("AI Filtering · Hebrew").
  - **Done differently:**
    - `ActiveFilterLists` (in `FilterListsCache.swift`) reads the row in two steps: decode only the catalog and work out which list URLs are on, then decode the lists, where each `CachedList` builds its `payload.filters` only if its URL is on. The other lists are read but never built into objects. Keyed by URL, not language, so lists subscribed by URL later fit as is. Measured with Hebrew on, against decoding the whole `FilterListsCache`: ~4.6 ms vs ~42 ms per message (before the split into two steps).
    - Allow and block share one `runAutomaticFilters(type:...)`; records of other types (e.g. `denyLanguage`) are skipped.
    - A record whose text is empty or only whitespace is skipped too, since it would match every message.
    - The match reason uses the language's localized name when the catalog entry has a `language` (as before, so Hebrew users see "עברית"), and the catalog `name` otherwise (`FilterListCatalogEntry.displayName`).
    - `isMatching(text:target:matching:filterCase:body:sender:)`: `case` is a keyword, so the label is `filterCase`.
    - **Measured** (`test_automaticFilters_performance`, simulator on a Mac): all 10 languages on, 2,450 records (480 regex), a message that matches nothing: **~24 ms per message**, no memory growth across iterations. A device will be slower; check on one before release.
- **`AutomaticFilterManager`**
  - `languages(for: .automaticBlocking)` comes from the cached catalog.
  - The cache age comes from the row.
- **Previews:** `AppManager` seeds a `FilterListsCache`. `DebugDataManager.expireAutomaticFiltersCache` is unchanged.

## 5. Converting the existing lists: per-entry review, not a script
**Interim (done):** a mechanical, behavior-identical conversion unblocks development.
- **Body lists** → `body` / `contains` / insensitive / junk.
- **Sender lists** → `sender` / regex `(?i)^<escaped>$`, which reproduces today's equality.

Checked with 4.3M old-vs-new comparisons over the report archive: zero differences, and every regex compiles. The local files live in `ai/` (gitignored).
- **Known gap:** `en` `"Extract email "` has a trailing space that validation trims.

**Before release:** all 2,448 entries (en 832, he 399, de 198, ar 177, it 167, es 144, ja 139, pt 135, fr 130, ko 127) are reviewed one by one, one language at a time, starting with `he`, then `en`.
- **For each entry,** decide:
  - matching (`contains` / whole-word `exact` / `regex`)
  - target
  - case
  - folder (junk or promotion, the owner's call by cluster)
  - keep, merge or drop
- **Evidence:** the reported-messages archive (`data/reported_messages_archive.json`), plus earlier measurements:
  - whole-word body matching costs about 14 points of recall and breaks CJK and Hebrew
  - `.com`/`.net`/`.org` sender entries never match today but would catch 59 messages
- **Per language:**
  1. Build a review table: entry, proposed record, corpus hits now vs. proposed, and a reason for each non-default choice.
  2. Show a summary of the non-default rows. The owner approves.
  3. Write only the approved rows and bump that file's `revision`.
  4. Run a corpus regression listing every verdict that flips.
- **Done when:**
  - All 10 languages are approved.
  - No records are dropped on decode.
  - Corpus recall is at least today's 81.7%.
  - Every allow-labelled message is still allowed.

**3.0 compatibility.** `scripts/ai_filters_to_3_0.py` rebuilds `automatic_filters.json` from `ai/*.sfsfilters`:
- body `contains` becomes `*_body`
- sender `exact` becomes `*_sender`
- anything else is skipped, and listed

## 6. Tooling, skills & docs
- **Local files:** `ai/catalog.json` and `ai/<lang>.sfsfilters` (gitignored).
- **`review-reports` / `add-filter-language` skills:**
  - Edit the right `.sfsfilters` and bump its `revision`.
  - `add-filter-language` also adds the language to `catalog.json`.
  - Run the 3.0 down-convert.
  - Upload `3.3.0/ai/*` and `3.0.0/automatic_filters.json` **only when asked**.
- **Project files:** new files go through Xcode's MCP. Target membership for existing files is set by hand in Xcode.
- **Docs:** `CLAUDE.md`, `docs/FRAMEWORK.md`, `docs/EXTENSION.md`, `docs/TESTS.md`.

## 7. Tests
- **Schema:**
  - `revision` round-trips and is left out of exports.
  - `name` round-trips, exports leave it out, and a file without it still loads with the fallback.
  - Allow without `folder` and regex without `case` import.
  - A 3.2-shaped file still imports.
  - The catalog decodes; a wrong format or version is rejected.
- **Cache:** a `FilterListsCache` round trip; a legacy base64 row reads as no cache.
- **Refresh (mocks):**
  - All 304 → touch only.
  - One list 200 → only that section changes, and the notification is posted.
  - A new fingerprint with the same content → saved quietly.
  - One list fails → the others are untouched.
  - A list removed from the catalog → its section is dropped.
  - No cache, or a forced refresh → no fingerprints sent.
- **`HTTPService`** (`URLProtocol` stub): `If-None-Match` is sent, a 304 maps to `.notModified`, and the ETag is read back.
- **`MessageEvaluationManagerTests`:**
  - Only enabled lists apply.
  - Regex sender.
  - Block to promotion.
  - The match reason shows the list name.

## 8. Next release: subscribe to any list, with UI (not in 3.3)
3.3 builds everything this needs (shared format, `name`, catalog, cache keyed by URL, per-list refresh). The next release adds the user-facing part:
- **Subscribe:** the user can subscribe to any list by URL. That means an "Add list" screen (paste a URL, or open an `.sfsfilters` link and choose "Subscribe" instead of "Import"). It shows the list's `name` and filter count before confirming.
- **Manage:** see subscribed lists, turn each on/off, and remove them.
- **UI design is presented for approval before it's built.**

**What a list needs, to be subscribable:**
1. **A public HTTPS link that returns the file itself.** A GitHub raw link works and answers 304 correctly. A "latest release" link also works through its redirects.
2. **A valid `.sfsfilters`,** the same file the app exports, so anyone can build a list in the app, export it and publish it. Bad entries are skipped one by one.
3. **Should have, added by hand in the file:** `name`, shown in the app (otherwise the file name is used), and `revision`, to tell real changes apart.

**How updates are found:**
- The same refresh as AI lists, on the same schedule.
- The server's fingerprint changes whenever the file changes, so publishers just push the new file.
- If a host gives no fingerprint, the app downloads the file on each check and compares the contents.

**App-side rules:**
- **Cap the list size** (number to decide, e.g. 1 MB or 5,000 filters), because the message extension has very little memory.
- **Ignore `forceClearBeforeImport`.** A subscribed list lives in its own section and never touches the user's own filters.
- **Language blocks (`denyLanguage`)** are dropped from AI lists. For user lists, allowing them is **an open decision.**

**What's needed then:**
- A synced Core Data entity for user subscriptions: URL, name and on/off.
- Their sections join the same cache row, keyed by URL. They're kept when the AI catalog changes.
- [ooqua/simply-filter-rules](https://github.com/ooqua/simply-filter-rules) works as-is today: no `revision` (fine), no name (fallback), and `forceClearBeforeImport` ignored.

## Verification
1. **Build and test through Xcode's MCP:** `BuildProject` (with tests), then `RunAllTests`.
2. **Check the conversion** against its done criteria (§5).
3. **Simulator:**
   - Clear the cache and launch. The catalog and every list should come back 200, followed by one save.
   - Expire the cache from the debug menu and relaunch. Everything should come back 304.
   - Change one list. Only that list should come back 200.
   - In Test Filters, the verdicts should be the same as before.
4. **No S3 upload until asked.**
