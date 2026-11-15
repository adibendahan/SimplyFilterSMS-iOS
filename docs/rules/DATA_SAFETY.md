# Data Safety Rules

Reported messages and filter archives are irreplaceable user content. Treat every delete as permanent.

- **Archive, verify, confirm, then delete.** Never delete from DynamoDB (single, batch or wipe) without a verified full-table local archive first, and never without the maintainer's confirmation. See `.claude/skills/review-reports/SKILL.md`.
- **Never delete mid-review.** Dismiss or process locally until a clear is explicitly asked for.
- **Never overwrite an archive with a smaller or empty dump.** Use dated, unique filenames.
- **If an archive write fails or its count doesn't match live data, stop and delete nothing.**
- **Fixing docs or tools is never permission** to run destructive or overwrite commands against live data or archives.
- **Never assume a copy survives** in chat history, tool transcripts or `/tmp`.
- **Never upload user data to the S3 hosting bucket.** It is world-readable (see [AWS_SETUP.md](../AWS_SETUP.md)). Check a bucket's policy before suggesting any upload.
- **AI Filtering list records are decided per entry.** Each record's type, target, matching, case and folder is chosen on its own with a reason. Never encode a fixed per-list mapping (such as sender → regex, body → contains/junk) in skills, docs or tools.
