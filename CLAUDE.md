# CLAUDE.md

Guidance for Claude Code in this repository. Only what the code doesn't say; for the rest, read the code.

## Project

Simply Filter SMS (Swift/SwiftUI, iOS 17+) filters SMS from unknown senders with Apple's IdentityLookup. Targets: the app, a Message Filter Extension (allow / junk / transaction / promotion), a Reporting Extension (report from iOS Messages), `Tests`, and `UI Tests`. Data syncs through Core Data + CloudKit, shared with the extension through the App Group `group.com.grizz.apps.dev.simply-filter-sms`. No package managers.

- **Build and test through Xcode.** New files are added with Xcode's MCP so they join their targets; an existing file's target membership has no MCP tool and is changed by hand in Xcode. Running tests: [docs/TESTS.md](docs/TESTS.md).
- **`UI Tests` is the App Store screenshot generator** for Fastlane (`testCreateSnapshots`, disabled in the test plan). Don't run it as testing.
- **Zero flaky or broken tests.** Every unit test passes on every run. A test that fails intermittently or for an environmental reason is fixed or deleted the day it's found, never documented as "known" or left disabled.
- **Localization:** BartyCrouch normalizes the `.strings` files (`.bartycrouch.toml`).

**Docs** (only what the code doesn't say):
- [docs/FRAMEWORK.md](docs/FRAMEWORK.md) — evaluation order, refresh and sync rules, `.sfsfilters` compatibility, scheduling
- [docs/SCREENS.md](docs/SCREENS.md) — one sentence per screen, plus its traps
- [docs/EXTENSION.md](docs/EXTENSION.md) — Message Filter and Reporting extension constraints
- [docs/TESTS.md](docs/TESTS.md) — running tests, mock conventions, the screenshot target
- [docs/DESIGN.md](docs/DESIGN.md) — design principles and the accent-color rules
- [docs/AWS_SETUP.md](docs/AWS_SETUP.md) — the reporting backend and S3 hosting of the AI Filtering lists
- [docs/localization/](docs/localization/) — per-language translation guides used by `/add-language`

## Architecture

- **Layers:** `Framework Layer/` (managers), `Services Layer/` (thin network gateways), `View Layer/` (screens and components). `AppManager.shared` creates and holds every manager and service; `AppManager(inMemory: true)` for tests and `AppManager.previews` for previews. Every manager has a `*Protocol` in `Managers/Protocols/`.
- **Managers own policy; services are gateways.** `FilterListService`, `ReportMessageService` and `UserNotificationCenterService` only fetch, post or schedule; what to do with the result is decided in a manager.
- **Every request is a type** in `Services Layer/Requests/` that owns its full `url` and `headers`; services never pass a base URL.
- **`Shared with Extension/`** is compiled into the app and the Message Filter Extension. Also compiled into the extension from elsewhere: `FilterTransferManagerProtocol.swift` (the `.sfsfilters` types and their only validation path), `MessageEvaluationManager(Protocol).swift` and `FilterListCatalogResponse.swift`.
- **`MessageEvaluationManager` has two initializers:** the app's `init(persistanceManager:)` follows the live context across `reloadContainer()`; the extension's and tests' `init(inMemory:)` owns a store loaded synchronously.
- **AI Filtering refresh** runs on the main actor; a concurrent caller joins the running refresh (`refreshTask`).
- **CloudKit recovery:** `reloadContainer()` runs only on a genuine offline→online reconnection (`NetworkStatus.isReconnection(from:)`). `.unknown` is not a network state: rebuilding the stack on the monitor's first report aborted the initial import. A failed setup is left to Core Data's own recovery; never retry it with `reloadContainer()`. After a reload, screens holding Core Data objects refresh through `.modifier(persistentStoreReload)`.
- **Inactivity reminder clock:** only `AppDelegate.applicationDidBecomeActive` moves it. Nothing on the launch path may, because `didFinishLaunching` also runs for background wakes.
- **FlowManager is a launch-order queue, not a navigator.** Order: first run → launch (file / deep link) → automatic What's New → user `request`. `next()` occupies it until `complete`.

## MVVM

- **ViewModel:** `class ViewModel: BaseViewModel, ObservableObject` inside `extension SomeView { }`, used as `SomeView.ViewModel`. `BaseViewModel` holds `appManager`. Views never touch managers.
- **`@StateObject` vs `@ObservedObject`:** sheets and screens that were recreated on parent re-renders use `@StateObject` with `init(model:) { _model = StateObject(wrappedValue: model) }`. **Home is the exception:** the `App` holds `AppHomeView.ViewModel` as `@StateObject` and Home is `@ObservedObject`; launch work runs from that ViewModel's `init`, not `.onAppear`.
- **Navigation:** `Screen.build()` makes each View + ViewModel. ViewModels publish `navigationScreen` (push) and `sheetScreen` (sheet); Home's sheets go through `FlowManager`.
- **Sheet callbacks — don't touch `Screen`.** Associated values break its `Int` raw values and the whole router. The presenting ViewModel owns the presented one (`@Published var fooViewModel: FooView.ViewModel?`, `Identifiable` via `let id = UUID()`), injects the closure when creating it, and presents with `.sheet(item:)`. Example: `FilterListView.ViewModel.addFilterViewModel`.
- **Home alerts aren't `Screen`s:** a `@Published var showFooAlert: Bool` plus `.alert(isPresented:)`. Never add a `Screen` that builds `EmptyView` to route one. To wait behind first run / launch / What's New, raise it from `navigationScreen`'s `didSet` (`oldValue != nil && navigationScreen == nil`) and guard on `isHomeUnobstructed`. Nudges sharing that hook are mutually exclusive: `tryRequestReview()` returns whether it prompted, and the inactivity ask runs only when it didn't.
- **`EmbeddedNotificationView` goes outside `NavigationView`,** or the toast appears below the navigation bar. Each `NotificationView.Notification` has a `timeout` and hides itself; no timers at call sites.
- **`StatefulItem<T>`** bridges getter/setter closures to a `Bool` for toggles backed by manager calls.

## Conventions

- **`"key"~`** is `NSLocalizedString("key", comment: "")`.
- **Enums over structs for constant data:** `CaseIterable` enums with computed properties (see `FilterType`, `RuleType`, `WhatsNewEntry`).
- **Extensions over repeated conditionals:** e.g. `element.conditionalTap(!isPad)` instead of `if !isPad { element.tap() }` at every call site.
- **Naming:** `*Protocol`, `mock_*` (one per protocol in `Tests/Mocks/`), `*Manager`, `*View`.
- **Logging:** `AppManager.logger`; the extension has its own.
- **Core Data model:** `Resources/Simply-Filter-SMS.xcdatamodeld`; Int64 raw values mapped to enums in `SharedExtensions.swift`. **After any model change, deploy the CloudKit schema to production** (CloudKit Console → Schema → Deploy to Production) before release: development auto-evolves, production doesn't, and a missing field silently stops syncing in TestFlight/App Store only. Check the diff first: a record type deployed to production can never be removed.
- **In-memory stores never sync** (`cloudKitContainerOptions = nil`). With mirroring on, a save in an isolated test run throws `No eligible connection available`.
- **`.sfsfilters` is the one filter-list format** for exports, AI lists and (later) subscribed lists. Changes are additive and optional so `version` stays `1` and 3.2 can still read new files. A field a record doesn't use is omitted, never a placeholder: regex records omit `case`, allow records omit `folder` (`exportKey(for:)` / `init?(exportKey:for:)`). Exports never write `name`.
- **What's New:** a new `WhatsNewEntry` bumps `currentWhatsNewVersion` **unless that version hasn't shipped yet.** An entry can be actionable (`isActionable`); the presenting screen handles it in `onActionableEntryTapped`.
- **Dark mode surfaces:** `.gray.opacity(…)`, not `Color(.systemGray6)`, which disappears in dark mode.
- **Don't use `.task` for one-time loads:** it re-fires when view identity changes. Use `Task { }` in the ViewModel's `init`.
- **Identity:** use `Filter.uuid` for `ForEach` ids, `scrollTo`, new-item dots and `@FocusState`, not `NSManagedObjectID`. Cache row ViewModels on the parent by that UUID; never build them inside `ForEach`.
- **Delayed clears check identity:** `if self?.newlyAddedFilter == filter { self?.newlyAddedFilter = nil }`, so an earlier timer can't clear a later value.
- **List row animation:** `listRowBackground` doesn't animate; use `.overlay` or modifiers on the row content. For a new-item marker, use a small accent `Circle()` driven by local `@State` opacity, with both `.onAppear` (rows that appear with the flag set) and `.onChange(of:)` (rows already there), guarded against double-firing.
