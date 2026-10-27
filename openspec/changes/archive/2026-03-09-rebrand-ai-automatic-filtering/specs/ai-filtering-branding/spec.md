## ADDED Requirements

### Requirement: AI Filtering screen title
The app SHALL display "AI Filtering" as the navigation title of the filter language list screen (previously "Automatic Filtering").

#### Scenario: Screen title updated
- **WHEN** the user opens the AI Filtering screen
- **THEN** the navigation bar SHALL display "AI Filtering"

### Requirement: AI Filtering explanatory footer
The AI Filtering screen SHALL display a footer that clearly explains the feature uses AI-generated keyword lists.

#### Scenario: Footer text is accurate
- **WHEN** the AI Filtering screen is visible
- **THEN** the footer SHALL read: "AI Filtering uses AI-generated keyword lists to detect spam and route messages to the junk folder. The lists are updated periodically. Your regular filters are still applied when AI Filtering is on."

### Requirement: Notification banner label
The in-app notification banner that appears after a successful AI Filtering update SHALL be labeled "AI Filtering".

#### Scenario: Notification shown after update
- **WHEN** AI Filtering lists are successfully downloaded
- **THEN** the notification banner title SHALL display "AI Filtering"

### Requirement: Error and empty state messages
Error and empty state strings on the AI Filtering screen SHALL reference "AI Filtering" instead of "Automatic Filtering".

#### Scenario: Empty state shown
- **WHEN** filter lists have never been downloaded
- **THEN** the empty state message SHALL reference "AI Filtering lists"

#### Scenario: Error state shown
- **WHEN** filter list download fails
- **THEN** the error message SHALL reference "AI Filtering lists"

### Requirement: Home screen section label
The section on the app home screen that links to AI Filtering SHALL be labeled "AI Filtering".

#### Scenario: Home screen label updated
- **WHEN** the user views the app home screen
- **THEN** the AI Filtering entry SHALL display "AI Filtering" as its label

### Requirement: Help section updated
The in-app help section SHALL reference "AI Filtering" in both the question and answer text.

#### Scenario: Help text updated
- **WHEN** the user opens the Help screen
- **THEN** the automatic filtering help entry SHALL use "AI Filtering" throughout

### Requirement: All localizations updated
Every supported locale (en, he, ar, es, fr, pt-BR) SHALL use the translated equivalent of "AI Filtering" for all strings in this spec.

#### Scenario: Non-English locale
- **WHEN** the device is set to a supported non-English locale
- **THEN** all "AI Filtering" labels SHALL appear in the translated form for that locale
- **AND** "AI" SHALL remain as the abbreviation (not translated)
