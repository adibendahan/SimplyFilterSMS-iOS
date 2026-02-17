## Why

Simply Filter SMS is a free, open-source app with no monetization. Adding a tip jar gives appreciative users a way to support the developer voluntarily, without paywalls, ads, or feature gating. Consumable in-app purchases are the simplest IAP model and align with the app's philosophy of keeping all features free.

## What Changes

- Add a new **TipJarView** screen with three consumable tip tiers (☕️ $1.99, 🍕 $4.99, 🎉 $9.99)
- Integrate **StoreKit 2** API for loading products and processing purchases (iOS 15.0+)
- Add a **StoreKit local configuration file** (`.storekit`) for Xcode-based testing
- Add a **confetti animation** using `CAEmitterLayer` wrapped in `UIViewRepresentable`, scaled by tip tier
- Add **entry points** to the tip jar from:
  - AppHomeView top toolbar menu
  - AboutView links section
- Display a **toast notification** on successful tip using the existing `EmbeddedNotificationView` system
- Add new **Screen.tipJar** case to the navigation router
- Add **localization keys** for tip jar UI text (English + Hebrew)

## Capabilities

### New Capabilities

- `tip-jar`: Consumable in-app purchase flow — product loading, purchase handling, transaction finishing, and tip jar UI with tier-scaled confetti feedback

### Modified Capabilities

None. This is a purely additive feature with no changes to existing behavior or specs.

## Impact

- **New files**: `TipJarView.swift` (view + viewmodel), confetti `UIViewRepresentable` wrapper, `.storekit` config file
- **Modified files**: `Screen.swift` (new case), `AppHomeView.swift` (menu entry point), `AboutView.swift` (link entry point), `Localizable.strings` (new keys)
- **Frameworks**: StoreKit (already imported for `SKStoreReviewController`, now used for IAP)
- **App Store Connect**: Three consumable IAP products must be created before production release
- **No new dependencies**: `CAEmitterLayer` is built into UIKit, StoreKit 2 is built into iOS 15+
