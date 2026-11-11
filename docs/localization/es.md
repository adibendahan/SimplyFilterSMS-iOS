# Translation Guide — Spanish (es)

**Language:** Spanish (Spain)
**BCP-47 code:** `es`
**Writing direction:** LTR
**Grammatical gender:** Yes (masculine / feminine), on nouns, articles, adjectives and past participles

---

## 4a. Grammar & Gender Strategy

### Variant: Spain

The app's Spanish is Spain Spanish, the variant Apple uses for `es`: **Ajustes** (not Configuración), **Añadir** (not Agregar), **Mantén pulsado** (not Mantén presionado). Use Spain vocabulary in every new string. Latin American terms that slipped in are listed in §4i.

### Addressing the user: informal singular (tú)

- Second person singular informal everywhere: `toca`, `elige`, `tus filtros`, `puedes`.
- Never `usted`, never `vosotros`.
- Imperatives are the tú form: `Toca`, `Abre`, `Elige`, `Selecciona`, `Añade`, `Escribe`, `Deja`, `Baja`.
- Recent past uses the present perfect, as in Spain: `has tocado`, `has elegido` (not `tocaste`).

### Gender-neutral toward the user

Spanish adjectives and participles that describe the reader are gendered (`listo / lista`, `mismo / misma`, `bienvenido / bienvenida`). The app doesn't assume the user's gender (the same policy as Hebrew and Arabic), so rephrase around them:

| Avoid | Use |
|---|---|
| cuando estés listo | cuando quieras |
| tú mismo | por tu cuenta / tú |
| ¡Bienvenido! / ¡Bienvenidos! | ¡Te damos la bienvenida! / ¡Hola! |
| ¿Estás seguro? | ¿Quieres continuar? |
| Eres el primero | — rephrase |

Words about other things keep their normal gender (`el filtro`, `la carpeta`, `los mensajes filtrados`).

### Buttons, menu items and titles

- **Buttons and menu actions**: infinitive (`Añadir`, `Exportar filtros`, `Restablecer el predeterminado`, `Seleccionar todo`), as iOS does.
- **Screen titles that invite**: tú imperative is fine (`Prueba tus filtros`).
- **Sentence case**, never Title Case: `Nuevos idiomas`, not `Nuevos Idiomas`.

### Accessibility hints

`Toca dos veces para` + infinitive: `Toca dos veces para editar`.

### Key nouns

| Noun | Spanish | Gender |
|---|---|---|
| Filter | filtro | m |
| Message | mensaje | m |
| Folder | carpeta | f |
| Sender | remitente | m |
| Language | idioma | m |
| App | app | f (`la app`) |
| Extension | extensión | f |
| List | lista | f |
| Country | país | m |

---

## 4b. Canonical Term Groups

