## Context

The app already has a `runFilterRules` pipeline in `MessageEvaluationManager` that evaluates active `AutomaticFiltersRule` CoreData records against each incoming message. Each rule maps to a `RuleType` enum case. The `shortSender` rule precedent shows how a rule can carry a single numeric parameter (`selectedChoice: Int64`). There is no existing mechanism to attach a list of string values to a rule.

The Message Filter Extension and the main app share a CoreData store via the App Group (`group.com.grizz.apps.dev.simply-filter-sms`). `MessageEvaluationManager` in the extension opens the same `NSPersistentCloudKitContainer` and reads `AutomaticFiltersRule` records directly — so any attribute added to that entity is automatically available to the extension with no extra plumbing.

Country detection must work at filter time inside the extension with no network access, using only the raw sender string as input.

## Goals / Non-Goals

**Goals:**
- Let the user enable a rule that blocks all senders not from an explicitly selected set of countries.
- Store the selected country list in CoreData (v3 → v4 lightweight migration) so it syncs across devices via CloudKit, consistent with every other user setting in the app.
- Detect the sender's country from the E.164 phone number prefix using a hardcoded calling-code map.
- Integrate the rule into the existing `runFilterRules` evaluation loop.
- Add a country picker screen reachable from the Automatic Filters rule row.

**Non-Goals:**
- Distinguishing individual countries that share a calling code (e.g., US vs. Canada vs. Jamaica within NANP `+1`) — they are grouped as one entry.
- Parsing non-E.164 senders (short codes, alphanumeric sender IDs) to a country — they are treated as unknown and blocked.
- Carrier-level or network-level country detection.

## Decisions

### 1. Storage: CoreData attribute on `AutomaticFiltersRule` (schema v3 → v4)

The existing `AutomaticFiltersRule` entity carries `selectedChoice: Int64` for numeric rule parameters (see `shortSender`). The country allowlist needs a list of strings instead.

**Decision:** Add a `selectedCountries: String` attribute to the `AutomaticFiltersRule` entity in a new CoreData model version (v4). The attribute stores a JSON-encoded `[String]` of ISO 3166-1 alpha-2 country codes (e.g., `["US","IL"]`). The enabled/disabled state continues to use the existing `isActive` flag.

**Why CoreData over UserDefaults:** The app syncs all user preferences across devices via CoreData + CloudKit (`NSPersistentCloudKitContainer`). UserDefaults is device-local and does not sync — using it would break iCloud sync consistency that every other feature in the app relies on. CoreData is the correct and only appropriate store for user-facing settings in this app.

**Alternatives considered:**
- New CoreData entity — over-engineered; a single attribute on the existing entity is sufficient.
- UserDefaults via App Group — rejected because it does not sync via CloudKit.

### 2. Country Detection: Hardcoded E.164 Calling-Code Map

There is no system API on iOS that parses raw phone number strings into country codes. `NSDataDetector` detects phone numbers but returns the raw string; `CNPhoneNumber` is a string wrapper only; `CoreTelephony` reflects the user's own carrier, not the sender's; `ILMessageFilterQueryRequest` exposes `receiverISOCountryCode` (the *user's* country, not the sender's). LibPhoneNumber is the standard solution but requires SPM/CocoaPods, which this project explicitly avoids.

**Decision:** Ship a hardcoded map of ITU calling-code prefixes defined in a new `CallingCodes.swift` file (compiled into `Shared with Extension/`). The map is keyed by calling-code string and maps to a `CallingCodeEntry` value type:

```swift
struct CallingCodeEntry {
    let callingCode: String      // e.g. "+44"
    let displayName: String      // e.g. "United Kingdom" or "North America (+1)"
    let isoCountryCodes: [String] // e.g. ["GB"] or ["US","CA","JM",...]
}

// Keyed by calling code string for O(1) lookup
let callingCodeMap: [String: CallingCodeEntry] = [
    "+1":   CallingCodeEntry(callingCode: "+1",   displayName: "North America (+1)", isoCountryCodes: ["US","CA","JM",...]),
    "+7":   CallingCodeEntry(callingCode: "+7",   displayName: "Russia & Kazakhstan (+7)", isoCountryCodes: ["RU","KZ"]),
    "+44":  CallingCodeEntry(callingCode: "+44",  displayName: "United Kingdom",     isoCountryCodes: ["GB"]),
    "+972": CallingCodeEntry(callingCode: "+972", displayName: "Israel",             isoCountryCodes: ["IL"]),
    // ...
]
```

**Step 1 — Normalize the sender string:**

Strip all characters that are not digits or `+`. Specifically: spaces, dashes, dots, parentheses, and any other formatting characters. Examples:
- `"+972 050-123-4567"` → `"+972050123456"`
- `"+1 (868) 123-4567"` → `"+18681234567"`
- `"Apple"` → `"Apple"` (no digits stripped — no `+`, unclassifiable)
- `"12345"` → `"12345"` (no `+`, unclassifiable)

If the normalized string does **not** start with `+`, the rule is skipped entirely — evaluation falls through to the next rule. Alphanumeric senders, short codes, and local-format numbers are not the concern of this rule.

**Step 2 — Longest-prefix match:**

Country codes are 1–3 digits long (so 2–4 characters including `+`). Try prefixes from longest to shortest:

```
"+XXX"  (4 chars) → check map
"+XX"   (3 chars) → check map
"+X"    (2 chars) → check map
no match          → rule is skipped, evaluation falls through
```

