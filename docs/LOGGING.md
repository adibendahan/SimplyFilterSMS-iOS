# Logging

The log alone must tell the whole story of what happened, with no value or decision missing, and without noise. Every new line of code that makes a decision, changes state, fails, or handles a user action logs it by these rules.

## API

- Only `Log.debug`, `Log.error` and `Log.fault` (`Shared with Extension/Log.swift`, compiled into the app and both extensions). Never `Logger`, `print`, or another level.
- `debug`: the story. Not persisted; everything shown in every build, user data included. A `debug` line can only be read live, from an unlocked device connected to a Mac, so whoever reads it already holds the device and its messages; hiding the data would protect nothing.
- `error`: a handled real failure. Pass the error as `error:`.
- `fault`: an impossible state.
- `error`/`fault` persist to disk and sysdiagnose, so user data in them goes through `\(private: …)`: shown in DEBUG, `<private>` in release.
- User data is only filter text, SMS sender and SMS body. Everything else (errors, userInfo, URLs, ids, file names) is public.

## Line shape

`[Type.method:line] <what happened>, <key: value>, <key: value> → <outcome>`

- `Log` adds the `[Type.method:line]` prefix, with the call site's line number. Never type one.
- A lowercase fragment, no trailing period.
- Every interpolated value is a value: text, enums, numbers, bools and dates alike. `Log` quotes and escapes it (`'abc'`, `'3'`, `'true'`). `nil` prints bare. A list is one value: `'[en, he]'`.
- An interpolated value is a `String`, integer, `Bool`, `Double`, `Date` (local time), `URL`, `UUID` or `CaseIterable` enum, or an array or set of `String` or `CaseIterable` values. Anything else doesn't compile: log the field that matters, never the object, and never wrap it in `String(describing:)`. A `TimeInterval` goes through `\(duration: …)`.
- Never hand-write a quoted value. Approved exceptions, fixed words in a value position: `FlowManager.nextScreen`'s `reason:`, `TipJarManager`'s transaction `source:`, and the evaluator's `allowed: '[]'`. Any new exception needs the owner's explicit approval.
- Pairs are `key: value`, separated by `, `. Never `=`, `|` or brackets between pairs.
- Outcome after ` → `: fixed words bare (`→ no match`, `→ skipped`), values interpolated (`→ \(action)`). Use `\(matched: Bool)` for `match` / `no match`. A change reads `\(old) → \(new)`.
- An error line says what failed. `Log` appends `error domain: …, code: …, description: …, userInfo: …`.
- Never: decoration (`━━━━`, `▶▶▶`), ALL CAPS, em dashes, indentation, `[tags]`.

```swift
Log.debug("matching changed, text: \(filter.text), matching: \(oldMatching) → \(newMatching)")
Log.debug("filter checked, type: \(type), text: \(text), target: \(target) → \(matched: matched)")
Log.error("invalid regex, text: \(private: text) → no match", error: error)
```

## Keep or drop

Every line answers these. A line earns its place by telling the reader something no other line does; never cut information no other line carries.

- What question does it answer for someone reading the log later? None: drop.
- Does another line already carry the same values, or does the next line imply it? Drop.
- Does it show a decision and its reason, including why something did not happen? Keep.
- Without it, could the reader tell which branch ran? If not, keep.
- Does it carry every input the decision used (values, thresholds, settings)? If not, add them.
- A state change shows before → after.
- Frequency: per render, frame or scroll, never. Per user action, message, request or lifecycle event is fine.
- Leftover instrumentation from chasing one bug: drop.
- A read logs only if it explains a later decision.
- Right level: error is a handled real failure, fault an impossible state.
- User data in error/fault without `private:`: fix.