| Concept | Canonical Spanish | Notes |
|---|---|---|
| Block / Allow | **Bloquear / Permitir** | Adjectives: `bloqueado`, `permitido` |
| Filter | **filtro / filtros** | |
| Filtering | **filtrado** | |
| Allowed Texts / Blocked Texts | **Textos permitidos / Textos bloqueados** | |
| Blocked languages | **Idiomas bloqueados** | |
| AI Filtering (feature name) | **Filtrado AI** | As on Home (`autoFilter_title`). In prose, the technology is `IA` (`listas de IA`) |
| Smart Filters | **Filtros inteligentes** | |
| Allow by Country | **Permitir por país** | UI name. In What's New prose: `países de confianza` |
| Filter Tools (menu) | **Herramientas de filtro** | |
| Test Your Filters | **Prueba tus filtros** | |
| Report (the app's action) | **Reportar** | `Reportar mensaje`, button `Reportar` |
| Reporting Extension | **extensión de informes** | |
| Export / Import | **Exportar / Importar** | |
| Regex | **Regex** (label), **patrón** (a pattern), **expresiones regulares** (prose) | |
| Sender | **Remitente** | Unknown sender: `Remitente desconocido` |
| Body | **Cuerpo** | |
| Folder | **Carpeta** | |
| Add | **Añadir** | Not Agregar |
| Tap / Double tap / Long press | **Toca / Toca dos veces / Mantén pulsado** | |
| Email | **correo** | Not Email, not mail |
| Settings | **Ajustes de iOS** | Not Configuración |
| Messages app | **la app Mensajes** | |
| Contacts | **Contactos** | |
| Tip Jar | **Propinas** | |
| Accent Color | **Color de acento** | |
| What's New | **Novedades** | |
| Help / About | **Ayuda / Acerca de** | |
| Close / Cancel | **Cerrar / Cancelar** | Distinct |
| On / Off | **ON / OFF** | |

---

## 4c. iOS System Term Matching — MANDATORY

These must match Spanish (Spain) iOS exactly. The values below are the ones the app uses today; verify on a device set to Spanish (Spain) before changing any of them.

| App string | iOS feature | Spanish term |
|---|---|---|
| `addFilter_folder_junk` | Messages "Junk" folder | **No deseado** |
| `addFilter_folder_transactions` | Messages "Transactions" folder | **Transacciones** |
| `addFilter_folder_promotions` | Messages "Promotions" folder | **Promociones** |
| `enableExtension_ready_callToAction` | Settings app | **Ajustes** |
| `enableExtension_step1_desc` | Settings → Apps | **Apps** |
| `enableExtension_step2_*` | Messages | **Mensajes** |
| `enableExtension_step3_*` | Unknown Senders section | **Desconocidos** |
| `enableExtension_step4_*` | Filter Unknown Senders | **Filtrar desconocidos** |
| `enableExtension_step5_*` | Spam filtering | **Filtrar spam** |
| `enableExtension_step6_desc` | SMS filter picker | **Filtro de mensajes de texto** |
| `enableReportingExtension_step2_*` | Phone | **Teléfono** |
| `enableReportingExtension_step3_*` | SMS/Call Reporting | **Informe de SMS/Llamadas** |
| `enableReportingExtension_step5_desc` | Context menu "More…" | **Más...** |
| `enableReportingExtension_step7_*` | Messages "Report Messages" | **Informar sobre mensajes** |
| `whatsNew_accessibility_desc` | Voice Control / Dynamic Type / Reduce Motion | **Control por voz / Tipo de texto dinámico / Reducir movimiento** |

---

## 4d. Strings to Keep Untranslated

- Brand names: Simply Filter SMS, iCloud, iOS, iMessage, App Store, GitHub, VoiceOver
- `aboutView_twitter` = `a_bd`; `aboutView_appIconCredit` = `Vitali Levit`; "Adi Ben-Dahan"
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- `SMS`, `Regex`, `spam`
- All emoji, exactly as in English
- Calling-code examples are localized: `+1` / `+34` (Spain)

---

## 4e. Typography

- Opening marks on every question and exclamation: `¿…?`, `¡…!`.
- Quoted UI names use ASCII single quotes: `'Mensajes'`.
- Dash: hyphen-minus with spaces, ` - `. Never an em dash.
- Decimal and list punctuation as in Spain; `p. ej.` for "e.g.".
- Preserve `%ld`, `%@`, `**bold**` and `\n` exactly.

---

## 4f. Length Constraint

Spanish runs about 15-25% longer than English. Keep buttons to the iOS-standard word and trim long-form copy rather than labels.

| Key | English | Spanish |
|---|---|---|
| `general_allow` | "Allow" (5) | "Permitir" (8) ✓ |
| `general_deny` | "Deny" (4) | "Bloquear" (8) ✓ |
| `general_close` | "Close" (5) | "Cerrar" (6) ✓ |
| `general_edit` | "Edit" (4) | "Editar" (6) ✓ |
| `addFilter_add` | "Add" (3) | "Añadir" (6) ✓ |
| `addFilter_match_exact` | "Exact" (5) | "Exacto" (6) ✓ |
| `addFilter_match_contains` | "Contains" (8) | "Contiene" (8) ✓ |
| `addFilter_target_sender` | "Sender" (6) | "Remitente" (9) ✓ |
| `whatsNew_continue` | "Continue" (8) | "Continuar" (9) ✓ |

---

## 4g. Tone & Register

- Friendly, informal (tú), concise.
- Everyday Spain Spanish; a colloquial word is fine where it reads naturally (`pillan spam`).
- English tech loanwords only where Spanish speakers use them: `app`, `spam`, `emojis`.

---

## 4h. Plurals (stringsdict)

Spanish uses `one` and `other` (`zero` is allowed for "none" wording, as in `general_active_count`: `Sin filtros`).

---

## 4i. Known Deviations to Fix

Existing strings that break this guide. Fix them when touching the area; renaming a UI label also means updating every FAQ answer that quotes it.

**Gendered toward the user:**

| Key | Now | Fix |
|---|---|---|
| `enableExtension_welcome` | ¡Bienvenidos! | ¡Te damos la bienvenida! |
| `enableExtension_welcome_desc` | …cuando estés listo. | …cuando quieras. |
| `enableReportingExtension_desc` | …cuando estés listo. | …cuando quieras. |

**Latin American terms (Spain variant):**

| Key | Now | Fix |
|---|---|---|
| `autoFilter_countryAllowlist_explanation` | Agrega… deseas… | Añade… quieres…; example `+972` → `+34` |
| `whatsNew_trustedCountries_desc` | Agrega… | Añade… |
| `enableReportingExtension_desc` | …el botón Configuración… | …el botón Ajustes… |

**Inconsistent terms:**

| Key | Now | Fix |
|---|---|---|
| `autoFilter_reportSpam` | Denunciar spam | Reportar spam |
| `whatsNew_aiFiltering_title` | Filtrado con IA | Filtrado AI |
| `autoFilter_improveAIFiltering`, `notification_reportingExtension_title` | Mejorar filtrado de IA | Mejorar Filtrado AI (also quoted in `faq_answer_report`) |
| `inactivityNotification_title` | …filtrado de IA… | …Filtrado AI… |
| `help_automaticFiltering` | …a la carpeta de no deseados | …a la carpeta No deseado |
| `autoFilter_email_shortTitle` | Email | Correo |

**Title Case:**

| Key | Now | Fix |
|---|---|---|
| `whatsNew_newLanguages_title` | 9 Nuevos Idiomas | 9 idiomas nuevos |
| `whatsNew_trustedCountries_title` | Países de Confianza | Países de confianza |
| `aboutView_supportSection` | Apoya la App | Apoya la app |
