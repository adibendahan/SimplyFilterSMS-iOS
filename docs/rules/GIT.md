# Git Rules

- **Never commit unreviewed changes.** Leave changes uncommitted and report what changed. Commit only when asked, and don't offer to.
- **A commit request is a commit-and-push request**, on every branch (new branches with `-u`).
- **"Commit when done" means one commit at the end.** Commit per step only when each step is reviewed and approved on its own; each such commit still builds and passes tests.
- **Commit messages are one short line** plus the attribution trailer. No body, no bullet lists. Explanations go in the conversation or, when they're rules, in docs.
- **PRs target `develop`, never `master`.** The maintainer updates `master`. Changes to the Community Lists site go in their own branch and PR.
