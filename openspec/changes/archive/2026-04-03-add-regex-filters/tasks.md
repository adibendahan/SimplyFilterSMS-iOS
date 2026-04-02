## 1. Model & Evaluation

- [x] 1.1 Add `FilterMatching.regex` case (raw value `2`) to `Constants.swift` with `name`, `icon`, and `logDescription`
- [x] 1.2 Add a `.regex` branch in `MessageEvaluationManager.evaluateFilter` — insert before the lowercasing block, compile `try? Regex(pattern)`, return `(try? message.contains(regex)) ?? false`

## 2. AddFilterView — Validation & UI

- [x] 2.1 Add `isInvalidRegex: Bool` computed property to `AddFilterView.ViewModel` — true when matching is `.regex`, text is non-empty, and `try? Regex(filterText)` is `nil`
- [x] 2.2 Disable the Add button when `isInvalidRegex` is true (alongside existing guards)
- [x] 2.3 Show an inline error badge next to the text field when `isInvalidRegex` is true (same visual pattern as `isDuplicateFilter`)
- [x] 2.4 Hide the `FilterCase` picker in `AddFilterView` when `selectedFilterMatching == .regex`

## 3. AddFilterView — Live Preview

- [x] 3.1 Add `@Published var regexTestText: String` to `AddFilterView.ViewModel`
- [x] 3.2 Add `regexTestResult: RegexTestResult` computed property (enum: `.match`, `.noMatch`, `.invalidPattern`, `.empty`) based on current `filterText` and `regexTestText`
- [x] 3.3 Show the "Test text" field in `AddFilterView` expanded section when `selectedFilterMatching == .regex`
- [x] 3.4 Show green checkmark / red X indicator next to the test field driven by `regexTestResult`

## 4. Localization

- [x] 4.1 Use `/add-localized-text` to add string for the Regex matching option label (shown in picker)
- [x] 4.2 Use `/add-localized-text` to add string for the invalid regex error badge
- [x] 4.3 Use `/add-localized-text` to add string for the "Test text" field placeholder

## 5. Tests

- [x] 5.1 Add unit tests to `MessageEvaluationManagerTests` covering: regex match, regex no-match, invalid pattern returns false, case-sensitive pattern, `(?i)` inline flag
- [x] 5.2 Add unit tests to `AddFilterView.ViewModel` (or equivalent) for `isInvalidRegex` and `regexTestResult` states
