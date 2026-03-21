# Translation Guide — Korean (ko)

**Language:** Korean
**BCP-47 code:** `ko`
**Direction:** LTR
**Grammatical gender:** None

---

## 4a. Grammar & Gender Strategy

### Grammatical Gender
Korean has no grammatical gender. Nouns do not inflect, and adjectives/verbs do not agree with noun gender. This means all strings can be translated without any gender concern.

### Addressing the User
Use **polite informal (해요체, haeyoche)** throughout — the standard register for Korean mobile apps. It is respectful but approachable, not overly formal. Example: "설정하세요" → not used; prefer "설정" (noun form) or "탭하세요" only when instructional. For button labels, use the **noun/action noun form** (e.g. "추가", "닫기", "편집") — Korean UI conventions strongly favour nominalised button labels, not imperative verb forms.

### Imperative Verbs
Imperatives in Korean carry no gender inflection. However, Korean UI conventions **strongly prefer noun or nominalized forms** on buttons (e.g. "삭제" not "삭제하세요"). Instructions in body text use the 해요체 ending (e.g. "탭하세요", "스크롤하세요").

### Numbers and Counters
Korean uses specific counter words (e.g. 개 for general objects). For `%ld filters`, use `%ld개` as the counter suffix attached to the number.

---

## 4b. Canonical Term Groups

| Concept | Canonical Term | Notes |
|---|---|---|
| Block / Deny (verb) | 차단 | Noun: 차단, verb: 차단하다. Used consistently for blocking/denying actions. |
| Allow / Permit (verb) | 허용 | Noun: 허용. Used consistently for allowing actions. |
| Filter / Filters (noun) | 필터 | Korean loan word, plural expressed by count (e.g. 필터 3개). |
| Sender | 발신자 | Standard telecom term for sender. |
| Message (SMS) | 메시지 | Standard iOS term. |
| Body (message content) | 본문 | Standard term for message body/content. |
| Language / Languages | 언어 | Standard term; no plural inflection needed. |
| Update (verb) | 업데이트 | Loan word, universally understood. Noun: 업데이트. |
| Junk (folder) | 스팸 | Apple iOS Messages uses "스팸" in Korean for the Junk folder. |
| Double tap (a11y) | 이중 탭 | Consistent VoiceOver hint phrase: "이중 탭하여 [action]". |
| Close | 닫기 | Distinct from Cancel. |
| Cancel | 취소 | Distinct from Close. |
| Settings (iOS app) | 설정 | Official Apple iOS Settings app name in Korean. |
| ON | ON | Use the English borrowed form — universally understood on iOS in Korea. |
| OFF | OFF | Use the English borrowed form — universally understood on iOS in Korea. |

---

## 4c. iOS System Term Matching

| App string | iOS feature | Korean iOS term |
|---|---|---|
| `addFilter_folder_junk` | iOS Messages "Junk" folder | **스팸** |
| `addFilter_folder_transactions` | iOS Messages "Transactions" folder | **거래** |
| `addFilter_folder_promotions` | iOS Messages "Promotions" folder | **프로모션** |
| `enableExtension_ready_callToAction` | iOS Settings app | **설정** |
| `autoFilter_ON` / `autoFilter_OFF` | Toggle labels | **ON / OFF** (English, standard in Korean iOS) |

---

## 4d. Strings to Keep Untranslated

- `aboutView_twitter` = "a_bd"
- `aboutView_github` = "GitHub"
- `aboutView_appIconCredit` = "Vitali Levit"
- "Adi Ben-Dahan" in `aboutView_aboutText`
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- Brand names: "Simply Filter SMS", "iCloud", "iOS", "AppStore", "VoiceOver", "Dynamic Type", "SimplyFilterSMS"
- All emoji — keep exactly as in English source

---

## 4e. Length Constraints

| Key | English | Limit | Korean target |
|---|---|---|---|
| `general_allow` | "Allow" (5) | ≤8 | 허용 (2) ✓ |
| `general_deny` | "Deny" (4) | ≤8 | 차단 (2) ✓ |
| `general_close` | "Close" (5) | ≤8 | 닫기 (3) ✓ |
| `general_edit` | "Edit" (4) | ≤7 | 편집 (2) ✓ |
| `autoFilter_ON` | "ON" (2) | ≤10 | ON (2) ✓ |
| `autoFilter_OFF` | "OFF" (3) | ≤12 | OFF (3) ✓ |
| `addFilter_add` | "Add" (3) | ≤8 | 추가 (2) ✓ |
| `addFilter_addFilter_allow` | "Add Allowed Text" (16) | ≤20 | 허용 텍스트 추가 (9) ✓ |
| `addFilter_addFilter_deny` | "Add Blocked Text" (16) | ≤20 | 차단 텍스트 추가 (9) ✓ |
| `addFilter_match_exact` | "Exact" (5) | ≤10 | 정확히 (4) ✓ |
| `addFilter_match_contains` | "Contains" (8) | ≤12 | 포함 (2) ✓ |
| `addFilter_target_sender` | "Sender" (6) | ≤10 | 발신자 (4) ✓ |
| `addFilter_target_body` | "Body" (4) | ≤10 | 본문 (2) ✓ |
| `whatsNew_continue` | "Continue" (8) | ≤12 | 계속 (2) ✓ |

All critical constrained strings are well within limits due to Korean's concise character system.

---

## 4f. Tone & Register

- Friendly, polite informal (해요체) for instructional body text
- Concise noun forms on buttons — no trailing 하세요 on labels
- Consistent with Korean mobile app conventions
- No em dashes (—) — use hyphen-minus (-) if a dash is needed
