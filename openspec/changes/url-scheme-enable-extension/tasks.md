## 1. URL Scheme Registration

- [ ] 1.1 Add `CFBundleURLTypes` entry with scheme `simplyfiltersms` to the app's Info.plist (via Xcode project settings)

## 2. Deep Link Routing

- [ ] 2.1 Add `Screen.fromDeepLink(host:)` static method that maps `"enable-extension"` → `.enableExtension` and returns `nil` for unrecognized hosts
- [ ] 2.2 Add `handleDeepLink(url:)` method on `AppHomeView.ViewModel` that dismisses any active `sheetScreen`/`modalFullScreen`, then after a brief delay sets `sheetScreen` to the resolved `Screen`
- [ ] 2.3 Add `.onOpenURL` modifier to `AppHomeView` body that calls `model.handleDeepLink(url:)`

## 3. Verification

- [ ] 3.1 Test cold launch: `xcrun simctl openurl booted "simplyfiltersms://enable-extension"` with app not running — verify EnableExtensionVideoView sheet appears
- [ ] 3.2 Test warm launch with no active sheet — verify sheet appears
- [ ] 3.3 Test warm launch with active sheet (e.g. HelpView) — verify old sheet dismisses and EnableExtensionVideoView appears
- [ ] 3.4 Test unrecognized URL `simplyfiltersms://foo` — verify no action taken
- [ ] 3.5 Build succeeds with no warnings
