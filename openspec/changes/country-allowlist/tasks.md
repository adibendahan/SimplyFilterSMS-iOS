## 1. CoreData Schema Migration (v3 → v4)

- [ ] 1.1 Duplicate the current CoreData model version to create v4 in `Simply-Filter-SMS.xcdatamodeld`
- [ ] 1.2 Add optional `String` attribute `selectedCountries` to the `AutomaticFiltersRule` entity in v4
- [ ] 1.3 Set v4 as the active model version and verify lightweight migration succeeds on launch

## 2. Calling-Code Map

- [ ] 2.1 Create `CallingCodes.swift` in `Framework Layer/Shared with Extension/`
- [ ] 2.2 Define the `CallingCodeEntry` struct (`callingCode`, `displayName`, `isoCountryCodes`)
- [ ] 2.3 Populate the full `callingCodeMap: [String: CallingCodeEntry]` dictionary covering all ITU country codes, with shared-code nations grouped (NANP as one entry, `+7` as one entry, etc.)
- [ ] 2.4 Implement `CallingCodes.callingCode(for sender: String) -> CallingCodeEntry?` — normalize the sender string, then try longest-prefix match (4-char, 3-char, 2-char); return `nil` if no `+` prefix or no match

## 3. RuleType & Constants

- [ ] 3.1 Add `case countryAllowlist = 6` to `RuleType` in `Constsants.swift`
- [ ] 3.2 Implement all `RuleType` computed properties for `.countryAllowlist`: `title`, `icon`, `iconColor`, `shortTitle`, `subtitle`, `action`, `actionTitle`, `sortIndex`, `isDestructive`, `toggleBackgroundColor`

## 4. PersistenceManager

- [ ] 4.1 Add `selectedCountries(for rule: RuleType) -> [String]` to `PersistanceManagerProtocol` and `PersistanceManager` — decodes JSON from `AutomaticFiltersRule.selectedCountries`
- [ ] 4.2 Add `setSelectedCountries(_ countries: [String], for rule: RuleType)` to `PersistanceManagerProtocol` and `PersistanceManager` — encodes to JSON and commits
- [ ] 4.3 Update mock `mock_PersistanceManager` to implement the two new protocol methods

## 5. AutomaticFilterManager

- [ ] 5.1 Add `selectedCountries(for rule: RuleType) -> [String]` to `AutomaticFilterManagerProtocol` and `AutomaticFilterManager` (delegates to `PersistanceManager`)
- [ ] 5.2 Add `setSelectedCountries(_ countries: [String], for rule: RuleType)` to `AutomaticFilterManagerProtocol` and `AutomaticFilterManager`
- [ ] 5.3 Update mock `mock_AutomaticFilterManager` to implement the two new protocol methods

## 6. MessageEvaluationManager

- [ ] 6.1 Add `.countryAllowlist` case to `runFilterRules` in `MessageEvaluationManager`
- [ ] 6.2 Implement the evaluation logic: decode `selectedCountries` from the rule record, call `CallingCodes.callingCode(for:)`, skip if nil or not in selected set, return `.junk` if matched calling code is not in the allowed list

## 7. CountryListView

- [ ] 7.1 Create `CountryListView.swift` in `View Layer/Screens/`
- [ ] 7.2 Create `CountryListView.ViewModel` (subclass of `BaseViewModel`) with published list of `CallingCodeEntry` items, selected calling codes, and search query
- [ ] 7.3 Implement search filtering in the ViewModel
- [ ] 7.4 Implement toggle selection in the ViewModel — persists immediately via `AutomaticFilterManager.setSelectedCountries`
- [ ] 7.5 Build the SwiftUI list: flag emoji + display name + calling code + checkmark for selected entries
- [ ] 7.6 Add `CountryListView` to `Screen.swift` as a new enum case and implement `build()`

## 8. Automatic Filters Rule Row UI

- [ ] 8.1 Update the Automatic Filters list view to render the disclosure row below the `.countryAllowlist` toggle when the rule is enabled
- [ ] 8.2 Implement the disclosure row: show selection summary (comma-separated display names, truncated with "+ N more", or "No countries selected" placeholder)
- [ ] 8.3 Wire the disclosure row tap to navigate to `CountryListView`

## 9. Localization

- [ ] 9.1 Add localization keys for the rule title, icon, and short title to `en` and `he` `.strings` files
- [ ] 9.2 Add localization key for the "No countries selected" placeholder
- [ ] 9.3 Run BartyCrouch to normalize all `.strings` files

## 10. Tests

- [ ] 10.1 Add unit tests for `CallingCodes.callingCode(for:)` covering: E.164 match, formatted number normalization, alphanumeric sender (returns nil), local-format number (returns nil), unrecognized `+` prefix (returns nil), shared calling code (e.g. `+1868` → NANP group)
- [ ] 10.2 Add unit tests for `MessageEvaluationManager.runFilterRules` with `.countryAllowlist` active: allowed country passes through, blocked country returns junk, no-`+` sender is skipped
- [ ] 10.3 Add unit tests for `PersistanceManager` selectedCountries encode/decode round-trip
