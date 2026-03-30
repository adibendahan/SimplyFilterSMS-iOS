---
name: review-reports
description: Review user-reported messages from DynamoDB, compile filter suggestions for automatic_filters.json, confirm with user, apply approved changes, and delete processed records.
license: MIT
metadata:
  author: SimplyFilterSMS
  version: "1.0"
---

Review user-reported messages and turn them into automatic filter suggestions.

**Context**
- DynamoDB table: `reported_messages`, region: `us-east-1`
- Record fields: `uuid` (S), `timestamp` (S), `sender` (S), `body` (S), `type` (S — "deny" or "allow")
- Filter file: `automatic_filters.json` (repo root)
- S3 path: `s3://grizz-apps-dev/simply-filter-sms/3.0.0/automatic_filters.json`
- Supported language keys: `en`, `he`, `ar`, `es`, `fr`, `de`, `pt`
- Filter lists per language: `allow_sender`, `allow_body`, `deny_sender`, `deny_body`

**Steps**

1. **Fetch all records**

   ```bash
   aws dynamodb scan --table-name reported_messages --region us-east-1
   ```

   Parse the `Items` array. If the table is empty, inform the user and stop.

2. **Display a summary**

   Show a table of all records:
   ```
   ## Reported Messages (N total)

   | # | Type  | Sender        | Body (truncated)         | Timestamp     |
   |---|-------|---------------|--------------------------|---------------|
   | 1 | deny  | 12345         | Win a free iPhone now... | 2024-01-15    |
   | 2 | allow | Apple         | Your code is 123456      | 2024-01-16    |
   ```

   Convert `timestamp` (ms since epoch) to a readable date for display.

3. **Compile suggestions**

   For each record, generate one or more filter suggestions:

   - Detect the language of the `body` text (use your language knowledge — look at script, common words, and structure).
   - For **deny** reports:
     - If `sender` looks like a keyword (alphabetic, not a phone number): suggest adding to `deny_sender` for the detected language. Prefer body keywords when the sender name is obscure or highly specific — broad body phrases catch more spam.
     - Extract 1–3 distinctive short phrases or keywords from `body` that would be good spam signals. Suggest adding each to `deny_body` for the detected language. Prefer short, distinctive phrases over long ones (3–5 words max).
     - Skip sender if it's just digits (phone number — too specific to be a useful filter).
   - For **allow** reports:
     - If `sender` is a recognizable brand/shortcode name (alphabetic): suggest adding to `allow_sender` for the detected language. Check if a case-insensitive variant is already present before suggesting.
     - Only suggest `allow_body` entries if the body contains a very distinctive trusted phrase.
   - **Domain/keyword collision strategy:** If a `deny_body` keyword could also appear in legitimate messages from a real entity (e.g. a brand name that's also used in phishing), pair it with an `allow_body` entry for the legitimate domain/phrase. The evaluation engine checks allow before deny, so the allow entry protects real messages while the deny entry blocks fakes. Example: adding `"carmeltunnels"` to deny_body while adding `"carmeltunnels.co.il"` (the real domain) to allow_body.
   - Skip suggestions for values already present in `automatic_filters.json`.
   - Group suggestions by language and list type.

4. **Present suggestions for review — one at a time**

   Use **AskUserQuestion** to walk through suggestions **one by one** (not in bulk). For each suggestion, show:
   - Which record it comes from
   - The list it would be added to (e.g. `he.deny_body`)
   - The value
   - A brief rationale

   Present a Yes/Skip choice for each. This lets the user refine or redirect (e.g. "block the sender instead", "what about pairing with an allow entry?") before moving on.

   Display a summary header before starting:
   ```
   ## Filter Suggestions (N total)
   Going through them one by one...
   ```

5. **Apply confirmed suggestions**

   Read `automatic_filters.json`, add each approved entry to the correct language and list, then write the file back. Preserve existing entries and maintain alphabetical sort order within each list.

6. **Upload to S3**

   ```bash
   aws s3 cp automatic_filters.json s3://grizz-apps-dev/simply-filter-sms/3.0.0/automatic_filters.json
   ```

   Confirm success before proceeding to deletion.

7. **Delete processed records**

   For each record whose suggestions were applied (at least one suggestion was approved from that record), delete it from DynamoDB:

   The table has a composite key (`uuid` hash + `timestamp` range). Use Python/boto3 for batch deletion:

   ```python
   import boto3
   client = boto3.client('dynamodb', region_name='us-east-1')
   requests = [
       {"DeleteRequest": {"Key": {"uuid": {"S": uuid}, "timestamp": {"S": ts}}}}
       for uuid, ts in records_to_delete  # list of (uuid, timestamp) tuples
   ]
   # batch_write_item supports max 25 per call
   client.batch_write_item(RequestItems={"reported_messages": requests})
   ```

   Only delete records that had at least one approved suggestion. Records where all suggestions were rejected remain in the table for future review.

   **"We're done" / cleanup:** If the user says they are done reviewing and it's OK to clean up (e.g. "we're done", "delete the rest", "clean up"), use **AskUserQuestion** to confirm: "Delete all remaining records from reported_messages, including those with no approved suggestions?" If confirmed, delete every remaining record in the table.

8. **Show final summary**

   ```
   ## Done

   - Applied N filter entries across M languages
   - Uploaded automatic_filters.json to S3
   - Deleted K records from reported_messages
   - Left L records unprocessed (all suggestions rejected)
   ```

**Guardrails**
- Never add raw phone numbers to any filter list — they are too specific.
- Never add single-character entries or entries shorter than 2 characters.
- Skip entries already present in the JSON (case-insensitive check).
- If AWS CLI commands fail, report the error and stop — do not partially apply changes.
- Upload to S3 must succeed before any DynamoDB deletions.
- If the user approves no suggestions, skip S3 upload and deletions entirely.
