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

### Requirement: AI Filtering icon animation
On iOS 17+, the AI Filtering icon on the home screen SHALL display a periodic lightning bolt animation to communicate that the feature is AI-powered and active.

#### Scenario: Animation plays periodically
- **WHEN** the user views the home screen on iOS 17+
- **AND** "Block All Unknown" is disabled
- **AND** the system "Reduce Motion" accessibility setting is off
- **THEN** the lightning bolt inside the shield icon SHALL flash yellow (double-spark) every 1.5 seconds

#### Scenario: Animation disabled for Block All Unknown
- **WHEN** "Block All Unknown" is enabled
- **THEN** the icon SHALL display a static white bolt on an indigo shield with no animation

#### Scenario: Animation respects Reduce Motion
- **WHEN** the system "Reduce Motion" accessibility setting is enabled
- **THEN** the icon SHALL display a static white bolt on an indigo shield with no animation

#### Scenario: No animation on iOS 16 and below
- **WHEN** the device runs iOS 16 or earlier
- **THEN** the icon SHALL display as a plain indigo shield with no animation

### Requirement: All localizations updated
Every supported locale (en, he, ar, es, fr, pt-BR) SHALL use the translated equivalent of "AI Filtering" for all strings in this spec.

#### Scenario: Non-English locale
- **WHEN** the device is set to a supported non-English locale
- **THEN** all "AI Filtering" labels SHALL appear in the translated form for that locale
- **AND** "AI" SHALL remain as the abbreviation (not translated)
