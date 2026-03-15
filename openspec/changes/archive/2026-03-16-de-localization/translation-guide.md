# Translation Guide — German (de)

**Language:** German
**BCP-47 code:** `de`
**Writing direction:** LTR
**Grammatical gender:** Yes (3 genders: masculine, feminine, neuter)

---

## 4a. Grammar & Gender Strategy

### Grammatical Gender

German assigns gender to all nouns. Key app nouns:

| Noun | German | Gender | Article |
|---|---|---|---|
| Filter | Filter | masculine | der Filter |
| Message/SMS | Nachricht | feminine | die Nachricht |
| Folder | Ordner | masculine | der Ordner |
| Sender | Absender | masculine | der Absender |
| Language | Sprache | feminine | die Sprache |
| Update | Aktualisierung | feminine | die Aktualisierung |
| App | App | feminine | die App |
| Extension | Erweiterung | feminine | die Erweiterung |
| List | Liste | feminine | die Liste |

Adjectives and past participles must agree with the gender and case of the noun they modify. In UI labels without articles (headings, buttons), uninflected forms are acceptable.

### Addressing the User

**Strategy: Informal singular (du)**

German mobile apps overwhelmingly use the informal "du" (you). Using "Sie" (formal) would feel corporate and out of place for a small indie utility app. All second-person references use du/dein.

### Imperative Verbs

German imperatives (du-form) for buttons: drop the final "-st" of the present tense (e.g., "du tippst" → "Tippe" or informally "Tipp"). Imperatives carry no gender inflection. Capitalize as sentence-start (all nouns capitalized in German — standard rule).

### RTL

Not applicable — German is LTR.

---

## 4b. Canonical Term Groups

| Concept | Canonical Term | Notes |
|---|---|---|
| Block / Deny (verb) | **Blockieren** | Past participle: "Blockiert"; adjective label: "Blockierte" |
| Allow / Permit (verb) | **Erlauben** | Past participle/adjective: "Erlaubte" |
| Filter / Filters (noun) | **Filter** | Same word in German, plural is also "Filter" (no -s) |
| Sender | **Absender** | Masculine: der Absender |
| Message (SMS) | **Nachricht** | Feminine: die Nachricht |
| Body (message body) | **Inhalt** | Short, fits buttons well |
| Language / Languages | **Sprache / Sprachen** | Feminine: die Sprache |
| Update (verb) | **Aktualisieren** | Past: "Aktualisiert am %@" |
| Junk (folder name) | **Junk** | Apple uses "Junk" in German iOS Messages — must match |
| Double tap (a11y hint) | **Doppeltippen** | E.g. "Doppeltippen, um …" |
| Close | **Schließen** | Distinct from Cancel |
| Cancel | **Abbrechen** | Distinct from Close |
| Settings (iOS) | **Einstellungen** | Official German iOS term |
| On / Off (toggle) | **AN / AUS** | Standard German toggle convention |

---

## 4c. iOS System Term Matching — MANDATORY

| App string | iOS feature | German term |
|---|---|---|
| `addFilter_folder_junk` | iOS Messages "Junk" folder | **Junk** (Apple uses "Junk" in German iOS) |
| `addFilter_folder_transactions` | iOS Messages "Transactions" folder | **Transaktionen** |
| `addFilter_folder_promotions` | iOS Messages "Promotions" folder | **Werbung** (Apple uses "Werbung" in German iOS) |
| `enableExtension_ready_callToAction` | iOS Settings app | **Einstellungen** |
| `autoFilter_ON` / `autoFilter_OFF` | Toggle labels | **AN / AUS** |

---

## 4d. Strings to Keep Untranslated

- `aboutView_twitter` = `"a_bd"` — social handle
- `aboutView_github` = `"GitHub"` — brand name
- `aboutView_appIconCredit` = `"Vitali Levit"` — proper name
- "Adi Ben-Dahan" in `aboutView_aboutText` — developer name
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- Brand names: Simply Filter SMS, iCloud, iOS, AppStore, VoiceOver, Dynamic Type
- All emoji — keep exactly as in English source

---

## 4e. Length Constraint

Target: within ~20% of shorter(English, Hebrew) character count. Exception: iOS system terms.

Tight keys (≤ specified limit):

| Key | English | Limit | German |
|---|---|---|---|
| `general_allow` | "Allow" (5) | ≤8 | "Erlaubt" (7) ✓ |
| `general_deny` | "Deny" (4) | ≤8 | "Sperren" (7) ✓ |
| `general_close` | "Close" (5) | ≤8 | "Schließen" (9) ⚠ |
| `general_edit` | "Edit" (4) | ≤7 | "Bearbeiten" (10) ⚠ |
| `autoFilter_ON` | "ON" (2) | ≤10 | "AN" (2) ✓ |
| `autoFilter_OFF` | "OFF" (3) | ≤12 | "AUS" (3) ✓ |
| `addFilter_add` | "Add" (3) | ≤8 | "Hinzufügen" (11) ⚠ — use "Hinzuf." or keep full (common in iOS) |
| `addFilter_match_exact` | "Exact" (5) | ≤10 | "Genau" (5) ✓ |
| `addFilter_match_contains` | "Contains" (8) | ≤12 | "Enthält" (7) ✓ |
| `addFilter_target_sender` | "Sender" (6) | ≤10 | "Absender" (8) ✓ |
| `addFilter_target_body` | "Body" (4) | ≤10 | "Inhalt" (6) ✓ |
| `whatsNew_continue` | "Continue" (8) | ≤12 | "Weiter" (6) ✓ |

Note: "Schließen", "Bearbeiten", "Hinzufügen" are standard iOS German button labels and widely accepted at their length. They match what Apple uses natively.

---

## 4f. Tone & Register

- Informal (du-form), not corporate
- Concise — prefer short synonyms where they exist
- Consistent with iOS app conventions for German
