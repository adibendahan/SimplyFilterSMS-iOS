## Why

Accent is currently the system default (blue). Users should be able to pick their own tint so chips, buttons, and other accent chrome match their taste, without adding a settings screen or putting it in About.

## What Changes

- Home `•••` menu item that presents a native color picker sheet (`UIColorPickerViewController`), not About, not Filter Tools, not a standalone settings screen.
- Persist the chosen color in `DefaultsManager` (`UserDefaults.standard`). Apply `.optionalTint` on Home so chrome using `.tint` follows it.
- Reset control on that same picker sheet to restore system blue.
- Semantic colors stay as they are: deny red, allow green, delete red, dimmed NavigationLink chevrons, smart-filter icon colors.

## Capabilities

### New Capabilities
- `accent-color`: Menu entry, `UIColorPickerViewController` sheet, persisted tint, Home `.optionalTint`, reset to system default.

### Modified Capabilities

## Impact

- **New:** picker sheet (Screen + view, same pattern as Help/About), `DefaultsManager` color key.
- **Modified:** Home menu / tint, `DefaultsManager` / protocol, `Screen`. Not `Simply_Filter_SMSApp` root `.tint`.
- **Unchanged:** hardcoded semantic colors listed above.
- **Localization:** menu item, sheet title, reset — EN first, then all locales after copy approval.
