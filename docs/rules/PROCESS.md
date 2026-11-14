# Process Rules

## Before writing code

- **Placement before code.** For a change you start yourself or a request that's ambiguous, first post which manager or type owns it (managers own policy; `AppManager` only creates and holds managers), the sibling pattern it copies, and the file section it goes in. Wait for approval. Approving a behavior is not approving its placement.
- **An explicit ask is the approval.** "Write X" means write it now. Mention placement choices in the report afterward.
- **Plans are input, not a contract.** Read a plan for its requirements, then design against the repo's own patterns. A plan's mechanisms may carry the defects it was written to fix. When you depart from one, record each departure in the plan.
- **Plans live in `docs/future-plans/`** and are never linked from `CLAUDE.md`. When a plan is done, move what's still true into the real docs and delete the plan.
- **Look up official specs first.** Before designing to a platform constraint (safe areas, asset sizes, crops), fetch and measure the official template or spec. Never estimate it.
- **In plan mode, wait for "ready".** Keep revising the plan and answering questions; don't exit plan mode or ask to implement until told.

## While working

- **Finish the whole request.** Don't do the smallest thing that answers the last message and wait for the rest to be found.
  - A feature follows the project's existing patterns: no parallel coordinator, wrapper type or placeholder "for now".
  - UI matches existing screens: spacing, titles, toolbar, close control, button styles. Propose source-language copy before translating.
  - If an order of operations was given, that order is the spec.
  - Cleanup means hunting: grep for what was removed, delete dead files and unused strings.
  - "Don't touch code" means no code changes at all. If a tool wrote files anyway, say which, and finish or revert.
  - Obey the latest instruction at every call site, not only the one you touched.
  - After two failures on a side quest, say so and offer to drop it.
- **Pin regressions to a change.** If something used to work, it's a regression: find when it last worked (`git log`, `git blame`), diff that path to `HEAD`, name the commit that changed the behavior and fix that. Don't rewrite unrelated code on a theory, and don't ship a speculative fix before reading the history.
- **Prove one case before a batch.** Run a single case, print the raw result, confirm the mechanism end to end, then scale up. When a batch fails, debug a single case instead of theorizing from aggregate errors.
- **Review findings must be real.** If a user can't physically do two things at once, it isn't a race. Existing product behavior isn't a new bug.

## Docs

- **Docs don't describe code.** Docs hold rules and traps the code can't say. Don't add lines narrating behavior. When a change makes a doc line false, delete it rather than rewriting it as a new description.
