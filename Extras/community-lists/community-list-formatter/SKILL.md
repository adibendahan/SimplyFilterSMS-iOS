---
name: community-list-formatter
description: Format filters someone already has (a pasted list, a CSV, a spreadsheet column, rules from another app, regexes) into a Simply Filter SMS Community List file (.sfsfilters). Use when the user wants to turn their own filters into a Simply Filter SMS list. It only formats what the user provides; it never adds, removes or invents filters.
---

# Community List formatter

Turn the user's own filters into a valid Simply Filter SMS Community List: a `.sfsfilters` JSON file they can host and share.

**You format; you don't author.** Every filter in the output comes from the user's input. Never add filters, never drop one silently, never "improve" the wording. If an entry can't be formatted, list it back to the user with the reason.

## 1. Collect the five required fields

A list missing any of these can't be subscribed to. Ask for whatever the input doesn't already state. Never invent a value.

| Field | Rule |
|---|---|
| `name` | The list's title. Short. |
| `description` | One sentence saying what the list does. |
| `author` | The person or project that maintains the list. |
| `homepage` | An `https://` URL for the list's site or repository. |
| `locale` | Language and country of the messages it targets: a lowercase ISO 639 language code, a hyphen, an uppercase ISO 3166 region code (`en-US`, `he-IL`, `pt-BR`). |

## 2. Turn each entry into a filter record

Each record has these fields:

| Field | Values | Default when the input doesn't say |
|---|---|---|
| `text` | The text or pattern to match. Keep it exactly as given. | (required) |
| `type` | `deny` (block) or `allow` | `deny` |
| `target` | `all`, `sender` or `body` | `all` |
| `matching` | `contains`, `exact` or `regex` | `contains` |
| `case` | `insensitive` or `sensitive` | `insensitive` |
| `folder` | `junk`, `transaction` or `promotion` | `junk` |

Two rules the app enforces:
- **Regex records omit `case`.** Put case-insensitivity inside the pattern with `(?i)` if the user wants it.
- **Allow records omit `folder`.** Allowed messages always go to the inbox.

If the input groups entries (a "block" column and an "allow" column, sections per folder, a sender list and a keyword list), map the groups to `type`, `folder` and `target`. When the mapping isn't clear, ask once for the whole input, not per entry.

Before writing the file:
- Check every regex compiles (ICU / `NSRegularExpression` syntax). Report any that don't instead of guessing a fix.
- Remove exact duplicates (same text, type, target, matching, case and folder) and tell the user how many.
- Leave empty entries out and say so.

## 3. Write the file

```json
{
  "format": "simply-filter-sms-filters",
  "version": 2,
  "exportedAt": "<now, ISO 8601 UTC, e.g. 2026-11-13T12:00:00Z>",
  "appVersion": "4.0.0",
  "name": "Scam Guard",
  "description": "Blocks loan and prize scams in English.",
  "author": "Jane Doe",
  "homepage": "https://github.com/you/scam-guard",
  "locale": "en-US",
  "filters": [
    { "text": "loan approved", "type": "deny", "target": "body", "matching": "contains", "case": "insensitive", "folder": "junk" },
    { "text": "(?i)^win\\s+\\$\\d+", "type": "deny", "target": "body", "matching": "regex", "folder": "promotion" },
    { "text": "MyBank", "type": "allow", "target": "sender", "matching": "exact", "case": "sensitive" }
  ]
}
```

- Save it as `<name-in-kebab-case>.sfsfilters`, UTF-8, pretty-printed with 2-space indentation.
- Never add other fields, placeholders or empty values.

## 4. Hand it over

Give the user the file and a short summary: how many filters, split by block / allow and by folder, plus anything left out and why. Then point them to the next steps in the guide: host the file at a public HTTPS URL that returns the file itself, and share that URL (or submit the list) so people can subscribe from **Community Lists › Subscribe from URL**.
