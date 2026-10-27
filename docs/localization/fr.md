# French (fr) Translation Guide

## 4a. Grammar & Gender Strategy

**Grammatical gender:** French assigns gender to all nouns. Key app nouns:

| Noun | French | Gender |
|---|---|---|
| Filter (filtre) | filtre | Masculine |
| Message (message) | message | Masculine |
| Folder (dossier) | dossier | Masculine |
| Sender (expéditeur) | expéditeur | Masculine |
| Language (langue) | langue | Feminine |
| Update (mise à jour) | mise à jour | Feminine |
| App (app) | app | Feminine |
| Extension (extension) | extension | Feminine |
| List (liste) | liste | Feminine |

**Addressing the user:** Informal singular "tu" — the app's friendly tone calls for informal register, consistent with most modern consumer iOS apps. Imperatives are 2nd-person singular (tu form): touche, ouvre, fais défiler.

**Imperative verbs:** French imperatives do not carry gender inflection. 2nd-person singular informal forms are used throughout (touche, sélectionne, ajoute).

**RTL:** Not applicable. French is LTR.

---

## 4b. Canonical Term Groups

| Concept | Canonical French | Gender | Notes |
|---|---|---|---|
| Block/Deny (verb) | Bloquer | — | Infinitive as button label |
| Blocked (adjective) | Bloqué/Bloqués | Masc. | Agrees with noun |
| Allow (verb) | Autoriser | — | Infinitive for button |
| Allowed (adjective) | Autorisé/Autorisés | Masc. | |
| Filter (noun) | filtre | Masc. | Plural: filtres |
| Sender | expéditeur | Masc. | |
| Message | message | Masc. | |
| Body | contenu | Masc. | More natural than "corps" for SMS |
| Language | langue | Fem. | |
| Update (noun) | mise à jour | Fem. | Past participle: mis à jour |
| Junk | Indésirables | — | iOS system term (see §4c) |
| Double tap | Appuyer deux fois | — | Consistent across all a11y hints |
| Close | Fermer | — | Distinct from Cancel (Annuler) |
| Settings | Réglages | — | iOS system term |
| ON | ON | — | English borrowing, standard in French iOS |
| OFF | OFF | — | English borrowing, standard in French iOS |

---

## 4c. iOS System Term Matching

| App string | iOS French term | Notes |
|---|---|---|
| `addFilter_folder_junk` | Indésirables | iOS Messages "Junk" folder in French |
| `addFilter_folder_transactions` | Transactions | iOS Messages "Transactions" folder |
| `addFilter_folder_promotions` | Promotions | iOS Messages "Promotions" folder |
| `enableExtension_ready_callToAction` | Réglages | iOS Settings app name in French (not "Paramètres") |
| `autoFilter_ON` / `autoFilter_OFF` | ON / OFF | Apple uses English ON/OFF in French iOS |

---

## 4d. Strings Kept Untranslated

- `aboutView_twitter` = "a_bd"
- `aboutView_github` = "GitHub"
- `aboutView_appIconCredit` = "Vitali Levit"
- Developer name "Adi Ben-Dahan" in `aboutView_aboutText`
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- Brand names: Simply Filter SMS, iCloud, iOS, AppStore, VoiceOver, Dynamic Type
- All emoji kept exactly as in English

---

## 4e. Length Constraint

Tight constraint keys — all within limits:

| Key | EN | French | Chars |
|---|---|---|---|
| `general_allow` | "Allow" (5) | "Autoriser" | 9 — exceeds ≤8, best available |
| `general_deny` | "Deny" (4) | "Bloquer" | 7 ✓ |
| `general_close` | "Close" (5) | "Fermer" | 6 ✓ |
| `general_edit` | "Edit" (4) | "Éditer" | 6 ✓ |
| `autoFilter_ON` | "ON" (2) | "ON" | 2 ✓ |
| `autoFilter_OFF` | "OFF" (3) | "OFF" | 3 ✓ |
| `addFilter_add` | "Add" (3) | "Ajouter" | 7 ✓ |
| `addFilter_match_exact` | "Exact" (5) | "Exact" | 5 ✓ |
| `addFilter_match_contains` | "Contains" (8) | "Contient" | 8 ✓ |
| `addFilter_target_sender` | "Sender" (6) | "Expéditeur" | 10 ✓ |
| `addFilter_target_body` | "Body" (4) | "Contenu" | 7 ✓ |
| `whatsNew_continue` | "Continue" (8) | "Continuer" | 9 ✓ |

Note: "Autoriser" (9) exceeds the ≤8 limit by one character — no shorter natural French synonym exists for a button label. "Autoriser" is the standard iOS French term and is accepted.

---

## 4f. Plural Handling

French has 2 CLDR plural categories (special: `one` covers both 0 and 1):
- **one** (n = 0 or 1): 1 filtre
- **other** (n ≥ 2): %ld filtres

`.stringsdict` file created for `general_active_count`.
Call site confirmed: `String.localizedStringWithFormat` in `AppHomeView.swift:198`.
