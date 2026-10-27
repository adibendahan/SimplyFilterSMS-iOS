## 1. Persistence

- [x] 1.1 Store accent as one RGB dictionary default (`accentColorRGB`); empty = system default
- [x] 1.2 Debug `reset()` clears `accentColorRGB`

## 2. Picker screen

- [x] 2.1 Add `Screen.chooseAccentColor` and `ChooseAccentColorView` (`NavigationView`, inline title, X close, full `UIColorPickerViewController`)
- [x] 2.2 Native picker with alpha off; persist as the user picks (not on dismiss); Reset clears storage
- [x] 2.3 Apply `.optionalTint` on the picker sheet from the current custom color

## 3. Home menu and tint

- [x] 3.1 Add `•••` menu item next to About (not Filter Tools); `requestSheet(.chooseAccentColor)`
- [x] 3.2 Apply `.optionalTint` on `AppHomeView`; toolbar `•••` / X pin `.tint(.primary)`

## 4. Copy, tests, docs

- [x] 5.1 Propose EN strings (menu, title, reset); wait for approval, then all 10 locales
- [x] 5.2 Unit-test DefaultsManager accent get/set via `UserDefaults.standard` (`DefaultsManager()`)
- [x] 5.3 Update SCREENS.md / DESIGN.md / CLAUDE.md for the new screen and accent persistence
