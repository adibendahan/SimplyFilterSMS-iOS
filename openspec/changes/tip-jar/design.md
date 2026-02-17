## Context

Simply Filter SMS has no monetization. The app currently imports StoreKit solely for `SKStoreReviewController.requestReview(in:)` in `AppHomeView`. All screens follow the nested ViewModel pattern (`SomeView.ViewModel: BaseViewModel, ObservableObject`) with navigation driven by the `Screen` enum router. The app targets iOS 15.2+ and uses no external dependencies.

## Goals / Non-Goals

**Goals:**
- Allow users to voluntarily tip the developer via three consumable IAP tiers
- Provide satisfying visual feedback (confetti + toast) scaled to tip amount
- Integrate cleanly with existing MVVM architecture and navigation patterns
- Enable local testing in Xcode without App Store Connect setup

**Non-Goals:**
- No tip history tracking or persistence
- No server-side receipt validation (unnecessary for consumable tips)
- No subscription or non-consumable products
- No new framework dependencies beyond StoreKit 2 (already linked)
- No footer entry point (deferred)

## Decisions

### 1. StoreKit 2 (modern async API) over StoreKit 1

**Choice:** Use `Product.products(for:)` and `Product.purchase()` from StoreKit 2.

**Why:** The app targets iOS 15.2+, and StoreKit 2 is available from iOS 15.0+. It provides a Swift-native async/await API with built-in transaction verification. StoreKit 1 (`SKPaymentQueue`, `SKProductsRequest`) requires delegate callbacks and manual receipt validation — unnecessary complexity for consumable tips.

**Alternative considered:** StoreKit 1 for broader compatibility. Rejected because iOS 15.2+ already covers StoreKit 2.

### 2. ViewModel handles StoreKit directly (no separate Store manager)

**Choice:** `TipJarView.ViewModel` will call `Product.products(for:)` and `product.purchase()` directly, and listen to `Transaction.updates` for the lifetime of the view.

**Why:** Tips are fire-and-forget consumables with no entitlements to track. A separate `StoreManager` would add a protocol, a mock, registration in `AppManager`, and wiring — all for three product IDs that are only ever used in one screen. The ViewModel already owns the purchase lifecycle.

**Alternative considered:** A `TipJarManager` registered in `AppManager` with protocol for testability. Rejected as over-engineering — the StoreKit calls are inherently side-effectful and don't benefit from mocking in unit tests.

### 3. CAEmitterLayer for confetti over pure SwiftUI animation

**Choice:** `UIViewRepresentable` wrapping a `UIView` with a `CAEmitterLayer` for particle-based confetti.

**Why:** `CAEmitterLayer` provides real particle physics (gravity, velocity spread, spin, fade) out of the box. Tier scaling is trivial: adjust `birthRate`, `lifetime`, and `velocity` parameters. Pure SwiftUI would require manually animating dozens of individual views with `withAnimation`, which is harder to tune and less performant.

**Alternative considered:** Pure SwiftUI `Canvas` with `TimelineView`. Could work but requires manual physics simulation. Also considered SPM packages like `ConfettiSwiftUI`, but the project has zero external dependencies and this shouldn't be the first.

### 4. Product IDs as a CaseIterable enum with computed properties

**Choice:** Define a `TipTier` enum (or similar) in `Constsants.swift` that conforms to `CaseIterable` with computed properties for product ID, emoji, display name, and confetti intensity.

**Why:** This matches the project convention used by `FilterType`, `RuleType`, and `WhatsNewEntry`. It keeps tip tier data centralized and type-safe. The enum raw value will be the product ID string.

### 5. Toast via existing NotificationView system

**Choice:** Add a new `NotificationView.Notification` case (e.g., `.tipSuccessful(String)`) for the thank-you toast, and use the existing `EmbeddedNotificationView` modifier already applied in the view hierarchy.

**Why:** Reuses existing infrastructure. The `NotificationView` already supports icon, title, subtitle, auto-dismiss timeout, and swipe-to-dismiss. Adding a new case is a one-line change to the enum.

### 6. Confetti overlay as a ViewModifier on TipJarView

**Choice:** The confetti animation will be a ZStack overlay within `TipJarView` itself, triggered by `purchaseState` changes. It will not be a reusable modifier across the app.

**Why:** Confetti is only used in the tip jar. Making it a global modifier or adding it to `ViewModfiers.swift` would suggest broader reuse that isn't planned. Keep it scoped to where it's used.

### 7. StoreKit local configuration file for development

**Choice:** Create a `TipJar.storekit` configuration file with the three consumable products. Set it as the StoreKit configuration in the scheme's Run settings during development.

**Why:** This enables full purchase flow testing in Simulator without App Store Connect. The `.storekit` file stays in the project but doesn't ship with the app. When ready for production, the same product IDs are created in App Store Connect.

## Risks / Trade-offs

**[Risk] StoreKit product loading fails (network issues, invalid IDs)**
→ Show a graceful empty/error state in the UI. Products array will be empty, tip buttons disabled or hidden. Since this is a voluntary feature, degradation is acceptable.

**[Risk] Purchase interrupted (app killed mid-transaction)**
→ `Transaction.unfinished` is checked on next launch. For consumables with no entitlements, we simply call `transaction.finish()` on any unfinished tip transactions. No user-visible impact.

**[Risk] App Review rejection for tip jar**
→ Consumable tip jars are well-established on the App Store. Key requirements: clear description that tips don't unlock features, proper product metadata in App Store Connect, and review screenshot of the purchase UI.

**[Trade-off] No unit tests for StoreKit interactions**
→ StoreKit 2 calls (`Product.products`, `product.purchase()`) are async system calls that don't lend themselves to unit testing without significant mocking infrastructure. The local `.storekit` config file provides integration testing coverage in Xcode. This is acceptable for a simple consumable flow.

**[Trade-off] Confetti scoped to TipJarView only**
→ If confetti is wanted elsewhere later, the `CAEmitterLayer` wrapper would need to be extracted. Acceptable since no other use case exists today.
