## Why

Users who haven't enabled the SMS filter extension need a way to be deep-linked directly into the Enable Extension screen. A custom URL scheme (e.g. `simplyfiltersms://enable-extension`) allows other apps, shortcuts, widgets, or support links to open the app and immediately present the EnableExtensionVideoView — removing friction from the activation flow.

## What Changes

- Register a custom URL scheme (`simplyfiltersms`) in the app's Info.plist via `CFBundleURLTypes`.
- Handle incoming URLs in the SwiftUI app entry point (`Simply_Filter_SMSApp`) using `.onOpenURL`.
- Route the `enable-extension` path to present the EnableExtensionVideoView as a sheet from AppHomeView.
- Design the URL routing to be extensible for future deep links to other screens.

## Capabilities

### New Capabilities
- `url-scheme-routing`: Custom URL scheme registration and routing infrastructure. Handles `simplyfiltersms://` URLs and maps paths to Screen enum cases, starting with `enable-extension` → EnableExtensionVideoView.

### Modified Capabilities
(none)

## Impact

- **Info.plist**: New `CFBundleURLTypes` entry for `simplyfiltersms` scheme.
- **Simply_Filter_SMSApp.swift**: Add `.onOpenURL` modifier to handle incoming URLs.
- **AppHomeView.ViewModel**: Needs to be reachable for setting `sheetScreen` from the URL handler (it already presents `.enableExtension` as a sheet).
- **No breaking changes**: Existing navigation and app behavior remain unchanged.
