## ADDED Requirements

### Requirement: App registers a custom URL scheme
The app SHALL register the `simplyfiltersms` URL scheme via `CFBundleURLTypes` in Info.plist so that iOS routes `simplyfiltersms://` URLs to the app.

#### Scenario: URL scheme is registered
- **WHEN** a user or system opens `simplyfiltersms://enable-extension`
- **THEN** iOS SHALL launch or foreground the app and deliver the URL

### Requirement: URL host maps to a Screen
The `Screen` enum SHALL provide a `fromDeepLink(host:)` static method that maps a URL host string to a `Screen?`. The initial supported mapping SHALL be `"enable-extension"` → `Screen.enableExtension`. Unrecognized hosts SHALL return `nil`.

#### Scenario: Recognized host
- **WHEN** the app receives a URL with host `"enable-extension"`
- **THEN** `Screen.fromDeepLink(host:)` SHALL return `Screen.enableExtension`

#### Scenario: Unrecognized host
- **WHEN** the app receives a URL with an unrecognized host (e.g. `"foo"`)
- **THEN** `Screen.fromDeepLink(host:)` SHALL return `nil`

#### Scenario: No host
- **WHEN** the app receives a URL with no host (e.g. `simplyfiltersms://`)
- **THEN** `Screen.fromDeepLink(host:)` SHALL return `nil`

### Requirement: Deep link presents target screen as a sheet on cold launch
On cold launch via a URL, the app SHALL present the resolved `Screen` as a sheet on top of AppHomeView.

#### Scenario: Cold launch with enable-extension URL
- **WHEN** the app is not running and a user opens `simplyfiltersms://enable-extension`
- **THEN** the app SHALL launch, display AppHomeView, and present EnableExtensionVideoView as a sheet

### Requirement: Deep link dismisses active sheet or modal before presenting
On warm launch (app already open), the app SHALL dismiss any currently active `sheetScreen` or `modalFullScreen` before presenting the deep link target as a sheet. The current navigation stack (pushed screens) SHALL remain unchanged.

#### Scenario: Sheet already showing
- **WHEN** the app is open with an active sheet (e.g. HelpView) and a URL `simplyfiltersms://enable-extension` is received
- **THEN** the app SHALL dismiss the active sheet and present EnableExtensionVideoView as a sheet

#### Scenario: Modal full screen showing
- **WHEN** the app is open with an active full-screen cover and a URL `simplyfiltersms://enable-extension` is received
- **THEN** the app SHALL dismiss the full-screen cover and present EnableExtensionVideoView as a sheet

#### Scenario: Pushed screen showing, no sheet
- **WHEN** the app is on a pushed screen (e.g. FilterListView) with no active sheet and a URL `simplyfiltersms://enable-extension` is received
- **THEN** the app SHALL present EnableExtensionVideoView as a sheet on top of the current pushed screen

#### Scenario: No active presentation
- **WHEN** the app is open on AppHomeView with no active sheet or modal and a URL `simplyfiltersms://enable-extension` is received
- **THEN** the app SHALL present EnableExtensionVideoView as a sheet

### Requirement: Unrecognized URLs are silently ignored
The app SHALL NOT crash, show errors, or alter navigation state when receiving a URL with an unrecognized host.

#### Scenario: Unknown deep link
- **WHEN** the app receives `simplyfiltersms://unknown-screen`
- **THEN** the app SHALL take no action and the current UI state SHALL remain unchanged
