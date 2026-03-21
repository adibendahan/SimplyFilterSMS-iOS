Read the Gmail inbox and help draft replies to support emails.

## Steps

**1. Fetch the inbox**

Use `mcp__gmail__search_emails` with query `in:inbox -from:apple.com -from:accounts.google.com -from:no-reply@google.com` to get all pending support emails.

**2. For each email in the inbox:**

- Read the full thread using `mcp__gmail__read_email` on all message IDs in the thread
- Summarize the issue in one sentence
- Determine if a template applies (see below)
- Propose a response

**3. Template matching**

Templates are in `docs/templates/`. Match based on the user's complaint:

| Issue | Template |
|-------|----------|
| Filtering not working, filters not doing anything, messages getting through | `filtering_not_working_en.html` (English), `filtering_not_working_he_m.html` (Hebrew) |
| User confirms issue is resolved / says it's working now | `all_good_en.html` (English), `all_good_he.html` (Hebrew) |

When using a template:
- Read the template file
- Extract the sender's first name from the `From:` field (e.g. "Daniel Hovet" → "Daniel", "Bill McClatchie" → "Bill")
- Replace `{{NAME}}` in the template with the sender's first name
- Use the HTML body as-is (it already has the deep link and formatting)
- Attach the appropriate screenshot using the `attachments` field (filtering_not_working templates only):
  - English template: attach `docs/templates/settings_en.jpg`
  - Hebrew template: attach `docs/templates/settings_he.jpg`

When no template applies:
- Draft a custom response in the same language as the user's email
- Start with the sender's first name in the greeting (e.g. "Hello Daniel," / "היי דניאל,")
- Match Adi's tone: concise, helpful, direct, no em-dashes, no corporate fluff
- Sign off with `- Adi.`

**4. For each proposed reply, present:**

```
--- EMAIL [n] ---
From: [name]
Subject: [subject]
Summary: [one sentence]
Template: [template name or "custom"]
Language: [EN / HE]

PROPOSED REPLY:
[the reply text or HTML preview]

Options: [s] send  [e] edit  [k] skip
```

Wait for the user to choose before proceeding to the next email. Do not send anything without explicit confirmation.

**5. Sending**

Use `mcp__gmail__send_email` with:
- `mimeType: "multipart/alternative"` for HTML replies
- `threadId` set to the thread ID from the original email (e.g. `19d01cd01775105f`)
- `inReplyTo` set to the RFC 2822 Message-ID header from the last email in the thread — this looks like `<CAXxx...@mail.gmail.com>`, NOT the Gmail API message ID. Use the Gmail API via bash to extract it:
  ```bash
  aws --no-cli-pager || true  # not needed, use curl or gcloud
  # Use this to get the raw Message-ID header:
  npx @gongrzhe/server-gmail-autoauth-mcp  # can't call directly
  ```
  Actually: use `mcp__gmail__read_email` and look for a `Message-ID:` line in the output. If not present, omit `inReplyTo` and rely on `threadId` + matching subject alone — Gmail will still attempt to thread it.
- Subject prefixed with `Re: ` matching the original subject exactly
- Personalized greeting replacing "Hello," or "היי," with the sender's first name
- Include the appropriate screenshot as an attachment (see Template matching above)

## Important

- Never send without the user typing `s` or explicitly confirming
- After sending, mark the original email as read using `mcp__gmail__modify_email` (remove `UNREAD` label)
- After sending an `all_good_*` template reply, also archive the thread using `mcp__gmail__modify_email` (remove `INBOX` label)
- If the inbox is empty, say so and stop
- Process one email at a time, in order
