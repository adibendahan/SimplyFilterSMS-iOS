---
name: "Add Localized Text"
description: Add one or more new localized strings to the app — proposes keys and English values, runs BartyCrouch, then translates into all supported languages
category: Localization
tags: [localization, translation, i18n]
---

Use this skill every time you need to add new user-facing text to the app.

**Input**: A description of the string(s) needed, or context from the feature being built. If unclear, use AskUserQuestion to ask.

---

## Step 1 — Propose keys and English values

Based on the context, propose one or more key/value pairs following the app's naming conventions:

- Keys use `camelCase` with a screen or domain prefix (e.g. `autoFilter_`, `general_`, `addFilter_`, `lang_`, `notification_`, `a11y_`)
- English values must:
  - Match the tone of surrounding strings (friendly, concise, informal)
  - **Never use an em dash (—). Always use a hyphen-minus (-) instead.**
  - Keep UI strings (buttons, labels, titles) as short as possible
  - Preserve `%ld`, `%@`, `%1$@` format specifiers if needed
  - Use `**bold**` markdown only for long-form explanatory strings rendered in SwiftUI

Present the proposed keys and values to the user and wait for approval. Allow the user to adjust wording, rename keys, or add/remove entries before proceeding.

---

## Step 2 — Add to English strings file

Once approved, add each key/value pair to `Simply Filter SMS/Resources/en.lproj/Localizable.strings`:

- Follow the existing blank-line-separated format: one `"key" = "value";` per block, blank line between each
- Insert near related keys (same screen/domain prefix), not at the end

---

## Step 3 — Run BartyCrouch

Run:
```bash
bartycrouch update
```

BartyCrouch will add each new key as `= ""` to all existing language files. Do not manually edit any other language file before this step.

---

## Step 4 — Identify supported languages

Read the Resources directory to find all existing `.lproj` folders (excluding `en.lproj` and `Base.lproj`). These are the languages to translate into.

Current supported languages (verify against actual folders):
`he`, `ar`, `es`, `fr`, `pt-BR`, `de`

---

## Step 5 — Translate into all supported languages

For each language, translate every new key. Fill in the empty `""` values that BartyCrouch added.

**Rules that apply to every translation:**

- **Never use an em dash (—). Always use a hyphen-minus (-) instead.**
- Preserve all format specifiers exactly: `%ld`, `%@`, `%1$@` etc.
- Preserve `**bold**` markdown in long-form strings
- Preserve `\n` newlines
- Match the tone and register of existing strings in that language file
- Keep translations as close to the English character count as possible — especially for buttons, labels, and titles

### iOS System Term Rule — MANDATORY

If any string refers to an iOS system UI element (folder names, app names, Settings labels, Messages app UI), you **must use the exact term Apple uses in that language**. Never freehand-translate an iOS system term.

| App string context | iOS feature | How to verify |
|---|---|---|
| Junk folder | iOS Messages "Junk" folder | Messages app in target language |
| Transactions folder | iOS Messages "Transactions" folder | Messages app in target language |
| Promotions folder | iOS Messages "Promotions" folder | Messages app in target language |
| Settings app | iOS Settings app name | Home screen / Settings icon |
| Any other iOS UI element | Varies | Set device to target language and check |

### Untranslated items — keep exactly as English

- Brand names: "Simply Filter SMS", "iCloud", "iOS", "App Store", "VoiceOver", "Dynamic Type"
- Social handles: `@grizz_dev` etc.
- Proper names: "Adi Ben-Dahan", "Vitali Levit"
- All emoji — keep exactly as in English source
- Phone calling codes: +1, +972, etc.

---

## Step 6 — Length constraint review

After translating all languages, flag any string where `len(translation) / len(english_source) > 2.0` (ignoring format specifiers in the ratio).

For each flagged string:
1. Show: key, English source (char count), translation (char count), ratio, language
2. Generate 2-3 shorter alternatives using idioms, abbreviations, or borrowings
3. For each alternative: char count + brief trade-off note

Present all flagged strings at once, then use **AskUserQuestion**:
> "I found N strings that are more than 2× longer than English. Review the options above — which approach do you prefer?"

Options:
- "Apply all suggested" — use the first/shortest alternative for every flagged string
- "Review one by one" — ask per string (batch up to 4 per AskUserQuestion)
- "Keep originals" — accept as-is

Apply chosen values. Also scan all translations for any em dash (—) and replace with hyphen-minus (-).

---

## Step 7 — Verify

Confirm that every new key now has a non-empty translation in every language file. Report any that are still empty.

---

## Output

Report:
- Keys added to English: list them
- Languages updated: list them
- Any strings flagged for length review and what was chosen
- Any iOS system terms used (and what was verified)
