## Why

iOS provides a native "Report Junk / Not Junk" flow in the Messages app, powered by the `IdentityLookupUI` framework, but Simply Filter SMS does not hook into it. Adding an Unwanted Communication Reporting Extension surfaces the app as a first-class participant in that flow, letting users report spam and ham directly from Messages — feeding real signal back to the app's Lambda backend to improve filter quality over time.

## What Changes

- Add a new **Reporting Extension** app extension target (`ILClassificationUIExtensionViewController`) to the Xcode project
- The extension presents a minimal confirmation UI when the user taps "Report Messages" in iOS Messages (long-press on a conversation)
- The extension receives the selected message(s) via `ILMessageClassificationRequest` and lets the user confirm a report action (junk, junk + block sender, or not junk)
- On confirmation the extension posts the report to the existing Lambda endpoint via `ReportMessageService`
- A new Settings toggle in the app explains how to enable the extension in Settings > Phone > SMS/Call Reporting
- Reuses existing design system (colors, typography, button styles) and localization infrastructure

## Capabilities

### New Capabilities
- `reporting-extension`: The `IdentityLookupUI` extension target, its UI, lifecycle, and integration with `ReportMessageService`

### Modified Capabilities

_(none — no existing spec-level requirements change)_

## Impact

- **New Xcode target:** `Reporting Extension` (extension bundle, `NSExtension` principal class `ILClassificationUIExtensionViewController` subclass)
- **New entitlement:** `com.apple.developer.message-filter` already present on main target; reporting extension needs its own entitlement file (same App Group)
- **Shared code:** `ReportMessageService`, `HTTPService`, `Constsants.swift` (ReportType enum) must be compiled into the new target
- **Localization:** New strings for the confirmation UI added to existing `.strings` files via BartyCrouch
- **No CoreData / CloudKit:** Extension container is wiped by the system on termination — no persistent state
- **Settings UI:** New informational section in `AboutView` or a dedicated `ReportingExtensionView` explaining how to enable the extension
- **One-extension-at-a-time limit:** iOS only allows one SMS/Call Reporting extension enabled at a time; onboarding copy should acknowledge this
