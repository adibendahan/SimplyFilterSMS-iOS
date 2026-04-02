## Why

Power users want to write precise filters for complex patterns (e.g., "any 5-digit number", "URLs from a specific domain") that `contains` and `exact` cannot express. Regular expression support in user-defined filters closes this gap without adding UI complexity for casual users.

## What Changes

- Add a new `FilterMatching.regex` case (raw value `2`) alongside the existing `contains` and `exact` options.
- Update `MessageEvaluationManager` to evaluate regex-typed filters using `NSRegularExpression`, respecting the existing `FilterCase` (case-insensitive / case-sensitive) setting.
- Validate regex syntax at entry time in `AddFilterView` — show an inline error and block saving if the pattern is invalid.
- Surface the regex option in the matching picker in `AddFilterView` with an appropriate label/icon.
- Update `TestFiltersView` to handle regex filters correctly during local test evaluation.

## Capabilities

### New Capabilities
- `regex-filters`: User-defined filters that use regular expression matching. Covers the new `FilterMatching.regex` enum case, evaluation logic, UI entry/validation, and test-filter support.

### Modified Capabilities

_(none — no existing spec-level behavior changes)_

## Impact

- **`Constants.swift`** — `FilterMatching` enum: new `.regex` case (raw value `2`), new `name`/`icon`/`logDescription` entries.
- **`MessageEvaluationManager.swift`** — filter evaluation: add regex branch that compiles `NSRegularExpression` from `filter.text` and tests it against the message.
- **`AddFilterView` / `AddFilterView.ViewModel`** — matching picker must show the regex option; ViewModel must validate the regex pattern and expose a validation error.
- **`TestFiltersView`** — passes messages through the same `MessageEvaluationManager`; no special changes needed beyond the evaluation update.
- **CoreData model** — no schema migration required; `FilterMatching` is stored as `Int64`, new raw value `2` is additive.
- **Localization** — new strings for regex option label and validation error message (via `/add-localized-text`).
