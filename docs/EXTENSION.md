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

---

# Reporting Extension

How users report messages from iOS Messages and how reports reach the backend.

---

## Overview

The Reporting Extension is an iOS app extension (`.appex`) that implements `ILClassificationUIExtensionViewController`. When a user long-presses one or more messages in iOS Messages and taps "Report Messages", iOS invokes this extension to present a confirmation UI and collect the user's classification choice.

**Files:**
- `Reporting Extension/ReportingExtensionViewController.swift` — principal class
- `Reporting Extension/ReportingConfirmationView.swift` — SwiftUI confirmation UI

**Bundle ID:** `com.grizz.apps.dev.Simply-Filter-SMS.Simply-Filter-SMS-Report-Extension`

**Enable:** Settings > Phone > SMS/Call Reporting > Simply Filter SMS

## How It Works

```
User long-presses message(s) in iOS Messages → "Report Messages"
    |
    v
ReportingExtensionViewController.prepare(for:)
  - reads all messageCommunications (sender + all bodies)
  - populates ReportingConfirmationView.ViewModel
    |
    v
ReportingConfirmationView (SwiftUI)
  - shows sender + all message bodies with dividers
  - offers: Junk / Junk & Block Sender / Not Junk
    |
    v
User selects action → taps Done
    |
    v
ReportingExtensionViewController.classificationResponse(for:)
  - maps ReportType → ILClassificationAction
  - sets response.userInfo = {sender, bodies: [String], type}
    |
    v
iOS system (outside sandbox) POSTs to https://api.ben-dahan.com/report
  - wraps as: {"classification": {sender, bodies, type}, "app": {...}, "_version": 1}
    |
    v
API Gateway j476b01zf3 → Velocity template → ClassificationReport Lambda
  - writes one DynamoDB record per body to reported_messages table
```

## Shared Code

The Reporting Extension compiles these files from the main app (not shared via framework):

| File | Purpose |
|------|---------|
| `Constsants.swift` | `ReportType` enum (junk / notJunk / junkAndBlockSender), `reportMessageURL` |
| `SharedExtensions.swift` | `~` localization operator; CoreData extensions guarded with `#if !REPORTING_EXTENSION` |
| `HTTPService.swift` + `URLRequestProtocol.swift` | Base networking (not used directly — iOS delivers report via system) |
| `ReportMessageRequest.swift` + `ReportMessageResponse.swift` | Request/response types (compiled in for completeness) |

## Key Constraints

- **No AppManager / CoreData** — Extension runs in a separate process with no access to the shared database
- **No direct networking** — Extension sandbox blocks all outbound network calls; reports are delivered by iOS via `ILClassificationExtensionNetworkReportDestination`
- **TestFlight/App Store only** — iOS only fires the system POST in production distribution builds, not local dev installs
- **One extension per device** — iOS allows only one SMS/Call Reporting extension enabled at a time (carrier apps may occupy this slot)
- **Multi-message** — `ILMessageClassificationRequest.messageCommunications` can contain multiple messages (same sender); all bodies are collected and sent as an array

## AWS Backend

- **Endpoint:** `https://api.ben-dahan.com/report` (public, no auth)
- **API Gateway:** `j476b01zf3` (region: `us-east-1`)
- **Lambda:** `ClassificationReport` (Python 3.13) — source at `Classification Report Lambda/lambda_function.py`
- **Database:** DynamoDB `reported_messages` table — one record per body per report

See `openspec/changes/archive/2026-03-19-add-reporting-extension/aws-setup.md` for full AWS details.
