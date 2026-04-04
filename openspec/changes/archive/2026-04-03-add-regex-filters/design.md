## Context

Filters are currently evaluated in `MessageEvaluationManager.evaluateFilter(_:sender:body:)` using one of two strategies driven by `FilterMatching`: substring search (`.contains`) or whole-word exact match (`.exact`). Both strategies pre-lowercase the operands when `FilterCase == .caseInsensitive`, then use `String.contains` / `String.range(of:options:)`.

Adding regex support requires a third evaluation path that bypasses the pre-lowercasing step and delegates entirely to the Swift `Regex` engine. Case sensitivity, when desired, is expressed by the user in the pattern itself (e.g., `(?i)`).

The `FilterMatching` raw value `2` is unused; assigning `.regex = 2` is additive and requires no CoreData migration.

## Goals / Non-Goals

**Goals:**
- Let users write regular expression patterns as filter text using Swift `Regex` (iOS 16+).
- Validate regex syntax at entry time — block saving invalid patterns and surface a clear error.
- Provide an inline live-preview test field in `AddFilterView` so users can verify their pattern before saving.
- Keep regex filters first-class in duplicate detection and test-filter evaluation (no special-casing needed beyond the evaluation branch).

**Non-Goals:**
- Regex support in automatic/community filters (managed server-side).
- Exposing `FilterCase` for regex — users control case sensitivity inline via `(?i)` in their pattern.
- Pre-compilation caching of `Regex` objects across evaluations (defer if profiling shows it's needed).

## Decisions

### 1. Regex engine: Swift `Regex` (iOS 16+)
The app targets iOS 16.6+. `Swift.Regex` is the modern, idiomatic choice over `NSRegularExpression`. Runtime string-pattern construction uses `try Regex(pattern)`, which produces a `Regex<AnyRegexOutput>`. Evaluation uses `String.contains(_:)` with the `Regex` instance. Both `try Regex(pattern)` and `String.contains(_:Regex)` can throw, so `try?` is used at the call site with a `false` fallback.

Evaluation pseudo-code:
```swift
// In MessageEvaluationManager, new branch for .regex:
guard let regex = try? Regex(filter.text ?? "") else { return false }
return (try? messageForEvaluation.contains(regex)) ?? false
```

`messageForEvaluation` is **not** lowercased before this call; the `.regex` branch must be added before the existing lowercasing block in `evaluateFilter`.

### 2. `FilterCase` picker hidden for regex
`FilterCase` is hidden when `selectedFilterMatching == .regex`. Users control case sensitivity inside their pattern via the standard `(?i)` inline flag. Showing the `FilterCase` picker for regex would be redundant and confusing.

### 3. Validation in ViewModel
`AddFilterView.ViewModel` exposes a computed `isInvalidRegex: Bool` — true when `selectedFilterMatching == .regex`, `filterText` is non-empty, and `try? Regex(filterText)` returns `nil`. The Add button is disabled when `isInvalidRegex` is true (alongside existing duplicate/length guards). An inline error badge (same visual pattern as the existing `isDuplicateFilter` badge) is shown under the same conditions.

### 4. Inline live-preview test field
When `selectedFilterMatching == .regex` and the expanded section is open, an additional text field labeled "Test text" appears below the matching picker (replacing the `FilterCase` picker slot). As the user types in both the pattern field and the test field, a small indicator shows whether the current pattern matches the test text in real time:
- **Green checkmark** — pattern is valid and matches
- **Red X** — pattern is valid but does not match
- **No indicator** — test field is empty or pattern is invalid

The ViewModel exposes `regexTestText: String` (published, user-editable) and `regexTestResult: RegexTestResult` (computed enum: `.match`, `.noMatch`, `.invalidPattern`, `.empty`). No new screen is needed; this lives entirely within `AddFilterView`.

### 5. Minimum filter length still applies
`kMinimumFilterLength` still gates the Add button. A single-character regex like `.` or `\d` is intentionally valid.

## Risks / Trade-offs

- **ReDoS (catastrophic backtracking):** Pathological patterns can cause slow evaluation in the Message Filter Extension, which runs synchronously. Swift `Regex` uses a different execution model than ICU (`NSRegularExpression`) and may have different backtracking characteristics. Mitigation: note as a known limitation; address with a timeout wrapper only if user reports arise.

- **Regex unfamiliarity:** Most users will not know regex syntax. The inline preview (Decision #4) and validation error mitigate the worst-case UX. A help reference is out of scope but could be added later.

- **Extension performance:** Regex compilation on every evaluation is slightly more expensive than `String.contains`. Negligible for typical filter list sizes. If filter counts grow, cache `Regex` objects keyed by pattern string.

## Migration Plan

No data migration required. The `FilterMatching` Int64 column in CoreData accepts any integer; raw value `2` decodes as `.regex` after the enum case is added. Old app versions that don't know `.regex` fall through to the `.contains` branch (substring match) — acceptable graceful degradation.

Rollout: standard App Store release. No feature flag needed.

## Open Questions

- Should `.regex` be hidden from the matching picker when `FilterTarget == .sender`? Deferred — expose uniformly for now; revisit based on support feedback.
