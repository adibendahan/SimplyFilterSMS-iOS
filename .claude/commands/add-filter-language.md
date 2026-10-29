---
name: "Add Filter Language"
description: Add a new AI Filtering language — generates locale-appropriate spam keywords and allow-lists, lets you review, then writes ai/<lang>.sfsfilters and adds it to ai/catalog.json
category: Localization
tags: [localization, filters, spam]
---

Add a new AI Filtering list: `ai/<code>.sfsfilters`, listed in `ai/catalog.json` (both at the repo root, gitignored). `3.0.0/automatic_filters.json` is frozen for apps 3.0–3.2: **never edit or upload it.**

**Input**: The argument after `/add-filter-language` is the BCP-47 language code (e.g. `fr`, `de`, `pt`), OR a language name. If omitted, ask.

---

## Step 1 — Identify the target language

If no language was specified, use **AskUserQuestion** to ask:
> "Which language do you want to add? Provide the language name or BCP-47 code (e.g. 'fr' for French, 'de' for German, 'pt' for Portuguese)."

Confirm: language name, BCP-47 code, and the primary country/region this list targets (a language may be spoken in multiple countries with different spam landscapes — e.g. Portuguese → Brazil vs Portugal).

**Important:** The catalog `language` must be a valid `NLLanguage` raw value (e.g. `pt`, not `pt-BR`). If the user provides a regional variant like `pt-BR`, map it to the base language code that `NLLanguage` recognises.

---

## Step 2 — Load the catalog

Read `ai/catalog.json`. If it's missing, fetch it from:
```
https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/3.3.0/ai/catalog.json
```

Verify no entry already has `"language": "<code>"` and `ai/<code>.sfsfilters` doesn't exist. If either does, inform the user and stop.

---

## Step 3 — Research and generate the filter lists

Before writing anything, reason carefully about the target language and region. The goal is a list that is **comprehensive but precise** — catching real spam without blocking legitimate messages.

> **Search budget:** Use your built-in knowledge first. You may perform **at most 2-3 web/agent searches** for genuinely unknown facts (e.g. an obscure local sender ID, a current politician's name, a rare iOS system term). If you believe more than 2-3 searches are needed, **ask the user for permission before searching**. Never launch a broad research agent just to be thorough — it wastes the session token budget.

### Key principles (learned from the `en` and `he` lists — always use `ai/en.sfsfilters` and `ai/he.sfsfilters` as your reference examples when researching format and scope)

**Phrase clusters, not bare words.** A single word like "free" or "gratis" will match legitimate messages. Instead generate clusters of 4–8 variations per concept:
- "Free" → "Free gift", "Free trial", "Free offer", "Free access", "100% free", "Completely free", "For free", "At no cost"

**Every locale has unique dominant spam categories.** Don't just translate the English list. Research what actually floods SMS inboxes in the target country. Examples from Hebrew: political party names + cannabis slang account for ~40% of the list. Identify the equivalent for the new locale before generating.

**Include English loanwords.** "free", "win", "VIP", "casino", "XXX", "bonus" appear verbatim in spam across many languages — always include them alongside native-language terms.

**Generate spelling and slang variants.** For any term where alternate spellings or slang are common (as in Hebrew: קנאביס / קנביס, or גראס / וויד / Weed), include all variants.

---

### 3a. Allowed senders

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

Allowed senders are **short alphanumeric sender IDs** exactly as they appear in the SMS header (typically 3–11 chars). Include known variants of the same sender (e.g. space vs underscore: "La Poste" + "LaPoste"). Do not add full phone numbers.

### 3b. Blocked phrases

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

### 3c. Allowed phrases

Add allowed phrases only specific strings that must **always** pass regardless of blocked phrases — typically a brand name from the allowed senders whose name also appears in spam keywords. If none are obvious, add none.

### 3d. Blocked senders

Add as blocked senders only obvious sender ID patterns used by spammers (e.g. `"xxx"`). Keep this minimal. If none are obvious, add none.

---

## Step 4 — False positive assessment

Before presenting the list for review, audit every blocked phrase for false positive risk. For each entry, ask: **could a legitimate message from an unknown sender contain this string in a non-spam context?**

### High-risk patterns to check

**Single common words.** A bare word like "prêt" (French for both "loan" AND "ready"), "Podemos" (Spanish political party AND "we can"), or "parabéns" (Portuguese congratulations used in birthday texts) will match legitimate everyday messages. Prefer phrases over single words. If a single word is kept, it must be unambiguous in the spam context.

**Extremely common surnames or given names used as politician identifiers.** "Sánchez" is one of the most common surnames in Spanish — it will match any text mentioning a person with that name. Use full names or more distinctive identifiers instead. Keep only names that are distinctive enough to rarely appear outside political spam (e.g. "Netanyahu" is distinctive; "Sánchez" is not).

**Short abbreviations (under 4 characters).** "RN", "PT", "LFI" match as substrings in many unrelated words and common text. Remove them unless they are completely unambiguous in the target language.

**Delivery and logistics phrases.** "Your package is waiting", "Delivery attempted", "Colis en attente" etc. are used verbatim by legitimate carriers. Only keep these if all major carriers for the target locale are already allowed senders. If a carrier is missing from the allowed senders, add it — do not remove the phrase.

**Account/security phrases.** "Verify your account", "Update your details", "Your card has been blocked" are also sent by legitimate banks. These are acceptable as blocked phrases **only if** major banks for the target locale are allowed senders — because legitimate bank messages will be cleared by the sender check before blocked phrases are evaluated.

**Congratulations / celebration words.** Words like "parabéns", "félicitations", "felicitaciones" are used in birthday texts, purchase confirmations, and achievement notifications from any business — not just spam. Use them only as part of a longer spam-specific phrase (e.g. "você ganhou", "vous avez gagné") rather than as a standalone word.

**Religious or culturally significant words with dual use.** Words like "benção" (blessing) can appear in family conversations. From unknown senders the risk is lower, but flag any entry that commonly appears in personal messages.

**Brand names that are also common words.** "Vox" is a political party AND an audio brand. "Free" is a telecom in France AND a spam keyword — handle with an allowed phrase, not by dropping the blocked phrase.

### What to do with flagged entries

For each flagged entry, either:
1. **Replace** with a longer, more specific phrase that preserves the spam signal (preferred)
2. **Remove** if no safe rephrasing exists
3. **Add the relevant sender to the allowed senders** if the false positive risk comes from a known legitimate service

Document the flagged entries and the decision made for each before proceeding to user review.

---

## Step 5 — Present for review

Turn every entry into a record, deciding each one on its own:

- **type:** `allow` / `deny`
- **target:** `sender` / `body` / `all`
- **matching:** `contains` / `exact` (whole word) / `regex`
- **case:** `insensitive` / `sensitive` (omitted for `regex`, which sets its own case with `(?i)`)
- **folder:** `junk` / `promotion` / `transaction` (deny only; omitted for `allow`)

Known trade-offs: whole-word `exact` on body costs recall and breaks scripts without spaces (CJK, Thai) and prefixed languages (Hebrew, Arabic); a sender name needs an exact, case-insensitive match (a regex or `exact`), not `contains`.

Show a review table: text, target, matching, case, folder, and a reason for each non-obvious choice, grouped by cluster (political, finance, adult, …). Also show a short summary: record counts per type, dominant spam categories covered, and any entries flagged and changed during the false positive assessment (Step 4).

Then use **AskUserQuestion** to ask:
> "Here is the proposed filter list for [Language] ([code]). Would you like to:
> A) Accept as-is and write the files
> B) Edit the records before writing
> C) Cancel"

