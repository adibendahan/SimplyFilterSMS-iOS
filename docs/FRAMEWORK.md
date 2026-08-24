# Framework & Services Layer

Deep dive into the managers, services, protocols, and data flow.

---

## AppManager

**Files:** `Framework Layer/Managers/AppManager.swift`, `Protocols/AppManagerProtocol.swift`

Singleton service locator (`AppManager.shared`). Creates, wires, and exposes all managers and services.

### Protocol

```swift
protocol AppManagerProtocol {
    static var logger: Logger { get }
    var persistanceManager: PersistanceManagerProtocol { get }
    var defaultsManager: DefaultsManagerProtocol { get set }
    var automaticFilterManager: AutomaticFilterManagerProtocol { get }
    var messageEvaluationManager: MessageEvaluationManagerProtocol { get }
    var networkSyncManager: NetworkSyncManagerProtocol { get }
    var amazonS3Service: AmazonS3ServiceProtocol { get }
    var reportMessageService: ReportMessageServiceProtocol { get }
    var tipJarManager: TipJarManagerProtocol { get }
    var filterTransferManager: FilterTransferManagerProtocol { get }
    var flowManager: FlowManagerProtocol { get }
    func onAppLaunch()
    func onNewUserSession()
}
```

### Initialization Order

1. `PersistanceManager` (in-memory if specified)
2. `DefaultsManager`
3. `MessageEvaluationManager` (app: receives persistance manager; follows live context across `reloadContainer()`)
4. `NetworkSyncManager` (receives persistance manager)
5. `AmazonS3Service` (receives network sync manager)
6. `ReportMessageService` (receives network sync manager)
7. `AutomaticFilterManager` (receives persistance manager + S3 service)
8. `TipJarManager`
9. `FilterTransferManager` (receives persistance manager)
10. `FlowManager` (receives defaults manager)
11. Logger wired to MessageEvaluationManager

In `#if DEBUG` + testing mode (`-Testing` launch argument): resets DefaultsManager and PersistanceManager.

### Lifecycle

- `onAppLaunch()` — Initializes app age, detects new session (day boundary), triggers auto-filter update if online.
- `onNewUserSession()` — Increments session counter, updates session timestamp, fetches latest automatic filters.
- `AppManager.previews` — Static in-memory instance with debug data loaded, used by SwiftUI previews.

### Logger

```swift
static let logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "main")
```

---

## MessageEvaluationManager

**Files:** `Framework Layer/Managers/MessageEvaluationManager.swift`, `Protocols/MessageEvaluationManagerProtocol.swift`

Core filtering engine. Shared between the main app and the Message Filter Extension.

### Protocol

```swift
protocol MessageEvaluationManagerProtocol {
    var context: NSManagedObjectContext { get }
    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult
    func setLogger(_ logger: Logger)
}
```

### MessageEvaluationResult

```swift
enum MessageEvaluationMatch {
    case none, noMatch, storeUnavailable
    case userFilter(String), smartFilter(String), automaticFilter(String)
}

struct MessageEvaluationResult {
    var action: ILMessageFilterAction  // .allow, .junk, .transaction, .promotion
    var match: MessageEvaluationMatch
    var reason: String? { match.caption }  // logs / Test Filters caption
}
```

### Evaluation Pipeline (order matters — first match wins)

1. **Allow filters** — `Filter` records with `type == .allow`. Returns `.allow` if matched.

2. **All Unknown** — Active `AutomaticFiltersRule` for `.allUnknown`. Returns `.junk` (absolute gate after allows).

3. **Automatic filters (allow)** — Active languages’ cached community lists: `allowSenders` / `allowBody`. Returns `.allow`.

4. **Filter rules** — Other active `AutomaticFiltersRule`s (`.allUnknown` skipped here):
   - `links` — Body contains a URL (`NSDataDetector`)
   - `numbersOnly` — Sender contains letters (i.e. not numbers-only)
   - `shortSender` — Sender length ≤ configurable threshold (3–6)
   - `email` — Sender looks like an email
   - `emojis` — Body contains emoji
   - `countryAllowlist` — Sender’s calling code not in the selected allowlist

5. **Deny filters** — `Filter` records with `type == .deny`. Returns the filter’s `denyFolderType.action`.

6. **Language deny** — `Filter` records with `type == .denyLanguage`. Dominant body language via `NLLanguageRecognizer`.

7. **Automatic filters (deny)** — Cached community `denySender` / `denyBody`. Returns `.junk`.

8. **No match** — `.allow` with `match: .noMatch`.

Owned-store load failure (extension/tests) returns `.allow` with reason `"storeUnavailable"` before the pipeline runs.

