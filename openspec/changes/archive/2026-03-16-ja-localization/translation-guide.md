# Japanese (ja) Translation Guide

## 4a. Grammar & Gender Strategy

### Grammatical Gender
Japanese has **no grammatical gender**. Nouns do not have gender, and adjectives/verbs do not agree with nouns by gender. This greatly simplifies translation — no gendered agreement is needed for any app noun.

Key app nouns (no gender inflection needed):
- フィルター (filter) — no gender
- メッセージ (message) — no gender
- フォルダ (folder) — no gender
- 送信者 (sender) — no gender
- 言語 (language) — no gender
- アップデート (update) — no gender
- アプリ (app) — no gender
- 拡張機能 (extension) — no gender
- リスト (list) — no gender

### Addressing the User
**Strategy: Omit the subject entirely (implicit you).**

Japanese naturally omits the subject pronoun. Imperatives and instructions are stated in the verb form without addressing the user directly. This is the standard mobile app pattern for Japanese iOS apps. On buttons and labels, use the noun form or the te-form as needed.

- Buttons: short noun or verb-masu form (e.g., 追加, 閉じる)
- Instructions: verb-te form or plain declarative

### Imperative Verbs
Japanese imperative forms do not carry gender. For buttons, use:
- Short noun form (e.g., 追加 "Add", 削除 "Delete") — most concise
- -masu stem for actions (e.g., 閉じる "Close")
- Never use the blunt command form (-ro/-e) — too harsh for a mobile app

### RTL
Japanese is LTR. No RTL considerations.

---

## 4b. Canonical Term Groups

| Concept | Canonical Japanese Term | Notes |
|---|---|---|
| Block / Deny (verb) | ブロック | Widely used in Japanese iOS apps; shorter than 拒否する |
| Block / Deny (adjective/noun) | ブロック済み / ブロック | e.g., "Blocked Texts" = ブロックテキスト |
| Allow / Permit (verb) | 許可 | Standard iOS term |
| Allow / Permit (adjective/noun) | 許可済み / 許可 | e.g., "Allowed Texts" = 許可テキスト |
| Filter / Filters (noun) | フィルター | Standard loanword, plural implicit |
| Sender | 送信者 | Standard term |
| Message (SMS) | メッセージ | Standard iOS term |
| Body (message body) | 本文 | Standard Japanese term for message body |
| Language / Languages | 言語 | Standard term |
| Update (verb) | 更新する | Standard iOS term |
| Update (past participle / "last updated") | 更新済み / 最終更新 | |
| Junk (folder name) | 迷惑メール | Apple's official iOS Messages folder name in Japanese |
| Transactions | トランザクション | Apple's official iOS Messages folder name in Japanese |
| Promotions | プロモーション | Apple's official iOS Messages folder name in Japanese |
| Double tap (accessibility) | ダブルタップ | Standard iOS VoiceOver term |
| Close | 閉じる | Distinct from Cancel |
| Cancel | キャンセル | Standard iOS term |
| Settings (iOS app) | 設定 | Official Apple Japanese term |
| ON | ON | English borrowed, universally used in Japanese iOS UIs |
| OFF | OFF | English borrowed, universally used in Japanese iOS UIs |

---

## 4c. iOS System Term Matching — MANDATORY

| App string | iOS feature | Japanese iOS term |
|---|---|---|
| `addFilter_folder_junk` | iOS Messages "Junk" folder | **迷惑メール** |
| `addFilter_folder_transactions` | iOS Messages "Transactions" folder | **トランザクション** |
| `addFilter_folder_promotions` | iOS Messages "Promotions" folder | **プロモーション** |
| `enableExtension_ready_callToAction` | iOS Settings app | **設定** |
| `autoFilter_ON` / `autoFilter_OFF` | Toggle state | **ON** / **OFF** (English, standard in Japanese iOS) |

---

## 4d. Strings to Keep Untranslated

- `aboutView_twitter` = `a_bd`
- `aboutView_github` = `GitHub`
- `aboutView_appIconCredit` = `Vitali Levit`
- Developer name "Adi Ben-Dahan" in `aboutView_aboutText`
- "Tel Aviv 🇮🇱" in `aboutView_aboutText`
- Brand names: Simply Filter SMS, iCloud, iOS, AppStore, VoiceOver, Dynamic Type
- All emoji — keep exactly as in English

---

## 4e. Length Constraint

Japanese is naturally compact. Loanwords (カタカナ) are slightly longer than English but ideographic characters (漢字) are very dense. Overall translations should be similar length or shorter than English.

Tight UI keys (confirmed within limit):

| Key | English | Limit | Japanese plan |
|---|---|---|---|
| `general_allow` | "Allow" (5) | ≤8 | 許可 (2) ✓ |
| `general_deny` | "Deny" (4) | ≤8 | ブロック (4) ✓ |
| `general_close` | "Close" (5) | ≤8 | 閉じる (3) ✓ |
| `general_edit` | "Edit" (4) | ≤7 | 編集 (2) ✓ |
| `autoFilter_ON` | "ON" (2) | ≤10 | ON (2) ✓ |
| `autoFilter_OFF` | "OFF" (3) | ≤12 | OFF (3) ✓ |
| `addFilter_add` | "Add" (3) | ≤8 | 追加 (2) ✓ |
| `addFilter_addFilter_allow` | "Add Allowed Text" (16) | ≤20 | 許可テキストを追加 (9) ✓ |
| `addFilter_addFilter_deny` | "Add Blocked Text" (16) | ≤20 | ブロックテキストを追加 (11) ✓ |
| `addFilter_match_exact` | "Exact" (5) | ≤10 | 完全一致 (4) ✓ |
| `addFilter_match_contains` | "Contains" (8) | ≤12 | 含む (2) ✓ |
| `addFilter_target_sender` | "Sender" (6) | ≤10 | 送信者 (3) ✓ |
| `addFilter_target_body` | "Body" (4) | ≤10 | 本文 (2) ✓ |
| `whatsNew_continue` | "Continue" (8) | ≤12 | 続ける (3) ✓ |

---

## 4f. Tone & Register

- Friendly and concise — match modern Japanese iOS app style
- Use loanwords (カタカナ) for tech terms where they are standard (フィルター, メッセージ, etc.)
- Use 漢字 for compact everyday concepts (許可, ブロック, 言語, etc.)
- Avoid overly formal keigo (honorific forms) — plain/masu form is appropriate
- Particle usage: を for objects, に for targets, の for possession
