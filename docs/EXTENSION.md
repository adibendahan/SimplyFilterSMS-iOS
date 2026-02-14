# Message Filter Extension

How iOS delivers SMS messages to the extension and how they are evaluated.

---

## Overview

The Message Filter Extension is an iOS app extension (`.appex`) that implements Apple's IdentityLookup framework. When an SMS arrives from an unknown sender (not in Contacts), iOS invokes the extension to classify the message.

**File:** `Message Filter Extension/MessageFilterExtension.swift`

## How It Works

```
Unknown SMS arrives
    |
    v
iOS Messages app
    |
    v
ILMessageFilterExtension.handle(_:context:completion:)
    |
    v
MessageFilterExtension.offlineAction(for:)
    |
    v
MessageEvaluationManager.evaluateMessage(body:sender:)
    |
    v
Returns ILMessageFilterAction (.allow / .junk / .transaction / .promotion)
    |
    v
iOS sorts message into appropriate folder
```

## Implementation

```swift
final class MessageFilterExtension: ILMessageFilterExtension {
    lazy var logger: Logger  // subsystem: extension category
    lazy var extensionManager: MessageEvaluationManagerProtocol  // MessageEvaluationManager()
}
```

The extension:
1. Creates its own `MessageEvaluationManager` instance (not via `AppManager` — the extension doesn't use the app's singleton)
2. Sets up its own `Logger` with category `"extension"` (vs `"main"` in the app)
3. Implements `ILMessageFilterQueryHandling` to handle incoming queries
4. All evaluation is **offline only** — no network deferral via `ILNetworkResponse`

## Shared Code

The extension and main app share code via the `Shared with Extension` folder:

| File | Purpose |
|------|---------|
| `AppPersistentCloudKitContainer.swift` | CoreData container using App Group for shared database access |
| `SharedExtensions.swift` | Extensions on `Filter`, `NLLanguage`, `ILMessageFilterAction`, `String` + the `~` localization operator |
| `Constsants.swift` | All enums (`FilterType`, `DenyFolderType`, etc.) and global constants |

## Database Access

The extension reads the same CoreData database as the main app via:
- **App Group:** `group.com.grizz.apps.dev.simply-filter-sms`
- **Container:** `AppPersistentCloudKitContainer` overrides `defaultDirectoryURL()` to point to the shared container
- **Read-only:** When `MessageEvaluationManager` is initialized without a container (as in the extension), it creates its own with `isReadOnly: true` to avoid write conflicts with the main app

## Key Constraints

- **No UI** — Extensions cannot present any interface
- **No network** — This extension only does offline evaluation (no `defer` to network)
- **Limited memory** — Extensions have stricter memory limits than apps
- **Shared database** — Must handle concurrent access with the main app gracefully
- **No AppManager** — The extension instantiates `MessageEvaluationManager` directly, bypassing the app's DI container