### Filter Matching Logic

For each user filter, matching depends on three settings:
- **FilterTarget:** `.all` (sender+body combined), `.sender`, or `.body`
- **FilterMatching:** `.contains`, `.exact` (word boundaries), or `.regex`
- **FilterCase:** `.caseInsensitive` or `.caseSensitive`

### Database Access

**App:** `init(persistanceManager:)` — `ContextSource.persistance`; `context` always reads `PersistanceManager.context` (survives `reloadContainer()`).

**Extension / tests:** `init(inMemory:)` — `ContextSource.owned`; owns an `AppPersistentCloudKitContainer` (`isReadOnly: true` unless in-memory). Loads the store synchronously in init (waits up to `kOwnedStoreLoadTimeout`). On failure/timeout, logs and leaves an empty store; evaluate then allows without running filters. Successful load sets `stalenessInterval = 0`.
---

## PersistanceManager

**Files:** `Framework Layer/Managers/PersistanceManager.swift`, `Protocols/PersistanceManagerProtocol.swift`

CoreData CRUD layer. Manages three entity types: `Filter`, `AutomaticFiltersRule`, `AutomaticFiltersLanguage`, plus cache records.

### Protocol (key methods)

```swift
protocol PersistanceManagerProtocol {
    var container: NSPersistentCloudKitContainer { get }
    var fingerprint: String { get set }

    // Filters
    func fetchFilterRecords() -> [Filter]
    func fetchFilterRecords(for filterType: FilterType) -> [Filter]
    func addFilter(text:type:denyFolder:filterTarget:filterMatching:filterCase:)
    func deleteFilters(withOffsets:in:)
    func deleteFilters(_ filters: Set<Filter>)
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType)
    func updateFilter(_ filter: Filter, filterMatching: FilterMatching)
    func updateFilter(_ filter: Filter, filterCase: FilterCase)
    func updateFilter(_ filter: Filter, filterTarget: FilterTarget)
    func updateFilter(_ filter: Filter, filterText: String)
    func isDuplicateFilter(text:filterTarget:filterMatching:filterCase:) -> Bool

    // Automatic filters
    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage]
    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule]
    func fetchAutomaticFiltersCacheRecords() -> [AutomaticFiltersCache]
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage?
    func fetchAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule?
    func ensureAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule
    func saveCache(_ filterList: AutomaticFilterListsResponse)
    func isCacheStale(_ filterList: AutomaticFilterListsResponse) -> Bool

    // Lifecycle
    func commitContext()
    func reloadContainer()
    #if DEBUG
    func loadDebugData()
    func reset()
    #endif
}
```

### Container Setup

Uses `AppPersistentCloudKitContainer` (subclass of `NSPersistentCloudKitContainer`):
- Stores database in the App Group container for extension sharing
- Supports in-memory mode for tests/previews
- CloudKit sync is automatic via the container

### CloudKit Schema Deployment (IMPORTANT)

**Every CoreData model change requires a manual schema deployment to production.**

The development CloudKit environment auto-evolves its schema when the app runs (new entities and attributes are picked up automatically). The production environment does **not** — it must be explicitly deployed via the CloudKit Console.

