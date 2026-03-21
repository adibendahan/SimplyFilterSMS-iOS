# Code Review Report: `ai-automatic-filtering` Branch

**Date:** 2026-03-20
**Scope:** ~230 files changed across 30 commits vs `develop`
**Reviewed by:** Claude Opus 4.6

---

## 1. LOCALIZATION (8 new languages)

### High Priority

| # | Lang | Key | Issue | Status |
|---|------|-----|-------|--------|
| 1 | French | `whatsNew_trustedCountries_desc` | Uses **vous** while rest of app uses **tu** | ✅ Fixed |
| 2 | French | `reportingExtension_footer` | "Vos/votre" → tu forms | ✅ Fixed |
| 3 | French | `reportingExtension_classify` (stringsdict) | "souhaitez-vous" → "souhaites-tu" | ✅ Fixed |
| 4 | Italian | `autoFilter_error` | Grammar: "nel scaricare" → "nello scaricare" | ✅ Fixed |
| 5 | pt-BR | `tipJar_tier_large_desc` | Bond quote reversed → "Agitado, não mexido" | ✅ Fixed |

### Medium Priority

| # | Lang | Key | Issue | Status |
|---|------|-----|-------|--------|
| 6 | Spanish | `testFilters_resultReason_noMatch` | "Sin resultado" → "Sin coincidencia" | ⏭ Skipped (intentionally terse) |
| 7 | German | `notification_hide` | "OK" → "Ausblenden" | ⏭ Skipped (intentionally short) |
| 8 | pt-BR | `addFilter_add` | "Incluir" → "Adicionar" | ✅ Fixed |
| 9 | fr/de/pt-BR | stringsdict `general_active_count` | Missing `zero` plural case | ✅ Fixed |
| 10 | Korean | Fastlane `description.txt` | "팁 항아리" → "팁 저금통" | ✅ Fixed |

---

## 2. AUTOMATIC FILTERS (`automatic_filters.json`)

### Critical — False Positives

**English/Hebrew pre-existing** — out of scope for this version, skipped.

### Other Filter Issues

| # | Issue | Status |
|---|-------|--------|
| 1 | English: `"No hidden Ñosts"` typo → `"No hidden costs"` | ✅ Fixed |
| 2 | Italian missing accents — added accented variants alongside unaccented | ✅ Fixed |
| 3 | Korean missing `Apple` from `allow_sender` | ✅ Fixed |
| 4 | Hebrew/Korean redundant `"xxx"` + `"XXX"` pairs | ✅ Fixed |
| 5 | Arabic `"عون"` (Aoun) also means "help" — false-positive prone | ⏭ Pre-existing, out of scope |
| 6 | CallingCodes.swift missing `+211` South Sudan | ✅ Fixed |

---

## 3. FRAMEWORK / SERVICES LAYER

### High Priority

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | `MessageEvaluationManager.swift` | Hardcoded English "Automatic Filters" reason string → restored `"autoFilter_title"~` | ✅ Fixed |

### Medium Priority

| # | File | Issue | Status |
|---|------|-------|--------|
| 2 | `Constants.swift` | File header said `Constsants.swift` | ✅ Fixed |
| 3 | `AutomaticFilterManagerProtocol.swift` + 4 files | Typo `setLanguageAutmaticState` → `setLanguageAutomaticState` | ✅ Fixed |
| 4 | `MessageEvaluationManager.swift` | Typo `isMataching` → `isMatching` | ✅ Fixed |

---

## 4. VIEW LAYER / ACCESSIBILITY

### High Priority

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | `NotificationView.swift` | Retain cycle in `onButtonTap` — fixed with `[weak self]` | ✅ Fixed |
| 2 | `CountryListView.swift` | Country rows missing VoiceOver selected state | ✅ Fixed |
| 3 | `ReportingConfirmationView.swift` | Report type buttons missing VoiceOver selected state | ✅ Fixed |
| 4 | `AppHomeView.swift` | Emoji toggle button — easter egg, VoiceOver intentionally unsupported | ⏭ Skipped |
| 5 | `ReportMessageView.swift` | VoiceOver announcement + extended dismiss delay (3s) when VoiceOver on | ✅ Fixed |

### Medium Priority

| # | File | Issue | Status |
|---|------|-------|--------|
| 6 | `CountryListView.swift` | Section headers missing `.accessibilityAddTraits(.isHeader)` | ✅ Fixed |
| 7 | `FilterListView.swift` | Menu button label — "More options" is generic, non-issue | ⏭ Non-issue |
| 8 | `WhatsNewView.swift` | Actionable button missing `.accessibilityElement(children: .combine)` | ✅ Fixed |

### Code Style

| # | File | Issue | Status |
|---|------|-------|--------|
| 9 | `ReportMessageView.swift` | File header said `TestFiltersView.swift` | ✅ Fixed |
| 10 | `EnableExtensionStepView.swift` | Fixed `.frame(height: 40)` — intentional for visual alignment | ⏭ Skipped |
| 11 | `ReportingConfirmationView.swift` | Footer/list overlap — list scrolls, non-issue | ⏭ Non-issue |

---

## 5. TESTS

### Bugs

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | `mock_AutomaticFilterManager.swift` | `rules` and `activeAutomaticFiltersTitle` setters incremented wrong counter | ✅ Fixed |
| 2 | `TestApplication.swift` | `assertLabel(of:contains:)` ignored `testIdentifier` param | ✅ Fixed |

### Missing Coverage

| # | Area | Gap | Status |
|---|------|-----|--------|
| 1 | Reporting Extension | `ReportMessageView.ViewModel` state transitions and service call | ✅ Added (`ReportMessageViewTests.swift`) |
| 2 | EnableExtensionView | No UI test or snapshot | ⏭ Not addressed |
| 3 | Country Allowlist | Empty countries list + disabled rule both skip the rule | ✅ Added (2 tests in `MessageEvaluationManagerTests`) |
| 4 | `MessageEvaluationManagerTests` | Shadowed `MessageTestCase` struct | ✅ Fixed |

---

## 6. MISC

| # | Area | Issue | Status |
|---|------|-------|--------|
| 1 | `@ObservedObject` vs `@StateObject` | Intentional split — `@StateObject` used on sheet/re-render-prone screens to fix ViewModel recreation bug. Documented in CLAUDE.md. | ✅ Documented |
| 2 | `isActionnable` typo | Renamed to `isActionable` + `onActionableEntryTapped` across all source files and docs | ✅ Fixed |
| 3 | Old `EnableExtensionVideoView` | Fully removed — clean replacement | ✅ No action needed |
| 4 | `ShieldGlintIcon` | Well-isolated animation, proper cleanup | ✅ No action needed |
