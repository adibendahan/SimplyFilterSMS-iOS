# Simplified Chinese (zh-Hans) Translation Guide

## Grammar and Addressing

Simplified Chinese has no grammatical gender, noun agreement, or grammatical plural inflection. App nouns such as 过滤器 (filter), 信息 (message), 列表 (list), 发件人 (sender), 语言 (language), 更新 (update), App, and 扩展 (extension) remain unchanged in every context.

Use concise, friendly second-person wording with “你” where addressing the user is useful. Omit the subject in buttons, titles, and short instructions. Use verb-led action labels such as “添加”, “选择”, “打开”, and “轻点”. Simplified Chinese is LTR; iOS handles layout direction without additional code.

## Canonical Terms

| Concept | Canonical term | Notes |
|---|---|---|
| Block / deny | 屏蔽 | Use 已屏蔽 for state labels; 拒绝 only for the generic deny action |
| Allow | 允许 | Use 允许的 for state labels |
| Filter | 过滤器 | Use 过滤 as the verb |
| Sender | 发件人 | Match Apple Messages terminology |
| Message / SMS | 信息 / 短信 | Use 信息 for Messages UI content and 短信 for the transport type |
| Body | 正文 | Message body or filter target |
| Language | 语言 | Use 已屏蔽的语言 for the list state |
| Update | 更新 | Use 更新于 for a timestamp |
| Junk folder/category | 垃圾短信 | Exact label observed in Simplified Chinese iOS Messages |
| Transactions | 交易信息 | Exact label observed in Simplified Chinese iOS Messages |
| Promotions | 推广信息 | Exact label observed in Simplified Chinese iOS Messages |
| Double tap | 轻点两下 | Official VoiceOver action phrase |
| Close / Cancel | 关闭 / 取消 | Keep the actions distinct |
| Settings | 设置 | Official iOS app name |
| On / Off | 开 / 关 | Concise native toggle states |

## iOS System Terms

The following terms were checked against a Simplified Chinese iOS device and must not be paraphrased:

| App context | iOS Simplified Chinese term |
|---|---|
| Messages app | 信息 |
| Unknown Senders | 未知发件人 |
| Screen Unknown Senders | 筛选未知发件人 |
| Text Message Filter | 短信过滤器 |
| Filter Spam | 过滤垃圾信息 |
| Junk category | 垃圾短信 |
| Transactions category | 交易信息 |
| Promotions category | 推广信息 |
| Settings app | 设置 |
| Accessibility: VoiceOver | 旁白 |
| Accessibility: Voice Control | 语音控制 |
| Accessibility: Dynamic Type | 动态字体 |
| Accessibility: Reduce Motion | 减弱动态效果 |

Keep “Simply Filter SMS”, “iCloud”, “iOS”, “App Store”, “GitHub”, “Adi Ben-Dahan”, “Vitali Levit”, and all emoji unchanged. Preserve “Tel Aviv 🇮🇱” semantically as “特拉维夫 🇮🇱”.

## Plurals, Length, and Tone

Chinese uses the CLDR `other` plural category. The strings dictionary may also include explicit `zero` and `one` variants where they improve the displayed sentence. Counts use the measure words 个 for filters and 条 for messages.

Keep labels compact and natural for a native iOS interface. Chinese translations are generally shorter than their English sources. System labels are exempt from shortening because exact recognition is more important than character count. Preserve every `%ld` and `%@` placeholder, Markdown `**bold**` markers, escaped newline, brand name, and emoji. Use a hyphen-minus (`-`), never an em dash.
