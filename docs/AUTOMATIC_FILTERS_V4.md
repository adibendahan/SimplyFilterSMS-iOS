# Automatic Filter Lists v4 — Plan

**Status:** Planned, not implemented (branch `feature/automatic-filter-records`, 2026-10-27).


## Context
Automatic filter lists (`automatic_filters.json`, S3 `3.0.0`) are four untyped string arrays per language. Their behavior is hardcoded in `MessageEvaluationManager`: senders use lowercased equality, body text uses lowercased "contains", and every deny goes to junk. The cache is one Core Data `AutomaticFiltersCache` row holding the list as base64 JSON in `filtersData`. Staleness is a base64 string compare (flaky `test_saveCache`). Every refresh downloads the full ~61 KB file even when nothing changed.

The goal:
- Ship the lists in the export format (versioned envelope + validated `FilterExportRecord`s), so each entry carries its own type, folder, target, matching and case.
- Detect changes with a content `revision` instead of a diff.
- Skip the download entirely when unchanged, using S3 conditional GET.

Decisions made:
- Change both the S3 schema and the cache.
- One S3 file, keyed by language.
- **Keep the cache in the Core Data App Group store.** The extension's read path stays exactly as it is.
- Use `revision` (not schema `version`) for content changes.
- Use ETag / `If-None-Match` to avoid the download. Verified against the live bucket: `304`, 0 bytes, against a 61 KB `200`.

## 1. Shared model (app + extension)
- Add `Framework Layer/Shared with Extension/FilterRecord.swift`. Move these into it from `Managers/Protocols/FilterTransferManagerProtocol.swift`:
  - `FilterExportRecord`
  - the five `exportKey` extensions
  - `FilterTransferCandidate`

  Turn `FilterTransferManager.candidate(from:)` into `FilterTransferCandidate.init?(record:)` and use it from both places, so imports and automatic lists share one validation path. Import behavior is unchanged.
- Add `AutomaticFilterListsPayload: Codable, Equatable`:
  ```
  format: "simply-filter-sms-automatic-filters"
  version: 1          // schema; decoder rejects > current (same rule as .sfsfilters)
  revision: Int       // content edition; bumped by tooling on every list change
  updatedAt: Date
  filterLists: [String: [FilterExportRecord]]
  ```
  - `validatedLists: [String: [FilterTransferCandidate]]` keeps only valid `.allow` / `.deny` records. Invalid records and `denyLanguage` records are dropped one by one and logged, without failing the whole list.
  - Decoding rules mirror `FilterTransferManager.decodePayload`.
- Delete `AutomaticFilterListsResponse` / `LanguageFilterListResponse`.

## 2. Cache (Core Data, same entity, no model change)
- `AutomaticFiltersCache.filtersData` now holds plain JSON (no base64) of a `AutomaticFiltersCacheEnvelope { etag: String?, payload: AutomaticFilterListsPayload }`.
  - Keeping the ETag inside the envelope means no model v5 and no CloudKit schema deploy.
  - The ETag always travels with the content it describes, including when the row syncs to another device.
- Legacy rows (base64 v3) fail to decode, so they're treated as "no cache". The next fetch is a full `200` and overwrites them.
- `PersistanceManager`:
  - `saveCache(with: AutomaticFiltersCacheEnvelope) -> Bool`
  - `cachedAutomaticFilters() -> AutomaticFiltersCacheEnvelope?` (fetch + decode in one place, replaces callers decoding `filtersData` themselves)
  - `touchCache()` (bumps `age`)
  - Drop `isCacheStale`. `fetchAutomaticFiltersCacheRecords` stays only if something still needs the raw row; otherwise remove it.
- The `hashed` attribute stays unused.

## 3. Avoiding the download (conditional GET)
- `HTTPServiceProtocol` gets `executeConditional<T: Decodable>(type:baseURL:request:etag:) async throws -> ConditionalResponse<T>`. It returns `.notModified` or `.modified(T, etag: String?)`.
  - Sends `If-None-Match` only when an `etag` is passed.
  - Uses `cachePolicy = .reloadIgnoringLocalCacheData`, so `URLCache` can't turn a 304 into a silent cached 200.
  - Maps HTTP 304 to `.notModified`, and 2xx to decode plus the response `ETag` header.
