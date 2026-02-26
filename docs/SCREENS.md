# Screens Architecture

Per-screen breakdown of all SwiftUI views in Simply Filter SMS.

For MVVM patterns and conventions, see [../CLAUDE.md](../CLAUDE.md). For the screen map and index, see [../ARCHITECTURE.md](../ARCHITECTURE.md).

---

## AppHomeView

**File:** `View Layer/Screens/AppHomeView.swift`
**Role:** Main screen and app entry point. Hosts all primary navigation.

### Layout

A `NavigationView` containing a `List` with three sections:

1. **Automatic Filtering** — Single `NavigationLink` to `.automaticBlocking` (LanguageListView in automatic mode). Displays an ON/OFF badge. Entire section is disabled when "block all unknown" rule is active.

2. **Smart Filters** — `ForEach` over `model.rules: [StatefulItem<RuleType>]`. Each rule renders as a `Toggle`. Toggling calls through `StatefulItem.didSet` -> ViewModel's `setAutomaticRuleState` -> `AutomaticFilterManager`. The `.shortSender` rule has an additional `Menu` picker for character threshold (3-6). All rules except `.allUnknown` are disabled when "block all unknown" is active.

3. **User Filters** — Three `NavigationLink` rows (allow, deny, denyLanguage) each showing an active filter count badge. Links to `FilterListView` with the corresponding `FilterType`.

### Navigation Bar

Trailing `Menu` (ellipsis icon) with items:
- Test Filters -> `.testFilters` sheet
- Report Message -> `.reportMessage` sheet
- Help -> `.help` sheet
- About -> `.about` sheet
- Tip Jar -> `.tipJar` sheet
- What's New -> `.whatsNew` sheet (only if `WhatsNewEntry.allCases` is non-empty)
- Load Debug Data (DEBUG builds only)

### Overlays

- `EmbeddedFooterView` — App version + copyright at bottom. Tap opens About sheet. Uses iOS 26 `glassEffect` with `ultraThinMaterial` fallback.
- `EmbeddedNotificationView` — Toast banner at top with spring animation. Shows offline status, sync completion, and filter update notifications.

### ViewModel

**Published state:**
- `filters: [Filter]` — All user filter records (for count badges)
- `title: String` — Navigation title
- `isAppFirstRun: Bool` — Triggers onboarding sheet on first launch
- `isAutomaticFilteringOn: Bool` — Whether any automatic filtering is active
- `isAllUnknownFilteringOn: Bool` — Whether the "block all unknown" rule is on (disables other rules/filters)
- `shortSenderChoice: Int` — Current threshold for short sender rule
- `subtitle: String` — Summary of active automatic filters
- `rules: [StatefulItem<RuleType>]` — Smart filter toggles with two-way binding
- `notification: NotificationView.ViewModel` — Toast notification state
- `navigationScreen`, `sheetScreen`, `modalFullScreen` — Navigation drivers

**Key methods:**
- `refresh()` — Reloads all state from managers. Called on every navigation pop, sheet dismiss, and notification.
- `startMonitoring()` — Registers `NotificationCenter` observers (once) for `.cloudSyncOperationComplete`, `.networkStatusChange`, `.automaticFiltersUpdated`.
- `showNotification(_:)` — Queues notifications if a sheet/modal is active (`pendingNotification`). Some notifications auto-dismiss after a timeout.
- `tryRequestReview()` — Prompts `SKStoreReviewController` after 7+ days and 5+ sessions. Triggered when user pops back from a navigation screen.
- `activeCount(for:)` — Returns count of filters for a given `FilterType`.

---

## EnableExtensionVideoView

**File:** `View Layer/Screens/EnableExtensionVideoView.swift`
**Role:** Onboarding screen shown on first launch. Guides user to enable the Message Filter Extension in iOS Settings.

Both `Screen.onboarding` and `Screen.enableExtension` map to this same view.

### Layout

Presented as a **sheet** (`.interactiveDismissDisabled()`). Contains:
- Description text
- A looping `VideoPlayer` (AVKit) — plays `enableExtension.mp4` (English) or `enableExtension.he.mp4` (Hebrew) based on locale. Loops via `.AVPlayerItemDidPlayToEndTime` observer.
- CTA button that deep-links to app's iOS Settings via `UIApplication.openSettingsURLString`
- Toolbar X button to dismiss

### ViewModel

