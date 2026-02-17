## 1. Data Model & Constants

- [x] 1.1 Add `TipTier` enum to `Constsants.swift` — `CaseIterable` with raw value String (product ID), computed properties for emoji, display name, and confetti intensity parameters (birthRate, lifetime, velocity)
- [x] 1.2 Add `NotificationView.Notification.tipSuccessful` case with heart icon, thank-you title/subtitle, and auto-dismiss timeout (3s)
- [x] 1.3 Add `onHide` closure to `NotificationView.ViewModel` — called when notification hides (auto or manual), nil'd after firing for one-shot behavior
- [x] 1.4 Build auto-hide into `NotificationView.ViewModel` — `show` didSet schedules auto-hide via cancellable `DispatchWorkItem` using notification's `timeout`, replacing manual `DispatchQueue` calls in AppHomeView/AboutView/TipJarView

## 2. StoreKit Configuration

- [x] 2.1 Create `TipJar.storekit` local configuration file with three consumable products (small, medium, large) matching the `TipTier` product IDs
- [x] 2.2 Configure the scheme's Run settings to use `TipJar.storekit` as the StoreKit configuration

## 3. Confetti Animation

- [x] 3.1 Create `ConfettiView` — a `UIViewRepresentable` wrapping a `UIView` with `CAEmitterLayer` that accepts intensity parameters (birthRate, lifetime, velocity) and auto-stops after a duration
- [x] 3.2 Verify confetti renders correctly in Simulator at all three intensity levels

## 4. TipJarView Screen

- [x] 4.1 Create `TipJarView` with nested `ViewModel: BaseViewModel, ObservableObject` — properties for `products: [Product]`, `purchaseState` (idle/purchasing/success with tier/error), and `notification: NotificationView.ViewModel`
- [x] 4.2 Implement `loadProducts()` async method using `Product.products(for:)` with `TipTier.allCases` product IDs
- [x] 4.3 Implement `purchase(_ product: Product)` async method — call `product.purchase()`, verify transaction, finish it, update `purchaseState` to trigger confetti and toast
- [x] 4.4 Implement `Transaction.updates` listener in ViewModel init for handling interrupted purchases (finish silently)
- [x] 4.5 Build TipJarView UI — ScrollView with top-aligned layout, header (heart emoji, title, subtitle), "CHOOSE A TIP" section label, three side-by-side `TipCard` views in HStack (emoji + name + description in fixed 30pt frame + accent price badge) with `.gray.opacity(0.1)` card backgrounds, custom `TipCardButtonStyle` (scale 0.95 on press), static disclaimer footer (no Restore Purchases — consumables don't require it), loading/error/unavailable states, confetti overlay, close button, `EmbeddedNotificationView` modifier **outside** NavigationView, auto-dismiss sheet via `onHide` after toast disappears, `verticalSizeClass` compact support for landscape, products loaded in ViewModel init (not .task)

## 5. Navigation Integration

- [x] 5.1 Add `.tipJar` case to `Screen` enum with `build()` returning `TipJarView(model: TipJarView.ViewModel())`
- [x] 5.2 Add tip jar menu item to `AppHomeView` toolbar `Menu` (heart/gift icon, localized label) — sets `sheetScreen = .tipJar`
- [x] 5.3 Add tip jar row to `AboutView` links section (heart icon, localized label) — presents `.tipJar` as sheet

## 6. Localization

- [x] 6.1 Add English localization keys to `Localizable.strings` — tip jar header text, button labels, toast title/subtitle, menu item label, about row label, error state text
- [x] 6.2 Add Hebrew localization keys to `he.lproj/Localizable.strings` with translated strings

## 7. Testing & Verification

- [x] 7.1 Run app in Simulator with StoreKit config — verify products load and display correct prices
- [x] 7.2 Test purchase flow for all three tiers — verify confetti intensity scales and toast appears
- [x] 7.3 Test cancel and error scenarios — verify no confetti/toast on cancel, error state on failure
- [x] 7.4 Test navigation from both AppHomeView menu and AboutView link
- [x] 7.5 Build project and run existing unit tests to verify no regressions
