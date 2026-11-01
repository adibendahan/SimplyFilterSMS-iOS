# Filter list row fixes (from `bugfixes-filter-lists`)

This branch was written two months before the latest `develop` and does not merge cleanly: `develop` has reworked `FilterListRowView` since (collapsible filter options, the iOS 17 floor cleanup, save-failure alerts). Redo the fixes below on top of `develop`; don't merge this branch.

## Already in `develop`

- Rows carry `.tag(rowModel.filter)`, so edit-mode multi-select works.
- `.deleteDisabled(editMode.isEditing)` on rows.

## Still missing from `develop`

1. **Section split reads live Core Data.** `regularRowViewModels` / `regexRowViewModels` filter on `$0.filter.filterMatching`. After a store reload a `Filter` can briefly report default values, so a regex row jumps into the regular section. Fix: the row ViewModel caches `filterType`, `filterTarget`, `filterMatching`, `filterCase` and `denyFolderType` (set in `init` and `updateFilter(_:)`, and by each `updateFilter(<option>:)` setter), and the view and the section split read the cached values. Test: `test_sectionSplitUsesCachedMatching`.
2. **Text comparisons use `filter.text`.** Same reload problem: the duplicate check, the unchanged check and the revert-on-invalid read a value that can flicker. Fix: a `committedText` updated only on a successful save or `updateFilter(_:)`.
3. **Option buttons stay visible in edit mode.** Hide them with opacity, `allowsHitTesting(false)` and `accessibilityHidden` while editing text or in edit mode, so the row layout doesn't jump. Reconcile with `develop`'s collapsible options before porting.
4. **Tapping in edit mode dismisses focus.** The list's `onTapGesture` needs `guard !editMode.isEditing` so it doesn't compete with row selection.
5. **Delete (N) ordering.** Copy the selection, clear `selectedFilters`, then delete; stay in edit mode until Done. Test: `test_deleteSelectedFilters`.

## Porting notes

- Item 1 is the real bug; 2–5 are polish.
- The branch adds an inline comment in the test and keeps `@discardableResult` on `updateFilter(filterText:)`. Both break current repo rules, so drop them when porting.
- `docs/SCREENS.md` lines on this branch describe code; per the docs rules, keep only the trap (section membership must not read live Core Data during a reload).
