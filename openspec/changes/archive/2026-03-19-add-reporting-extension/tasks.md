## 0. Apple Developer Portal & App Store Connect

- [x] 0.1 ~~Register a new App ID~~ — existing App ID `com.grizz.apps.dev.Simply-Filter-SMS.Simply-Filter-SMS-Report-Extension` found; use this
- [x] 0.2 Enable the **App Groups** capability on the existing App ID and add `group.com.grizz.apps.dev.simply-filter-sms` to it
- [x] 0.3 ~~Create provisioning profiles manually~~ — all targets use Automatic signing; Xcode manages profiles automatically
- [x] 0.4 ~~Create distribution provisioning profile manually~~ — handled by Automatic signing
- [x] 0.5 ~~Verify the new extension bundle ID is included under the main app's App Store Connect entry~~ — deferred; confirm on next TestFlight upload

## 1. Xcode Target Setup

- [x] 1.1 Created "Reporting Extension" appExtension target (bundle ID: `com.grizz.apps.dev.Simply-Filter-SMS.Simply-Filter-SMS-Report-Extension`) via xcodeproj-cli; also set INFOPLIST_FILE, CODE_SIGN_ENTITLEMENTS, SWIFT_ACTIVE_COMPILATION_CONDITIONS=REPORTING_EXTENSION, CODE_SIGN_STYLE=Automatic, DEVELOPMENT_TEAM
- [x] 1.2 Create `Reporting Extension/` folder in the project root and add `Info.plist` with `NSExtensionPointIdentifier` set to `com.apple.identitylookupui.classification-ui`
- [x] 1.3 Create `Reporting Extension/Reporting Extension.entitlements` (App Group: `group.com.grizz.apps.dev.simply-filter-sms`) — same group as main app and filter extension
- [x] 1.4 Added all shared source files to Reporting Extension target via xcodeproj-cli; also guarded `HTTPServiceBase` with `#if !REPORTING_EXTENSION` (references `NetworkSyncManagerProtocol` not available in extension)

## 2. Shared Code Compatibility

- [x] 2.1 Audit `Constsants.swift` — no guards needed; `SharedUITestsHelpers.swift` will be compiled into the extension (same as filter extension), making `TestIdentifier` available
- [x] 2.2 Wrap `extension Filter { }` and `extension AutomaticFiltersRule { }` in `SharedExtensions.swift` with `#if !REPORTING_EXTENSION` so they are excluded when compiling the reporting extension target
- [x] 2.3 Add `junkAndBlockSender` case (raw value `2`) to `ReportType` in `Constsants.swift`; `type` returns `"deny"`, `name` returns `"reportMessage_junkAndBlockSender"~`

## 3. Extension Principal Class

- [x] 3.1 Create `Reporting Extension/ReportingExtensionViewController.swift` — subclass of `ILClassificationUIExtensionViewController`; embeds `ReportingConfirmationView` via `UIHostingController` as a child view controller
- [x] 3.2 Implement `classificationResponse(for:)` — reads selected `ReportType` from view model, sets `response.userInfo = {sender, body, type}` so iOS POSTs it to `api.ben-dahan.com/report` via `ILClassificationExtensionNetworkReportDestination`, returns `ILClassificationResponse` with mapped `ILClassificationAction`
- [x] 3.3 Wire `extensionContext.isReadyForClassificationResponse` via Combine sink on `confirmationViewModel.$selectedReportType`

## 4. Confirmation UI

- [x] 4.1 Create `Reporting Extension/ReportingConfirmationView.swift` — SwiftUI view with nested `ViewModel: ObservableObject` exposing `selectedReportType: ReportType?`
- [x] 4.2 Render three tappable rows for `.junk`, `.junkAndBlockSender`, `.notJunk` using `ReportType.name`; selected row shows a checkmark in accent color
- [x] 4.3 No message content or sender shown in the UI
- [x] 4.4 Uses SwiftUI `.accentColor` and standard list typography — consistent with the app

## 5. Networking in Extension

- [x] 5.1 Extract `sender` and `body` from `ILMessageClassificationRequest.messageCommunications.first`
- [x] 5.2 Set `response.userInfo = ["sender": ..., "body": ..., "type": ...]` — iOS delivers the POST to `ILClassificationExtensionNetworkReportDestination` outside the extension sandbox (direct HTTPService call not possible; extension sandbox blocks all outbound networking)
- [x] 5.3 Fire-and-forget via system delivery; no user-visible error; delivery only occurs in TestFlight/App Store builds

## 6. Localization

- [x] 6.1 Added `"reportMessage_junkAndBlockSender"` to English `.strings` file (reuses `reportMessage_` namespace alongside existing junk/notJunk strings)
- [x] 6.2 `ReportType.junkAndBlockSender.name` returns `"reportMessage_junkAndBlockSender"~`
- [x] 6.3 BartyCrouch normalized all files; translated into he, ar, es, fr, de, it, ja, ko, pt-BR (longest: fr at 1.85× English length, within limits)

## 7. Verification

- [x] 7.1 Build the Reporting Extension target in Xcode and confirm zero errors/warnings
- [x] 7.2 Run on a physical device or simulator: enable the extension in Settings > Phone > SMS/Call Reporting, long-press a conversation in Messages, tap "Report Messages", and confirm the UI appears
- [ ] 7.3 Verify all three actions route the correct `type` string to Lambda (check network logs) — pending TestFlight build
- [ ] 7.4 Verify "Report Junk & Block Sender" also adds the sender to the system block list — pending TestFlight build
- [x] 7.5 Confirm existing unit tests still pass (`xcodebuild test`)
