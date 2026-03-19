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

### Requirement: Extension presents confirmation UI showing message preview
When invoked from the iOS Messages "Report Messages" flow, the extension SHALL present a confirmation UI that shows the sender and all selected message bodies, and asks the user to choose a report action.

#### Scenario: User invokes report from Messages (single message)
- **WHEN** the user long-presses a conversation in iOS Messages and taps "Report Messages"
- **THEN** the extension's confirmation UI SHALL be displayed showing the sender and the message body labeled "Message"

#### Scenario: User invokes report from Messages (multiple messages)
- **WHEN** the user selects multiple messages and taps "Report Messages"
- **THEN** the extension's confirmation UI SHALL display the sender once and all selected bodies, labeled "Message 1", "Message 2", etc., separated by dividers

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

### Requirement: Extension delivers report via iOS system networking
Upon user confirmation, the extension SHALL set `userInfo` on the `ILClassificationResponse` with `sender`, `bodies` (array of all selected message bodies), and `type`. iOS (outside the extension sandbox) SHALL POST this data to `https://api.ben-dahan.com/report` via `ILClassificationExtensionNetworkReportDestination`. Each body SHALL be stored as a separate DynamoDB record.

#### Scenario: Junk report delivered
- **WHEN** the user confirms "Report Junk" or "Report Junk & Block Sender"
- **THEN** the extension SHALL set `type: "deny"` in userInfo
- **THEN** iOS SHALL POST `{sender, bodies, type}` to the classification report endpoint

#### Scenario: Not Junk report delivered
- **WHEN** the user confirms "Not Junk"
- **THEN** the extension SHALL set `type: "allow"` in userInfo

#### Scenario: Multiple bodies stored separately
- **WHEN** the user reports N messages at once
- **THEN** the ClassificationReport Lambda SHALL write N separate records to DynamoDB (one per body)

#### Scenario: Network delivery failure
- **WHEN** the system POST to Lambda fails or times out
- **THEN** iOS handles delivery silently; the extension has already returned its classification response (fire-and-forget from extension's perspective)

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
`ReportType` in `Constsants.swift` SHALL have a `junkAndBlockSender` case (raw value 2) that maps to `ILClassificationAction.reportJunkAndBlockSender` and sends `type: "deny"` to Lambda (same as `junk`).

#### Scenario: junkAndBlockSender maps to deny
- **WHEN** the extension constructs a classification report for `junkAndBlockSender`
- **THEN** `type` SHALL equal `"deny"`

#### Scenario: Existing ReportType cases unaffected
- **WHEN** the `junk` or `notJunk` cases are used
- **THEN** their `type` strings SHALL remain `"deny"` and `"allow"` respectively