First match wins. This is necessary because some shorter codes are prefixes of longer ones (e.g., `+1` would incorrectly match `+1868` Trinidad numbers if tried first).

Example: sender `"+18682001234"`
1. Try `"+186"` — no match
2. Try `"+18"` — no match
3. Try `"+1"` — match → `CallingCodeEntry` for North America

Example: sender `"+97250123456"`
1. Try `"+972"` — match → `CallingCodeEntry` for Israel ✓

**Step 3 — Evaluate against allowed entries:**

The `AutomaticFiltersRule.selectedCountries` JSON stores calling-code strings (not ISO codes), e.g. `["+1", "+972"]`. At evaluation time, compare the matched `callingCode` from step 2 against the stored list. If it's in the list → allow. If not → junk.

Storing calling codes (not ISO codes) keeps the lookup direct: the match result from step 2 is the key, no secondary lookup needed.

**Known map limitations:**
- **NANP (`+1`)** — ~25 nations share `+1` and are indistinguishable by prefix. Grouped as one picker entry.
- **Other shared codes** — `+7` (Russia/Kazakhstan), `+47` (Norway/Svalbard), etc. Same grouping.
- **Map staleness** — baked into the binary, updated only on app release. ITU codes change very rarely; acceptable risk.

### 3. Rule Evaluation Priority

The `runFilterRules` loop in `MessageEvaluationManager` iterates active rules and stops at the first match. CoreData fetch order is non-deterministic without a sort descriptor.

**Decision:** Add an explicit `sortIndex` to `RuleType` for `.countryAllowlist` (e.g., `sortIndex = 6`, appearing after existing rules in the UI). In `runFilterRules`, add a `NSSortDescriptor` on `ruleType` when fetching, or handle priority implicitly by keeping `.countryAllowlist` as a blocking rule that runs normally within the loop.

The country allowlist intentionally interacts with `allUnknown`: if `allUnknown` is also active, it will already block everything — the country allowlist adds no extra value in that case, but causes no conflict since both produce `.junk`.

### 4. UI: Toggle + Tappable Disclosure Row

The country allowlist rule needs two distinct interaction targets: one to enable/disable the rule, and one to configure the country selection. These are separate concerns and should be separate rows — a familiar iOS Settings pattern.

**Decision:** In the Automatic Filters list, the `.countryAllowlist` rule renders as two rows:

1. **Toggle row** — the standard rule row with title, icon, and a toggle. Enables/disables the rule (`AutomaticFiltersRule.isActive`). Identical in appearance to all other rule rows.
2. **Disclosure row** — appears directly below the toggle row when the rule is enabled. Shows the current selection as a summary (e.g., "Israel, North America (+1)" or "None selected"). Tapping it navigates to `CountryListView`.

The disclosure row is hidden when the toggle is off — no need to pick countries when the rule is inactive.

`CountryListView` lists all calling-code entries (flag emoji + display name + calling code), supports search, and uses checkmarks for multi-selection. Selection is persisted immediately on each tap (no "Save" button). The `action` / `actionTitle` properties on `RuleType` are **not** used for this rule.

### 5. New `RuleType` Case: `.countryAllowlist`

Add `case countryAllowlist = 6` to `RuleType`. All existing switch statements in `RuleType` (title, icon, iconColor, subtitle, action, actionTitle, shortTitle, isDestructive, toggleBackgroundColor, sortIndex) must handle the new case. `isDestructive` returns `false`; `toggleBackgroundColor` uses `.accentColor`.

## Risks / Trade-offs

- **Non-E.164 senders (no `+` prefix)** → local-format numbers (e.g., `0501234567`), short codes (e.g., `12345`), and alphanumeric senders (e.g., `Apple`, `BANK`) cannot be matched to any country. The rule skips them entirely — they fall through to subsequent rules. This is the correct behavior: the rule is about country codes, not sender format.
- **NANP `+1` ambiguity** → US, Canada, and ~25 other nations share `+1` and cannot be distinguished by prefix. Mitigation: expose them as a single grouped entry ("North America (+1)") in the country picker — never as separate countries — so the user isn't misled.
- **Other shared calling codes** → `+7` (Russia/Kazakhstan), `+47` (Norway/Svalbard), etc. Same mitigation: group them as one picker entry per shared code.
- **Calling-code map maintenance** → baked into the binary. ITU codes change very rarely; acceptable. Map defined in `CallingCodes.swift` (compiled into `Shared with Extension/`).
- **CoreData lightweight migration** → adding an optional `String` attribute qualifies for lightweight migration; no custom mapping model needed. Risk is low.

## Migration Plan

1. Add a new CoreData model version (v4) with `selectedCountries: String` (optional) on `AutomaticFiltersRule`. Set the active model version to v4 and configure lightweight migration (`NSMigratePersistentStoresAutomaticallyOption` + `NSInferMappingModelAutomaticallyOption`) — adding an optional attribute qualifies for lightweight migration with no mapping model required.
2. Existing `AutomaticFiltersRule` records will have `selectedCountries = nil` after migration. The rule evaluation treats nil/empty as "no countries selected" → rule behaves as disabled (safe default — no messages accidentally blocked on upgrade).
3. The new `RuleType` case (`.countryAllowlist = 6`) is not persisted to CoreData until the user enables the rule, so existing records are unaffected.

## Open Questions

None.