**Steps after any CoreData model change:**
1. Run the debug build on a device or simulator and let it launch fully — the dev schema updates automatically.
2. Go to [CloudKit Console](https://icloud.developer.apple.com/dashboard) → select the app container → Schema → Environments.
3. Review the diff between Development and Production carefully. Watch for stale record types from deleted/abandoned features — once deployed to production they **cannot be removed**.
4. If the diff looks clean, click **Deploy to Production**.

**Symptoms of a missing production schema field:** data syncs correctly in debug builds but not in TestFlight/App Store builds. Fields silently dropped on upload; only previously-deployed fields come back after reinstall.

### Fingerprint

A computed string of filter UUIDs + automatic rule states (`ruleId` / `isActive` / `selectedCountries`) + language rows (`lang` / `isActive`). Does **not** include `AutomaticFiltersCache`. Used by `NetworkSyncManager` to detect whether a CloudKit import changed user-visible filter data.

### Cache Management

- `saveCache()` — Encodes `AutomaticFilterListsResponse` to base64, stores in CoreData with hash and timestamp. Deletes old cache records first.
- `isCacheStale()` — Compares encoded base64 strings of new vs cached filter lists.

### Debug Support

- `loadDebugData()` — Populates with sample filters (deny/allow/language) for previews and testing.
- `reset()` — Deletes all records from all entities.

---

## AutomaticFilterManager

**Files:** `Framework Layer/Managers/AutomaticFilterManager.swift`, `Protocols/AutomaticFilterManagerProtocol.swift`

Manages community-sourced filter lists fetched from AWS S3, plus smart rule states and language blocking states.

### Protocol (key members)

```swift
protocol AutomaticFilterManagerProtocol {
    var isAutomaticFilteringOn: Bool { get }
    var activeAutomaticFiltersTitle: String? { get }
    var automaticFiltersCacheAge: Date? { get }
    var rules: [RuleType] { get }

    func languages(for mode: LanguageListView.Mode) -> [NLLanguage]
    func languageAutomaticState(for language: NLLanguage) -> Bool
    func setLanguageAutmaticState(for language: NLLanguage, value: Bool)
    func automaticRuleState(for rule: RuleType) -> Bool
    func setAutomaticRuleState(for rule: RuleType, value: Bool)
    func selectedChoice(for rule: RuleType) -> Int
    func setSelectedChoice(for rule: RuleType, choice: Int)
    func updateAutomaticFiltersIfNeeded()
    func forceUpdateAutomaticFilters() async
}
```

### Key Behaviors

- `isAutomaticFilteringOn` — True if any language has automatic filtering enabled AND cache records exist.
- `activeAutomaticFiltersTitle` — Comma-separated localized names of active languages (e.g., "English, Hebrew").
- `languages(for:)` — Returns different lists per mode:
  - `.automaticBlocking` — Languages available in the cached filter lists
  - `.blockLanguage` — All supported `NLLanguage` cases minus already-blocked ones
- `updateAutomaticFiltersIfNeeded()` — Checks if cache is older than `kUpdateAutomaticFiltersMinDays` (3 days). If so, fetches from S3 in a background `Task`.
- `forceUpdateAutomaticFilters()` — Async. Always fetches regardless of cache age. Used by pull-to-refresh.
- After an S3 fetch, cache writes (`updateCacheIfNeeded`) run on the **MainActor** so Core Data view-context work stays on the main thread.
- Rule/language state changes persist immediately via `PersistanceManager.commitContext()`.

---

## DefaultsManager

**Files:** `Framework Layer/Managers/DefaultsManager.swift`, `Protocols/DefaultsManagerProtocol.swift`

UserDefaults wrapper for app settings.

### Protocol

```swift
protocol DefaultsManagerProtocol {
    var isAppFirstRun: Bool { get set }
    var isExpandedAddFilter: Bool { get set }
    var lastOfflineNotificationDismiss: Date? { get set }
    var sessionAge: Date? { get set }
    var sessionCounter: Int { get set }
    var didPromptForReview: Bool { get set }
    var lastSeenWhatsNewVersion: Int { get set }
    var didDismissReportingExtensionNudge: Bool { get set }
    var accentColorRGB: [String: Double] { get set }
    var appAge: Date { get }
    #if DEBUG
    func reset()
    #endif
}
```

### Key Properties

- `isAppFirstRun` — Controls onboarding display. Set to `false` after first dismiss.
- `isExpandedAddFilter` — Persists the expand/collapse state of AddFilterView's advanced options.
- `sessionCounter` / `sessionAge` — Track user sessions for review prompt logic.
- `appAge` — First launch date. Initialized once, never changes.
- `didPromptForReview` — Ensures App Store review prompt is shown only once.
- `lastOfflineNotificationDismiss` — Suppresses offline notification for `kHideiClouldStatusMemory` (60) minutes after dismiss.
- `lastSeenWhatsNewVersion` — Tracks the last What's New version the user has seen. Compared against `currentWhatsNewVersion` to decide whether to show the What's New sheet.
- `accentColorRGB` — `@StoredDefault` dictionary (`kNoColorDict` = system accent). `Color(accentRGB:)` / `Color.accentRGB` convert. Debug `reset()` clears the key.

---

## NetworkSyncManager

**Files:** `Framework Layer/Managers/NetworkSyncManager.swift`, `Protocols/NetworkSyncManagerProtocol.swift`

Monitors network connectivity and CloudKit sync status.

### Protocol

```swift
protocol NetworkSyncManagerProtocol: AnyObject {
    var syncStatus: SyncStatus { get }    // .unknown, .active, .failed
    var networkStatus: NetworkStatus { get } // .unknown, .online, .offline
    func onFirstStatusKnown(_ handler: @escaping () -> Void)
}
```

### Notification Names (defined in protocol file)

```swift
extension NSNotification.Name {
    static let networkStatusChange
    static let cloudSyncOperationComplete
    static let automaticFiltersUpdated
    static let onClipboardSet
    static let filtersStateChanged
    static let persistentStoreReloaded
}
```

### Network Monitoring

Uses `NWPathMonitor` on a background queue. Posts `.networkStatusChange` on status changes.

### CloudKit Sync Monitoring

Subscribes to `NSPersistentCloudKitContainer.eventChangedNotification`. Tracks three event types (setup, import, export). Maintains a "pre-sync fingerprint" (from `PersistanceManager.fingerprint`) to detect actual data changes during import.

On **successful import**: posts `.cloudSyncOperationComplete` (toast + refresh) when the fingerprint changed. Failed imports are logged separately.

`AppHomeView.startMonitoring` also compares store fingerprint to the last UI fingerprint once and `refresh()`es if the store is already ahead (import finished before observers were registered).

### Recovery Logic

When network comes online after a failed sync, or setup fails while online, reloads the CloudKit container. Failed setup schedules up to two delayed retries (5s, then 10s); a pending retry is cancelled if network recovery reloads first or setup succeeds. Retries run unless the network is known offline (`.unknown` is allowed — path monitor may not have reported yet).

`PersistanceManager.reloadContainer()` resets the view context (invalidating all managed objects), loads a new container, then posts `.persistentStoreReloaded` on the main queue. Screens that cache Core Data objects conform to `ViewWithPersistentStoreReload` and apply `.modifier(persistentStoreReload)` (`PersistentStoreReload.swift`).
---

## TipJarManager

**Files:** `Framework Layer/Managers/TipJarManager.swift`, `Protocols/TipJarManagerProtocol.swift`

Manages in-app purchase tip jar using StoreKit 2. Three consumable tip tiers (small, medium, large).

### Protocol

```swift
protocol TipJarManagerProtocol {
    @MainActor var products: [Product] { get }
    @MainActor var isLoadingProducts: Bool { get }
    func purchase(_ product: Product) async -> TipPurchaseResult
}
```

### TipPurchaseResult

```swift
enum TipPurchaseResult {
    case success(TipTier)
    case userCancelled
    case pending
    case failure(Error)
}
```

### Key Behaviors

- **Product loading** — On init, launches a `Task` that calls `Product.products(for:)` with `TipTier.allCases` product IDs. Products are sorted by price ascending. Both `products` and `isLoadingProducts` are `@MainActor`-isolated.
- **Transaction listener** — Background `Task` listens to `Transaction.updates` for server-side transaction completions. Finishes verified transactions automatically.
- **Unfinished transactions** — On init, iterates `Transaction.unfinished` and finishes any verified pending transactions.
- **Purchase flow** — `purchase(_:)` handles all StoreKit result cases (success, userCancelled, pending, unknown) and verification. Returns a typed `TipPurchaseResult`.
- **StoreKit configuration** — Local `TipJar.storekit` file (synced from App Store Connect) in `Resources/` for simulator testing. Referenced in the scheme's `LaunchAction`.

### TipTier

Defined in `Constants.swift`. `CaseIterable` enum with `String` raw values (product IDs). Computed properties: `emoji`, `displayName`, `tierDescription`, `iconColor`, `confettiBirthRate`, `confettiLifetime`, `confettiVelocity`.

---

## FilterTransferManager

**Files:** `Framework Layer/Managers/FilterTransferManager.swift`, `Protocols/FilterTransferManagerProtocol.swift`

Merge-only import/export of user filters. Export writes a versioned JSON payload to a `.sfsfilters` file in the temp directory — the user picks which filters first (same picker UI as import). Import never deletes existing filters; new rows get new UUIDs via `addFilter`. One in-flight picker at a time (`pendingPreview` / `pendingKind` / `lastImportResult`).

### Protocol

```swift
protocol FilterTransferManagerProtocol {
    var pendingPreview: FilterTransferPreview { get }
    var pendingKind: FilterTransferKind { get }
    func exportPayload() throws -> Data
    func writeExportFile(candidates: [FilterTransferCandidate]) throws -> URL
    func queueExport() -> FilterTransferPreview
    func clearPendingExport()
    func deleteExportFile(at url: URL)
    func isExportFile(_ url: URL) -> Bool
    func readFile(at url: URL) throws -> Data
    func previewImport(data: Data) throws -> FilterTransferPreview
    func queueImport(data: Data) throws -> FilterTransferPreview
    func clearPendingImport() -> FilterTransferResult?
    func importFilters(_ candidates: [FilterTransferCandidate]) -> FilterTransferResult
}
```

### Key Behaviors

- **`queueImport`** starts an import session (`pendingPreview`, `pendingKind = .importFilters`). Home still `recordLaunch(.filterImport)` when there is nothing to add; `presentNextFlow` shows the native alert instead of the preview sheet.
- **`queueExport`** starts an export session from local filters (`pendingKind = .exportFilters`). Home `requestSheet(.filterExport)`.
- **`importFilters`** writes onto that session. **`clearPendingImport`** ends it and returns the result (or nil) for the dismiss toast.
- **`writeExportFile(candidates:)`** writes only the selected rows and holds the temp URL. The export picker presents the share sheet on top of itself. **`clearPendingExport()`** runs when that picker dismisses and deletes the temp file.
- **`isExportFile`** is `.sfsfilters` only. **`deleteExportFile`** only removes a `.sfsfilters` file inside the temp directory.
- Custom UTI / document type: `kFilterExportTypeIdentifier` in `Constants.swift`.

---

## FlowManager

**Files:** `Framework Layer/Managers/FlowManager.swift`, `Protocols/FlowManagerProtocol.swift`

Launch-order queue for Home sheets. It is not a navigator — Home still owns `sheetScreen`.

### Protocol

```swift
protocol FlowManagerProtocol {
    func recordLaunch(_ screen: Screen) -> Bool
    func request(_ screen: Screen)
    func enableWhatsNew()
    func next() -> Screen?
    func complete(_ screen: Screen)
    func resetSession()
}
```

### Key Behaviors

- **Occupancy:** `next()` sets `activeScreen`. Further `next()` returns nil until `complete`.
- **Order:** first run (`.enableExtension`) → launch (file / deep link) → automatic What's New (after `enableWhatsNew()`) → user `request`.
- **`recordLaunch`** returns `false` for `.enableExtension` during first run (already showing that sheet). Last successful launch wins.
- Automatic What's New is skipped if the session started as first run or a launch claimed the session.
- Debug `AppManager.reset()` clears the pending import and `resetSession()`.

---

## Services Layer

### HTTPService (Base)

**Files:** `Services Layer/Base/HTTPService.swift`, `Base/URLRequestProtocol.swift`

Generic HTTP client with protocol-based request definitions.

```swift
protocol HTTPServiceProtocol {
    func execute<T: Decodable>(type: T.Type, baseURL: URL, request: URLRequestProtocol) async throws -> T
}
```

**URLRequestProtocol** defines: `path`, `method` (GET/POST/PUT/DELETE/PATCH), `task` (plain or with parameters), `errorDomain`.

**HTTPServiceBase** — Common base for services. Holds `httpService: HTTPServiceProtocol` and a weak `networkSyncManager` reference.

### AmazonS3Service

**File:** `Services Layer/AmazonS3Service.swift`

```swift
protocol AmazonS3ServiceProtocol: AnyObject {
    func fetchAutomaticFilters() async -> AutomaticFilterListsResponse?
}
```

- Fetches `GET /simply-filter-sms/1.0.0/automatic_filters.json` from S3
- Guards against duplicate concurrent requests via `isFetching` flag
- Returns `nil` when offline or already fetching

### ReportMessageService

**File:** `Services Layer/ReportMessageService.swift`

```swift
protocol ReportMessageServiceProtocol: AnyObject {
    @discardableResult
    func reportMessage(reportMessageRequestBody: ReportMessageRequestBody) async -> Bool
}
```

- Posts to `POST /report` (`https://api.ben-dahan.com/report`, public, no auth)
- Body: `{ classification: { sender, bodies, type } }`
- Returns `true` on HTTP 200

### Request/Response DTOs

**AutomaticFilterListsResponse:**
```swift
struct AutomaticFilterListsResponse: Codable {
    let filterLists: [String: LanguageFilterListResponse]  // language code -> filter lists
}
struct LanguageFilterListResponse: Codable {
    let allowSenders: [String]
    let allowBody: [String]
    let denySender: [String]
    let denyBody: [String]
}
```

Supports base64 encoding/decoding for CoreData caching.

**ReportMessageResponse:**
```swift
struct ReportMessageResponse: Codable {
    let statusCode: Int?
    let message: String?
}
```

---

## Utility Files

### EmojiGenerator

**File:** `Framework Layer/EmojiGenerator.swift`

`enum EmojiGenerator` with a single static method `randomEmoji() -> String`. Picks from 11 Unicode emoji ranges, validates via `isEmojiPresentation` / `isEmoji`, retries up to 8 times, falls back to "smile". Used by the emoji rule toggle button in AppHomeView.

### SharedUITestsHelpers

**File:** `Framework Layer/SharedUITestsHelpers.swift`

- `UIApplication.isInTestingMode` — Checks for `-Testing` in process arguments (DEBUG only)
- `TestIdentifier` enum — All accessibility identifiers used by UI tests (e.g., `.addFilterButton`, `.appMenuButton`, `.testSenderInput`)