- `isAppFirstRun: Bool` — `@Published` with `didSet` writing back to `DefaultsManager`. Both dismiss paths set this to `false`.
- `videoURLForCurrentLocale()` — Returns bundled `.mp4` URL with Hebrew locale suffix detection.

### Notable

- Uses `@StateObject` (not `@ObservedObject`) since it owns its ViewModel lifecycle as a sheet.

---

## HelpView

**File:** `View Layer/Screens/HelpView.swift`
**Role:** FAQ and support screen. Presented as a sheet from AppHomeView's menu.

### Layout

A `NavigationView` wrapping a `ScrollView` with:
- Subtitle text
- Two contact buttons side by side:
  - **Email** (conditionally shown via `MFMailComposeViewController.canSendMail()`) — opens `MailView` sheet, a `UIViewControllerRepresentable` wrapper around `MFMailComposeViewController` pre-filled with `kSupportEmail`.
  - **GitHub** — external `Link` to the repo URL.
- **FAQ list** — `ForEach` over `model.questions: [QuestionView.ViewModel]`. Each `QuestionView` is an expandable accordion: tap the question to toggle `isExpanded`, which reveals the answer with an `opacitySlowInFastOut` transition. The first question has an `.activateFilters` action that opens the EnableExtension sheet when tapped.
- Toolbar X button to dismiss
- `EmbeddedFooterView` overlay (tapping opens About sheet via `sheetScreen`)

### ViewModel

- `questions: [QuestionView.ViewModel]` — Loaded from `AppManager.getFrequentlyAskedQuestions()` which returns hardcoded localized FAQ entries.
- `title: String` — Navigation title.
- `sheetScreen: Screen?` — For presenting sub-sheets (About, EnableExtension).
- `composeMailScreen: Bool` — Drives the `MailView` sheet presentation.
- `result: Result<MFMailComposeResult, Error>?` — Mail compose result (unused beyond storage).

### Supporting Components

- **QuestionView** (`Others/QuestionView.swift`) — Self-contained accordion. Has its own `ViewModel` (not a `BaseViewModel` subclass — just `ObservableObject`). Supports an optional `QuestionAction` enum (`.none`, `.activateFilters`) with an `onAction` closure. RTL-aware chevron icon.
- **MailView** (`Others/MailView.swift`) — `UIViewControllerRepresentable` wrapping `MFMailComposeViewController`. Uses Coordinator pattern for delegate callbacks. Pre-fills recipient with `kSupportEmail`.

---

## AboutView

**File:** `View Layer/Screens/AboutView.swift`
**Role:** App info, credits, and external links. Presented as a sheet from AppHomeView or HelpView.

### Layout

A `NavigationView` containing a `VStack` with:
- **Header** — App logo image, app name as large bold title, version + build number.
- **List** (`.grouped` style) with two sections:
  1. **About** — Markdown-rendered about text (`AttributedString(markdown:)` with inline-only parsing, fallback to plain text).
  2. **Links** — Five rows, each with an icon + title + subtitle:
     - GitHub -> external `Link` to `appGithubURL`
     - Email -> opens `MailView` sheet if mail is available, otherwise copies `kSupportEmail` to clipboard via `setClipboard()` and shows a toast notification
     - Twitter -> external `Link` to `appTwitterURL`
     - Icon designer credit -> external `Link` to `iconDesignerURL` (Instagram)
     - App Store review -> external `Link` to `appReviewURL`

### Overlays

- `EmbeddedNotificationView` — Toast banner for clipboard copy confirmation. Uses the same notification system as AppHomeView but scoped to this screen.
- Toolbar X button to dismiss.

### ViewModel

- `composeMailScreen: Bool` — Drives `MailView` sheet.
- `result: Result<MFMailComposeResult, Error>?` — Mail compose result.
- `notification: NotificationView.ViewModel` — Owns its own notification model for clipboard toasts.
- `setClipboard(content:displayName:)` — Copies to `UIPasteboard` and posts `.onClipboardSet` notification.
- `showNotification(_:)` — Same pattern as AppHomeView's but simpler (no pending queue since no sub-sheets to block). Observes `.onClipboardSet` via `NotificationCenter` in `init`.

### Notable