- `AmazonS3Service.fetchAutomaticFilters(etag:) async -> ConditionalResponse<AutomaticFilterListsPayload>?` (nil on offline or error, as today). New path: `/simply-filter-sms/4.0.0/automatic_filters.json`. `3.0.0` stays live for old app versions.
- `AutomaticFilterManager.updateCacheIfNeeded`:
  - Sends an ETag only when a decodable cache exists. A missing or corrupt cache always gets a full fetch, so a stale ETag can never leave a device with no lists.
  - `.notModified` → `touchCache()`.
  - `.modified(payload, etag)`:
    - `payload.revision > cached.revision` (or no cache) → save the envelope and post `.automaticFiltersUpdated`.
    - Otherwise (same file re-uploaded) → save only the new ETag and touch.
  - `forceUpdateAutomaticFilters` sends no ETag and always saves.
- The `kUpdateAutomaticFiltersMinDays` gate stays as is. A check is now nearly free, so it could be shortened later. That's out of scope here.

## 4. Consumers
- `MessageEvaluationManager`:
  - Extract `isMatching(filter:)` (`MessageEvaluationManager.swift:366`) into `isMatching(text:target:matching:case:body:sender:)`. User filters and automatic records both use it.
  - `loadAutomaticFilterCache` decodes the envelope from the same Core Data row the extension reads today. Decode it once per evaluation instead of in each of the two steps.
  - Allow and deny steps iterate validated records. Deny uses `record.denyFolder.action`. Priority order (#3 and #7) is unchanged.
- `AutomaticFilterManager.languages(for: .automaticBlocking)` and `automaticFiltersCacheAge` go through `cachedAutomaticFilters()`.
- Seed the preview cache in `AppManager` (`AppManager.swift:64`) with an envelope. `DebugDataManager.expireAutomaticFiltersCache` is unchanged (it backdates `age`).

## 5. Converting the existing list: per-entry review, not a script
There are 2,448 entries across 10 languages (en 832, he 399, de 198, ar 177, it 167, es 144, ja 139, pt 135, fr 130, ko 127). I read every entry and decide its full record. No mapping is applied blindly. Scripts are only used for bookkeeping: collecting rows, measuring against the corpus, and writing the approved results.

**Inputs for each decision**
- The entry itself, its language, and its list (allow/deny, sender/body).
- The reported-messages archive (`data/reported_messages_archive.json`, 1,754 records, ~868 unique). It shows what each entry actually catches today, and what it would catch or miss under the proposed matching.
- Earlier measurements (memory: on-device LLM SMS filtering measurements):
  - Full-word body matching costs about 14 points of recall and breaks CJK and Hebrew prefix morphology.
  - Tokenized sender matching gains +1.4 points at zero false-positive cost.
  - `.com`/`.net`/`.org` in `en.deny_sender` are dead today under equality and would cover 59 messages.

**What gets decided for each entry, and the reasoning behind it**
- **Matching**
  - **`contains`**: the default for body phrases, domains and URLs, and anything CJK, Hebrew or Arabic, where prefixes and suffixes attach to the word (e.g. Hebrew ה/ו/ב/ל/ש).
  - **`exact` (whole-word)**: short Latin-script words that, as substrings, hit innocent text. "Get" matches "budget/together", "Win" matches "window", "Now" matches "know", "Buy", "Won", "Teen", "Boss", "Form", "Only", "Stop". Senders that are names or brands also get `exact`.
  - **`regex`**: only where one pattern correctly replaces several entries or variants (e.g. `בל"ד`/`בל״ד`, or `Royal Mail`/`RoyalMail`). Every regex is checked to compile and tested against the corpus.
- **Target**:
  - `sender` for sender lists, by default.
  - Domain and TLD tokens (`.com`, `.cc`) become sender `contains`. That's the measured gain, so it's an intended behavior change and gets flagged.
  - `all` only when the same token appears in both places.
- **Case**: insensitive by default. Sensitive only where case carries the meaning (acronyms that are also common words, e.g. `MAGA`, `NFT`, `VIP`).
- **Folder**: junk stays the default. Commercial promotions (`Sale`, `Deal`, `Lowest rate`, `While supplies last`) may move to `promotion`. Political campaign senders and phrases (much of `he`) are proposed for `promotion` too. **That one is your call**, presented per cluster.
- **Keep / merge / drop**:
  - Exact duplicates and case-duplicates get merged (e.g. `Beyachad`/`BEYAHAD`/`ביחד`).
  - Entries the corpus shows as pure noise are dropped and listed separately, never silently removed. Examples: `Junk`, `Spam`, `Lose`, and short Hebrew words like `גרם` ("caused"/"gram") or `החזר` ("refund", which hits real bank SMS).
  - Entries that would catch the known mis-reported clusters (Cal, municipality OTPs, Signal/Roblox/TikTok codes, State Farm, unsubscribe receipts) are flagged.

**Process: one language at a time, starting with `he`, then `en`, then the rest**
1. Build a review table for the language. Each row has: original entry, list, proposed record, corpus hits now vs proposed, and a one-line rationale for any non-default choice.
2. Show you a summary first: counts by decision type, then every **non-default** row (changed matching, folder moves, merges, drops, regexes). Plain carry-overs (body phrase → body/contains/insensitive/junk) are collapsed into a count, and the full table is available if you want it.
3. You approve or adjust, and I apply only the approved rows to the v4 file under that language.
4. After each language, run a corpus regression: total recall and every message whose verdict flipped, both directions, listed.

Done when all 10 languages are approved. Then the v4 file is decoded by the app test fixture with **zero dropped records**, overall corpus recall is ≥ today's 81.7%, and every allow-labelled corpus message is still allowed. Any recall drop has to be explained and accepted by you.

**v3 compatibility.** Keep the original as `automatic_filters.v3.json`. Add `scripts/automatic_filters_v3.py`, which down-converts v4 back into v3 so `3.0.0` keeps getting updates:
- `contains` body → `*_body`
- sender `exact` → `*_sender` (equality)
- anything regex, sensitive-case or non-junk is skipped, with a printed list

## 6. Skills & docs
- `review-reports` and `add-filter-language` skills:
  - edit v4 records
  - **auto-increment `revision`**
  - run the down-convert
  - upload `4.0.0/` and `3.0.0/` only when asked
- Docs: `CLAUDE.md`, `docs/FRAMEWORK.md`, `docs/EXTENSION.md`, `docs/TESTS.md`. Remove the `test_saveCache` known-failure entry from memory.
- Add the new files to `project.pbxproj` by hand. `FilterRecord.swift` goes in both the app and Message Filter Extension targets.

## 7. Tests
- Payload: invalid and `denyLanguage` records dropped, unsupported `version` rejected, legacy base64 cache treated as no cache.
- `AutomaticFilterManagerTests` via mocks:
  - 304 → touch only, no notification
  - higher revision → save + notify
  - same revision with a new ETag → ETag saved, no notify
  - no cache → no ETag sent
  - force → no ETag sent
- `HTTPService`: a `URLProtocol` stub checks that the `If-None-Match` header is sent, 304 maps to `.notModified`, and the ETag is read back.
- `MessageEvaluationManagerTests` (fixtures at lines 142, 306, 336, 366, 574): switch to envelope fixtures, and add regex, sender-exact and deny-to-promotion cases.
- `PersistanceManagerTests`: replace the cache tests with an envelope round trip.
- Update `mock_PersistanceManager`, `mock_AmazonS3Service` and `mock_HTTPService`.

## Verification
1. XcodeBuildMCP: `session_show_defaults`, then `build_sim` (app + extension), then `test_sim` on Tests (in the background, with a tailed log).
2. Check the conversion against its done criteria in §5: zero records dropped on decode, corpus recall ≥ 81.7%, and every allow-labelled message still allowed.
3. Simulator: launch with the cache cleared and the log showing a 200 + save. Relaunch after expiring the cache from the debug menu, and the log should show a 304 + touch. In Test Filters, known spam and allow samples should give the same verdicts as before.
4. Don't upload to S3 until you ask.
