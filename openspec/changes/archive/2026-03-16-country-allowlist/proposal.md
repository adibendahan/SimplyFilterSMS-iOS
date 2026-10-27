## Why

Users in specific countries receive SMS messages almost exclusively from domestic senders, making international numbers unwanted noise. There is currently no way to block all messages except those from a selected set of countries, forcing users to create many individual filters to approximate this behavior.

## What Changes

- Add a new "Allowed Countries" rule under Automatic Filters that, when enabled, blocks all messages from senders whose phone number does not match any of the user-selected country codes.
- Provide a country selection screen where the user can pick one or more countries to allow; all other countries are blocked.
- The rule is off by default; enabling it reveals the country picker.
- When no countries are selected, the rule is treated as disabled (to avoid accidentally blocking everything).
- The filter is applied in `MessageEvaluationManager` alongside existing automatic rules.

## Capabilities

### New Capabilities
- `country-allowlist`: A rule that blocks SMS messages from senders not matching any user-selected country dialing code, with a UI to select allowed countries.

### Modified Capabilities
- (none)

## Impact

- **`AutomaticFilterManager`** — new rule type evaluated against sender phone number.
- **`MessageEvaluationManager`** — calls into the new rule during evaluation.
- **`PersistanceManager` / CoreData** — new persistent setting for enabled state + selected countries (likely `DefaultsManager` / `UserDefaults` via App Group, accessible from the extension).
- **`AutomaticFiltersRule` / `RuleType`** — new `RuleType` case for the allowlist rule.
- **View Layer** — new country picker screen and a new toggle row in the Automatic Filters list.
- **Localization** — new strings for rule name, description, and country picker.
- **App Group** — selected country list must be readable by the Message Filter Extension.
