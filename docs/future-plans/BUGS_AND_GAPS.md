# Bugs and Gaps

Found along the way; each is fixed in its own change.

## App

- **Subscribed Community Lists aren't in subscription order.** In the App Store screenshot run, "Delivery Scam Shield" was subscribed first and "Store Deals" second, yet Store Deals is listed above it. `FilterListManager.communityLists` lists curated URLs, then `fetchCommunityListRecords()` in whatever order the store returns them (not checked whether that order is stable).
- **Curated lists look the same as subscribed ones.** Add a label to curated Community Lists so people can tell them apart from lists they subscribed to by URL.
- **The lists' empty state needs a better look.** Maybe some color on the icon.
- **The menu button is blank on iPhone Duo's outer display in landscape.** Home shows an empty circle where ••• should be, and no status bar.
- **`FilledButton`'s corner radius doesn't match the iOS standard.** A fixed `cornerRadius(8)` in `ButtonStyles.swift`; it looks off next to the system's rounder buttons and the device corners. Shared by the Welcome sheet's Settings button, What's New's Continue, Add Filter and Report Message.
- **Encourage people to allow their first name and address.** A new experience shown the first time someone adds a block or allow filter or turns on a list, inviting them to add allow filters for their first name and address.

## App Store

- **Make the screenshots look nice in the App Store.** Today they're plain captures; design store-ready images around them.
