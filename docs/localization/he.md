# Translation Guide — Hebrew (he)

**Language:** Hebrew
**BCP-47 code:** `he`
**Writing direction:** RTL
**Grammatical gender:** Yes (masculine / feminine), on nouns, verbs, adjectives, pronouns and possessives

Hebrew is the app's second language and the reference the other gendered languages follow (see `ar.md`).

---

## 4a. Grammar & Gender Strategy

### The rule: never a form that picks a gender

Hebrew marks gender on almost every word that refers to the reader. The app never picks one. A form written the same for both genders is never an issue and is encouraged. Where the written singular differs between male and female, use the **plural**. One sentence never mixes the two: if it addresses the reader in plural (`תמצאו`) and in a shared singular form (`שלך`), flag it and pick one (or go impersonal, below) so it reads as one voice. A quoted or bold UI name (`ב'הפילטרים שלך'`) is a label, not the sentence's voice, so it never counts:

| Form | Use | Never |
|---|---|---|
| Imperative | הוסיפו, בחרו, לחצו, פתחו, גללו, הקלידו, השאירו, שלחו, נסו, עקבו | הוסף / הוסיפי, בחר / בחרי, לחץ / לחצי |
| Pronoun | אתם | אתה, את |
| Possessive | שלך, -ך (written the same for both: הפילטרים שלך, תרומתך) or שלכם, -כם | |
| Past tense | לחצת, דיווחת (written the same for both) or לחצתם, דיווחתם | |
| Future / modal | תרצו, תוכלו | תרצה, תרצי |
| Present tense, adjectives about the user | מוכנים, נהנים, מקבלים (masculine plural is the inclusive plural) | מוכן / מוכנה, נהנה / נהנית |

No slash forms (`לחץ/י`, `מוכן/ה`), no parentheses forms. They are hard to read and break with VoiceOver.

### When a plural sentence is awkward, go impersonal

Hebrew has neutral constructions that address nobody:

- **Verbal noun (שם פעולה)** for buttons, menu items, titles and steps: הוספה, עריכה, מחיקה, סגירה, ייצוא, ייבוא, חיפוש, איפוס, הסתרה, הפעלת הסינון, פתיחת הגדרות iOS.
- **Impersonal plural present** for questions: איך בודקים את הפילטרים? / איך עוזרים לשפר את סינון AI?
- **Modal + infinitive**: אפשר לבחור…, ניתן לקרוא…, יש לאפשר…
- **Passive**: ההודעה תיחסם, הפילטרים מתעדכנים, שום דבר לא יימחק.

### Buttons, menu items and titles

- Verbal noun, never an imperative: `הוספה`, not `הוסף`; `הסתרה`, not `הסתר`; `בחירת הכל`, not `בחר הכל`.
- A title that names a screen the user opens can be a plural imperative when it's an invitation (`בחנו את הפילטרים שלכם`), but a verbal noun is preferred for new titles.
- Never open a title with `כדי ש…` or any subordinate clause; it reads as translated English. Use a verbal noun, a casual question (`נהנים מהאפליקציה?`) or a plain statement (`הסנכרון ל-iCloud מושהה`).

### Accessibility hints

`הקשה כפולה ל` + verbal noun: `הקשה כפולה לעריכה`, `הקשה כפולה לפתיחת הגדרות מערכת ההפעלה`. Never `הקש פעמיים כדי…`.

### Other people and things

- **The app** is feminine (האפליקציה): `Simply Filter SMS בודקת`, `לא אוספת`, `נבחרה`, `חינמית`.
- **Users in general**: plural, `המשתמשים`, `כל המשתמשים`.
- **Sender (שולח)** is a grammatical noun, not the reader, so its masculine form is fine: `השולח נמצא באנשי קשר`.
- **The developer speaking in first person** (About, FAQ): first person past and future are gender-neutral (`חשבתי`, `אשמח`, `שלחו לי מייל`). Avoid first-person present adjectives (`אני שמח`).

### Key nouns

