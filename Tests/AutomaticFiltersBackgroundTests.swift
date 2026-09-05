//
//  AutomaticFiltersBackgroundTests.swift
//  Tests
//

import Foundation
import XCTest
import UserNotifications
@testable import Simply_Filter_SMS

class AutomaticFiltersBackgroundTests: XCTestCase {

    private var automaticFilterManager: mock_AutomaticFilterManager!
    private var defaultsManager: mock_DefaultsManager!
    private var notifications: mock_UserNotificationCenterService!
    private var isAutomaticFilteringOn = false
    private var testSubject: SchedulingManager!

    override func setUp() {
        super.setUp()
        self.isAutomaticFilteringOn = false
        self.automaticFilterManager = mock_AutomaticFilterManager()
        self.defaultsManager = mock_DefaultsManager()
        self.notifications = mock_UserNotificationCenterService()
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { [unowned self] in
            return self.isAutomaticFilteringOn
        }
        self.defaultsManager.sessionCounter = 1
        self.testSubject = SchedulingManager(automaticFilterManager: self.automaticFilterManager,
                                             defaultsManager: self.defaultsManager,
                                             userNotificationCenterService: self.notifications)
    }

    override func tearDown() {
        self.testSubject = nil
        self.notifications = nil
        self.defaultsManager = nil
        self.automaticFilterManager = nil
        super.tearDown()
    }

    func test_syncInactivityReminder_aiOnAndAllowed_schedules() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .authorized

        self.testSubject.syncInactivityReminder()

