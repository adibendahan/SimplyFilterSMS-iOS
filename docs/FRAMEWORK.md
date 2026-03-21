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
    func onAppLaunch()
    func onNewUserSession()
    func getFrequentlyAskedQuestions() -> [QuestionView.ViewModel]
}
```

### Initialization Order

1. `PersistanceManager` (in-memory if specified)
2. `DefaultsManager`
3. `MessageEvaluationManager` (receives persistance container)
4. `NetworkSyncManager` (receives persistance manager)
5. `AmazonS3Service` (receives network sync manager)
6. `ReportMessageService` (receives network sync manager)
7. `AutomaticFilterManager` (receives persistance manager + S3 service)
8. `TipJarManager`
9. Logger wired to MessageEvaluationManager

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
    func evaluateMessage(body: String, sender: String) -> MessageEvaluationResult
    func setLogger(_ logger: Logger)
}
```

### MessageEvaluationResult

```swift
struct MessageEvaluationResult {
    let action: ILMessageFilterAction  // .allow, .junk, .transaction, .promotion
    let reason: String?                // Human-readable reason for the decision
}
```

### Evaluation Pipeline (order matters — first match wins)

1. **Allow filters** — Fetches `Filter` records with `type == .allow`. Checks if sender or body matches (per filter's target, matching, and case settings). Returns `.allow` if matched.

2. **Deny filters** — Fetches `Filter` records with `type == .deny`. Same matching logic. Returns the filter's `denyFolderType.action` (`.junk`, `.transaction`, or `.promotion`).

3. **Language deny** — Fetches `Filter` records with `type == .denyLanguage`. Uses `NLLanguageRecognizer` to detect the message body's dominant language. If that language is in the deny list, returns `.junk`.

4. **Automatic filters** — Fetches `AutomaticFiltersLanguage` records (active ones). For each active language, loads the cached `AutomaticFilterListsResponse` (base64-decoded from CoreData). Checks sender against `allowSenders`/`denySender` and body against `allowBody`/`denyBody`.

5. **Smart rules** — Fetches `AutomaticFiltersRule` records (active ones). Checks in order:
   - `allUnknown` — Block everything (most destructive)
   - `links` — Body contains a URL (via `NSDataDetector`)
   - `numbersOnly` — Sender is all digits
   - `shortSender` — Sender length <= configurable threshold (3-6 chars)
   - `email` — Sender contains `@` and `.`
   - `emojis` — Body contains emoji characters

6. **No match** — Returns `.allow` with reason `"noMatch"`.

### Filter Matching Logic

For each filter, matching depends on three settings:
- **FilterTarget:** `.all` (sender+body combined), `.sender`, or `.body`
- **FilterMatching:** `.contains` (substring) or `.exact` (full string match using word boundaries)
- **FilterCase:** `.caseInsensitive` or `.caseSensitive`

### Database Access

Creates its own `NSManagedObjectContext` from the shared `AppPersistentCloudKitContainer`. When instantiated by the extension, uses `isReadOnly: true`.

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

A computed string concatenation of all filter texts + automatic filter states. Used by `NetworkSyncManager` to detect whether a CloudKit sync actually changed data (by comparing pre-sync and post-sync fingerprints).

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

---

## NetworkSyncManager

**Files:** `Framework Layer/Managers/NetworkSyncManager.swift`, `Protocols/NetworkSyncManagerProtocol.swift`

Monitors network connectivity and CloudKit sync status.

### Protocol

```swift
protocol NetworkSyncManagerProtocol: AnyObject {
    var syncStatus: SyncStatus { get }    // .unknown, .active, .failed
    var networkStatus: NetworkStatus { get } // .unknown, .online, .offline
}
```

### Notification Names (defined in protocol file)

```swift
extension NSNotification.Name {
    static let networkStatusChange
    static let cloudSyncOperationComplete
    static let automaticFiltersUpdated
    static let onClipboardSet
}
```

### Network Monitoring

Uses `NWPathMonitor` on a background queue. Posts `.networkStatusChange` on status changes.

### CloudKit Sync Monitoring

Subscribes to `NSPersistentCloudKitContainer.eventChangedNotification`. Tracks three event types (setup, import, export). Maintains a "pre-sync fingerprint" (from `PersistanceManager.fingerprint`) to detect actual data changes during import. Posts `.cloudSyncOperationComplete` only when fingerprint changed.

### Recovery Logic

When network comes online after a failed sync, calls `PersistanceManager.reloadContainer()` to retry CloudKit sync.

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

Defined in `Constsants.swift`. `CaseIterable` enum with `String` raw values (product IDs). Computed properties: `emoji`, `displayName`, `tierDescription`, `iconColor`, `confettiBirthRate`, `confettiLifetime`, `confettiVelocity`.

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

**URLRequestProtocol** defines: `path`, `method` (GET/POST/PUT/DELETE/PATCH), `task` (plain or with parameters), `errorDomain`, `auth` (whether to include API key).

**HTTPServiceBase** — Common base for services. Holds `httpService: HTTPServiceProtocol` and a weak `networkSyncManager` reference.

**Authentication:** When `auth: true`, reads `API_KEY` from `Info.plist` and adds it as `x-api-key` header.

### AmazonS3Service

**File:** `Services Layer/AmazonS3Service.swift`

```swift
protocol AmazonS3ServiceProtocol: AnyObject {
    func fetchAutomaticFilters() async -> AutomaticFilterListsResponse?
}
```

- Fetches `GET /simply-filter-sms/1.0.0/automatic_filters.json` from S3
- No authentication required
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

- Posts to `POST /ReportMessage` on AWS Lambda
- Requires API key authentication
- Body: `{ sender, body, type }` where type is "deny" or "allow"
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