- The clipboard fallback pattern: when `MFMailComposeViewController.canSendMail()` is false (e.g., simulator or no mail account), tapping Email copies the address to clipboard and shows a toast instead of opening the mail composer.
- Has its own `EmbeddedNotificationView` instance (separate from AppHomeView's) — each screen that needs toast notifications manages its own.
- Custom `NSNotification.Name` constants are all defined in `NetworkSyncManagerProtocol.swift`: `.networkStatusChange`, `.cloudSyncOperationComplete`, `.automaticFiltersUpdated`, `.onClipboardSet`.

---

## TestFiltersView

**File:** `View Layer/Screens/TestFiltersView.swift`
**Role:** Debug/testing tool for users to test their filters against sample input. Presented as a sheet from AppHomeView's menu.

### Layout

A `NavigationView` wrapping a `ZStack` (for loading overlay) containing a `Form` with a single section:
- **Sender** `TextField` — with floating label above (manually positioned via ZStack + negative padding).
- **Message body** `TextEditor` — multiline input (fixed 80pt height), auto-focused 0.7s after appear.
- **Result display** — `FadingTextView` showing the filter evaluation result with a fade-in/fade-out animation on text change.
- **Test button** — `FilledButton` style. Disabled when both inputs are empty. Calls `evaluateMessage()` and dismisses the keyboard.
- **Loading overlay** — Semi-transparent background + `ProgressView` shown when `state == .loading` (currently `state` is declared but never set to `.loading`).

### ViewModel

- `text: String`, `sender: String` — Two-way bound to the input fields.
- `fadeTextModel: FadingTextView.ViewModel` — Drives the result text display.
- `state: ViewState` — Enum with `.userInput`, `.loading`, `.result(String)` cases. Has custom `==` conformance.
- `evaluateMessage()` — Calls `MessageEvaluationManager.evaluateMessage(body:sender:)` directly. If sender is empty, defaults to `"1234567"`. Displays both the action result (junk/allow/promotion/transaction) and the reason (which filter matched).

### Supporting Components

- **FadingTextView** (`Others/FadingTextView.swift`) — Animates text transitions: fades out old text, swaps, fades in new text. Has its own lightweight `ViewModel` (plain `ObservableObject`, not `BaseViewModel`). Uses `onReceive` to react to text changes.
- **Field enum** — Defined inside the `TestFiltersView` extension. Used with `@FocusState` for keyboard focus management.
- **ViewState enum** — Also defined inside the extension. Supports associated value for result text.

---

## LanguageListView

**File:** `View Layer/Screens/LanguageListView.swift`
**Role:** Dual-purpose screen controlled by a `Mode` enum. Used by `Screen.addLanguageFilter` (mode: `.blockLanguage`) and `Screen.automaticBlocking` (mode: `.automaticBlocking`).

### Modes

- **`.blockLanguage`** — Presented as a sheet. Wraps body in its own `NavigationView`. Each language is a `Button` that adds a deny-language filter via `PersistanceManager.addFilter()` and dismisses. Large title, toolbar X button.
- **`.automaticBlocking`** — Pushed via `NavigationLink` from AppHomeView (already inside a `NavigationView`, so no wrapper). Each language is a `Toggle` using `StatefulItem<NLLanguage>` with getter/setter bridging to `AutomaticFilterManager.languageAutomaticState` / `setLanguageAutmaticState`. Inline title. Supports pull-to-refresh (`.refreshable`) when cache is stale (>0 days old).

### Layout

A single `List` section with:
- `ForEach` over `model.languages: [StatefulItem<NLLanguage>]` — renders either buttons or toggles per mode.
- **Empty state** (automatic mode only) — if languages array is empty, shows either a loading `ProgressView` or an error message (distinguishing offline vs. fetch error).
- **Footer** — In block-language mode: explanatory text. In automatic mode: last-updated timestamp (formatted via `DateFormatter`) + help text second line.

### ViewModel

- `mode: Mode` — Set at init, determines all behavior branching.
- `languages: [StatefulItem<NLLanguage>]` — Language list from `AutomaticFilterManager.languages(for:)`, wrapped in `StatefulItem` for toggle binding (automatic mode) or plain display (block mode).
- `isLoading: Bool`, `isOnline: Bool` — Loading/network state for empty-state UI.
- `shouldAllowRefresh: Bool` — Enables pull-to-refresh only when cache is >0 days old.
- `footer: String`, `footerSecondLine: String?` — Footer text, mode-dependent.
- `refresh()` — Reloads languages and recalculates footer/refresh state from managers.
- `addFilter(language:)` — Block-language mode only. Creates a `.denyLanguage` filter with the language's `filterText` (format: `$lang:english`).
- `forceUpdateFilters()` — `async @Sendable`. Sleeps 1s (for pull-to-refresh animation), calls `AutomaticFilterManager.forceUpdateAutomaticFilters()`, then refreshes on main queue.

### NotificationCenter Observers (automatic mode only)

- `.networkStatusChange` — When coming online with an empty language list, triggers `updateAutomaticFiltersIfNeeded()` and shows loading.
- `.automaticFiltersUpdated` — Refreshes the language list when filters finish updating.

### Notable

- Conforms to `@unchecked Sendable` to support the `@Sendable` requirement of `.refreshable`.
- The conditional `NavigationView` wrapper pattern: `.blockLanguage` adds its own, `.automaticBlocking` relies on the parent's. Uses the `View.if()` extension for conditional toolbar/refreshable modifiers.

---

## AddFilterView

**File:** `View Layer/Screens/AddFilterView.swift`
**Role:** Form for creating a new deny or allow filter. Used by `Screen.addDenyFilter` (filterType: `.deny`) and `Screen.addAllowFilter` (filterType: `.allow`).

### Layout

A `NavigationView` wrapping a `ScrollView` with a `VStack`:
- **Filter text** `TextField` — auto-focused after 0.7s. Shows inline duplicate warning badge (red octagon + text) when `isDuplicateFilter` is true.
- **Advanced options** (collapsible via "More/Less" toggle button with rotating arrow):
  - **Deny folder** picker (deny type only) — segmented `Picker` for `.junk`, `.transaction`, `.promotion`.
  - **Filter target** picker — segmented: all / sender / body.
  - **Filter matching** picker — segmented: contains / exact.
  - **Filter case** picker — segmented: case insensitive / case sensitive.
- **Add button** — `FilledButton` style. Disabled when text is shorter than `kMinimumFilterLength` (1) or is a duplicate. Calls `addFilter()` and dismisses.
- Toolbar X button to dismiss.

### ViewModel

- `filterType: FilterType` — Set at init (`.deny` or `.allow`). Controls title and whether deny-folder picker is shown.
- `filterText: String` — Two-way bound to text field.
- `selectedDenyFolderType`, `selectedFilterTarget`, `selectedFilterMatching`, `selectedFilterCase` — Two-way bound to segmented pickers.
- `isExpanded: Bool` — Controls advanced options visibility. Persisted to `DefaultsManager.isExpandedAddFilter` via `didSet`.
- `isDuplicateFilter: Bool` — Computed property. Checks `PersistanceManager.isDuplicateFilter()` in real time as user types. Guarded by `didAddFilter` flag to avoid false positives after submission.
- `addFilter()` — Delegates to `PersistanceManager.addFilter()` with all selected options.

### Notable

- The expanded/collapsed state of the advanced section is persisted across sessions via `DefaultsManager`.
- Duplicate detection is live — computed on every SwiftUI re-render by querying CoreData.

---

## FilterListView

**File:** `View Layer/Screens/FilterListView.swift`
**Role:** Displays and manages the list of user-created filters for a given type. Used by `Screen.denyFilterList`, `.allowFilterList`, `.denyLanguageFilterList` — all build `FilterListView` with different `FilterType`.

### Layout

Pushed via `NavigationLink` from AppHomeView (no own `NavigationView`). A `List` with multi-selection support (`selection: $model.selectedFilters`) containing a single section:
- **Header** — Column labels: "Text" (or "Language") + "Options" (or "Folder").
- **Rows** — `ForEach` over `model.filters` rendering `FilterListRowView` components. Supports `.onDelete` for swipe-to-delete.
- **Footer** — Help text explaining the filter type + an `AddFilterButton` at the bottom (opens the appropriate add-filter sheet). The button is hidden for `.denyLanguage` when no more languages are available to block.

### Navigation Bar

`NavigationBarMenu` — contextual trailing items:
- **Normal mode:** Ellipsis `Menu` with "Edit" (enters edit mode) and "Add Filter" options.
- **Edit mode:** Shows `EditButton` + a red "Delete (N)" button when filters are selected. Bulk-deletes selected filters.

### ViewModel

- `filterType: FilterType` — Set at init, determines which filters to fetch and which add-filter screen to present.
- `filters: [Filter]` — Fetched from `PersistanceManager.fetchFilterRecords(for:)`, filtered by type.
- `selectedFilters: Set<Filter>` — Multi-selection state for edit mode.
- `editMode: EditMode` — Controls List edit mode (`.inactive` / `.active`).
- `canBlockAnotherLanguage: Bool` — Whether the add-language button should be shown (checks if unblocked languages remain).
- `footer: String` — Help text, varies by filter type.
- `sheetScreen: Screen?` — For presenting add-filter sheets. Triggers `refresh()` on dismiss.
- `refresh()` — Re-fetches filters from persistence.
- `deleteFilters(withOffsets:in:)` — Swipe-to-delete. Delegates to `PersistanceManager.deleteFilters()`.
- `deleteFilters(_:)` — Bulk delete from edit mode selection.

### Supporting Components

- **FilterListRowView** (`Others/FilterListRowView.swift`) — Individual filter row with inline editing. Has its own `ViewModel` (subclasses `BaseViewModel`). Layout varies by filter type:
  - **Deny/Allow:** `EditableText` for inline text editing (tap to edit, minimum 3 chars) + three `Menu` buttons for filter target, matching mode, and case sensitivity — each with tap-to-toggle and long-press for full menu. Color-coded: green when non-default option is active.
  - **Deny Language:** Read-only localized language name (resolved from `$lang:` format via `NLLanguage(filterText:)`).
  - **Deny types with folder support:** Additional `Menu` for deny folder (junk/transaction/promotion).
  - All updates call through to `PersistanceManager.updateFilter()` and trigger `onUpdate` callback to parent.

- **EditableText** (`Others/EditableText.swift`) — Tap-to-edit text component. Uses a ZStack with overlapping `Text` (display) and `TextField` (edit) toggled by `editProcessGoing` state. Enforces minimum character count. Calls `onCommit` when editing ends.

---

## ReportMessageView

**File:** `View Layer/Screens/ReportMessageView.swift`
**Role:** Allows users to report a message as spam or not-spam to the backend. Presented as a sheet from AppHomeView's menu.

### Layout

Structurally similar to TestFiltersView — a `NavigationView` wrapping a `ZStack` (for state overlays) containing a `Form`:
- **Sender** `TextField` — floating label, auto-focused after 0.7s.
- **Message body** `TextEditor` — multiline, 80pt height.
- **Report type** segmented `Picker` — junk / not junk (`ReportType.allCases`).
- **Report button** — `FilledButton` style. Disabled when both inputs empty. Calls `reportMessage()`.

**State overlays** (unlike TestFiltersView, these are fully used):
- **Loading:** `.thinMaterial` full-screen overlay + `ProgressView`.
- **Result:** `.thinMaterial` overlay + animated `CheckView` (green checkmark drawn with `Path` + `trim` animation) + thank-you text. Auto-dismisses after 1 second via `onChange(of: state)`.

Navigation title and toolbar X button are conditionally hidden during loading/result states via `View.if()`.

### ViewModel

- `text: String`, `sender: String` — Two-way bound inputs.
- `selectedReport: ReportType` — Junk or not junk.
- `state: ViewState` — Same enum pattern as TestFiltersView (`.userInput`, `.loading`, `.result(String)`) with `isResult` computed property.
- `reportMessage()` — Sets state to `.loading`, creates `ReportMessageRequestBody`, calls `ReportMessageService.reportMessage()` via async `Task`. On completion, sets state to `.result` on main queue.

### Notable

- Conforms to `@unchecked Sendable` for the async `Task` in `reportMessage()`.
- The `ViewState` enum is nearly identical to TestFiltersView's — both defined independently inside their respective extensions.
- Unlike TestFiltersView, this screen fully uses all three states (userInput -> loading -> result -> auto-dismiss).
- `CheckView` (`Others/CheckView.swift`) — Animated checkmark using `Path` with `trim` animation. Purely cosmetic, no ViewModel.

---

## WhatsNewView

**File:** `View Layer/Screens/WhatsNewView.swift`
**Role:** Shows new features added in the latest version. Presented as a sheet from AppHomeView on second+ launch when `currentWhatsNewVersion` exceeds the user's `lastSeenWhatsNewVersion`.

### Layout

A `NavigationView` wrapping a `ScrollView`:
- **Header** — "What's New" title and subtitle.
- **Entry cards** — `ForEach` over `WhatsNewEntry.allCases`. Each card shows an emoji icon, title, and description. Actionable entries (e.g., `.tipJar`) are tappable and trigger `onActionnableEntryTapped`.
- **Dismiss button** — `FilledButton` at bottom. Sets `lastSeenWhatsNewVersion` to `currentWhatsNewVersion` and dismisses.
- Toolbar X button to dismiss.

### ViewModel

- `entries: [WhatsNewEntry]` — All entries sorted by `order`.
- `onActionnableEntryTapped: ((WhatsNewEntry) -> Void)?` — Optional closure called when an actionable entry is tapped. Passed in from the presenting screen.
- `markAsSeen()` — Sets `lastSeenWhatsNewVersion` to `currentWhatsNewVersion` so the sheet won't re-appear.

### Actionable Entries

`WhatsNewEntry` has an `isActionnable` computed property. When `true`, the entry row becomes a tappable `Button` that calls `markAsSeen()`, invokes `onActionnableEntryTapped`, and dismisses the sheet. The presenting screen handles navigation — e.g., `AppHomeView` sets `pendingScreenAfterDismiss = .tipJar` so the Tip Jar sheet opens after WhatsNew dismisses.

This pattern is general-purpose: any future `WhatsNewEntry` case can become actionable by returning `true` from `isActionnable`, and the presenting screen decides what to do in the `onActionnableEntryTapped` closure.

### Notable

- `WhatsNewEntry` is a `CaseIterable` enum in `Constsants.swift` with computed properties for title, description, emoji, order, and `isActionnable`.
- `currentWhatsNewVersion` must be bumped in `Constsants.swift` when adding new entries.
- The What's New sheet only shows when: it's not the user's first session (`wasFirstRunOnInit == false`), `isAppFirstRun` is `false`, and `currentWhatsNewVersion > lastSeenWhatsNewVersion`.

---

## TipJarView

**File:** `View Layer/Screens/TipJarView.swift`
**Role:** Tip jar screen for voluntary in-app purchases. Presented as a sheet from AppHomeView's menu, AboutView, or via an actionable What's New entry.

### Layout

A `NavigationView` wrapping a `ZStack` (for confetti overlay) containing a `ScrollView`:
- **Header** — Heart emoji, title ("tipJar_header"), and subtitle ("tipJar_subheader").
- **Tip cards** — `HStack` of three `TipCardView` components (small/medium/large, in separate file). Each shows the tier's emoji, display name, description, and price badge. When a specific card is being purchased, its price badge is replaced with a `ProgressView` spinner. Loading state shows a `ProgressView`. Empty state shows "tipJar_unavailable" text.
- **Footer** — Explanatory text ("tipJar_footer").
- **Confetti overlay** — `ConfettiView` (CAEmitterLayer-based) shown after successful purchase. Intensity scales with tier (birthRate, lifetime, velocity).
- Toolbar X button to dismiss.

### Landscape Support

Uses `@Environment(\.verticalSizeClass)` with an `isCompact` flag to reduce font sizes, spacing, and padding in landscape orientation.

### ViewModel

**Published state:**
- `products: [Product]` — StoreKit products fetched from `TipJarManager`.
- `isLoading: Bool` — True while products are being fetched.
- `purchaseState: PurchaseState` — Enum: `.idle`, `.purchasing(TipTier)`, `.success(TipTier)`, `.error`.
- `notification: NotificationView.ViewModel` — Toast notification for thank-you message.
- `shouldDismiss: Bool` — Triggers dismiss after thank-you toast hides.

**Key methods:**
- `init` — Reads products from `TipJarManager`. If still loading, polls `isLoadingProducts` every 100ms on `@MainActor` until ready.
- `purchase(_:)` — Sets state to `.purchasing(tier)`, calls `TipJarManager.purchase()`. On success: shows confetti + thank-you toast, auto-resets after confetti duration. On error: auto-resets after 3s.
- `isPurchasing(tier:)` — Returns true if the given tier is the one currently being purchased.

### Supporting Components

- **TipCardView** (`TipCardView.swift`) — Button with `TipCardButtonStyle` (scale + opacity effect on press). Displays tier emoji, name, description, and price badge with accent color background. Shows a `ProgressView` spinner in place of the price when the card's tier is being purchased.
- **ConfettiView** (`Others/ConfettiView.swift`) — `UIViewRepresentable` wrapping `CAEmitterLayer`. Configurable birthRate, lifetime, and velocity. Emits from top of screen with various cell shapes and colors. Auto-stops emission after 0.3s (particles continue falling).
- **NotificationView** `.tipSuccessful` case — Toast notification with `onHide` callback that triggers sheet dismissal.
