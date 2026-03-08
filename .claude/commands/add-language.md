---
name: "Add Language"
description: Translate the app to a new language — builds a translation guide, translates all strings, and wires up the Xcode project
category: Localization
tags: [localization, translation, i18n]
---

Translate the Simply Filter SMS app into a new language.

**Input**: The argument after `/add-language` is the BCP-47 language code (e.g. `fr`, `de`, `ar`), OR a language name. If omitted, ask.

---

## Step 1 — Identify the target language

If no language was specified, use **AskUserQuestion** to ask:
> "Which language do you want to add? Provide the language name or BCP-47 code (e.g. 'fr' for French, 'ar' for Arabic)."

Confirm: language name, BCP-47 code, writing direction (LTR or RTL), and whether the language has grammatical gender.

---

## Step 2 — Read source files

Read both existing strings files in full:
- `Simply Filter SMS/Resources/en.lproj/Localizable.strings`
- `Simply Filter SMS/Resources/he.lproj/Localizable.strings`

These are the two references. English is the source of truth for keys and meaning. Hebrew shows how RTL and informal plural-address strategies were applied in practice.

---

## Step 3 — Create the change directory

Create:
```
openspec/changes/<code>-localization/
```

Where `<code>` is the BCP-47 code (e.g. `es-localization`, `fr-localization`).

---

## Step 4 — Build the translation guide

Create `openspec/changes/<code>-localization/translation-guide.md`.

The guide must contain **four sections**:

### 4a. Grammar & Gender Strategy

Analyze the target language's grammar rules and define a clear strategy. Address:

- **Grammatical gender**: Does the language assign gender to nouns? If yes, list the gender of the key app nouns (filter, message, folder, sender, language, update, app, extension, list) and specify how adjectives/participles agree with them.
- **Addressing the user**: Choose one strategy and justify it:
  - *Plural* (like Hebrew): avoids gender ambiguity, used when language has gendered second-person forms
  - *Informal singular tú/tu/du/etc.*: natural for mobile apps in many languages
  - *Formal singular*: only if informal would feel out of place in that language/market
