## Context

The app already has a `ReportMessageService` that posts junk/not-junk reports to a Lambda endpoint, and a `ReportType` enum (`junk` / `notJunk`) in `Constsants.swift`. The existing reporting UI (`ReportMessageView`) is inside the main app. This change adds a second, system-integrated path: an `ILClassificationUIExtensionViewController` subclass that surfaces when the user long-presses a conversation in iOS Messages and taps "Report Messages."

The extension runs in a separate process, is instantiated fresh on every invocation, and has its container wiped by the system on termination. It cannot access CoreData, CloudKit, or `AppManager.shared`.

## Goals / Non-Goals

**Goals:**
- Add a Reporting Extension target that participates in the iOS "Report Messages" flow
- Collect junk / not-junk feedback and forward it to the existing Lambda endpoint
- Reuse `HTTPService`, `ReportMessageRequest`, and `ReportMessageRequestBody` from the services layer (compiled into the new target)
- Present a SwiftUI confirmation UI embedded in the UIKit extension view controller
- Add a new `reportJunkAndBlockSender` case to `ReportType` (or handle it alongside `junk`)

**Non-Goals:**
- Persistent state inside the extension (wiped on termination — by design)
- Access to user filters or CoreData from within the extension
- Changing or replacing the existing in-app `ReportMessageView` flow
- Supporting Call Reporting (SMS/Call Reporting extension covers both, but this change focuses on SMS)

## Decisions

### 1. System-delivered networking via `ILClassificationExtensionNetworkReportDestination`

Apple offers two report delivery modes: (a) system delivers the `userInfo` payload to a configured HTTPS endpoint via associated domains, or (b) the extension makes the network call itself and returns the action to iOS.

**Decision: (a) — set `userInfo` on `ILClassificationResponse` and let iOS POST it to `ILClassificationExtensionNetworkReportDestination`.**

Rationale: Option (b) was attempted first but the extension sandbox blocks all outbound networking — DNS queries and HTTP calls are killed by the OS. Option (a) requires a `classificationreport:` associated domain entitlement, an AASA file at `/.well-known/apple-app-site-association`, and a public (no API key) HTTPS endpoint. A new API Gateway (`j476b01zf3`, custom domain `api.ben-dahan.com`) and ACM certificate were set up to support this. The system POST only fires from TestFlight/App Store builds — not from dev installs. Full AWS setup documented in `aws-setup.md`.

### 2. No `ReportMessageService` wrapper — use `HTTPService` directly

`ReportMessageService` extends `HTTPServiceBase`, whose initializer calls `AppManager.shared.networkSyncManager`. Pulling in `AppManager` into the extension target would drag in CoreData, CloudKit, and the full framework layer.

**Decision: instantiate `HTTPService()` directly in the extension and call `execute(...)` with a `ReportMessageRequest`.** No network-status guard — the extension's lifecycle is short and fire-and-forget. If the request fails (offline), we log and move on; the user's explicit tap is the signal, not the delivery confirmation.

### 3. UIKit root + SwiftUI content

`ILClassificationUIExtensionViewController` is a UIKit class. SwiftUI is used for all UI in the app.

**Decision: the extension's principal class subclasses `ILClassificationUIExtensionViewController` and adds a `UIHostingController<ReportingConfirmationView>` as a child view controller.** This keeps the UIKit surface minimal (lifecycle only) and the actual UI in SwiftUI.

### 4. Three-action UI: Junk / Junk + Block Sender / Not Junk

`ILClassificationAction` has three non-`.none` cases: `.reportJunk`, `.reportJunkAndBlockSender`, `.reportNotJunk`. The existing `ReportType` enum has `junk` and `notJunk`.

**Decision: add a `junkAndBlockSender` case to `ReportType`** (raw value 2). It sends the same `"deny"` type string to Lambda as `junk`, but returns `.reportJunkAndBlockSender` to iOS so the system also adds the sender to the block list. This keeps Lambda logic unchanged.

### 5. Shared source files compiled into both targets

Rather than extracting a shared framework (overkill), the following files are added to the Reporting Extension target in Xcode:
- `HTTPService.swift` + `URLRequestProtocol.swift` (base networking)
- `ReportMessageRequest.swift` + `ReportMessageResponse.swift` + `ReportMessageRequestBody`
- `Constsants.swift` (for `ReportType` and the Lambda base URL)
- `SharedExtensions.swift` (for the `~` localization operator)

No new framework target is needed.

### 6. No in-app onboarding for the reporting extension

The iOS onboarding path is: Settings > Phone > SMS/Call Reporting > Simply Filter SMS. There is no public API to detect enablement state, making any in-app prompt a static one-way instruction. This is deferred to a future change.

## Risks / Trade-offs

- **One extension at a time**: iOS allows only one SMS/Call Reporting extension enabled per device. Users with a carrier app that occupies this slot won't be able to enable ours. → No mitigation possible; acknowledge in App Store copy.
- **No delivery confirmation**: Fire-and-forget networking means we can't retry on failure or confirm the report landed. → Acceptable — same behavior as the existing in-app report flow.
- **UIKit boilerplate**: `ILClassificationUIExtensionViewController` is UIKit-only; requires hosting controller plumbing. → Contained to the principal class (~50 lines).
- **`Constsants.swift` recompiled in extension**: The file is large and includes CoreData-dependent enum extensions (`Filter` computed properties). Those properties reference CoreData types not available in the extension. → Solution: use `#if canImport(CoreData)` guards in `SharedExtensions.swift` around CoreData-dependent code, or move `ReportType` to a smaller shared file.

## Open Questions

~~Should the confirmation UI show a preview of the reported message body/sender?~~ **Resolved: No** — keep the UI clean; no message content shown.

~~Do we want to add an onboarding nudge?~~ **Resolved: Out of scope.** There is no public API to detect whether the reporting extension is enabled. Deferred to a future change.
