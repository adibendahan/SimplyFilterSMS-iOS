# Simplified Chinese (zh-Hans) Translation Guide

## 4a. Grammar & Gender Strategy

### Grammatical Gender
Simplified Chinese has **no grammatical gender**. Nouns do not have gender, and adjectives/verbs do not agree with nouns by gender.

Key app nouns (no gender inflection needed):
- 过滤器 (filter)
- 信息 (message)
- 列表 (list)
- 发件人 (sender)
- 语言 (language)
- 更新 (update)
- App
- 扩展 (extension)

### Addressing the User
**Strategy: Informal singular 你, omitted on short labels.**

Use concise, friendly second-person wording with “你” where addressing the user is useful. Omit the subject in buttons, titles, and short instructions.

### Imperative Verbs
Use verb-led action labels such as “添加”, “选择”, “打开”, and “轻点”. Do not use overly formal written Chinese.

### RTL
Simplified Chinese is LTR. No RTL considerations. iOS handles layout direction without additional code.

---

## 4b. Canonical Term Groups

| Concept | Canonical Chinese Term | Notes |
|---|---|---|
| Block / Deny (verb) | 屏蔽 | Prefer over 拒绝 for filter actions |
| Block / Deny (adjective/noun) | 已屏蔽 | e.g. "Blocked Texts" = 已屏蔽的文本 |
| Deny (generic action) | 拒绝 | Only for `general_deny` |
| Allow / Permit (verb) | 允许 | Standard iOS term |
| Allow / Permit (adjective/noun) | 允许的 | e.g. "Allowed Texts" = 允许的文本 |
| Filter / Filters (noun) | 过滤器 | Use 过滤 as the verb |
| Sender | 发件人 | Match Apple Messages terminology |
| Message (Messages UI) | 信息 | Messages app content |
| SMS (transport) | 短信 | Transport type |
| Body (message body) | 正文 | Filter target |
| Language / Languages | 语言 | "Blocked Languages" = 已屏蔽的语言 |
| Update (verb) | 更新 | |
| Update (timestamp) | 更新于 | |
| Junk (folder name) | 垃圾短信 | Exact Simplified Chinese iOS Messages label |
| Transactions | 交易信息 | Exact Simplified Chinese iOS Messages label |
| Promotions | 推广信息 | Exact Simplified Chinese iOS Messages label |
| Double tap (accessibility) | 轻点两下 | Official VoiceOver action phrase |
| Close | 关闭 | Distinct from Cancel |
| Cancel | 取消 | Standard iOS term |
| Settings (iOS app) | 设置 | Official Apple Simplified Chinese term |
| ON | 开 | Concise native toggle state |
| OFF | 关 | Concise native toggle state |

---

## 4c. iOS System Term Matching — MANDATORY

| App string | iOS feature | Simplified Chinese iOS term |
|---|---|---|
| `addFilter_folder_junk` | iOS Messages "Junk" folder | **垃圾短信** |
| `addFilter_folder_transactions` | iOS Messages "Transactions" folder | **交易信息** |
| `addFilter_folder_promotions` | iOS Messages "Promotions" folder | **推广信息** |
| `enableExtension_ready_callToAction` | iOS Settings app | **设置** |
| `enableExtension_step2_title` | Messages app | **信息** |
| `enableExtension_step3_title` | Unknown Senders | **未知发件人** |
| `enableExtension_step4_title` | Screen Unknown Senders | **筛选未知发件人** |
| `enableExtension_step5_title` | Filter Spam | **过滤垃圾信息** |
| `enableExtension_step6_desc` | Text Message Filter | **短信过滤器** |
| `autoFilter_ON` / `autoFilter_OFF` | Toggle state | **开** / **关** |
| Accessibility: VoiceOver | VoiceOver | **旁白** |
| Accessibility: Voice Control | Voice Control | **语音控制** |
| Accessibility: Dynamic Type | Dynamic Type | **动态字体** |
| Accessibility: Reduce Motion | Reduce Motion | **减弱动态效果** |

Never shorten or paraphrase an iOS system term, even if the string is longer than English.

---

## 4d. Strings to Keep Untranslated

- `aboutView_twitter` = `a_bd`
- `aboutView_github` = `GitHub`
- `aboutView_appIconCredit` = `Vitali Levit`
- Developer name "Adi Ben-Dahan" in `aboutView_aboutText`
- Brand names: Simply Filter SMS, iCloud, iOS, App Store, GitHub, VoiceOver
- Translate Dynamic Type / Voice Control / Reduce Motion with the official iOS Simplified Chinese terms above
- Preserve “Tel Aviv 🇮🇱” semantically as “特拉维夫 🇮🇱”
- All emoji — keep exactly as in English

**Partially translate:** `general_copyright` — keep "Adi Ben-Dahan", translate the rights phrase.

---

## 4e. Length Constraint

Chinese translations are generally shorter than English because characters are dense. Keep labels compact and natural for a native iOS interface. System labels are exempt from shortening.

Tight UI keys (confirmed within limit):

| Key | English | Limit | Chinese plan |
|---|---|---|---|
| `general_allow` | "Allow" (5) | ≤8 | 允许 (2) ✓ |
| `general_deny` | "Deny" (4) | ≤8 | 拒绝 (2) ✓ |
| `general_close` | "Close" (5) | ≤8 | 关闭 (2) ✓ |
| `general_edit` | "Edit" (4) | ≤7 | 编辑 (2) ✓ |
| `autoFilter_ON` | "ON" (2) | ≤10 | 开 (1) ✓ |
| `autoFilter_OFF` | "OFF" (3) | ≤12 | 关 (1) ✓ |
| `addFilter_add` | "Add" (3) | ≤8 | 添加 (2) ✓ |
| `addFilter_addFilter_allow` | "Add Allowed Text" (16) | ≤20 | 添加允许的文本 (7) ✓ |
| `addFilter_addFilter_deny` | "Add Blocked Text" (16) | ≤20 | 添加屏蔽的文本 (7) ✓ |
| `addFilter_match_exact` | "Exact" (5) | ≤10 | 完全匹配 (4) ✓ |
| `addFilter_match_contains` | "Contains" (8) | ≤12 | 包含 (2) ✓ |
| `addFilter_target_sender` | "Sender" (6) | ≤10 | 发件人 (3) ✓ |
| `addFilter_target_body` | "Body" (4) | ≤10 | 正文 (2) ✓ |
| `whatsNew_continue` | "Continue" (8) | ≤12 | 继续 (2) ✓ |

---

## 4f. Tone & Register

- Friendly and concise — match modern Simplified Chinese iOS app style
- Prefer verb-led buttons and short state labels
- Use measure words consistently: 个 for filters, 条 for messages
- Preserve every `%ld` / `%@` placeholder, Markdown `**bold**`, escaped newline, brand name, and emoji
- Use a hyphen-minus (`-`), never an em dash
- Localize calling-code examples to `+1` / `+86` in country-allowlist help copy
