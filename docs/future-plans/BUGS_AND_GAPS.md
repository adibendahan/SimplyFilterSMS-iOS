# Bugs and Gaps

Found along the way; each is fixed in its own change.

## App

- **Encourage people to allow their first name and address.** A new experience shown the first time someone adds a block or allow filter or turns on a list, inviting them to add allow filters for their first name and address. Agreed design (mockups: https://claude.ai/artifact/EgSdnWZYGSgEiAj2LMVVZN, screen 6):
  - Trigger: a block or allow filter saved, a list or a Smart Filter turned on. Never while the welcome screen is up; the first session counts.
  - A tappable toast shows immediately (not a nudge waiting for Home); tapping opens the "Stay Reachable" sheet.
  - The toast shows at most twice, in different sessions: if the first is dismissed without a tap, the next trigger in a later session shows it again. Tapping it, or opening the sheet from the menu, ends it for good.
  - Sheet top: green rounded-square icon, large "Stay Reachable" title, the courier/clinic/neighbor copy with **your name** and **your street** bold.
  - Sections of First name, Surname, Street (name only, no number), all optional. English first, then the phone's other language. Each extra section's header is its language picker (change or remove); "Add Language" adds another.
  - Language list: the phone's languages first, then every other language A to Z.
  - Reopen any time from Home's menu: Add Filter › Stay Reachable, after Allow / Block / Language.
  - Each filled field becomes an allow filter, exact (whole word), case-insensitive. A field already allowed, or repeating an earlier field on the sheet, is grayed out and isn't counted; a centered line under its section names it ("Adi is already allowed. Cohen is entered twice.", screen 12). The button reads "Add N Allowed Texts", the app's own term.
  - Status 2026-11-18: built and translated into every language, uncommitted. Checked on screen by the owner; code review pending.
  - Departure: "Already allowed" uses the existing duplicate check, which matches the exact text with any filter type, the same rule Add Filter uses. The sheet reads those texts once when it opens; nothing can add a filter while it is up.

## Screenshots

- **iPad shots sometimes hang on an animation nobody can see.** About one run in ten, Subscribe from URL (shot 09) or Test Your Filters in Arabic (shot 07) stops reporting idle after text is typed: the screen is still, the app says an animation is running, and every later step waits 60 seconds until the shot times out. The retry on restarted simulators passes. The recordings show nothing moving but the cursor. Suspects: the URL field's loading spinner, removed with its row when the preview loads, or the iPad keyboard (both screens have typing; only one has a spinner). Next step: run the shot until it hangs and sample the app from the Mac during the hang.

## App Store

- **Make the screenshots look nice in the App Store.** Today they're plain captures; design store-ready images around them.
