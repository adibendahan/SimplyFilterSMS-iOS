## ADDED Requirements

### Requirement: Processing is requested after the app becomes alive
The system SHALL submit one `BGProcessingTask` request with `requiresNetworkConnectivity` and whose `earliestBeginDate` is at least `kUpdateAutomaticFiltersMinDays` after the request is submitted. The system SHALL register the processing handler during app launch.

#### Scenario: Open the app
- **WHEN** the app finishes launching
- **THEN** a processing task SHALL be registered
- **AND** a processing request SHALL be submitted with `earliestBeginDate` no earlier than 3 days from that moment

#### Scenario: Processing ran
- **WHEN** a processing task completes (success or skip because the cache is fresh)
- **THEN** the system SHALL submit the next processing request with the same 3-day earliest begin rule

### Requirement: Background wake uses the existing cache-age fetch
When iOS delivers the processing task, the system SHALL call `updateAutomaticFiltersIfNeeded()` (fetch from S3 only if the cache is older than `kUpdateAutomaticFiltersMinDays`, then save through the existing cache path). The Message Filter Extension SHALL NOT fetch.

#### Scenario: Cache older than 3 days
- **WHEN** a processing task runs and the automatic filters cache age is 3 or more days
- **THEN** the system SHALL fetch the automatic filter list and update the App Group cache if the payload is new

#### Scenario: Cache still fresh
- **WHEN** a processing task runs and the cache is younger than 3 days
- **THEN** the system SHALL NOT fetch from S3
- **AND** the system SHALL still complete the task and schedule the next request

#### Scenario: Extension evaluates a message
- **WHEN** an unknown SMS arrives after a successful background cache write
- **THEN** the Message Filter Extension SHALL evaluate using the updated cache without using the network