| Noun | Hebrew | Gender | Plural |
|---|---|---|---|
| Filter | פילטר | m | פילטרים |
| Message | הודעה | f | הודעות |
| Folder | תיקייה | f | תיקיות |
| Sender | שולח | m | שולחים |
| Language | שפה | f | שפות |
| App | אפליקציה | f | אפליקציות |
| Extension | תוסף | m | תוספים |
| List | רשימה | f | רשימות |
| Country | מדינה | f | מדינות |
| Text (filter text) | טקסט | m | טקסטים |

---

## 4b. Canonical Term Groups

| Concept | Canonical Hebrew | Notes |
|---|---|---|
| Filter (noun) | **פילטר / פילטרים** | Not מסנן. `מסננת` only for the app's role in iOS ("Simply Filter SMS לא נבחרה כמסננת") |
| Filtering | **סינון** | `הסינון`, `סינון AI` |
| Allowed Texts (list) | **טקסטים מאופשרים** | |
| Blocked Texts (list) | **טקסטים חסומים** | |
| Blocked languages | **שפות חסומות** | |
| Block (action noun) | **חסימה** | `חסימת שפה` |
| Allow (action noun) | **אישור / מתן אפשרות** | Avoid bare `אפשר`, which also reads as "possible" |
| AI Filtering | **סינון AI** | In prose, `בינה מלאכותית` or `ה-AI` is fine |
| AI-based (lists) | **מבוססות AI** | Not `של AI`: `רשימות סינון מבוססות AI` |
| Allow notifications | **אפשרו התראות** | Apple's term is `לאפשר התראות`; not `אשרו` |
| Smart Filters | **פילטרים חכמים** | |
| Allow by Country | **אפשר לפי מדינה** | UI name of the rule. In What's New prose: `מדינות מהימנות` |
| Filter Tools (menu) | **כלי פילטור** | |
| Test Your Filters | **בחנו את הפילטרים שלכם** | |
| Report (action) | **דיווח** | `דיווח על הודעה`, `לחצו לדיווח` |
| Reporting Extension | **תוסף הדיווח** | |
| Export / Import | **ייצוא / ייבוא** | |
| Regex | **Regex** (label), **ביטוי** (a pattern), **ביטויים רגולריים** (prose) | |
| Sender | **שולח** | Unknown sender: `שולח לא מוכר` |
| Body (filter target) | **הודעה** on the target picker, **גוף ההודעה** in prose | |
| Folder | **תיקייה** | Full spelling, two yods |
| Tap | **לחצו** | `לחצו על`. VoiceOver hints keep `הקשה כפולה` |
| Long press | **לחיצה ארוכה** | |
| Double tap (a11y) | **הקשה כפולה** | |
| Email | **מייל** in prose, **אימייל** on the button | Not `דואר אלקטרוני`, except the Smart Filter for email senders |
| Optional | **אופציונלי** | Not `אופציונאלי` |
| Settings | **הגדרות iOS** | `הגדרות מערכת ההפעלה` also appears; prefer `הגדרות iOS` in new strings |
| Messages app | **אפליקציית ההודעות** | |
| Contacts | **אנשי קשר** | |
| iCloud sync | **הסנכרון ל-iCloud** | |
| Tip Jar | **צנצנת טיפים** | |
| Accent Color | **צבע הדגשה** | |
| What's New | **מה חדש** | |
| Close / Cancel | **סגירה / ביטול** | Distinct |
| On / Off | **פועל / כבוי** | |

---

## 4c. iOS System Term Matching — MANDATORY

These must match Hebrew iOS exactly, even when Apple's term is a singular imperative. The values below are the ones the app uses today; verify on a device set to Hebrew before changing any of them.

