# Create a Community List

A Community List is a filter list that anyone can publish and anyone using Simply Filter SMS can subscribe to. The app checks it for changes every day, so subscribers always have your latest version.

## 1. Build the list in the app

The easiest way is to build it with Simply Filter SMS itself:

1. Add the filters you want to share (allow and block filters, with any folder, target, matching and case options).
2. Open the menu on the home screen, then **Filter Tools → Export Filters**.
3. Pick the filters to include, tap **Export** and save the `.sfsfilters` file.

Language blocks aren't part of a list: they're a personal preference, not a filter, so the export leaves them out.

## 2. Describe it

Open the file in any text editor and add these fields at the top level, next to `"format"`:

```json
{
  "format": "simply-filter-sms-filters",
  "version": 2,
  "name": "Scam Guard",
  "description": "Blocks loan and prize scams in English.",
  "homepage": "https://github.com/you/scam-guard",
  "locale": "en-US",
  "revision": 1,
  "filters": [ ... ]
}
```

| Field | What it's for |
|---|---|
| `name` | The list's title in the app. Without it, the file name is shown. |
| `description` | One line under the title saying what the list blocks. |
| `homepage` | Your site or repository (an `https` link), shown as a link under the description. |
| `locale` | **Required.** The language and country of the messages it targets, like `en-US` or `he-IL`. |
| `revision` | A number you raise with every change that matters. Optional. |

Keep everything else exactly as exported. Entries the app can't use are skipped one by one, so a typo costs one filter, not the whole list.

## 3. Host it

The list needs **a public HTTPS link that returns the file itself**, not a web page about it.

- **GitHub** works well: commit the file to a public repository and use its raw link (`https://raw.githubusercontent.com/...`), or attach it to a release and use the "latest release" link (`https://github.com/<you>/<repo>/releases/latest/download/<file>.sfsfilters`).
- Any web server works, as long as the link downloads the file over HTTPS.

To publish a change, just replace the file at the same link. The app notices it on its next daily check.

## 4. Share or propose it

- **Share the link.** Anyone can paste it in **Community Lists → Add List by URL**.
- **Propose it for the app's directory.** Open a [Propose a Community List](https://github.com/adibendahan/SimplyFilterSMS-iOS/issues/new?template=propose-community-list.yml) issue. Listed lists appear for every user, so they're reviewed first.
