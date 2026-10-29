# Extensions

The constraints and traps of the two app extensions. Which files each target compiles is in `CLAUDE.md`; changing an existing file's target membership is done by hand in Xcode.

---

## Message Filter Extension

iOS calls it for every SMS from a sender not in Contacts; it returns allow, junk, transaction or promotion.

- **Offline only.** It never defers to the network (`ILNetworkResponse`); all data comes from the shared store. Lists are downloaded by the app.
- **No `AppManager`.** It builds its own `MessageEvaluationManager()`, with its own logger (category `extension`).
- **Read-only, synchronous store.** It opens the App Group store read-only and loads it synchronously in `init`. If the load fails, every message is allowed (`storeUnavailable`) rather than evaluated against an empty store.
- **Memory is tight.** The AI Filtering cache row is read once per message, and only the lists whose language is on are decoded (`ActiveFilterLists`).
- The extension target also compiles `PersistanceManagerProtocol` so the shared `MessageEvaluationManager` type-checks; it only ever uses the owned-store path.

---

## Reporting Extension

The "Report Messages" sheet in iOS Messages (long-press → Report): it shows the sender and bodies and offers Junk, Junk & Block Sender, or Not Junk. Enabled in Settings > Phone > SMS/Call Reporting.

- **It can't make network calls.** The sandbox blocks them. It returns the choice in `userInfo` (`sender`, `bodies`, `type`), and iOS itself POSTs it to `https://api.ben-dahan.com/report`.
- **iOS only sends that POST from TestFlight and App Store builds,** never from a local development install. Test reporting on TestFlight.
- **Only one reporting extension can be on per device,** and a carrier app may already hold the slot.
- **A report can hold several messages** from the same sender; all bodies are sent as one array.
- **No Core Data.** Shared code that touches Core Data is wrapped in `#if !REPORTING_EXTENSION`.

The backend (API Gateway, Lambda, DynamoDB) is in [AWS_SETUP.md](AWS_SETUP.md).
