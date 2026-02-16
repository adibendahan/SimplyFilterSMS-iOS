## 1. Fix Encoding

- [x] 1.1 In `AutomaticFilterListsResponse.encoded` (`Simply Filter SMS/Services Layer/Responses/AutomaticFilterListsResponse.swift`), create a `JSONEncoder` with `outputFormatting = .sortedKeys` instead of using a default `JSONEncoder()`

## 2. Verify

- [x] 2.1 Run `test_saveCache` in `PersistanceManagerTests` and confirm it passes reliably
- [x] 2.2 Build the project to ensure no compilation errors
