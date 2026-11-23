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
# or only the named ones. Placing them on the product page is done by hand.
fastlane upload_creative_assets
fastlane upload_creative_assets files:header-21x9-en.png,header-21x9-he.png
```

The search results banner (`search-3x2-<lang>.png`) is one template, `fastlane/creative_assets/source/search-3x2.html`, rendered per language with headless Chrome at 3840 × 2560 (`--allow-file-access-from-files`). Its query takes `lang`, `dir`, and `title`, `private` and `openSource` from the store screenshots' captions file. Its phones show `source/screens/<lang>/`: copies of the iPhone shots 1, 2 and 3 as `home.png`, `ai.png` and `blocked.png`. The same banner shows on every device, each cropping it differently, so keep its layout: a crop shows more or less of the phones.

## Localization

```sh
cd Extras && bartycrouch update
```

## GitHub Pages site

`Extras/github-pages/` deploys to GitHub Pages by itself on a push to `master` that touches it (`.github/workflows/pages.yml`). Changes go to `develop` in their own PR; the maintainer updates `master`. To redeploy without a change:

```sh
gh workflow run pages.yml --ref master
```
