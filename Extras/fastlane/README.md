fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload the framed screenshots (screenshots/latest/store, or path:screenshots/<version>/store) to App Store Connect

### ios download_metadata

```sh
[bundle exec] fastlane ios download_metadata
```

Download existing metadata from App Store Connect

### ios upload_metadata

```sh
[bundle exec] fastlane ios upload_metadata
```

Upload metadata to App Store Connect

### ios upload_creative_assets

```sh
[bundle exec] fastlane ios upload_creative_assets
```

Upload creative assets (fastlane/creative_assets/*.png, or files:a.png,b.png) to the App Asset Library

### ios place_search_banner

```sh
[bundle exec] fastlane ios place_search_banner
```

Set the uploaded search-3x2-<lang>-<suffix>.png images as a version's search results banner

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