**If B (edit):**
- Ask which records or clusters to change
- Accept additions, removals and setting changes as freeform input
- Show the revised table and confirm before proceeding

---

## Step 6 — Write the list and the catalog

Write `ai/<code>.sfsfilters` with the approved records in `filters`:

```json
{
  "appVersion": "<current app version>",
  "exportedAt": "<now, ISO-8601 UTC, e.g. 2026-10-30T12:00:00Z>",
  "filters": [ ... ],
  "format": "simply-filter-sms-filters",
  "name": "AI Filtering · <English language name>",
  "revision": 1,
  "version": 1
}
```

Never write placeholder fields.

Add the entry to `ai/catalog.json`, keeping `lists` sorted by `id`:

```json
{ "id": "ai-<code>", "name": "<English language name>", "url": "<code>.sfsfilters", "language": "<code>" }
```

Write both files with `json.dump(..., ensure_ascii=False, indent=2, sort_keys=True)`, no trailing newline (catalog: same, without `sort_keys`, keeping the existing key order).

After writing, verify:
1. Both files are valid JSON, and the other list files are unchanged.
2. The record count matches the approved table.
3. The catalog has exactly one entry for `<code>`.

---

## Step 7 — Upload to S3 (optional)

Use **AskUserQuestion** to ask:
> "Upload `ai/<code>.sfsfilters` and `ai/catalog.json` to S3 now?"

If yes, upload the list **before** the catalog, so the catalog never points at a missing file:
```bash
aws s3 cp ai/<code>.sfsfilters s3://grizz-apps-dev/simply-filter-sms/3.3.0/ai/<code>.sfsfilters --content-type application/json
aws s3 cp ai/catalog.json s3://grizz-apps-dev/simply-filter-sms/3.3.0/ai/catalog.json --content-type application/json
```

The bucket is world-readable: never upload anything else. Report success or failure.

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
- Files written: `ai/<code>.sfsfilters`, `ai/catalog.json`
- record counts per type + dominant categories covered