| App string | iOS feature | Hebrew term |
|---|---|---|
| `addFilter_folder_junk` | Messages "Junk" folder | **זבל** |
| `addFilter_folder_transactions` | Messages "Transactions" folder | **עסקאות** |
| `addFilter_folder_promotions` | Messages "Promotions" folder | **קידומי מכירות** |
| `enableExtension_ready_callToAction` | Settings app | **הגדרות** |
| `enableExtension_step1_desc` | Settings → Apps | **אפליקציות** |
| `enableExtension_step2_*` | Messages | **הודעות** |
| `enableExtension_step3_*` | Unknown Senders section | **שולחים לא ידועים** |
| `enableExtension_step4_*` | Filter Unknown Senders | **סינון שולחים לא ידועים** |
| `enableExtension_step5_*` | Spam filtering | **סינון ספאם** |
| `enableExtension_step6_desc` | SMS filter picker | **מסנן הודעות טקסט** |
| `enableReportingExtension_step2_*` | Phone | **טלפון** |
| `enableReportingExtension_step3_*` | SMS/Call Reporting | **דיווח על SMS/שיחות** |
| `enableReportingExtension_step5_desc` | Context menu "More…" | **עוד...** |
| `enableReportingExtension_step7_*` | Messages "Report Messages" | **דווח על הודעות** (Apple's wording; keep) |
| `whatsNew_accessibility_desc` | Voice Control | **בקרה קולית** |
| `whatsNew_accessibility_desc` | Dynamic Type | **גודל טקסט** (Hebrew uses the Settings label, not the English name) |
| `whatsNew_accessibility_desc` | Reduce Motion | **הפחת תנועה** (Apple's wording; keep) |

---

## 4d. Strings to Keep Untranslated

- Brand names: Simply Filter SMS, iCloud, iOS, iMessage, App Store, GitHub, VoiceOver
- `aboutView_twitter` = `a_bd`
- Latin `SMS`, `AI`, `Regex`, `Issue` stay Latin inside Hebrew sentences
- All emoji, exactly as in English
- Calling codes stay as in English: `+1`, `+972`

Translated on purpose: the developer's name (`עדי בן-דהן`) and the icon designer's (`ויטאלי לויט`).

---

## 4e. Typography & Mixed-Direction Text

- **Prefix letters before Latin, digits or symbols take a hyphen**: `ב-GitHub`, `ל-iCloud`, `ה-AI`, `ב-**10 שפות**`, `ו-**סינון AI**`.
- **Prefix letters before a bold Hebrew word attach directly, outside the bold**: `ב**אנשי קשר**`, `ל**עזרה**`, `מ**כלי פילטור**`. No hyphen.
- **Quoted UI names** use ASCII single quotes: `'הודעות'`, `ב'Simply Filter SMS'`.
- **Dash**: hyphen-minus with spaces, ` - `. Never an em dash, never a maqaf (־).
- **Abbreviations** use gershayim (`ע״י`) or, better, the full words (`על ידי`).
- **Full spelling (כתיב מלא)**: תיקייה, ייחודי, איפוס, תיחסם, מאוד.
- **Bullets** are `•` after `\n`, as in English.
- Preserve `%ld`, `%@`, `**bold**` and `\n` exactly. In RTL, `%ld` sits where the number is read: `%ld פילטרים`, `הודעה %ld`.

---

## 4f. Length Constraint

Hebrew is usually shorter than English and is the baseline other guides measure against. Keep buttons and labels to one or two words.

| Key | English | Hebrew |
|---|---|---|
| `general_close` | "Close" (5) | "סגירה" (5) ✓ |
| `general_edit` | "Edit" (4) | "עריכה" (5) ✓ |
| `addFilter_add` | "Add" (3) | "הוספה" (5) ✓ |
| `addFilter_match_exact` | "Exact" (5) | "מדויק" (5) ✓ |
| `addFilter_match_contains` | "Contains" (8) | "מכיל" (4) ✓ |
| `addFilter_target_sender` | "Sender" (6) | "שולח" (4) ✓ |
| `autoFilter_ON` / `autoFilter_OFF` | "ON" / "OFF" | "פועל" / "כבוי" ✓ |
| `whatsNew_continue` | "Continue" (8) | "המשך" (4) ✓ |

---

## 4g. Tone & Register

- Friendly and direct, the way an Israeli app talks: plain words, no officialese.
- Prefer everyday words (`לשנות`, `לבדוק`) over formal ones (`לבצע שינוי`, `הינן`).
- `אנא` sparingly; `נסו שוב` is enough.
- English loanwords where Israelis use them: פילטר, אפליקציה, ספאם, אימוג'ים, טיפ.
- Present tense for general truths, not future; English "will" does not carry over: `כשלא פותחים, רשימות הסינון מפסיקות להתעדכן`, not `אם לא תפתחו… לא יתעדכנו`.
- Name the noun when its antecedent is far away: `עלול להסיר את האפליקציה`, not `עלול להסיר אותה` when `אותה` could mean the app or the lists.

---

## 4h. Plurals (stringsdict)

Hebrew uses `one`, `two`, `many`, `other` (`zero` is allowed for "none" wording, as in `general_active_count`). Each form follows the same gender rule: `איך תרצו לסווג אותה?`, not `איך תרצה`.

---

## 4i. Known Deviations to Fix

Existing strings that break this guide. Fix them when touching the area; renaming a UI label also means updating every FAQ answer that quotes it.

**Gendered singular address:**

| Key | Now | Problem |
|---|---|---|
| `autoFilter_countryAllowlist_explanation` | הוסף… שמהן אתה רוצה… | singular imperative and `אתה` |
| `enableReportingExtension_desc` | הפעל… עקוב… ולחץ… כשאתה מוכן | singular throughout |
| `enableReportingExtension_step5_title` / `_desc` | לחץ לחיצה ארוכה… | singular imperative |
| `enableReportingExtension_step6_title` / `_desc` | בחר הודעות / בחר… שברצונך | singular |
| `enableReportingExtension_step7_desc` | לחץ על 'דווח על הודעות'… | `לחץ` (the quoted iOS term stays) |
| `autoFilter_improveAIFiltering`, `notification_reportingExtension_title` | שפר סינון AI | singular imperative |
| `notification_reportingExtension_subtitle` | דווח על הודעות ספאם | singular imperative |
| `notification_reportingExtension_button` | הצטרף | singular imperative |
| `autoFilter_reportSpam` | דווח על ספאם | singular imperative |
| `addFilter_regexTestCaption` | בדוק את הביטוי שלך: | `בדוק` is a masculine imperative |
| `whatsNew_regexFilters_desc` | …סנן עם… | singular imperative |
| `importFilters_selectAll` | בחר הכל | → `בחירת הכל` |
| `inactivityNotification_stopAsking` | אל תשאל שוב | singular (the app is asking; → `לא לשאול שוב`) |
| `autoFilter_forceUpdate` | עדכן עכשיו | → `עדכון עכשיו` |
| `addFilter_more` / `addFilter_less` | הראה… | → `הצגת…` |
| `notification_hide` | הסתר | → `הסתרה` |
| `reportMessage_junkAndBlockSender` | זבל וחסום שולח | singular imperative |
| `reportingExtension_classify` (stringsdict) | איך תרצה לסווג… | → `תרצו` |
| `general_allow` / `general_deny` | אפשר / חסום | singular imperatives |
| Smart Filter names: `autoFilter_allUnknown`, `_links`, `_numbersOnly`, `_shortSender`, `_email`, `_emojis`, `autoFilter_countryAllowlist` | חסום… / אפשר… | singular imperatives; the FAQ answers quote these names |

**Spelling and consistency:**

| Key | Now | Fix |
|---|---|---|
| `help_allow` | יחודיים | ייחודיים |
| `testFilters_senderTitle` | אופציונאלי | אופציונלי (as in `help_enableReporting_caption`) |
| `testFilters_footer` | אופציונאלי | אופציונלי |
| `lang_how` | תחסם | תיחסם |
| `aboutView_aboutText` | מאד | מאוד |
| `faq_answer_shareFilters` | ב-**ייבוא פילטרים** | ב**ייבוא פילטרים** (no hyphen before a Hebrew word) |