        XCTAssertEqual(self.notifications.removePendingCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 1)
        XCTAssertEqual(self.notifications.lastAddedRequest?.identifier, kAutomaticFiltersInactivityNotificationId)
        let trigger = self.notifications.lastAddedRequest?.trigger as? UNCalendarNotificationTrigger
        XCTAssertEqual(trigger?.repeats, true)
        XCTAssertNotNil(trigger?.dateComponents.day)
        XCTAssertEqual(trigger?.dateComponents.hour, 19)
        XCTAssertEqual(trigger?.dateComponents.minute, 0)
    }

    func test_syncInactivityReminder_aiOff_cancelsOnly() {
        self.isAutomaticFilteringOn = false
        self.notifications.authorizationStatusValue = .authorized

        self.testSubject.syncInactivityReminder()

        XCTAssertEqual(self.notifications.removePendingCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 0)
    }

    func test_syncInactivityReminder_denied_doesNotSchedule() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .denied

        self.testSubject.syncInactivityReminder()

        XCTAssertEqual(self.notifications.removePendingCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 0)
    }

    func test_syncInactivityReminder_aiTurnsOffBeforeAuthCallback_doesNotSchedule() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .authorized
        self.notifications.authorizationStatusDelay = {
            self.isAutomaticFilteringOn = false
        }

        self.testSubject.syncInactivityReminder()

        XCTAssertEqual(self.notifications.removePendingCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 0)
    }

    func test_cancelInactivityReminder_removesPending() {
        self.testSubject.cancelInactivityReminder()

        XCTAssertEqual(self.notifications.removePendingCounter, 1)
        XCTAssertEqual(self.notifications.lastRemovedIdentifiers, [kAutomaticFiltersInactivityNotificationId])
        XCTAssertEqual(self.notifications.addCounter, 0)
    }

    func test_filtersStateChanged_aiOff_cancelsReminder() {
        self.isAutomaticFilteringOn = false
        self.notifications.resetCounters()

        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)

        XCTAssertEqual(self.notifications.removePendingCounter, 1)
    }

    func test_filtersStateChanged_aiOn_doesNotCancel() {
        self.isAutomaticFilteringOn = true
        self.notifications.resetCounters()

        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)

        XCTAssertEqual(self.notifications.removePendingCounter, 0)
    }

    func test_requestInactivityNotificationAuthorization_denied_recordsDecline() {
        self.notifications.requestAlertAuthorizationGranted = false
        let expectation = self.expectation(description: "auth")

        self.testSubject.requestInactivityNotificationAuthorization { granted in
            XCTAssertFalse(granted)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.notifications.requestAlertAuthorizationCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 0)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationAskCount, 1)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclinedSession, 1)
    }

    func test_requestInactivityNotificationAuthorization_granted_marksGrantedAndSchedules() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.notifications.requestAlertAuthorizationGranted = true
        let expectation = self.expectation(description: "auth")

        self.testSubject.requestInactivityNotificationAuthorization { granted in
            XCTAssertTrue(granted)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.notifications.requestAlertAuthorizationCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 1)
        XCTAssertTrue(self.defaultsManager.inactivityNotificationWasGranted)
    }

    func test_updateAutomaticFilters_doesNotTouchReminder() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .authorized
        self.testSubject.syncInactivityReminder()
        self.notifications.resetCounters()

        await self.automaticFilterManager.updateAutomaticFiltersIfNeeded()

        XCTAssertEqual(self.automaticFilterManager.updateAutomaticFiltersIfNeededCounter, 1)
        XCTAssertEqual(self.notifications.removePendingCounter, 0)
        XCTAssertEqual(self.notifications.addCounter, 0)
    }

    func test_shouldShow_firstAsk_true() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined

        let shouldShow = await self.testSubject.shouldShowInactivityNotification()

        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.inactivityNotificationDismissTitle, "inactivityNotification_notNow"~)
    }

    func test_shouldShow_aiOff_false() async {
        self.isAutomaticFilteringOn = false
        self.notifications.authorizationStatusValue = .notDetermined

        let shouldShow = await self.testSubject.shouldShowInactivityNotification()

        XCTAssertFalse(shouldShow)
    }

    func test_shouldShow_alreadyAuthorized_marksGrantedAndFalse() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .authorized

        let shouldShow = await self.testSubject.shouldShowInactivityNotification()

        XCTAssertFalse(shouldShow)
        XCTAssertTrue(self.defaultsManager.inactivityNotificationWasGranted)
        XCTAssertEqual(self.notifications.addCounter, 1)
    }

    func test_shouldShow_gapBlocksUntilThreeSessions() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.inactivityNotificationAskCount = 1
        self.defaultsManager.inactivityNotificationDeclinedSession = 1
        self.defaultsManager.sessionCounter = 3

        let blocked = await self.testSubject.shouldShowInactivityNotification()
        XCTAssertFalse(blocked)

        self.defaultsManager.sessionCounter = 4
        let shouldShow = await self.testSubject.shouldShowInactivityNotification()
        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.inactivityNotificationDismissTitle, "inactivityNotification_notNow"~)
    }

    func test_shouldShow_thirdAsk_stopAskingTitle() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.inactivityNotificationAskCount = 2
        self.defaultsManager.inactivityNotificationDeclinedSession = 1
        self.defaultsManager.sessionCounter = 10

        let shouldShow = await self.testSubject.shouldShowInactivityNotification()
        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.inactivityNotificationDismissTitle, "inactivityNotification_stopAsking"~)
    }

    func test_shouldShow_afterMaxAsks_false() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.inactivityNotificationAskCount = 3
        self.defaultsManager.sessionCounter = 20

        let shouldShow = await self.testSubject.shouldShowInactivityNotification()
        XCTAssertFalse(shouldShow)
    }

    func test_recordDecline_notFinal_incrementsAndStoresSession() {
        self.defaultsManager.sessionCounter = 5
        self.testSubject.recordInactivityNotificationDecline()
        XCTAssertEqual(self.defaultsManager.inactivityNotificationAskCount, 1)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclinedSession, 5)
    }

    func test_recordDecline_final_setsMaxAsks() {
        self.defaultsManager.inactivityNotificationAskCount = 2
        self.testSubject.recordInactivityNotificationDecline()
        XCTAssertEqual(self.defaultsManager.inactivityNotificationAskCount, 3)
    }

    func test_shouldShow_revoke_resetsAndShowsFirstAsk() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .denied
        self.defaultsManager.inactivityNotificationWasGranted = true
        self.defaultsManager.inactivityNotificationAskCount = 3
        self.defaultsManager.inactivityNotificationDeclinedSession = 2
        self.defaultsManager.sessionCounter = 9

        let shouldShow = await self.testSubject.shouldShowInactivityNotification()
        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.inactivityNotificationDismissTitle, "inactivityNotification_notNow"~)
        XCTAssertFalse(self.defaultsManager.inactivityNotificationWasGranted)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationAskCount, 0)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclinedSession, 0)
    }
}
