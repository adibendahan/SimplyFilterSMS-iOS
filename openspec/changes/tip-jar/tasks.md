## 1. Data Model & Constants

- [ ] 1.1 Add `TipTier` enum to `Constsants.swift` — `CaseIterable` with raw value String (product ID), computed properties for emoji, display name, and confetti intensity parameters (birthRate, lifetime, velocity)
- [ ] 1.2 Add `NotificationView.Notification.tipSuccessful` case with heart icon, thank-you title/subtitle, and auto-dismiss timeout

## 2. StoreKit Configuration

- [ ] 2.1 Create `TipJar.storekit` local configuration file with three consumable products (small, medium, large) matching the `TipTier` product IDs
- [ ] 2.2 Configure the scheme's Run settings to use `TipJar.storekit` as the StoreKit configuration

## 3. Confetti Animation

- [ ] 3.1 Create `ConfettiView` — a `UIViewRepresentable` wrapping a `UIView` with `CAEmitterLayer` that accepts intensity parameters (birthRate, lifetime, velocity) and auto-stops after a duration
- [ ] 3.2 Verify confetti renders correctly in Simulator at all three intensity levels

## 4. TipJarView Screen

- [ ] 4.1 Create `TipJarView` with nested `ViewModel: BaseViewModel, ObservableObject` — properties for `products: [Product]`, `purchaseState` (idle/purchasing/success with tier/error), and `notification: NotificationView.ViewModel`
- [ ] 4.2 Implement `loadProducts()` async method using `Product.products(for:)` with `TipTier.allCases` product IDs
- [ ] 4.3 Implement `purchase(_ product: Product)` async method — call `product.purchase()`, verify transaction, finish it, update `purchaseState` to trigger confetti and toast
- [ ] 4.4 Implement `Transaction.updates` listener in ViewModel init for handling interrupted purchases (finish silently)
- [ ] 4.5 Build TipJarView UI — header message, three tip buttons (emoji + name + localized price), loading/error states, confetti overlay, close button, `EmbeddedNotificationView` modifier

## 5. Navigation Integration

- [ ] 5.1 Add `.tipJar` case to `Screen` enum with `build()` returning `TipJarView(model: TipJarView.ViewModel())`
- [ ] 5.2 Add tip jar menu item to `AppHomeView` toolbar `Menu` (heart/gift icon, localized label) — sets `sheetScreen = .tipJar`
- [ ] 5.3 Add tip jar row to `AboutView` links section (heart icon, localized label) — presents `.tipJar` as sheet

## 6. Localization

- [ ] 6.1 Add English localization keys to `Localizable.strings` — tip jar header text, button labels, toast title/subtitle, menu item label, about row label, error state text
- [ ] 6.2 Add Hebrew localization keys to `he.lproj/Localizable.strings` with translated strings

## 7. Testing & Verification

- [ ] 7.1 Run app in Simulator with StoreKit config — verify products load and display correct prices
- [ ] 7.2 Test purchase flow for all three tiers — verify confetti intensity scales and toast appears
- [ ] 7.3 Test cancel and error scenarios — verify no confetti/toast on cancel, error state on failure
- [ ] 7.4 Test navigation from both AppHomeView menu and AboutView link
- [ ] 7.5 Build project and run existing unit tests to verify no regressions