- **Imperative verbs**: State whether imperatives carry gender inflection (most don't) and what form to use for buttons.
- **RTL**: If the language is RTL, note that layout mirroring is handled by iOS automatically — no code changes needed, but punctuation placement in translated strings must follow RTL conventions.

### 4b. Canonical Term Groups

For each concept below, define the **single canonical term** to use across all keys that share that meaning. Do not vary the term within a group.

Mandatory groups to cover:

| Concept | Keys to check |
|---|---|
| Block / Deny (verb + adjective) | `general_deny`, `filterList_denied`, `filterList_deniedLanguage`, `autoFilter_*` block toggles |
| Allow / Permit (verb + adjective) | `general_allow`, `filterList_allowed`, `autoFilter_numbersOnly` |
| Filter / Filters (noun) | `filterList_filters`, `general_active_count`, `autoFilter_smartFilters`, `autoFilter_yourFilters` |
| Sender | `addFilter_target_sender`, `testFilters_senderTitle`, `reportMessage_senderTitle`, `autoFilter_shortSender` |
| Message (SMS) | `testFilters_messageTitle`, `addFilter_target_body` context |
| Body (message body, filter target) | `addFilter_target_body`, `addFilter_target_all` |
| Language / Languages | `lang_*`, `filterList_deniedLanguage`, `addFilter_addLanguage`, `general_lang` |
| Update (verb + past participle) | `autoFilter_forceUpdate`, `autoFilter_lastUpdated`, `notification_sync_subtitle` |
| Junk (folder name) | `addFilter_folder_junk`, `reportMessage_junk` — prefer iOS system term if one exists |
| Double tap (accessibility) | All `a11y_*` hint strings — must be a single consistent phrase |
| Close vs Cancel | `general_close` vs `enableExtension_ready_cancel` — these are distinct concepts |
| Settings (iOS Settings app) | `enableExtension_ready_callToAction` — use the official iOS term in target language |
| On / Off (toggle state) | `autoFilter_ON`, `autoFilter_OFF` |

For each group: state the canonical term, its gender (if applicable), and any inflected forms needed.

### 4c. iOS System Term Matching — MANDATORY

Certain strings in this app refer directly to **iOS system UI elements** (folder names, app names, setting names). These **must use the exact term Apple uses in the target language**, not a freehand translation.

To find the official iOS term: look up how the iOS Settings app, Messages app, or App Store renders that UI element in the target language. When in doubt, set the device to that language and check.

| App string | iOS feature | How to verify |
|---|---|---|
| `addFilter_folder_junk` | iOS Messages "Junk" folder | Open Messages app in target language |
| `addFilter_folder_transactions` | iOS Messages "Transactions" folder | Open Messages app in target language |
| `addFilter_folder_promotions` | iOS Messages "Promotions" folder | Open Messages app in target language |
| `enableExtension_ready_callToAction` | iOS Settings app name | Check home screen / Settings icon label |
| `autoFilter_ON` / `autoFilter_OFF` | Visual convention for toggle labels in iOS | Check iOS Settings toggles and native apps |

**Never shorten or paraphrase an iOS system term**, even if it results in a string longer than 2× English. Length is acceptable when matching an official Apple label — the user must be able to recognise the exact folder/feature name they see in iOS.

### 4d. Strings to Keep Untranslated

Always keep these unchanged regardless of language:
- `aboutView_twitter` — social handle
- `aboutView_github` — brand name
- `aboutView_appIconCredit` — proper name (Vitali Levit)
- Developer name "Adi Ben-Dahan" embedded in `aboutView_aboutText`
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- Brand names: "Simply Filter SMS", "iCloud", "iOS", "AppStore", "VoiceOver", "Dynamic Type"
- All emoji — keep exactly as in English source

### 4e. Length Constraint

**Keep translations as close to the original character count as possible**, measured against the shorter of the English or Hebrew value for the same key.

Short UI strings (buttons, headers, labels) are space-constrained. If a natural translation exceeds the shorter reference by more than ~20%, find a shorter synonym or rephrase.

**Exception:** strings that reference iOS system terms (see §4c) are exempt from the length constraint — correctness takes priority over brevity there.

These keys are the tightest — flag any translation over 12 characters:

| Key | English | Limit |
|---|---|---|
| `general_allow` | "Allow" (5) | ≤8 |
| `general_deny` | "Deny" (4) | ≤8 |
| `general_close` | "Close" (5) | ≤8 |
| `general_edit` | "Edit" (4) | ≤7 |
| `autoFilter_ON` | "ON" (2) | ≤10 |
| `autoFilter_OFF` | "OFF" (3) | ≤12 |
| `addFilter_add` | "Add" (3) | ≤8 |
| `addFilter_match_exact` | "Exact" (5) | ≤10 |
| `addFilter_match_contains` | "Contains" (8) | ≤12 |
| `addFilter_target_sender` | "Sender" (6) | ≤10 |
| `addFilter_target_body` | "Body" (4) | ≤10 |
| `whatsNew_continue` | "Continue" (8) | ≤12 |

### 4e. Tone & Register

Define the tone to match the app's character:
- Friendly and informal (not corporate)
- Concise — prefer shorter synonyms over longer precise ones on buttons and labels
- Consistent with the strategies defined in sections 4a–4d

---

## Step 5 — Decide on plural handling for `general_active_count`

The string `general_active_count` = `"%ld filters"` currently produces **"1 filters"** in English — a known limitation accepted across all existing locales. iOS solves this properly with `.stringsdict` plural rules, but none exist in this project yet.

Before translating, **ask the user** using AskUserQuestion:
> "The string 'X filters' in the app doesn't handle singular ('1 filter') in any language yet. Do you want to add proper plural support for this language using a `.stringsdict` file, or keep the same approach as English/Hebrew (always use the plural form)?"

**If yes (add `.stringsdict`):**
- Create `Simply Filter SMS/Resources/<code>.lproj/Localizable.stringsdict`
- Use the CLDR plural categories for the target language (e.g. Spanish has `one` and `other`; Arabic has six categories: `zero`, `one`, `two`, `few`, `many`, `other`)
- Format:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
      <key>general_active_count</key>
      <dict>
          <key>NSStringLocalizedFormatKey</key>
          <string>%#@filters@</string>
          <key>filters</key>
          <dict>
              <key>NSStringFormatSpecTypeKey</key>
              <string>NSStringPluralRuleType</string>
              <key>NSStringFormatValueTypeKey</key>
              <string>ld</string>
              <key>one</key>
              <string>1 filtro</string>
              <key>other</key>
              <string>%ld filtros</string>
          </dict>
      </dict>
  </dict>
  </plist>
  ```
- Also register `<code>.lproj/Localizable.stringsdict` in `project.pbxproj` (same process as the `.strings` file)
- In the `.strings` file, the `general_active_count` key can be omitted or kept as a fallback
- **IMPORTANT — call site:** `.stringsdict` plural rules are only applied by `String.localizedStringWithFormat()`, NOT by `String(format:)`. Verify that `AppHomeView.swift` uses `String.localizedStringWithFormat("general_active_count"~, count)`. If it uses `String(format:)`, the stringsdict is silently ignored and the `.strings` fallback (always plural) is used instead.

**If no:** translate `general_active_count` using the plural form (e.g. `"%ld filtros"`) and note the limitation.

---

## Step 6 — Translate all strings

Create `Simply Filter SMS/Resources/<code>.lproj/Localizable.strings`.

**Format rules:**
- Use the same blank-line-separated format as `he.lproj`: one `"key" = "value";` per block, blank line between each
- Preserve all format specifiers exactly: `%ld`, `%@`, `%1$@` etc.
- Preserve `**bold**` markdown in long-form strings (used for bold rendering in SwiftUI)
- Preserve `\n` newlines in multi-line strings
- Apply the translation guide strictly — canonical terms, length constraints, grammar strategy

Translate every key from `en.lproj`. Do not skip any key.

After writing the file, verify key count matches English by counting `=` occurrences in both files.

---

## Step 6b — Review strings longer than 2× English

After writing the strings file, compute every string where `len(translation) / len(english_source) > 2.0` (ignoring format specifiers like `%ld` and `%@` in the ratio).

For each flagged string:
1. Show the key, the English source (with char count), the current translation (with char count), and the ratio
2. Generate **2–3 genuinely shorter alternatives** using your knowledge of the target language — idioms, abbreviations, borrowings from English that are widely understood (e.g. "ON/OFF", "Spam"), or single-word synonyms
3. For each alternative, show its char count and a brief note on trade-offs (clarity, naturalness, register)

**Present all flagged strings at once** in a table like this:

```
Key: autoFilter_ON
  EN: "ON" (2)  →  Current: "ACTIVADO" (8)  [4.0×]
  Option A: "ON" (2) — English borrowed term, universally understood on iOS
  Option B: "SÍ" (2) — natural but changes meaning (Yes vs On)
  Option C: "ACT." (4) — abbreviated, less natural

Key: tipJar_title
  EN: "Tip Jar" (7)  →  Current: "Bote de propinas" (16)  [2.3×]
  Option A: "Propinas" (8) — drops "bote de", still clear and concise
  Option B: "Donativos" (9) — slightly different nuance (donation vs tip)
```

Then use **AskUserQuestion** to ask:
> "I found N strings that are more than 2× longer than English. Review the options above — which approach do you prefer?"

Options:
- "Apply all suggested (Option A for each)" — use the first/shortest alternative for every flagged string
- "Review one by one" — ask per-string (use one AskUserQuestion per string, up to 4 at a time)
- "Keep originals" — accept the longer translations as-is

**If "Apply all suggested":** update every flagged string in the `.strings` file with Option A.

**If "Review one by one":** batch the flagged strings into groups of 4, ask AskUserQuestion for each batch (one question per string, up to 4 per call), then apply chosen values.

**If "Keep originals":** no changes, proceed.

After any edits, re-verify key count matches English.

---

## Step 7 — Register the locale in Xcode

Edit `Simply Filter SMS.xcodeproj/project.pbxproj` to add the new locale:

1. Find the `knownRegions` array and add `"<code>"` to it (keep alphabetical order)
2. Find the `PBXVariantGroup` for `Localizable.strings` and add a new child `PBXFileReference` entry for `<code>.lproj/Localizable.strings`, following the exact format of the existing `he` entry

**Important**: The `.pbxproj` format is whitespace-sensitive. Copy the exact formatting of the Hebrew entry as a template.

---

## Step 8 — Verify key parity

Do a final key-parity check:
- Read `en.lproj/Localizable.strings` and list all keys
- Read the new `<code>.lproj/Localizable.strings` and list all keys
- Report any missing or extra keys

If all keys are present: confirm and move to the next step.

---

## Step 9 — Update snapshot tests

### 9a. SnapshotsTestCase.swift

Edit `UI Tests/SnapshotsTestCase.swift`. The `addFilter` section uses a `switch langCode` to pick locale-appropriate spam sample text. Add a `case` for the new language:

```swift
case "<langCode>":
    addFilterText = "<sample spam word in that language>"
    addFilterScreenshot = "05.addFilter"
```

Use a realistic short word that would appear in SMS spam in that locale (e.g. a word for "loan", "promo", "credit", or "win"). `langCode` comes from `Locale.current.languageCode` — use the language portion only (e.g. `"pt"` for `pt-BR`, `"fr"` for `fr`, `"ar"` for `ar`).

### 9b. Fastfile

Edit `fastlane/Fastfile`. Both the `iphone_screenshots` and `ipad_screenshots` lanes have a `languages:` array. Add the BCP-47 code exactly as passed to this skill (e.g. `"fr"`, `"ar"`, `"pt-BR"`) to both lanes.

---

## Step 10 — Layout stress test instructions

Provide the user with a ready-to-use Xcode scheme launch argument for testing:

```
-AppleLanguages (<code>)
```

Add this to the scheme's **Run > Arguments Passed On Launch** in Xcode. It forces the app into the target locale without changing the device language.

Also flag any translated strings that are noticeably longer than their English source (>30% longer), since these are candidates for layout truncation or wrapping — especially at larger Dynamic Type sizes. List them explicitly so the user knows what to visually verify.

For RTL languages (Arabic, Persian, Hebrew — though Hebrew already exists): confirm that all strings use natural sentence direction and that any embedded LTR content (URLs, numbers, brand names) is correctly wrapped with Unicode directional markers if needed.

---

## Step 11 — App Store metadata reminder

Remind the user that the in-app translation is now complete, but the **App Store listing** is managed separately in **App Store Connect** and is not touched by this change. To fully support the new language on the App Store, the following need to be localized there:

- App name
- Subtitle
- Description
- Keywords
- "What's New" release notes
- Screenshots (if they contain UI text)

These are edited at [appstoreconnect.apple.com](https://appstoreconnect.apple.com) under the app's page → select the language.

---

## Output

At the end, report:
- Language added and locale code
- Translation guide location: `openspec/changes/<code>-localization/translation-guide.md`
- Strings file: `Simply Filter SMS/Resources/<code>.lproj/Localizable.strings`
- Plural `.stringsdict`: created or skipped (with reason)
- Key count (must match English)
- Xcode project updated: yes/no
- Strings that exceeded the length constraint (flagged for layout review)
- Test launch argument: `-AppleLanguages (<code>)`
- App Store metadata: reminder that it needs separate action in App Store Connect
