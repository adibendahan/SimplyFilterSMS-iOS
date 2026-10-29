---
name: review-reports
description: Review user-reported messages from DynamoDB, compile filter suggestions for the AI Filtering lists (ai/<lang>.sfsfilters), confirm with user, apply approved changes. Always archive raw reports locally before any DynamoDB deletion.
license: MIT
metadata:
  author: SimplyFilterSMS
  version: "2.0"
---

Review user-reported messages and turn them into automatic filter suggestions.

**Context**
- DynamoDB table: `reported_messages`, region: `us-east-1`
- Record fields: `uuid` (S), `timestamp` (S), `sender` (S), `body` (S), `type` (S — "deny" or "allow")
- Filter lists: `ai/<lang>.sfsfilters` (repo root, gitignored), one per language, listed in `ai/catalog.json`
- S3 path: `s3://grizz-apps-dev/simply-filter-sms/3.3.0/ai/`
- `3.0.0/automatic_filters.json` is frozen for apps 3.0–3.2. **Never edit or upload it.**
- Supported languages: the `language` values in `ai/catalog.json` — always target the matching language
- Record shapes and file rules: see **List files** below
- Batch helper: `.claude/skills/review-reports/report_batch.py`
- Python venv: `.claude/skills/review-reports/.venv/` (run `python3 -m venv .venv && .venv/bin/pip install boto3` if missing)
- Archive path: `data/reported_messages_archive.json` (+ dated copy). Gitignored — contains user SMS content.

## CRITICAL — no irreversible deletes without archive

**DynamoDB deletes are permanent.** Point-in-time recovery may be disabled. Never treat the table as disposable. Reported messages are irreplaceable user content.

Also mirrored in `.cursor/rules/never-destroy-user-data.mdc` (always-apply).

**Hard rules (non-negotiable):**
1. **Session start with any table data:** run `archive` first; print path, count, size; keep dated unique snapshots.
2. **Before the first DynamoDB delete of a session**, export the **entire** current table to a local JSON archive and verify the file.
3. **Never delete mid-batch during review.** Mark records processed/dismissed in local state only until the user explicitly asks to clear the table (or finish cleanup). During review: **zero** DynamoDB deletes.
4. Before any bulk clear / table wipe: confirm the archive file exists, `count` in the archive matches a fresh DynamoDB scan, and get explicit user confirmation (show path + count).
5. If archive write fails or counts don't match — **STOP. Do not delete anything.**
6. **Never overwrite a good archive** with a smaller/empty scan. Dated files must use unique timestamps.
7. **Never** treat "fixing docs/tools" as permission to run destructive or archive-overwrite commands against live data.
8. **Never** assume chat history, tool transcripts, or `/tmp` will retain recoverable copies — write durable local files.
9. When in doubt, ask the user before any destructive action. Prefer keeping uncertain rows in DynamoDB over deleting them.

### Archive format

```json
{
  "exported_at": "ISO-8601",
  "source_table": "reported_messages",
  "region": "us-east-1",
  "count": N,
  "records": [
    {"uuid": "...", "timestamp": "...", "sender": "...", "body": "...", "type": "deny|allow"}
  ]
}
```

```bash
PY=".claude/skills/review-reports/.venv/bin/python"
SCRIPT=".claude/skills/review-reports/report_batch.py"

# Full-table archive (required before any deletes)
$PY $SCRIPT archive
# → writes data/reported_messages_archive_<timestamp>.json AND data/reported_messages_archive.json
```

After archiving, print: path, record count, file size. Compare count to live table.

**Archive safety:** `archive` refuses to overwrite a larger existing `reported_messages_archive.json` with a smaller/empty scan (unless `--force`). Dated snapshots always use a unique timestamp filename so prior dumps are not clobbered.

## First-time setup (new Mac)

1. **Install AWS CLI**
   ```bash
   brew install awscli
   aws --version
   ```

2. **Configure AWS credentials**
   ```bash
   aws configure
   ```
   Region `us-east-1`, output `json`. Or copy `~/.aws/credentials` and `~/.aws/config` from another Mac.

3. **Verify access**
   ```bash
   aws dynamodb describe-table --table-name reported_messages --region us-east-1
   aws s3 ls s3://grizz-apps-dev/simply-filter-sms/3.3.0/ai/
   ```

4. **Set up Python venv**
   ```bash
   cd ".claude/skills/review-reports"
   python3 -m venv .venv
   .venv/bin/pip install boto3
   ```

Required IAM: `dynamodb:Scan`, `dynamodb:BatchWriteItem` on `reported_messages`; `s3:PutObject` on `grizz-apps-dev/simply-filter-sms/*`.

## Pagination workflow (large backlogs)

**Helper commands:**
```bash
PY=".claude/skills/review-reports/.venv/bin/python"
SCRIPT=".claude/skills/review-reports/report_batch.py"

$PY $SCRIPT count
$PY $SCRIPT archive          # full dump — do this at session start if deletes may happen later
$PY $SCRIPT fetch --batch-size 100
$PY $SCRIPT fetch --batch-size 100 --refresh
```

