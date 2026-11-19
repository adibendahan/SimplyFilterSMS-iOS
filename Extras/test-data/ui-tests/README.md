# UI test data

Served from `s3://grizz-apps-dev/simply-filter-sms/ui-tests/` to the app when it's launched with `-Testing -UITestData` (DEBUG only). World-readable: test data only, never user data. Upload lists before `catalog.json`:

```
aws s3 cp Extras/test-data/ui-tests/ s3://grizz-apps-dev/simply-filter-sms/ui-tests/ --recursive --exclude "README.md" --exclude "catalog.json" --content-type application/json
aws s3 cp Extras/test-data/ui-tests/catalog.json s3://grizz-apps-dev/simply-filter-sms/ui-tests/catalog.json --content-type application/json
```

A test's expectation traces to one record here; change a record and its test together.

Names stay within 28 and authors within 25 (`CommunityListItem.maxNameWidth` / `maxAuthorWidth`, counted by `String.listTextWidth`), or Subscribe from URL refuses the list.

| File | Record | Expected in the Filter Tester |
|---|---|---|
| `ai-en.sfsfilters` | deny, body contains `winner prize`, junk | English on: Junk |
| `ai-en.sfsfilters` | deny, body regex `(?i)verification code \d{6}`, transaction | English on: Transaction |
| `ai-en.sfsfilters` | allow, sender exact `TrustedBank` | English on: Allowed, even with a denied body |
| `ai-he.sfsfilters` | deny, body contains `הלוואה מיידית`, junk | Hebrew on: Junk |
| `community-deny.sfsfilters` (curated "UI Test Promotions") | deny, body contains `crypto bonus`, promotion | list on: Promotion |
| `community-allow.sfsfilters` (curated "UI Test Trusted Senders") | allow, sender exact `SchoolOffice` | list on: Allowed |
| `subscribe.sfsfilters` ("UI Test Subscription", not in the catalog) | 2 deny, 1 allow | Subscribe from URL preview |
| `invalid.sfsfilters` | not a filter list | Subscribe from URL refuses it |
