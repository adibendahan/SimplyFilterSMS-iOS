## Context

The app currently has no URL scheme handling. All navigation is driven internally via the `Screen` enum and `@Published` properties on `AppHomeView.ViewModel` (`sheetScreen`, `modalFullScreen`, `navigationScreen`). The app entry point (`Simply_Filter_SMSApp`) creates the `AppHomeView` with its ViewModel directly in the `WindowGroup`.

SwiftUI provides `.onOpenURL` on the `WindowGroup` scene to handle incoming URLs. The ViewModel already supports presenting `EnableExtensionVideoView` as a sheet via `self.model.sheetScreen = .enableExtension`.

## Goals / Non-Goals

**Goals:**
- Register a `simplyfiltersms://` URL scheme so the app can be opened via URLs
- Handle `simplyfiltersms://enable-extension` to present the EnableExtensionVideoView sheet
- Keep the routing extensible so future deep links to other screens are trivial to add

**Non-Goals:**
- Universal Links (HTTPS-based deep links) — out of scope, would require an AASA file and domain configuration
- Deep linking into push-navigation screens (filter lists, automatic blocking) — sheets only for now

## Decisions

### 1. URL scheme name: `simplyfiltersms`

Lowercase, no hyphens — follows Apple's convention for custom URL schemes. Matches the app's identity.

**Alternatives considered:**
- `sfsms` — too cryptic, not discoverable
- `simply-filter-sms` — hyphens in schemes can cause issues with some URL parsers

### 2. Route via `.onOpenURL`, dismiss then present

Place `.onOpenURL` on `AppHomeView` inside `WindowGroup`. The handler parses the URL host, dismisses any active sheet or modal, then presents the target screen as a sheet.

**Behavior:**
- **App already open (warm launch):** Dismiss any active `sheetScreen` or `modalFullScreen`, then after a brief delay present the deep link target as a sheet. The current navigation stack (pushed screens) stays as-is — the sheet appears on top of whatever is showing.
- **Cold launch:** The URL is received after the view hierarchy loads. Present the deep link target as a sheet on top of AppHomeView.

The ViewModel already owns `sheetScreen` and `modalFullScreen` as `@Published` properties, so dismissing is just setting them to `nil` and presenting is setting `sheetScreen` to the target.

**Alternatives considered:**
- Dedicated `DeepLinkRouter` class — over-engineering for a single route; can be extracted later if many routes are added
- Handle in `AppDelegate` via `application(_:open:options:)` — mixes UIKit and SwiftUI patterns unnecessarily; `.onOpenURL` is the idiomatic SwiftUI approach

### 3. URL format: `simplyfiltersms://enable-extension`

Use the URL `host` component as the route identifier. The host maps directly to a `Screen` enum case via a static lookup.

```
simplyfiltersms://enable-extension
                  └── host = "enable-extension" → Screen.enableExtension
```

**Extensibility:** Adding a new deep link requires only adding a case to the host-to-Screen mapping. For example:
- `simplyfiltersms://help` → `.help`
- `simplyfiltersms://test-filters` → `.testFilters`

### 4. Add a `deepLink` static mapping on `Screen`

Add a static method or initializer on the `Screen` enum that maps a URL host string to a `Screen?`. This keeps routing logic co-located with the enum and makes it easy to discover supported deep links.

```swift
extension Screen {
    static func fromDeepLink(host: String) -> Screen? { ... }
}
```

### 5. Info.plist configuration via Xcode project settings

Register the URL scheme via `CFBundleURLTypes` in the app's Info.plist. This is a build-time setting, no runtime configuration needed.

## Risks / Trade-offs

- **URL scheme collision** → Low risk. `simplyfiltersms` is specific enough. No mitigation needed.
- **App not yet loaded when URL arrives** → SwiftUI's `.onOpenURL` handles both cold and warm launch. The ViewModel may not have finished `onAppLaunch()` on cold start. Mitigation: the sheet presentation already defers via `@Published`, so the UI will present once the view hierarchy is ready.
- **Dismissal timing** → SwiftUI needs a runloop cycle to process dismissals before presenting a new sheet. Mitigation: use `DispatchQueue.main.asyncAfter` with a short delay between dismissing the current sheet/modal and presenting the deep link target. This is a known SwiftUI pattern for sequential presentation changes.
- **Pushed screen stays visible** → If the user is on a pushed screen (e.g. FilterListView) and a URL arrives, the sheet will appear on top of that pushed screen, not AppHomeView. This is intentional — the user's navigation context is preserved.
