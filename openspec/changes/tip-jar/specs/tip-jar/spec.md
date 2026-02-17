## ADDED Requirements

### Requirement: Tip tier definition
The system SHALL define exactly three consumable in-app purchase tiers as a `CaseIterable` enum with computed properties for product ID, emoji, display name, and confetti intensity. The tiers are:
- Small: product ID `com.grizz.apps.simplyfiltersms.tip.small`, emoji ☕️, price tier ~$1.99
- Medium: product ID `com.grizz.apps.simplyfiltersms.tip.medium`, emoji 🍕, price tier ~$4.99
- Large: product ID `com.grizz.apps.simplyfiltersms.tip.large`, emoji 🎉, price tier ~$9.99

#### Scenario: Tip tiers are enumerable
- **WHEN** the app accesses the tip tier enum
- **THEN** all three tiers SHALL be available via `CaseIterable` iteration in small/medium/large order

### Requirement: Product loading
The system SHALL load tip products from StoreKit using `Product.products(for:)` with the three tip product IDs when the tip jar screen appears.

#### Scenario: Products load successfully
- **WHEN** the tip jar screen appears and StoreKit returns products
- **THEN** the system SHALL display all returned products with their localized display name and price

#### Scenario: Products fail to load
- **WHEN** the tip jar screen appears and StoreKit fails to return products (network error, invalid IDs)
- **THEN** the system SHALL display an appropriate empty/error state and tip buttons SHALL NOT be interactive

### Requirement: Purchase flow
The system SHALL initiate a purchase via `Product.purchase()` when the user taps a tip button, and SHALL call `transaction.finish()` on verified transactions.

#### Scenario: Successful purchase
- **WHEN** the user taps a tip button and the purchase completes with a verified transaction
- **THEN** the system SHALL finish the transaction, display a confetti animation, and show a thank-you toast notification

#### Scenario: Purchase cancelled by user
- **WHEN** the user cancels the purchase sheet
- **THEN** the system SHALL return to the tip jar screen with no feedback or error

#### Scenario: Purchase fails
- **WHEN** the purchase fails due to a StoreKit error (not cancellation)
- **THEN** the system SHALL display an error state to the user

#### Scenario: Interrupted purchase recovered on next launch
- **WHEN** the app launches and `Transaction.unfinished` contains tip transactions
- **THEN** the system SHALL finish those transactions silently (no UI feedback)

### Requirement: Confetti animation
The system SHALL display a confetti particle animation using `CAEmitterLayer` wrapped in `UIViewRepresentable` upon successful tip purchase. The animation intensity SHALL scale with the tip tier.

#### Scenario: Small tip confetti
- **WHEN** a small tip purchase succeeds
- **THEN** the system SHALL display a subtle, short confetti animation

#### Scenario: Medium tip confetti
- **WHEN** a medium tip purchase succeeds
- **THEN** the system SHALL display a moderate confetti animation with more particles and longer duration than the small tier

#### Scenario: Large tip confetti
- **WHEN** a large tip purchase succeeds
- **THEN** the system SHALL display a full-screen confetti explosion with maximum particles and longest duration

### Requirement: Thank-you toast notification
The system SHALL display a toast notification upon successful tip purchase using the existing `NotificationView` / `EmbeddedNotificationView` system with a new notification case.

#### Scenario: Toast appears after successful tip
- **WHEN** a tip purchase succeeds
- **THEN** the system SHALL show a toast with a heart icon, a thank-you title, and auto-dismiss after a timeout

### Requirement: Tip jar screen navigation
The system SHALL register a `.tipJar` case in the `Screen` enum and provide entry points from AppHomeView and AboutView.

#### Scenario: Navigate from AppHomeView menu
- **WHEN** the user taps the tip jar option in the AppHomeView toolbar menu
- **THEN** the system SHALL present the TipJarView as a sheet

#### Scenario: Navigate from AboutView
- **WHEN** the user taps the tip jar row in the AboutView links section
- **THEN** the system SHALL present the TipJarView as a sheet

### Requirement: Tip jar screen UI
The TipJarView SHALL display a header area with a message encouraging voluntary support, followed by three tip buttons showing the emoji, display name, and localized price for each tier. The view SHALL include a dismiss button in the navigation bar.

#### Scenario: Tip jar screen displays all tiers
- **WHEN** the tip jar screen is presented and products have loaded
- **THEN** the system SHALL display three tip buttons in small/medium/large order, each showing the tier emoji, name, and price from StoreKit

#### Scenario: Tip jar screen is dismissible
- **WHEN** the user taps the close button in the navigation bar
- **THEN** the system SHALL dismiss the tip jar sheet

### Requirement: StoreKit local configuration
The project SHALL include a `.storekit` configuration file defining the three consumable tip products for Xcode-based testing without App Store Connect.

#### Scenario: Local testing in Xcode
- **WHEN** the developer runs the app in Xcode with the StoreKit configuration selected in the scheme
- **THEN** the three tip products SHALL be available for purchase in the Simulator using the StoreKit testing environment

### Requirement: Localization
All user-facing text in the tip jar feature SHALL be localized using the `~` postfix operator with keys in both English and Hebrew `.strings` files.

#### Scenario: Tip jar text is localized
- **WHEN** the tip jar screen is displayed in a supported locale
- **THEN** all static text (header, button labels, toast messages) SHALL appear in the user's language
