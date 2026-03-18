## ADDED Requirements

### Requirement: Extension registers as SMS/Call Reporting provider
The app SHALL include a Reporting Extension target that registers with iOS as an SMS/Call Reporting extension via `NSExtension` with `NSExtensionPointIdentifier` set to `com.apple.identitylookupui.classification-ui`. The extension SHALL be distributed as part of the Simply Filter SMS app bundle.

#### Scenario: Extension appears in iOS Settings
- **WHEN** the user navigates to Settings > Phone > SMS/Call Reporting
- **THEN** Simply Filter SMS SHALL appear as an available reporting provider

#### Scenario: Extension is selectable
- **WHEN** the user selects Simply Filter SMS in SMS/Call Reporting settings
- **THEN** it SHALL become the active reporting extension

---

### Requirement: Extension presents confirmation UI on report invocation
When invoked from the iOS Messages "Report Messages" flow, the extension SHALL present a confirmation UI that asks the user to choose a report action. The UI SHALL NOT display any preview of the message content or sender.

#### Scenario: User invokes report from Messages
- **WHEN** the user long-presses a conversation in iOS Messages and taps "Report Messages"
- **THEN** the extension's confirmation UI SHALL be displayed

#### Scenario: No message content shown
- **WHEN** the confirmation UI is displayed
- **THEN** the UI SHALL NOT show the sender's phone number, name, or any part of the message body

---

### Requirement: Extension offers three report actions
The confirmation UI SHALL present exactly three actions: Report Junk, Report Junk & Block Sender, and Not Junk. The UI SHALL enable the Done/confirm button only after the user selects one of the three actions.

#### Scenario: User selects Report Junk
- **WHEN** the user selects "Report Junk" and confirms
- **THEN** the extension SHALL return `ILClassificationAction.reportJunk` to iOS

#### Scenario: User selects Report Junk & Block Sender
- **WHEN** the user selects "Report Junk & Block Sender" and confirms
- **THEN** the extension SHALL return `ILClassificationAction.reportJunkAndBlockSender` to iOS
- **THEN** iOS SHALL add the sender to the system block list

#### Scenario: User selects Not Junk
- **WHEN** the user selects "Not Junk" and confirms
- **THEN** the extension SHALL return `ILClassificationAction.reportNotJunk` to iOS

#### Scenario: User cancels without selecting
- **WHEN** the confirmation UI is displayed and the user has not selected any action
- **THEN** the confirm button SHALL be disabled

---

### Requirement: Extension forwards report to Lambda endpoint
Upon user confirmation, the extension SHALL fire-and-forget a POST request to the existing `/ReportMessage` Lambda endpoint using `ReportMessageRequestBody` with the sender and body extracted from `ILMessageClassificationRequest`. The report SHALL be sent before the extension returns its classification response.

#### Scenario: Junk report forwarded
- **WHEN** the user confirms "Report Junk" or "Report Junk & Block Sender"
- **THEN** the extension SHALL POST a request with `type: "deny"` to the Lambda endpoint

#### Scenario: Not Junk report forwarded
- **WHEN** the user confirms "Not Junk"
- **THEN** the extension SHALL POST a request with `type: "allow"` to the Lambda endpoint

#### Scenario: Network request fails
- **WHEN** the network request to Lambda fails or times out
- **THEN** the extension SHALL log the error and still return the classification response to iOS (no retry, no user-visible error)

---

### Requirement: Extension uses app design language
The confirmation UI SHALL follow the app's existing design system — accent colors, typography, and button styles consistent with the rest of Simply Filter SMS. Strings SHALL be localized using the existing `.strings` files and the `~` operator.

#### Scenario: UI matches app appearance
- **WHEN** the confirmation UI is displayed
- **THEN** it SHALL use the app's accent color and typography scale

#### Scenario: UI is localized
- **WHEN** the device language is set to a supported locale (e.g., Hebrew, Spanish)
- **THEN** all confirmation UI strings SHALL appear in the correct language

---

### Requirement: ReportType extended with junkAndBlockSender case
`ReportType` in `Constsants.swift` SHALL gain a `junkAndBlockSender` case (raw value 2) that maps to `ILClassificationAction.reportJunkAndBlockSender` and sends `type: "deny"` to Lambda (same as `junk`).

#### Scenario: junkAndBlockSender maps to deny
- **WHEN** the extension constructs a `ReportMessageRequestBody` for `junkAndBlockSender`
- **THEN** `body.type` SHALL equal `"deny"`

#### Scenario: Existing ReportType cases unaffected
- **WHEN** the `junk` or `notJunk` cases are used
- **THEN** their `type` strings SHALL remain `"deny"` and `"allow"` respectively
