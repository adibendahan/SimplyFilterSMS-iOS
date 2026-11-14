# Code Style Rules

- **No explanatory comments in Swift.** No `///` doc comments and no inline `//` explaining a line. Only the file header and `//MARK:` markers. A non-obvious constraint goes in `CLAUDE.md` or `docs/`, or into a well-named property or method (`NetworkStatus.isReconnection(from:)` replaced a four-clause condition and its comment).
  - These stay: closing-brace labels (`} // NavigationView`, `#endif // DEBUG`), two blank lines before a `//MARK:`, and reference data such as the calling-code numbers on `CallingCodeEntry` cases.
- **No dense one-liners.** One decision per line. Compute each input in its own named `let`, store an awaited result in a `let`, then `switch` on it. Don't build an object inline as an argument next to a trailing `$0` closure, and don't use clever tricks (`guard set.insert(x).inserted`) where a plain loop or `first(where:)` reads clearer. A short `guard` with a few plain conditions on one line is fine.
- **One return outside guards.** Early exits only as `guard … else { return }` at the top. Otherwise declare `let result: T`, assign it in `if` / `else` or a `switch`, and return once. `switch` computed properties that return per case are the established exception.
- **Never `@discardableResult`.** Callers that ignore a result write `_ =`, and every `_ =` site is checked for whether ignoring it is correct.
- **Direct calls over notifications.** If the poster can reach a single known receiver (it holds it, or the receiver hands it a closure), call it directly. `NotificationCenter` is for genuine broadcasts with several or unknown listeners.
- **Repo patterns beat invented mechanisms.** Before adding a mechanism, find the sibling feature that already solves that shape of problem and copy it. A new pattern needs approval first. When two existing patterns don't combine, pick the one that covers the case and say so.
- **Match the file layout:** `//MARK: - Initialization -`, `Public API (XProtocol)`, `Private` section order, explicit `self.`, explicit `return`, `[weak self]` in escaping closures.
- **Self-review before presenting.** Grep for an existing helper behind each new loop, filter or lookup, and read the full `git diff` for redundant locals, duplicated logic and leftovers.
- **Localization keys are descriptive** (`whatsNew_freshLook_title`), never numbered (`whatsNew_1_title_1`).
