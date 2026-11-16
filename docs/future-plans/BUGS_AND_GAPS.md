# Bugs and Gaps

Found along the way; each is fixed in its own change.

## App

- **Subscribed Community Lists aren't in subscription order.** In the App Store screenshot run, "Delivery Scam Shield" was subscribed first and "Store Deals" second, yet Store Deals is listed above it. `FilterListManager.communityLists` lists curated URLs, then `fetchCommunityListRecords()` in whatever order the store returns them (not checked whether that order is stable).
- **The lists' empty state needs a better look.** Maybe some color on the icon.
- **Encourage people to allow their first name and address.** A new experience shown the first time someone adds a block or allow filter or turns on a list, inviting them to add allow filters for their first name and address.

## App Store

- **Make the screenshots look nice in the App Store.** Today they're plain captures; design store-ready images around them.
