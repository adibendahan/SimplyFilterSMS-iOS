# Brazilian Portuguese (pt-BR) Translation Guide

## 4a. Grammar & Gender Strategy

**Grammatical gender:** Portuguese assigns gender to nouns. Key app nouns:

| Noun | Portuguese | Gender |
|---|---|---|
| Filter (filtro) | filtro | Masculine |
| Message (mensagem) | mensagem | Feminine |
| Folder (pasta) | pasta | Feminine |
| Sender (remetente) | remetente | Masculine |
| Language (idioma) | idioma | Masculine |
| Update (atualização) | atualização | Feminine |
| App (app/aplicativo) | app (m) / aplicativo (m) | Masculine |
| Extension (extensão) | extensão | Feminine |
| List (lista) | lista | Feminine |

**Addressing the user:** Informal singular "você" — standard for Brazilian mobile apps. "Você" is technically 3rd-person grammatically but used as 2nd-person in Brazilian Portuguese. Avoids any gender ambiguity in imperatives.

**Imperative verbs:** Imperatives in Brazilian PT don't carry gender inflection. We use 2nd/3rd-person imperatives (toque, selecione, abra) for button labels — consistent with Apple's own pt-BR UI strings.

**RTL:** Not applicable. pt-BR is LTR.

---

## 4b. Canonical Term Groups

| Concept | Canonical pt-BR | Gender | Notes |
|---|---|---|---|
| Block/Deny (verb) | Bloquear | — | Infinitive used as button label |
| Blocked (adjective) | Bloqueado/Bloqueados | Masc. | Agrees with "filtro/textos" |
| Allow (verb) | Permitir | — | Infinitive for button |
| Allowed (adjective) | Permitido/Permitidos | Masc. | |
| Filter (noun) | filtro | Masc. | Plural: filtros |
| Sender | remetente | Masc. | |
| Message | mensagem | Fem. | Plural: mensagens |
| Body | conteúdo | Masc. | "conteúdo" more natural than "corpo" for SMS |
| Language | idioma | Masc. | More natural than "língua" in app context |
| Update (noun) | atualização / atualizado (past) | Fem./— | |
| Junk | Lixo Eletrônico | — | iOS system term (see §4c) |
| Double tap | Toque duas vezes | — | Consistent across all a11y hints |
| Close | Fechar | — | Distinct from Cancel (Cancelar) |
| Settings | Ajustes | — | iOS system term |
| ON | ON | — | English borrowing, standard on iOS pt-BR |
| OFF | OFF | — | English borrowing, standard on iOS pt-BR |

---

## 4c. iOS System Term Matching

| App string | iOS pt-BR term | Notes |
|---|---|---|
| `addFilter_folder_junk` | Lixo Eletrônico | iOS Messages "Junk" folder in pt-BR |
| `addFilter_folder_transactions` | Transações | iOS Messages "Transactions" folder |
| `addFilter_folder_promotions` | Promoções | iOS Messages "Promotions" folder |
| `enableExtension_ready_callToAction` | Ajustes | iOS Settings app name in pt-BR (not "Configurações") |
| `autoFilter_ON` / `autoFilter_OFF` | ON / OFF | Apple uses English ON/OFF in pt-BR iOS toggles |

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

| Key | EN | pt-BR | Chars |
|---|---|---|---|
| `general_allow` | "Allow" (5) | "Permitir" | 8 ✓ |
| `general_deny` | "Deny" (4) | "Bloquear" | 8 ✓ |
| `general_close` | "Close" (5) | "Fechar" | 6 ✓ |
| `general_edit` | "Edit" (4) | "Editar" | 6 ✓ |
| `autoFilter_ON` | "ON" (2) | "ON" | 2 ✓ |
| `autoFilter_OFF` | "OFF" (3) | "OFF" | 3 ✓ |
| `addFilter_add` | "Add" (3) | "Incluir" | 7 ✓ |
| `addFilter_match_exact` | "Exact" (5) | "Exato" | 5 ✓ |
| `addFilter_match_contains` | "Contains" (8) | "Contém" | 6 ✓ |
| `addFilter_target_sender` | "Sender" (6) | "Remetente" | 9 ✓ |
| `addFilter_target_body` | "Body" (4) | "Conteúdo" | 8 ✓ |
| `whatsNew_continue` | "Continue" (8) | "Continuar" | 9 ✓ |

---

## 4f. Plural Handling

pt-BR has 2 CLDR plural categories:
- **one** (n = 1): 1 filtro
- **other**: %ld filtros

`.stringsdict` file created for `general_active_count`.
Call site confirmed: `String.localizedStringWithFormat` in `AppHomeView.swift:198`.