Local state: `.claude/skills/review-reports/.review-state.json` (gitignored). Tracks cache + dismissed/processed keys so they don't reappear in `fetch`.

**Default batch size:** **100** (user may ask for larger/smaller).

**Session start (if the table has records):**
1. `count --refresh` (or `count` after refresh fetch).
2. Run **`archive`** immediately and confirm the file on disk — even if you plan to only dismiss locally during review. This protects against accidental deletes later.
3. Tell the user: archive path + count.

**Known recurring patterns** (auto-handle; don't re-ask unless unsure):
- **Shabbat candle spam** → `he` deny body: `נרות שבת` / `הדליקי נרות`
- **US political SMS** → unique tracking domains, not vague footers like `Stop to End`
- **Tree-service cold outreach** → `local tree service`; `Free quote` may already exist
- **Religious chain spam** → distinctive phrases/domains
- **Israeli debt/gov phish** → shortener + distinctive Hebrew phrase; don't block real org names alone
- **Legit brands reported as deny** → do **not** deny the brand; promo phrase / domain only
- **`amzn.to` / AWS default hostnames** → too broad; never add
- **Phone senders / test / bare "Stop"** → dismiss locally
- **Israeli election spam** → party + politician names in **Hebrew and Latin** as `he` deny records

**Per-batch loop:**

1. `fetch --batch-size 100`
2. Summary table for the batch.
3. Compile suggestions (all languages; dedup vs existing + shorter-filter rule).
4. Bulk Yes/Skip table (one row per proposed record: text, target, matching, case, folder, hits, reason); user replies `all` / `all except …`.
5. Apply approved entries to the local `ai/<lang>.sfsfilters` files only — **no S3 yet**.
6. **Local cleanup only:**
   - Processed (filter applied or already covered) → mark dismissed/processed in local state (**do not DynamoDB-delete**)
   - Skipped / noise → dismiss locally
   ```bash
   $PY $SCRIPT dismiss --file /tmp/keys-to-dismiss.json
   ```
7. Repeat until pending is 0 or user stops.

**End of session:**
1. Bump `revision` (+1) and set `exportedAt` (now, ISO-8601 UTC) once in each list file changed this session.
2. Upload **only** when the user asks (`upload` / `finish` with upload), and only the changed files:
   ```bash
   aws s3 cp ai/he.sfsfilters s3://grizz-apps-dev/simply-filter-sms/3.3.0/ai/he.sfsfilters --content-type application/json
   ```
   Upload `ai/catalog.json` too only if it changed. The bucket is world-readable: never upload anything else.
3. **Table cleanup / wipe** — only when the user explicitly asks to clear DynamoDB:
   - Re-run `archive` (or confirm existing archive is complete and current).
   - Verify archive `count` == live table count.
   - Ask: "Archive has N records at `data/…`. Delete all N from DynamoDB?"
   - Only then run deletes (batch helper or boto3, max 25 per `batch_write_item`).
   - Re-scan to confirm table is empty.

## Compile suggestions

- Route to the correct language file (`ai/<lang>.sfsfilters`).
- Layered suggestions: specific domain/sender **plus** a broader but non-vague phrase.
- Don't deny legitimate business names; prefer promo/domain signals.
- Each suggestion is a full record (target, matching, case, folder) chosen for that entry, with a reason. See **List files**.
- Dedup: skip a proposal an existing record already catches (same text, or a broader existing record that matches it).
- Prefer bulk tables over one-by-one.

## List files

Each `ai/<lang>.sfsfilters` is a `.sfsfilters` payload (`format`, `version: 1`, `name`, `revision`, `exportedAt`, `appVersion`, `filters`). Every record is decided on its own — there is no default shape:

- **type:** `allow` / `deny`
- **target:** `sender` / `body` / `all`
- **matching:** `contains` / `exact` (whole word) / `regex`
- **case:** `insensitive` / `sensitive` (omitted for `regex`, which sets its own case with `(?i)`)
- **folder:** `junk` / `promotion` / `transaction` (deny only; omitted for `allow`)

For each proposed record, the suggestions table shows the record, the archive hits it would catch, and a reason for the choice. Known trade-offs from earlier measurements:
- whole-word `exact` on body costs recall and breaks CJK and Hebrew
- a sender name needs an exact, case-insensitive match (a regex or `exact`), not `contains`

Never write placeholder fields. Write with `json.dump(payload, f, ensure_ascii=False, indent=2, sort_keys=True)` (no trailing newline), so diffs stay small. Bump `revision` once per session per changed file (see **End of session**).

## Guardrails

- **Archive before any DynamoDB delete. No exceptions.**
- Never delete mid-review; dismiss/process locally until explicit cleanup.
- Never add raw phone numbers or entries shorter than 2 characters.
- Skip entries already present (case-insensitive) or redundant vs a shorter existing filter.
- If AWS commands fail, stop — do not partially destroy data.
- Do **not** upload to S3 after every batch — only when the user asks.
- Never edit or upload `3.0.0/automatic_filters.json`.
- If the user approves no suggestions, still never delete without archive + confirmation.
