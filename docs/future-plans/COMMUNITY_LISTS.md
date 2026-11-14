# Community Lists (plan)

In progress for 4.0.0. "Community Lists" is the user-facing name for lists the user subscribes to.

3.3 already built everything this needs (shared format, `name`, catalog, cache keyed by URL, per-list refresh). The next release adds the user-facing part.

**Decided (2026-11-12):**
- **Home:** one "Community Lists" row, the first row of the Your Filters section (visible in the App Store screenshots), showing the count of lists that are on. It can move under AI Filtering once the directory grows. It pushes a Community Lists screen: one list of all lists, then "Add List by URL", then links to create and to propose a list.
- **No difference between curated and URL-added lists:** every row is a tall row with the list's name (title), its description (subtitle) and its homepage link, plus a toggle. A URL-added list can be removed; a curated one can only be turned off, since it would come back from the catalog.
- **Format additions:** two optional top-level `.sfsfilters` fields, `description` (the row subtitle) and `homepage` (the maintainer's site). The file is the single source for what a row shows.
- **Curated directory:** `community/catalog.json` on S3, next to `ai/catalog.json`, listing only each list's URL. Adding a list needs no app release. It starts with the one list we know, [ooqua/simply-filter-rules](https://github.com/ooqua/simply-filter-rules).
- **Proposing a list:** a GitHub issue form in this repo ("Propose a Community List": URL, name, description, language). The owner reviews it and adds the list to the catalog. The app's "Propose" button opens the form.
- **The guide:** a markdown page in this repo (English only) on building a list (the app's export is the easiest way), the hosting rules below, and how to propose it. The app links to it.
- **Subscribe by URL:** an "Add List by URL" sheet with a URL field and a Paste button. Once a URL is entered, the app downloads the list and previews its row (title, subtitle, homepage), or shows an error if it isn't a valid `.sfsfilters`. "Subscribe" adds it to the screen's list, turned on.
- **Evaluation:** community lists are treated exactly like AI Filtering lists: their allow records join step 3 and their deny records join step 7 of the pipeline (`docs/FRAMEWORK.md`), after the AI lists' records in each step.
- **Manage:** turn each list on or off, and remove the user's own lists.
- **The Community Lists screen design is presented for approval before it's built.**

**Built so far (2026-11-12), screens not started:**
- Format fields, a `CommunityList` entity (model 6: `url`, `isActive`), evaluation, the guide (`docs/COMMUNITY_LISTS_GUIDE.md`) and the issue form. Everything else reuses the AI Filtering code.
- **Departure:** curated lists are `curated-community-list` entries in a new catalog, `4.0.0/catalog.json` (`version` `2`, local copy `ai/catalog-4.0.0.json`), which also lists the AI languages. The entry's `name`, `description` and `homepage` override the file's. 3.3 already downloads and caches them and never applies them. User-added URLs join the same refresh and the same cache row.
- Curated lists start off. Turning one on creates its row, so if it later leaves the catalog it stays as the user's own list.

**Open:**
- **3.3 on the same Apple ID** drops Community Lists from the shared cache row when it refreshes; a 4.0 device restores them on its next refresh, and they don't filter in between.
- A Community List change posts `.filterListsUpdated`, whose toast says "AI Filtering".
- After the dev work: turn `docs/COMMUNITY_LISTS_GUIDE.md` into a designed HTML page hosted on S3, and point `communityListGuideURL` (and the issue form's guide link) at it. `communityListProposalURL` also moves to S3, as a redirect to the issue form.
- Before release: deploy the CloudKit schema (new `CD_CommunityList` record type), bump to 4.0.0, What's New entry.

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

**Notes:**
- [ooqua/simply-filter-rules](https://github.com/ooqua/simply-filter-rules) works as-is today: no `revision` (fine), no name (fallback), and `forceClearBeforeImport` ignored.
