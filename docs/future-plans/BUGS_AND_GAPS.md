# Bugs and Gaps

Found along the way; each is fixed in its own change.

## App

- **Subscribed Community Lists aren't in subscription order.** In the App Store screenshot run, "Delivery Scam Shield" was subscribed first and "Store Deals" second, yet Store Deals is listed above it. `FilterListManager.communityLists` lists curated URLs, then `fetchCommunityListRecords()` in whatever order the store returns them (not checked whether that order is stable).
- **Curated lists look the same as subscribed ones.** Add a label to curated Community Lists so people can tell them apart from lists they subscribed to by URL.
- **The lists' empty state needs a better look.** Maybe some color on the icon.
