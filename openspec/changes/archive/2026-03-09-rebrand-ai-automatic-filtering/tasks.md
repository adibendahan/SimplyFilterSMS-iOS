## 1. English strings (en.lproj)

- [x] 1.1 Update `autoFilter_title` value to "AI Filtering"
- [x] 1.2 Update `autoFilter_empty` to reference "AI Filtering lists" instead of "Automatic Filtering lists"
- [x] 1.3 Update `autoFilter_error` to reference "AI Filtering lists" instead of "Automatic Filtering lists"
- [x] 1.4 Update `notification_automatic_title` value to "AI Filtering"
- [x] 1.5 Update `help_automaticFiltering_question` to "How does AI Filtering work?"
- [x] 1.6 Update `help_automaticFiltering` to: "AI Filtering uses AI-generated keyword lists to detect spam and route messages to the junk folder. The lists are updated periodically. Your regular filters are still applied when AI Filtering is on."

## 2. Hebrew strings (he.lproj)

- [x] 2.1 Update `autoFilter_title` to the Hebrew equivalent of "AI Filtering"
- [x] 2.2 Update `autoFilter_empty` to reference "AI Filtering" instead of "סינון אוטומטי"
- [x] 2.3 Update `autoFilter_error` to reference "AI Filtering" instead of "סינון אוטומטי"
- [x] 2.4 Update `notification_automatic_title` to the Hebrew equivalent of "AI Filtering"
- [x] 2.5 Update `help_automaticFiltering_question` to the Hebrew equivalent of "How does AI Filtering work?"
- [x] 2.6 Update `help_automaticFiltering` to the Hebrew equivalent of the new English text (AI-generated lists)

## 3. Arabic strings (ar.lproj)

- [x] 3.1 Update `autoFilter_title` to the Arabic equivalent of "AI Filtering"
- [x] 3.2 Update `autoFilter_empty` to reference "AI Filtering" instead of "التصفية التلقائية"
- [x] 3.3 Update `autoFilter_error` to reference "AI Filtering" instead of "التصفية التلقائية"
- [x] 3.4 Update `notification_automatic_title` to the Arabic equivalent of "AI Filtering"
- [x] 3.5 Update `help_automaticFiltering_question` and `help_automaticFiltering` to Arabic equivalent of new text

## 4. Spanish strings (es.lproj)

- [x] 4.1 Update `autoFilter_title` to the Spanish equivalent of "AI Filtering"
- [x] 4.2 Update `autoFilter_empty` to reference "AI Filtering" instead of "Filtrado automático"
- [x] 4.3 Update `autoFilter_error` to reference "AI Filtering" instead of "Filtrado automático"
- [x] 4.4 Update `notification_automatic_title` to the Spanish equivalent of "AI Filtering"
- [x] 4.5 Update `help_automaticFiltering_question` and `help_automaticFiltering` to Spanish equivalent of new text

## 5. French strings (fr.lproj)

- [x] 5.1 Update `autoFilter_title` to the French equivalent of "AI Filtering"
- [x] 5.2 Update `autoFilter_empty` to reference "AI Filtering" instead of "Filtrage automatique"
- [x] 5.3 Update `autoFilter_error` to reference "AI Filtering" instead of "Filtrage automatique"
- [x] 5.4 Update `notification_automatic_title` to the French equivalent of "AI Filtering"
- [x] 5.5 Update `help_automaticFiltering_question` and `help_automaticFiltering` to French equivalent of new text

## 6. Portuguese strings (pt-BR.lproj)

- [x] 6.1 Update `autoFilter_title` to the Portuguese equivalent of "AI Filtering"
- [x] 6.2 Update `autoFilter_empty` to reference "AI Filtering" instead of "Filtro Automático"
- [x] 6.3 Update `autoFilter_error` to reference "AI Filtering" instead of "Filtro Automático"
- [x] 6.4 Update `notification_automatic_title` to the Portuguese equivalent of "AI Filtering"
- [x] 6.5 Update `help_automaticFiltering_question` and `help_automaticFiltering` to Portuguese equivalent of new text

## 7. Icon animation (iOS 17+)

- [x] 7.1 Add `@State private var shieldGlintTrigger` and `@Environment(\.accessibilityReduceMotion)` to `AppHomeView`
- [x] 7.2 Replace plain `bolt.shield.fill` image with `phaseAnimator([0, 1, 2, 1, 0], trigger:)` double-spark animation on iOS 17+
- [x] 7.3 Gate animation on `!isAllUnknownFilteringOn && !reduceMotion`; show static palette icon otherwise
- [x] 7.4 Add `.task` sleep loop to fire trigger every 1.5 seconds
- [x] 7.5 Confirm animation stops and resets cleanly when Block All Unknown is toggled

## 8. Verify

- [x] 8.1 Grep for remaining "Automatic Filtering" in all `.strings` files and confirm zero matches
- [x] 8.2 Grep for remaining "Automatic Filtering" in all `.swift` files and confirm zero user-facing matches (internal identifiers are expected)
- [x] 8.3 Build the app and run on simulator — confirm AI Filtering screen title, footer text, notification banner, and icon animation all work correctly
