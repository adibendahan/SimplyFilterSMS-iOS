# Arabic (ar) Translation Guide

## 4a. Grammar & Gender Strategy

**Grammatical gender:** Arabic assigns gender (masculine/feminine) to all nouns. Key app nouns:

| Noun | Arabic | Gender |
|---|---|---|
| Filter (مرشّح) | مرشّح | Masculine |
| Message (رسالة) | رسالة | Feminine |
| Folder (مجلد) | مجلد | Masculine |
| Sender (مرسِل) | مُرسِل | Masculine |
| Language (لغة) | لغة | Feminine |
| Update (تحديث) | تحديث | Masculine |
| App (تطبيق) | تطبيق | Masculine |
| Extension (امتداد) | امتداد | Masculine |
| List (قائمة) | قائمة | Feminine |

**Addressing the user:** Plural/gender-neutral forms (أنتم) are used to avoid gender ambiguity, consistent with the Hebrew approach. Most imperative forms are gender-neutral in context.

**Imperative verbs:** Arabic imperatives carry gender/number inflection. We use masculine singular imperatives (اضغط، افتح، اختر) as the neutral default for UI buttons, which is standard practice in iOS Arabic apps.

**RTL:** Arabic is RTL. iOS handles layout mirroring automatically. All strings use natural Arabic sentence direction. LTR content (brand names, URLs) is embedded as-is and iOS renders them correctly.

---

## 4b. Canonical Term Groups

| Concept | Canonical Arabic | Gender | Notes |
|---|---|---|---|
| Block/Deny (verb) | حظر (ḥaẓar) | — | Verb; past form "حُظِر", active "يحظر" |
| Blocked (adjective) | محظور | Masc. | "محظورة" for fem./pl. |
| Allow (verb) | السماح | — | Or "اسمح" as imperative |
| Allowed (adjective) | مسموح | Masc. | "مسموحة" for fem./pl. |
| Filter (noun) | مرشّح | Masc. | Plural: مرشّحات |
| Sender | المُرسِل | Masc. | With definite article |
| Message | رسالة | Fem. | Plural: رسائل |
| Body | المحتوى | Masc. | "content" is more natural than "جسم" for SMS |
| Language | لغة | Fem. | Plural: لغات |
| Update (noun/verb) | تحديث | Masc. | |
| Junk | غير مرغوب فيه | — | iOS system term (see §4c) |
| Double tap | اضغط مرتين | — | Consistent across all a11y hints |
| Close | إغلاق | — | Distinct from Cancel (إلغاء) |
| Settings | الإعدادات | — | iOS system term |
| ON | تشغيل | — | |
| OFF | إيقاف | — | |

---

## 4c. iOS System Term Matching

| App string | iOS Arabic term | Notes |
|---|---|---|
| `addFilter_folder_junk` | غير مرغوب فيه | iOS Messages "Junk" folder in Arabic |
| `addFilter_folder_transactions` | المعاملات | iOS Messages "Transactions" folder |
| `addFilter_folder_promotions` | العروض الترويجية | iOS Messages "Promotions" folder |
| `enableExtension_ready_callToAction` | الإعدادات | iOS Settings app name in Arabic |
| `autoFilter_ON` | تشغيل | Standard iOS toggle ON state |
| `autoFilter_OFF` | إيقاف | Standard iOS toggle OFF state |

---

## 4d. Strings Kept Untranslated

- `aboutView_twitter` = "a_bd" (social handle)
- `aboutView_github` = "GitHub" (brand name)
- `aboutView_appIconCredit` = "Vitali Levit" (proper name)
- Developer name "Adi Ben-Dahan" in `aboutView_aboutText`
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- Brand names: Simply Filter SMS, iCloud, iOS, AppStore, VoiceOver, Dynamic Type
- All emoji kept exactly as in English

---

## 4e. Length Constraint

Tight constraint keys — all within limits:

| Key | EN | AR | Chars |
|---|---|---|---|
| `general_allow` | "Allow" (5) | "سماح" | 4 ✓ |
| `general_deny` | "Deny" (4) | "حظر" | 3 ✓ |
| `general_close` | "Close" (5) | "إغلاق" | 5 ✓ |
| `general_edit` | "Edit" (4) | "تعديل" | 5 ✓ |
| `autoFilter_ON` | "ON" (2) | "تشغيل" | 5 ✓ |
| `autoFilter_OFF` | "OFF" (3) | "إيقاف" | 5 ✓ |
| `addFilter_add` | "Add" (3) | "إضافة" | 5 ✓ |
| `addFilter_match_exact` | "Exact" (5) | "مطابق" | 5 ✓ |
| `addFilter_match_contains` | "Contains" (8) | "يحتوي" | 5 ✓ |
| `addFilter_target_sender` | "Sender" (6) | "المُرسِل" | 7 ✓ |
| `addFilter_target_body` | "Body" (4) | "المحتوى" | 7 ✓ |
| `whatsNew_continue` | "Continue" (8) | "متابعة" | 6 ✓ |

---

## 4f. Plural Handling

Arabic has 6 CLDR plural categories. A `.stringsdict` file is created with all 6 forms for `general_active_count`:

- **zero**: لا مرشّحات
- **one**: مرشّح واحد
- **two**: مرشّحان
- **few** (3–10): %ld مرشّحات
- **many** (11–99): %ld مرشّحًا
- **other** (100+): %ld مرشّح

Call site confirmed: `String.localizedStringWithFormat("general_active_count"~, count)` in AppHomeView.swift:198.
