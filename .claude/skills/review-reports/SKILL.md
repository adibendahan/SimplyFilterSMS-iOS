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
     - If `sender` looks like a keyword (alphabetic, not a phone number): suggest adding to `deny_sender` for the detected language.
     - Extract 1–3 distinctive short phrases or keywords from `body` that would be good spam signals. Suggest adding each to `deny_body` for the detected language.
     - Skip sender if it's just digits (phone number — too specific to be a useful filter).
   - For **allow** reports:
     - If `sender` is a recognizable brand/shortcode name (alphabetic): suggest adding to `allow_sender` for the detected language.
     - Only suggest `allow_body` entries if the body contains a very distinctive trusted phrase.
   - Skip suggestions for values already present in `automatic_filters.json`.
   - Group suggestions by language and list type.

4. **Present suggestions for review**

   Display all suggestions in a structured format:

   ```
   ## Filter Suggestions

   ### English (en)
   **deny_body** (from record #1, #3):
   - "free iphone"
   - "claim your prize"
   - "0% risk"

   **allow_sender** (from record #2):
   - "Apple"

   ### Hebrew (he)
   **deny_body** (from record #5):
   - "זכית"
   ```

   Then use **AskUserQuestion** to ask: "Which suggestions would you like to apply? Reply with 'all', specific numbers/ranges (e.g. '1,3,5-7'), or 'none'. You can also edit individual entries."

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
