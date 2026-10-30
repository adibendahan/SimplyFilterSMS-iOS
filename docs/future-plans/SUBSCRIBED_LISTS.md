# Subscribed Filter Lists (plan)

Not built yet. Planned for the release after 3.3.

3.3 already built everything this needs (shared format, `name`, catalog, cache keyed by URL, per-list refresh). The next release adds the user-facing part:
- **Subscribe:** the user can subscribe to any list by URL. That means an "Add list" screen (paste a URL, or open an `.sfsfilters` link and choose "Subscribe" instead of "Import"). It shows the list's `name` and filter count before confirming.
- **Manage:** see subscribed lists, turn each on/off, and remove them.
- **UI design is presented for approval before it's built.**

**What a list needs, to be subscribable:**
1. **A public HTTPS link that returns the file itself.** A GitHub raw link works and answers 304 correctly. A "latest release" link also works through its redirects.
2. **A valid `.sfsfilters`,** the same file the app exports, so anyone can build a list in the app, export it and publish it. Bad entries are skipped one by one.
3. **Should have, added by hand in the file:** `name`, shown in the app (otherwise the file name is used), and `revision`, to tell real changes apart.

**How updates are found:**
- The same refresh as AI lists, on the same schedule.
- The server's fingerprint changes whenever the file changes, so publishers just push the new file.
- If a host gives no fingerprint, the app downloads the file on each check and compares the contents.

**App-side rules:**
- **Cap the list size** (number to decide, e.g. 1 MB or 5,000 filters), because the message extension has very little memory.
- **Ignore `forceClearBeforeImport`.** A subscribed list lives in its own section and never touches the user's own filters.
- **Language blocks (`denyLanguage`)** aren't part of the format: they're a preference, not a filter. Lists never apply them.

**What's needed then:**
- A synced Core Data entity for user subscriptions: URL, name and on/off.
- Their sections join the same cache row, keyed by URL. They're kept when the AI catalog changes.
- [ooqua/simply-filter-rules](https://github.com/ooqua/simply-filter-rules) works as-is today: no `revision` (fine), no name (fallback), and `forceClearBeforeImport` ignored.
