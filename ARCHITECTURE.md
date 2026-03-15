# ARCHITECTURE.md

Detailed architecture reference for Simply Filter SMS.

For project-wide patterns (MVVM, navigation, conventions), see [CLAUDE.md](CLAUDE.md).

## Documentation Index

| Document | Description |
|----------|-------------|
| [docs/SCREENS.md](docs/SCREENS.md) | Per-screen breakdown of all SwiftUI views, ViewModels, layouts, and supporting components |
| [docs/FRAMEWORK.md](docs/FRAMEWORK.md) | Framework and Services layer — all managers, protocols, data flow, and the message evaluation pipeline |
| [docs/EXTENSION.md](docs/EXTENSION.md) | Message Filter Extension — how iOS delivers SMS to the extension and how it evaluates them |
| [docs/TESTS.md](docs/TESTS.md) | Testing patterns, unit tests, UI tests, mocks, and test infrastructure |
| [docs/DESIGN.md](docs/DESIGN.md) | Visual design system — colors, typography, spacing, components, and guidelines for new features |

## Screen Map

| Screen enum case | View | Presentation |
|---|---|---|
| `appHome` | AppHomeView | Root |
| `onboarding` | EnableExtensionView | Sheet (first run) |
| `help` | HelpView | Sheet |
| `about` | AboutView | Sheet |
| `enableExtension` | EnableExtensionView (= onboarding) | Sheet |
| `testFilters` | TestFiltersView | Sheet |
| `addLanguageFilter` | LanguageListView (mode: .blockLanguage) | Sheet |
| `addAllowFilter` | AddFilterView (filterType: .allow) | Sheet |
| `addDenyFilter` | AddFilterView (filterType: .deny) | Sheet |
| `automaticBlocking` | LanguageListView (mode: .automaticBlocking) | Push |
| `denyFilterList` | FilterListView (filterType: .deny) | Push |
| `allowFilterList` | FilterListView (filterType: .allow) | Push |
| `denyLanguageFilterList` | FilterListView (filterType: .denyLanguage) | Push |
| `reportMessage` | ReportMessageView | Sheet |
| `whatsNew` | WhatsNewView | Sheet |
| `tipJar` | TipJarView | Sheet |
| `countryList` | CountryListView | Sheet |

## Manager Dependency Graph

```
AppManager (Singleton)
├── PersistanceManager ──── CoreData + CloudKit
├── DefaultsManager ─────── UserDefaults
├── NetworkSyncManager ──── NWPathMonitor + CloudKit events
│   └── depends on: PersistanceManager
├── MessageEvaluationManager ── Filter evaluation engine
│   └── depends on: PersistanceManager (container)
├── AutomaticFilterManager ─── Community filter lists
│   └── depends on: PersistanceManager, AmazonS3Service
├── TipJarManager ─────────── StoreKit 2 IAP
├── AmazonS3Service ────────── HTTP → S3
│   └── depends on: NetworkSyncManager
└── ReportMessageService ───── HTTP → Lambda
    └── depends on: NetworkSyncManager
```

## Message Evaluation Pipeline

When an SMS arrives, `MessageEvaluationManager.evaluateMessage(body:sender:)` runs these checks in order (first match wins):

1. **All Unknown** → `.junk` (absolute gate — if enabled, blocks everything regardless of other filters)
2. **Allow filters** → `.allow` (user-created allowlist)
3. **Automatic filters (allow)** → `.allow` (trusted senders/body phrases from S3 community lists)
4. **Filter rules** → `.junk` (links, numbersOnly, shortSender, email, emojis, countryAllowlist)
5. **Deny filters** → `.junk` / `.transaction` / `.promotion` (user-created blocklist)
6. **Deny language filters** → `.junk` (blocked languages via NLLanguageRecognizer)
7. **Automatic filters (deny)** → `.junk` (spam keywords/senders from S3 community lists)
8. **No match** → `.allow` (default)
