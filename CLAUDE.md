# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Simply Filter SMS is an iOS app (Swift/SwiftUI, iOS 15.2+) that filters unknown SMS messages using Apple's IdentityLookup framework. It includes a Message Filter Extension that runs in the background to classify incoming messages as junk, transaction, or promotion. Data syncs across devices via CoreData + CloudKit (NSPersistentCloudKitContainer).

App Store: https://apps.apple.com/us/app/simply-filter-sms/id1603222959

## Build & Test

Open `Simply Filter SMS.xcodeproj` in Xcode. No package managers (SPM/CocoaPods) are used.

**Targets:**
- `Simply Filter SMS` — Main app
- `Message Filter Extension` — ILMessageFilterExtension (`.appex`)
- `Tests` — Unit tests
- `UI Tests` — Snapshot tests via Fastlane

**Command-line build/test:**
```bash
xcodebuild -project "Simply Filter SMS.xcodeproj" -scheme "Simply Filter SMS" -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project "Simply Filter SMS.xcodeproj" -scheme "Simply Filter SMS" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

**Localization:** BartyCrouch normalizes `.strings` files (English + Hebrew). Config in `.bartycrouch.toml`.

## Architecture

Three-layer clean architecture with protocol-based dependency injection:

### Framework Layer (`Simply Filter SMS/Framework Layer/`)
- **AppManager** — Singleton service locator (`AppManager.shared`). Creates and holds all managers/services. Use `AppManager(inMemory: true)` for previews/tests.
- **MessageEvaluationManager** — Core filtering engine. Evaluates sender + body against user filters, automatic rules, and language filters. Shared between app and extension.
- **PersistanceManager** — CoreData CRUD operations for `Filter`, `AutomaticFiltersRule`, `AutomaticFiltersLanguage` entities.
- **AutomaticFilterManager** — Fetches community filter lists from S3, applies automatic rules (block links, numbers-only senders, short senders, emails, emojis, all unknown).
- **DefaultsManager** — UserDefaults wrapper for app settings.
- **NetworkSyncManager** — NWPathMonitor + CloudKit sync status tracking.

Every manager has a corresponding `*Protocol` in `Managers/Protocols/` for testability.

### Services Layer (`Simply Filter SMS/Services Layer/`)
- **AmazonS3Service** — Fetches automatic filter lists from AWS S3.
- **ReportMessageService** — Reports spam/ham to AWS Lambda endpoint.
- **HTTPService** — Base class for HTTP requests with `URLRequestProtocol`.

### View Layer (`Simply Filter SMS/View Layer/`)
- **Screens/** — SwiftUI views: `AppHomeView`, `FilterListView`, `AddFilterView`, `TestFiltersView`, `LanguageListView`, `AboutView`, `HelpView`, `ReportMessageView`, `EnableExtensionVideoView`.
- **Others/** — `BaseViewModel` (base class for all ViewModels), reusable components, button styles, view modifiers.

### Shared with Extension (`Framework Layer/Shared with Extension/`)
Code compiled into both the app and the Message Filter Extension:
- `Constsants.swift` — All enums (`FilterType`, `DenyFolderType`, `FilterTarget`, `FilterMatching`, `FilterCase`, `RuleType`, `ReportType`) and global constants.
- `SharedExtensions.swift` — Extensions on `Filter` (CoreData), `NLLanguage`, `ILMessageFilterAction`, `String`, plus the `~` postfix operator.
- `AppPersistentCloudKitContainer.swift` — CoreData/CloudKit container setup with App Group (`group.com.grizz.apps.dev.simply-filter-sms`).

### Message Filter Extension (`Message Filter Extension/`)
- `MessageFilterExtension.swift` — Entry point implementing `ILMessageFilterQueryHandling`. Uses `MessageEvaluationManager` to evaluate messages offline (no network deferral).

## MVVM Pattern

Every screen follows the same structure:

- **Nested ViewModel:** Declared as `class ViewModel: BaseViewModel, ObservableObject` inside `extension SomeView { }`. Always accessed as `SomeView.ViewModel`.
- **BaseViewModel:** Holds a single `appManager: AppManagerProtocol` property (defaults to `AppManager.shared`). All ViewModels subclass it for DI access.
- **View owns ViewModel:** Each View holds `@ObservedObject var model: ViewModel`. Views never access managers directly.
- **Screen enum router:** `Screen.swift` defines all screens as enum cases with a `build()` factory method that instantiates the View+ViewModel pair. Used for both navigation and sheet presentation.
- **Navigation via published optionals:** ViewModels expose `@Published var navigationScreen: Screen?` (push), `sheetScreen: Screen?` (sheet), and `modalFullScreen: Screen?` (full-screen cover) to drive navigation declaratively.
- **StatefulItem<T>:** Generic wrapper (`View Layer/Others/StatefulItem.swift`) that bridges getter/setter closures to a `Bool state` property with `didSet`. Used for Toggle bindings backed by manager calls.
- **Overlay modifiers:** `EmbeddedFooterView` (app version footer) and `EmbeddedNotificationView` (toast banner) are applied via `.modifier()` in ZStack overlays. Defined in `ViewModfiers.swift`.
- **Previews:** Always use `AppManager.previews` (in-memory store with debug data).

See [ARCHITECTURE.md](ARCHITECTURE.md) for the full documentation index, dependency graph, and links to detailed docs on [screens](docs/SCREENS.md), [framework/services](docs/FRAMEWORK.md), [extension](docs/EXTENSION.md), [tests](docs/TESTS.md), and [design system](docs/DESIGN.md).

## Key Conventions

- **Localization operator:** Postfix `~` operator converts string keys to localized strings: `"key"~` equals `NSLocalizedString("key", comment: "")`.
- **Enums over structs for constant data:** When defining a fixed set of entries with computed properties (display names, icons, colors, etc.), prefer `CaseIterable` enums with computed properties over structs with separate arrays. See `FilterType`, `RuleType`, `WhatsNewEntry` in `Constsants.swift` for examples.
- **Naming:** `*Protocol` for interfaces, `mock_*` prefix for test mocks, `*Manager` for services, `*View` for SwiftUI views.
- **Logging:** `AppManager.logger` (OSLog `Logger`) used throughout. Extension has its own logger instance.
- **CoreData model:** Versioned at `Resources/Simply-Filter-SMS.xcdatamodeld` (v3). Entities use Int64 raw values mapped to Swift enums via computed properties in `SharedExtensions.swift`.
- **Test mocks:** Located in `Tests/Mocks/` — one mock per protocol.
- **App Group:** Shared container `group.com.grizz.apps.dev.simply-filter-sms` allows CoreData access from both app and extension.
