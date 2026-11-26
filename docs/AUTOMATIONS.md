# Automations

How to run each automation in this repo.

---

## App Store screenshots

Three steps, all from `Extras/`: capture (`screenshots/<version>/`), frame (`screenshots/<version>-store/`), upload.

Needs `hinge` for the Duo (`brew install artemnovichkov/tap/hinge`), Google Chrome for framing, and Apple's device frames in `Extras/local/bezels/`. Captions live in `Extras/fastlane/store_screenshots/captions/<locale>.json`.

```sh
cd Extras

# See the languages, devices, shots (and, for framing, the frame files)
./screenshots.sh --list
./store-screenshots.sh --list

# Check a change on one shot first
./screenshots.sh -l en -d iphone -s 1
./store-screenshots.sh -l en -d iphone -s 1
open screenshots/4.0.0-store/en-US/iphone-01-home.png

# A few languages, reusing the last build
./screenshots.sh --skip-build -l he -l ar

# One device, three simulators at once
./screenshots.sh -d iphone -p 3

# Everything, in the background (a long run); per-run logs are in
# $TMPDIR/simply-filter-sms-screenshots/logs
nohup ./screenshots.sh > "$TMPDIR/screenshots.log" 2>&1 &
tail -f "$TMPDIR/screenshots.log"

# Frame everything captured for the newest version, or a given one
./store-screenshots.sh
./store-screenshots.sh -v 4.0.0

# Upload the framed set (never the raw captures)
fastlane upload_screenshots path:screenshots/4.0.0-store
```

## App Store metadata and assets

From `Extras/`. All lanes use the App Store Connect API key in `~/.appstoreconnect/private_keys/`.

```sh
cd Extras

# Pull the live store text into fastlane/metadata/ (do this before editing it)
fastlane download_metadata

# Push fastlane/metadata/. App Store Connect rejects emoji in What's New
# (release_notes.txt), and one rejected language fails the whole run: nothing saves.
fastlane upload_metadata

# Upload every fastlane/creative_assets/*.png to the App Asset Library,
# or only the named ones. This only stores them; see the next lane.
fastlane upload_creative_assets
fastlane upload_creative_assets files:search-3x2-en-4.0.2.png,search-3x2-he-4.0.2.png

# Make the uploaded search-3x2-<lang>-<suffix>.png images the search banner of
# an app version, in every language (or only the listed App Store locales).
fastlane place_search_banner version:4.0.2 suffix:4.0.2
fastlane place_search_banner version:4.0.2 suffix:4.0.2 locales:en-US,he
```

The App Asset Library skips any file name it already holds (the lane prints `Skipping <name>: already in the library`), so an updated image needs a new name. Uploaded images are only stored there, shown as "Prepare for Submission"; a *placement* is what puts an image on a version's page, one per language.

`place_search_banner` finds the version in App Store Connect (create it there first, as you do for every release), and for each language deletes its current search banner placement and creates one with the new image: Apple allows only one search banner per language, so the old one must go first. If Apple refuses the new image, the lane puts the old one straight back and prints the error. A language whose image is already set is left alone, so running it twice is safe. It changes only the version you name; the live version keeps its banner until the new one is released.

## App Store search banner

The banner shown in App Store search results (`fastlane/creative_assets/search-3x2-<lang>.png`, 3840 × 2560, one per language). It is drawn from one template, `fastlane/creative_assets/source/search-3x2.html`: the tagline and the "Private by design" / "Open source" row from the store screenshots' captions file, over three phones showing the iPhone shots 1, 2 and 3 (Home in the middle, AI Filtering and Block List tilted on the sides). The same banner shows on every device, each cropping it differently, so keep its layout: a crop shows more or less of the phones.

Redo it whenever Home, AI Filtering or the Block List look different in a release. It needs Google Chrome and the new captures from `screenshots.sh`.

```sh
cd Extras

# 1. Draw English only and look at it
./search-banner.sh -l en
open fastlane/creative_assets/search-3x2-en.png

# 2. Draw all 11 languages from the newest captures (or a given version)
./search-banner.sh
./search-banner.sh -v 4.0.2

# 3. Draw all 11, upload them as search-3x2-<lang>-<version>.png,
#    and set them as that version's search banner
./search-banner.sh --upload
```

What each step does:
- **Drawing** copies `screenshots/<version>/<locale>/iphone-01-home.png`, `iphone-02-ai-filtering.png` and `iphone-03-blocked-texts.png` into `fastlane/creative_assets/source/screens/<lang>/` as `home.png`, `ai.png` and `blocked.png`, then has headless Chrome take a picture of the template and saves it over `search-3x2-<lang>.png`. Without `-v` it uses the newest version folder in `screenshots/`.
- **`--upload`** copies each banner to `search-3x2-<lang>-<version>.png` (the library already holds last release's names), runs `fastlane upload_creative_assets` with those files, waits until App Store Connect has processed them, deletes the copies, then runs `fastlane place_search_banner version:<version> suffix:<version>` (above). The version in App Store Connect must exist and have the same number as the captures folder; if they differ, upload with the script and run the lane yourself with the right `version:`.
- **Check it** in App Store Connect on that version's page: each language's search banner shows the new image. It goes live with the version, once Apple approves it.
- **Commit** the changed `search-3x2-*.png` and `source/screens/` files.

## README screenshots

The README shows nine iPhone images from the App Store set in `docs/images/`, at half size (660 × 1434). After framing a new version (`store-screenshots.sh`), copy them over:

```sh
cd "<repo root>"
version=4.0.2
for name in 01-home 02-ai-filtering 03-blocked-texts 04-allowed-texts 05-add-filter \
            06-blocked-languages 07-test-your-filters 08-countries 09-community-lists; do
    sips -z 1434 660 "Extras/screenshots/${version}-store/en-US/iphone-${name}.png" \
        --out "docs/images/${name}.png"
done
git status --short docs/images
```

`sips` is the Mac's built-in image tool; `-z 1434 660` resizes to that height and width. `git status` lists only the images that actually changed; screens that look the same come out byte-identical and don't show up.

## Branches and pull requests

Work goes on a branch off `develop`, and every PR targets `develop` (never `master`).

```sh
# Start: a new branch from an up-to-date develop
git switch develop && git pull --ff-only
git switch -c bugfix/short-name

# Commit and push (the first push of a branch needs -u)
git add <files>
git commit -m "One short line saying what changed."
git push -u origin bugfix/short-name

# Open the PR into develop; it prints the PR's link
gh pr create --base develop --title "Title" --body "- What changed"

# A later push to the same branch updates the open PR. Check for one:
gh pr list --head bugfix/short-name --state all

# Edit an open PR's description
gh pr edit <number> --body-file description.md
```

After the PR is merged on GitHub, clean up:

```sh
git fetch --prune                     # forget branches deleted on GitHub
gh pr view <number> --json state      # must say MERGED
git switch develop && git pull --ff-only
git merge-base --is-ancestor bugfix/short-name origin/develop && echo merged
git branch -d bugfix/short-name       # deletes only if merged; refuses otherwise
git push origin --delete bugfix/short-name
git branch -a                         # should list only develop and master
```

`git branch -d` (lower case) refuses to delete unmerged work; never switch it to `-D` to force it.

## Localization

```sh
cd Extras && bartycrouch update
```

## GitHub Pages site

`Extras/github-pages/` deploys to GitHub Pages by itself on a push to `master` that touches it (`.github/workflows/pages.yml`). Changes go to `develop` in their own PR; the maintainer updates `master`. To redeploy without a change:

```sh
gh workflow run pages.yml --ref master
```
