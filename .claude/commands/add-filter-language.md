---
name: "Add Filter Language"
description: Add a new language to the automatic_filters.json — generates locale-appropriate spam keywords and allow-lists, lets you review, then writes the updated JSON file
category: Localization
tags: [localization, filters, spam]
---

Add a new language entry to the automatic filters JSON.

**Input**: The argument after `/add-filter-language` is the BCP-47 language code (e.g. `fr`, `de`, `pt`), OR a language name. If omitted, ask.

---

## Step 1 — Identify the target language

If no language was specified, use **AskUserQuestion** to ask:
> "Which language do you want to add? Provide the language name or BCP-47 code (e.g. 'fr' for French, 'de' for German, 'pt' for Portuguese)."

Confirm: language name, BCP-47 code, and the primary country/region this list targets (a language may be spoken in multiple countries with different spam landscapes — e.g. Portuguese → Brazil vs Portugal).

**Important:** The JSON key must be a valid `NLLanguage` raw value (e.g. `pt`, not `pt-BR`). If the user provides a regional variant like `pt-BR`, map it to the base language code that `NLLanguage` recognises.

---

## Step 2 — Load the current JSON

Check if `automatic_filters.json` exists at the project root (`/Users/adi/Developer/SimplyFilterSMS-iOS/automatic_filters.json`).

**If the file exists**, use **AskUserQuestion** to ask:
> "Found a local `automatic_filters.json`. Use the existing file, or fetch a fresh copy from S3 (overwrites the local file)?"

- If the user chooses to use the existing file, read it directly.
- If the user chooses to fetch fresh, fetch from:
  ```
  https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/3.0.0/automatic_filters.json
  ```
  Then overwrite the local file with the fetched content before proceeding.

**If the file does not exist**, fetch from S3 and write it to the project root.

Parse the JSON and verify the target language code is **not already present** in `filter_lists`. If it is, inform the user and stop.

---

## Step 3 — Research and generate the filter lists

Before writing anything, reason carefully about the target language and region. The goal is a list that is **comprehensive but precise** — catching real spam without blocking legitimate messages.

### Key principles (learned from the `en` and `he` lists — always use these two as your reference examples when researching format and scope)

**Phrase clusters, not bare words.** A single word like "free" or "gratis" will match legitimate messages. Instead generate clusters of 4–8 variations per concept:
- "Free" → "Free gift", "Free trial", "Free offer", "Free access", "100% free", "Completely free", "For free", "At no cost"

**Every locale has unique dominant spam categories.** Don't just translate the English list. Research what actually floods SMS inboxes in the target country. Examples from Hebrew: political party names + cannabis slang account for ~40% of the list. Identify the equivalent for the new locale before generating.

**Include English loanwords.** "free", "win", "VIP", "casino", "XXX", "bonus" appear verbatim in spam across many languages — always include them alongside native-language terms.

**Generate spelling and slang variants.** For any term where alternate spellings or slang are common (as in Hebrew: קנאביס / קנביס, or גראס / וויד / Weed), include all variants.

---

### 3a. allow_sender

Identify well-known legitimate services that send SMS in the primary country. The size of this list depends on how that country's SMS ecosystem works — if businesses use alphanumeric sender IDs (most countries outside the US), the list needs to be **comprehensive**. If SMS mostly arrives from numeric phone numbers, this list is less useful.

Cover these categories systematically:
- National postal and delivery services
- Major banks and payment apps
- Health insurance and public health services
- Telecom operators
- Government and tax authority services
- Major retailers and e-commerce
- Food delivery and ride-sharing apps
- Utility companies (electricity, gas, water)

`allow_sender` values are **short alphanumeric sender IDs** exactly as they appear in the SMS header (typically 3–11 chars). Include known variants of the same sender (e.g. space vs underscore: "La Poste" + "LaPoste"). Do not add full phone numbers.

### 3b. deny_body

Generate a comprehensive list covering **all of the following categories**. For each category, produce phrase clusters (multiple variations per concept) in the target language, plus English loanwords where applicable.

**Universal spam categories** (adapt phrasing to the target language):
- Financial: loans, mortgages, debt relief, credit offers, fast cash, investment, earn from home, guaranteed income, double your money
- Prize / lottery: win, winner, prize, congratulations, you've been selected, gift, shopping voucher
- Free offers: free gift, free trial, free access, free consultation, no cost, at no cost, completely free, 100% free
- Urgency: act now, limited time, expires, hurry, last chance, don't miss, offer ends
- Work from home: work from home, earn per week, be your own boss, passive income, financial freedom
- Health / pharma: weight loss, miracle cure, pharmacy, Viagra (and local equivalents), no prescription, slimming
- Adult content: XXX, discreet, meet singles, adult (and local-language equivalents)
- MLM / pyramid: multi-level marketing, downline, referral income
- Click bait: click here, click now, visit our website, tap here, follow the link
- Fake disclaimers: "not spam", "no spam" in the target language — spammers often add these
- Counterfeit / luxury goods: Rolex, name brand (if relevant to the region)

**Locale-specific dominant categories** — research and generate thoroughly:
- Political spam: **always include this category for every language.** Political SMS spam is universal. Include: major political party names, prominent politician names (full name + common nickname/surname alone), election-related words (election, vote, campaign, donate, rally, protest), and coalition/movement names. Use the target country's current political landscape.
- Religious solicitation: if donation-request texts are common in this locale, include relevant terms (blessing, commandment, charity, tithe, etc. in the target language)
- Drug-related: if cannabis or other drug SMS spam is common, include native terms + slang + English loanwords
- Country-specific scam types: e.g. fake utility bills (EDF for France), fake courier notices (Chronopost, DHL local), fake government alerts (HMRC for UK, Serasa/CPF for Brazil), Gewinnspiel for Germany
- Any other category that is notably prevalent in that country's SMS spam landscape

