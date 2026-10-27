# AI Filter Lists 3.3 — Plan

**Status:** In progress on `feature/automatic-filter-records` (release 3.3.0).
- Step 1 (shared records) is done in `39eac8a`. It needs the rework listed in §1 to match this design.
- Steps 2–7 are not started.


## Context
Today the AI Filtering lists ship as `automatic_filters.json` at S3 `3.0.0`.

**How they work today:**
- **Format:** four untyped string arrays per language (`allow_sender`, `allow_body`, `deny_sender`, `deny_body`).
- **Matching** is hardcoded in `MessageEvaluationManager`:
  - senders: lowercased equality
  - body: lowercased "contains"
  - every deny goes to junk
- **Cache:** one Core Data `AutomaticFiltersCache` row, holding the whole file as base64 JSON in `filtersData`.
- **Staleness:** a base64 string compare, which makes `test_saveCache` flaky.
- **Refresh:** downloads the full ~61 KB every time, even when nothing changed.

**Goals:**
1. **One schema for every filter list.** An AI list is a plain `.sfsfilters` file, exactly the format of an exported filters file. Later, user-managed lists that people subscribe to (e.g. [ooqua/simply-filter-rules](https://github.com/ooqua/simply-filter-rules), already a `.sfsfilters`) use the same schema and the same code path.
2. **Each record carries its own behavior:** type, folder, target, matching and case. Nothing is hardcoded per list.
3. **Skip downloads that aren't needed,** using S3 conditional GET with ETags. Verified on the live bucket: `304` with 0 bytes, against a 61 KB `200`.

**Decisions:**
- **One file per language** on S3, plus a small index that lists the available languages.
- **The phone keeps one cache row**, the same `AutomaticFiltersCache` row in the same Core Data App Group store. Inside it, each list has its own section with its own ETag.
  - No model change, no CloudKit schema work, and the container setup is untouched.
  - The extension reads exactly as it does today: Core Data, read-only, one row, no network, no files.
- **Every list in the index is cached**, not only the enabled ones. That way, turning a language on works immediately, even offline (same as today).
- **The schema stays at `version: 1`.** Every change is additive and optional, so app 3.2 can still import AI and subscribed lists.

## How it works (plain version)

**On S3:**
```
simply-filter-sms/3.3.0/ai/index.json         → "available: en, he, ar, …"
simply-filter-sms/3.3.0/ai/en.sfsfilters
simply-filter-sms/3.3.0/ai/he.sfsfilters
…
```

**On the phone:** one cache row, with one section per list:
```
AutomaticFiltersCache.filtersData
├─ en: ETag "abc", the English filters
├─ he: ETag "xyz", the Hebrew filters
└─ ar: ETag "k9q", the Arabic filters
```

**Refresh:** for each list, the app asks "I have `en` with tag `abc`. Anything new?"
- **No change:** the server answers `304` and nothing is downloaded.
- **`he` changed:** only the `he` file is downloaded, and only the `he` section is replaced.
- **`ar` turned on while offline:** it's already cached, so it filters right away.
- **A message arrives:** the extension opens the row and checks only the enabled languages. A Hebrew match is reported as "AI Filtering · Hebrew".
- **Later, subscribed lists:** each one is just another section, checked and used the same way.

## 1. Schema (app + extension)
**What's in place from step 1 and stays:**
- `FilterExportRecord`, `FilterTransferCandidate` and `FilterTransferCandidate.init?(record:)` live in `FilterTransferManagerProtocol.swift`, which compiles into the app and the Message Filter Extension.
  - `init?(record:)` is the single validation path. Invalid records are dropped one at a time.
- The `exportKey` mappings live in `SharedExtensions.swift`.
- Regex records leave out `case`:
  - `FilterMatching.definesOwnCase`
  - `FilterCase.exportKey(for:)` and `init?(exportKey:for:)`
  - On import, regex records store `.caseInsensitive` internally.

**Rework (this design):**
- **`FilterExportPayload` gets `revision: Int?`.**
  - Managed lists (AI lists now, subscriptions later) set it, and tooling bumps it on every content change.
  - Plain exports leave it out.
  - `format`, `version` (stays 1), `exportedAt`, `appVersion`, `filters` and `forceClearBeforeImport` don't change. AI files still include `exportedAt` and `appVersion`, because 3.2 requires both.
- **Allow records leave out `folder`.** It's the same pattern as regex and `case`: an allow verdict never goes to a folder.
  - `FilterType` gets a property saying whether that type has a folder. It's false for `.allow`. Name to be settled in code, mirroring `definesOwnCase`.
  - `DenyFolderType.exportKey(for:)` / `init?(exportKey:for:)` apply it, next to the existing `exportKey` pair. On import, allow records store `.junk` internally.
  - `FilterTransferManager` export and `init?(record:)` use the pair. This affects user exports too, so allow filters export without `folder`.
- **Replace `AIFilterListsResponse`** (`Services Layer/Responses/`, added in step 1) with **`AIFilterIndexResponse`**:
  ```
  { "format": "simply-filter-sms-ai-index", "version": 1, "lists": ["en", "he", …] }
  ```
  The lists themselves decode as `FilterExportPayload`, sharing a decode path with `FilterTransferManager`'s current private `decodePayload`.
- **AI lists don't accept `denyLanguage` records,** since a language block makes no sense inside a per-language list. They're dropped like any invalid record.
- **Delete `AutomaticFilterListsResponse` / `LanguageFilterListResponse`** once the fetch moves over (step 3).

## 2. Cache (one Core Data row, sections per list)
- **What `AutomaticFiltersCache.filtersData` holds:** plain JSON (no base64) of
  ```
  AIFiltersCache {
    indexETag: String?
    lists: [ { id: "en", etag: String?, payload: FilterExportPayload } ]
  }
  ```
  - `id` is the language code for AI lists. Later, a subscribed list's id is its URL.
  - Each ETag sits next to the content it describes, so the pairing holds even when the row syncs to another device.
- **Validated on save.** Records are checked once, when saved in the app, and invalid ones are dropped before they're stored. The extension never re-compiles a regex just to validate it; matching compiles it per message, as user regex filters already do.
- **Legacy rows.** A row in the old base64 3.0 format doesn't decode, so it counts as "no cache". The next refresh is a full fetch, which overwrites it.
- **`PersistanceManager`:**
  - `cachedAIFilters() -> AIFiltersCache?` fetches and decodes in one place.
  - `saveCache(_ cache: AIFiltersCache) -> Bool` replaces the row's content and sets `age`.
  - `touchCache()` bumps `age` only.
  - Drop `isCacheStale` and `deleteExistingCaches`' "wipe everything first" behavior. Saving still keeps a single row.
- **Unchanged:** the `hashed` and `uuid` attributes stay unused, and sync behaves as today (one row, newest wins).

## 3. Refresh (conditional GET, per list)
- **`HTTPService`**
  - New `executeConditional(baseURL:request:etag:) async throws -> ConditionalResponse` that returns raw `Data`. Callers decode it, because the dates are ISO 8601.
  - Sends `If-None-Match` only when an ETag is passed.
  - Sets `cachePolicy = .reloadIgnoringLocalCacheData`, so `URLCache` can't turn a 304 into a hidden 200.
  - Maps 304 to `.notModified`, and 2xx to `.modified(Data, etag: String?)`.
- **`AmazonS3Service`**
  - `fetchAIIndex(etag:)` and `fetchAIList(id:etag:)` (paths under `/simply-filter-sms/3.3.0/ai/`).
  - Both return nil when offline or on error, as today.
  - `3.0.0/automatic_filters.json` stays live for older app versions.
- **`AutomaticFilterManager.updateAutomaticFiltersIfNeeded` steps:**
  1. Fetch the index, sending the cached `indexETag` only if the cache decodes.
     - A 304 reuses the cached list ids.
     - A failed index fetch ends the refresh with no change.
  2. For each id in the index, fetch the list, sending that entry's ETag only if the entry exists.
     - A 304 keeps the entry.
     - A 200 replaces only that entry.
     - A failure keeps the old entry. Lists are independent, so one failure never touches the others.
  3. Drop entries whose id is no longer in the index.
  4. If anything changed, save the row once. Otherwise call `touchCache()`.
  5. Post `.automaticFiltersUpdated` when a list was added or removed, or when its content changed: a higher `revision`, or different filters when there is no `revision`. A new ETag on identical content is saved quietly.
- **`forceUpdateAutomaticFilters`** sends no ETags at all.
- **Out of scope:** `kUpdateAutomaticFiltersMinDays` stays as it is.

## 4. Consumers
- **`MessageEvaluationManager`**
  - Extract `isMatching(filter:)` into `isMatching(text:target:matching:case:body:sender:)`. User filters and AI records both use it.
  - Decode the cache row once per evaluation, not once per step.
  - Use the lists whose `id` is an active `AutomaticFiltersLanguage`.
  - Allow step (#3), then deny step (#7); the priority order is unchanged. A deny uses the record's folder.
  - The match reason names the list's language.
- **`AutomaticFilterManager`**
  - `languages(for: .automaticBlocking)` comes from the cached list ids.
  - `automaticFiltersCacheAge` comes from the row's `age`.
- **Previews and debug**
  - `AppManager` seeds the preview cache with an `AIFiltersCache`.
  - `DebugDataManager.expireAutomaticFiltersCache` is unchanged.

## 5. Converting the existing list: per-entry review, not a script

**Interim (done 2026-10-28):** the 3.0 lists were first converted mechanically with **no behavior change**, to unblock development:
- **Body lists** → `body` / `contains` / insensitive / junk.
- **Sender lists** → `sender` / regex `(?i)^<escaped>$`, with no `case`. This reproduces today's full-sender equality.

It was checked with 4.3M old-vs-new comparisons over the report archive plus probes: zero differences, and every regex compiles. The placeholder is currently one local `ai_filters.json`.
- **Next:** split it into `ai/index.json` and `ai/<lang>.sfsfilters` and drop `folder` from allow records.
- **Before release:** the per-entry review below replaces this placeholder.
- **Known gap:** `en` `"Extract email "` has a trailing space that record validation trims.

There are 2,448 entries across 10 languages (en 832, he 399, de 198, ar 177, it 167, es 144, ja 139, pt 135, fr 130, ko 127). Every entry is read and its full record decided individually; no mapping is applied blindly. Scripts only do bookkeeping: collecting rows, measuring against the corpus, and writing the approved results.

**Inputs for each decision**
- The entry itself, its language, and its list (allow/deny, sender/body).
- The reported-messages archive (`data/reported_messages_archive.json`, 1,754 records, about 868 unique). It shows what each entry catches today, and what it would catch or miss under the proposed matching.
- Earlier measurements:
  - Full-word body matching costs about 14 points of recall, and breaks CJK and Hebrew prefix morphology.
  - Tokenized sender matching gains 1.4 points at zero false-positive cost.
  - `.com`/`.net`/`.org` in `en.deny_sender` never match today under equality, but would cover 59 messages.

**What gets decided for each entry**
- **Matching**
  - **`contains`**: the default for body phrases, domains, URLs, and CJK, Hebrew or Arabic text.
  - **`exact` (whole-word)**: short Latin words that hit innocent text as substrings, e.g. "Get"/"budget", "Win"/"window", "Now"/"know". Also sender names and brands.
  - **`regex`**: only where one pattern correctly replaces several variants (`בל"ד`/`בל״ד`, `Royal Mail`/`RoyalMail`). Each one must compile and is tested against the corpus.
- **Target**
  - `sender` for sender lists.
  - Domain and TLD tokens become sender `contains`. That's an intended change and gets flagged.
  - `all` only when the token appears in both places.
- **Case**: insensitive by default, sensitive only where case carries the meaning (`MAGA`, `NFT`, `VIP`). Regex records leave `case` out.
- **Folder**
  - Deny records are junk by default.
  - Commercial promotions may move to `promotion`.
  - Political campaign senders and phrases are proposed for `promotion`. **That's the owner's call, decided cluster by cluster.**
  - Allow records leave `folder` out.
- **Keep, merge or drop**
  - Duplicates and case-duplicates are merged.
  - Corpus-proven noise is dropped, and always listed (`Junk`, `Spam`, `Lose`, `גרם`, `החזר`).
  - Entries that would hit known mis-reported clusters are flagged: Cal, municipality OTPs, Signal/Roblox/TikTok codes, State Farm, unsubscribe receipts.

**Process: one language at a time, starting with `he`, then `en`, then the rest**
1. Build a review table: original entry, proposed record, corpus hits now vs. proposed, and a one-line rationale for each non-default choice.
2. Show a summary: counts, then every non-default row. Plain carry-overs are collapsed into a count.
3. The owner approves or adjusts. Only approved rows are written to `ai/<lang>.sfsfilters`, and its `revision` is bumped.
4. Run a corpus regression after each language: recall, plus every message whose verdict flipped, in both directions.

**Done when:**
- All 10 languages are approved.
- Every file decodes with zero dropped records.
- Overall corpus recall is at least today's 81.7%.
- Every allow-labelled corpus message is still allowed.
- Any recall drop has been explained and accepted.

**3.0 compatibility.** `automatic_filters.json` (3.0 format) stays. `scripts/ai_filters_to_3_0.py` rebuilds it from `ai/*.sfsfilters`:
- `contains` body becomes `*_body`.
- sender `exact` becomes `*_sender`.
- Regex, sensitive-case and non-junk records are skipped, with a printed list.

## 6. Tooling, skills & docs
- **Local working files:** `ai/index.json` and `ai/<lang>.sfsfilters` in the repo root, gitignored like `automatic_filters.json`. They replace `ai_filters.json`.
- **`review-reports` and `add-filter-language` skills:**
  - Edit the right `ai/<lang>.sfsfilters`, and bump **that file's** `revision`.
  - `add-filter-language` also adds the language to `ai/index.json`.
  - Run the 3.0 down-convert.
  - Upload `3.3.0/ai/*` and `3.0.0/automatic_filters.json` **only when asked**.
- **Project files:**
  - New files go through Xcode's MCP (`XcodeWrite`), which sets their targets.
  - Changing an existing file's target membership has no MCP tool, so it's done by hand in Xcode.
- **Docs:** `CLAUDE.md`, `docs/FRAMEWORK.md`, `docs/EXTENSION.md`, `docs/TESTS.md`. Remove the `test_saveCache` known-failure note.

## 7. Tests
- **Schema**
  - `revision` round-trips, and exports leave it out.
  - Allow records export without `folder` and import without it.
  - A 3.2-shaped file (no `revision`, allow with `folder`) still imports.
  - The index decodes, and a wrong format or version is rejected.
- **Cache**
  - An `AIFiltersCache` round trip through `PersistanceManager`.
  - A legacy base64 row reads as no cache.
- **Refresh** (`AutomaticFilterManagerTests`, mocks)
  - All 304 → touch only, no notification.
  - One list 200 with a higher revision → only that entry replaced, notification posted.
  - A new ETag on the same content → saved quietly.
  - One list fails → the other entries are untouched.
  - A list removed from the index → its entry is dropped.
  - No cache, or a forced refresh → no ETags sent.
- **`HTTPService`** (`URLProtocol` stub): `If-None-Match` is sent, a 304 maps to `.notModified`, and the ETag is read back.
- **`MessageEvaluationManagerTests`**
  - Fixtures switch to `AIFiltersCache`.
  - New cases: only enabled lists apply, regex sender, deny to promotion, and the match reason names the language.
- **Mocks:** update `mock_PersistanceManager`, `mock_AmazonS3Service` and `mock_HTTPService`.

## 8. Later: user-subscribed lists (not in 3.3)
- **Same file format:** a `.sfsfilters` at a URL, ideally with `revision`.
- **Same cache:** one more entry in `AIFiltersCache.lists`, with the URL as its `id`. It's refreshed by the same per-list conditional GET and evaluated by the same code.
- **Needs a new synced entity** for which lists a user subscribed to and whether each is enabled. That's the role `AutomaticFiltersLanguage` plays for AI languages.

## Verification
1. **Build and test through Xcode's MCP:** `BuildProject` (with tests) builds the app and both extensions, then `RunAllTests`.
2. **Check the conversion** against its done criteria in §5.
3. **Simulator:**
   - Clear the cache and launch. The log should show the index and every list come back 200, then a single save.
   - Expire the cache from the debug menu and relaunch. Every request should come back 304, followed by a touch.
   - Change one local list and serve it. Only that list should come back 200.
   - In Test Filters, known spam and allow samples should give the same verdicts as before.
4. **Don't upload to S3 until asked.**
