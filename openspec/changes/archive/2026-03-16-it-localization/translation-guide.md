# Italian (it) Translation Guide

## 4a. Grammar & Gender Strategy

### Grammatical Gender
Italian assigns grammatical gender to all nouns. Key app nouns:

| Noun | Italian | Gender | Notes |
|---|---|---|---|
| filter | filtro | masculine | i filtri (pl) |
| message | messaggio | masculine | i messaggi (pl) |
| folder | cartella | feminine | le cartelle (pl) |
| sender | mittente | masculine | i mittenti (pl) |
| language | lingua | feminine | le lingue (pl) |
| update | aggiornamento | masculine | gli aggiornamenti (pl) |
| app | app | feminine | invariable |
| extension | estensione | feminine | le estensioni (pl) |
| list | lista | feminine | le liste (pl) |

Adjectives and past participles must agree with the nouns they modify. E.g.:
- "testi bloccati" (masculine plural) — not "testi bloccate"
- "lingue bloccate" (feminine plural) — not "lingue bloccati"

### Addressing the User
**Informal singular (tu)** — standard for Italian mobile apps. The Italian market consistently uses informal address for consumer apps. Imperative verbs (tocca, scorri, aggiungi, seleziona) are already uninflected, so no gender issue there.

### Imperative Verbs
Italian imperatives (informal tu) carry no gender inflection. 2nd person singular imperative used for button/action labels: "Aggiungi", "Tocca", "Seleziona", "Scorri", "Apri".

### RTL
Italian is LTR — no directional considerations needed.

---

## 4b. Canonical Term Groups

| Concept | Canonical Term | Gender | Notes |
|---|---|---|---|
| Block / Deny (verb) | **Blocca** | — | imperative; "Testi bloccati" (adj, masc pl) |
| Allow / Permit (verb) | **Consenti** | — | imperative; "Testi consentiti" (adj, masc pl) |
| Filter / Filters | **filtro / filtri** | masc | "Filtri" as section heading |
| Sender | **mittente / mittenti** | masc | |
| Message (SMS) | **messaggio / messaggi** | masc | |
| Body (filter target) | **corpo** | masc | short, consistent with iOS API terminology |
| Language / Languages | **lingua / lingue** | fem | |
| Update (verb) | **aggiorna** | — | imperative for buttons; "aggiornato" (past part., masc) |
| Junk | **Indesiderati** | masc pl | Apple's official iOS Messages folder name in Italian |
| Double tap | **Doppio tocco** | — | consistent across all a11y hint strings |
| Close | **Chiudi** | — | distinct from Annulla (Cancel) |
| Cancel | **Annulla** | — | |
| Settings | **Impostazioni** | fem pl | Apple's official term for the iOS Settings app |
| ON | **ON** | — | Apple uses "ON" as-is in Italian iOS |
| OFF | **OFF** | — | Apple uses "OFF" as-is in Italian iOS |

---

## 4c. iOS System Term Matching

| App string | iOS feature | Italian term | Source |
|---|---|---|---|
| `addFilter_folder_junk` | iOS Messages "Junk" folder | **Indesiderati** | iOS Messages app in Italian |
| `addFilter_folder_transactions` | iOS Messages "Transactions" folder | **Transazioni** | iOS Messages app in Italian |
| `addFilter_folder_promotions` | iOS Messages "Promotions" folder | **Promozioni** | iOS Messages app in Italian |
| `enableExtension_ready_callToAction` | iOS Settings app | **Impostazioni** | iOS home screen / Settings icon label |
| `autoFilter_ON` / `autoFilter_OFF` | Toggle labels | **ON** / **OFF** | Apple uses English ON/OFF universally in Italian iOS |

---

## 4d. Strings to Keep Untranslated
- `aboutView_twitter` → keep "a_bd"
- `aboutView_github` → keep "GitHub"
- `aboutView_appIconCredit` → keep "Vitali Levit"
- "Adi Ben-Dahan" in `aboutView_aboutText` and `general_copyright` → keep as proper name
- "Tel Aviv 🇮🇱" → keep
- Brand names: "Simply Filter SMS", "iCloud", "iOS", "AppStore", "VoiceOver", "SimplyFilterSMS"
- **VoiceOver** → keep as brand name
- **Voice Control** → translate as "Controllo vocale" (Apple's official Italian term)
- **Dynamic Type** → translate as "Testo dinamico" (Apple's official Italian term in Settings > Accessibility)
- **Reduce Motion** → translate as "Riduci movimento" (Apple's official Italian term in Settings > Accessibility)
- All emoji → keep exactly as in English source
- `general_copyright` → keep "Adi Ben-Dahan", translate "All rights reserved" → "Tutti i diritti riservati."

---

## 4e. Length Constraints

Flagged keys that require care:

| Key | EN | Limit | Italian | Action |
|---|---|---|---|---|
| `general_allow` | "Allow" (5) | ≤8 | "Consenti" (8) | ✓ at limit |
| `general_deny` | "Deny" (4) | ≤8 | "Blocca" (6) | ✓ |
| `general_close` | "Close" (5) | ≤8 | "Chiudi" (6) | ✓ |
| `general_edit` | "Edit" (4) | ≤7 | "Modifica" (8) | ⚠ 1 over — Apple's own Italian UI uses "Modifica"; keep |
| `autoFilter_ON` | "ON" (2) | ≤10 | "ON" (2) | ✓ |
| `autoFilter_OFF` | "OFF" (3) | ≤12 | "OFF" (3) | ✓ |
| `addFilter_add` | "Add" (3) | ≤8 | "Aggiungi" (8) | ✓ at limit |
| `addFilter_addFilter_allow` | "Add Allowed Text" (16) | ≤20 | "Aggiungi testo consentito" (25) | ⚠ needs review |
| `addFilter_addFilter_deny` | "Add Blocked Text" (16) | ≤20 | "Aggiungi testo bloccato" (23) | ⚠ needs review |
| `addFilter_match_exact` | "Exact" (5) | ≤10 | "Esatto" (6) | ✓ |
| `addFilter_match_contains` | "Contains" (8) | ≤12 | "Contiene" (8) | ✓ |
| `addFilter_target_sender` | "Sender" (6) | ≤10 | "Mittente" (8) | ✓ |
| `addFilter_target_body` | "Body" (4) | ≤10 | "Corpo" (5) | ✓ |
| `whatsNew_continue` | "Continue" (8) | ≤12 | "Continua" (8) | ✓ |

---

## 4f. Tone & Register
- Friendly and informal (tu)
- Concise — prefer shorter Italian synonyms where available
- Imperative verbs for actions: "Tocca" (Tap), "Aggiungi" (Add), "Seleziona" (Select), "Apri" (Open), "Scorri" (Scroll)
- Country calling code replacement: `+972` → `+39` (Italy)