### 3c. allow_body

Add to `allow_body` only specific strings that must **always** pass regardless of deny_body matches — typically a brand name from allow_sender whose name also appears in spam keywords. If none are obvious, use an empty array.

### 3d. deny_sender

Add to `deny_sender` obvious sender ID patterns used by spammers (e.g. `"xxx"`). Keep this minimal. If none are obvious, use an empty array.

---

## Step 4 — False positive assessment

Before presenting the list for review, audit every entry in `deny_body` for false positive risk. For each entry, ask: **could a legitimate message from an unknown sender contain this string in a non-spam context?**

### High-risk patterns to check

**Single common words.** A bare word like "prêt" (French for both "loan" AND "ready"), "Podemos" (Spanish political party AND "we can"), or "parabéns" (Portuguese congratulations used in birthday texts) will match legitimate everyday messages. Prefer phrases over single words. If a single word is kept, it must be unambiguous in the spam context.

**Extremely common surnames or given names used as politician identifiers.** "Sánchez" is one of the most common surnames in Spanish — it will match any text mentioning a person with that name. Use full names or more distinctive identifiers instead. Keep only names that are distinctive enough to rarely appear outside political spam (e.g. "Netanyahu" is distinctive; "Sánchez" is not).

**Short abbreviations (under 4 characters).** "RN", "PT", "LFI" match as substrings in many unrelated words and common text. Remove them unless they are completely unambiguous in the target language.

**Delivery and logistics phrases.** "Your package is waiting", "Delivery attempted", "Colis en attente" etc. are used verbatim by legitimate carriers. Only keep these if all major carriers for the target locale are already in `allow_sender`. If a carrier is missing from `allow_sender`, add it — do not remove the phrase.

**Account/security phrases.** "Verify your account", "Update your details", "Your card has been blocked" are also sent by legitimate banks. These are acceptable in deny_body **only if** major banks for the target locale are in `allow_sender` — because legitimate bank messages will be cleared by the sender check before deny_body is evaluated.

**Congratulations / celebration words.** Words like "parabéns", "félicitations", "felicitaciones" are used in birthday texts, purchase confirmations, and achievement notifications from any business — not just spam. Use them only as part of a longer spam-specific phrase (e.g. "você ganhou", "vous avez gagné") rather than as a standalone word.

**Religious or culturally significant words with dual use.** Words like "benção" (blessing) can appear in family conversations. From unknown senders the risk is lower, but flag any entry that commonly appears in personal messages.

**Brand names that are also common words.** "Vox" is a political party AND an audio brand. "Free" is a telecom in France AND a spam keyword — handle via `allow_body`, not by removing from `deny_body`.

### What to do with flagged entries

For each flagged entry, either:
1. **Replace** with a longer, more specific phrase that preserves the spam signal (preferred)
2. **Remove** if no safe rephrasing exists
3. **Add the relevant sender to `allow_sender`** if the false positive risk comes from a known legitimate service

Document the flagged entries and the decision made for each before proceeding to user review.

---

## Step 5 — Present for review

Show the user the full proposed entry in JSON format:

```json
"<code>": {
  "allow_sender": [ ... ],
  "allow_body": [ ... ],
  "deny_sender": [ ... ],
  "deny_body": [ ... ]
}
```

Also show a short summary: allow_sender count, deny_body count, dominant spam categories covered, and any entries that were flagged and modified during the false positive assessment (Step 4).

Then use **AskUserQuestion** to ask:
> "Here is the proposed filter entry for [Language] ([code]). Would you like to:
> A) Accept as-is and write the updated JSON
> B) Edit the lists before writing
> C) Cancel"

**If B (edit):**
- Ask which section(s) to modify
- Accept additions or removals as freeform input
- Show the revised entry and confirm before proceeding

---

## Step 6 — Write the updated JSON

Merge the new language entry into the loaded JSON under `filter_lists.<code>`.

Write the complete updated JSON to:
```
automatic_filters.json
```
at the root of the project (`/Users/adi/Developer/SimplyFilterSMS-iOS/automatic_filters.json`).

Formatting rules:
- 2-space indentation
- Arrays with one item per line (same style as the existing file)
- Keys in the same order as existing entries: `allow_sender`, `allow_body`, `deny_sender`, `deny_body`
- Valid JSON — no trailing commas, balanced braces

After writing, verify:
1. All existing language entries are unchanged (spot-check `en` and `he`)
2. The new entry is present under the correct key
3. The file is valid JSON

---

## Step 7 — Upload to S3 (optional)

Use **AskUserQuestion** to ask:
> "Upload `automatic_filters.json` to S3 now?"

If yes, run:
```bash
aws s3 cp /Users/adi/Developer/SimplyFilterSMS-iOS/automatic_filters.json s3://grizz-apps-dev/simply-filter-sms/3.0.0/automatic_filters.json --content-type application/json
```

Report success or failure.

---

## Step 8 — Update Fastfile

Add the new language's locale code to the `languages` array in **both** the `iphone_screenshots` and `ipad_screenshots` lanes in `fastlane/Fastfile`.

**`en-US` must always be last** — this ensures the simulator is left in English after a screenshot run, preventing locale bleed into subsequent test runs.

Example: adding German (`de`) → append `"de"` before `"en-US"`:
```ruby
languages: ["he-IL", "ar", "es", "pt-BR", "fr", "de", "en-US"],
```

---

## Output

Report:
- Language added: name + NLLanguage key + primary target country
- File written: `automatic_filters.json` at project root
- allow_sender count
- deny_body count + dominant categories covered
