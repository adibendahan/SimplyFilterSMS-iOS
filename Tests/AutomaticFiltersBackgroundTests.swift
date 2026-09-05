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

    func test_requestAuthorizationFromExplainer_denied_recordsDecline() {
        self.notifications.requestAlertAuthorizationGranted = false
        let expectation = self.expectation(description: "auth")

        self.testSubject.requestNotificationAuthorizationFromExplainer { granted in
            XCTAssertFalse(granted)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.notifications.requestAlertAuthorizationCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 0)
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerAskCount, 1)
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession, 1)
    }

    func test_requestAuthorizationFromExplainer_granted_marksGrantedAndSchedules() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.notifications.requestAlertAuthorizationGranted = true
        let expectation = self.expectation(description: "auth")

        self.testSubject.requestNotificationAuthorizationFromExplainer { granted in
            XCTAssertTrue(granted)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.notifications.requestAlertAuthorizationCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 1)
        XCTAssertTrue(self.defaultsManager.automaticFiltersNotificationPermissionWasGranted)
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

        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()

        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.notificationExplainerDismissTitle, "autoFilter_notificationExplainer_notNow"~)
    }

    func test_shouldShow_aiOff_false() async {
        self.isAutomaticFilteringOn = false
        self.notifications.authorizationStatusValue = .notDetermined

        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()

        XCTAssertFalse(shouldShow)
    }

    func test_shouldShow_alreadyAuthorized_marksGrantedAndFalse() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .authorized

        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()

        XCTAssertFalse(shouldShow)
        XCTAssertTrue(self.defaultsManager.automaticFiltersNotificationPermissionWasGranted)
        XCTAssertEqual(self.notifications.addCounter, 1)
    }

    func test_shouldShow_gapBlocksUntilThreeSessions() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount = 1
        self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession = 1
        self.defaultsManager.sessionCounter = 3

        let blocked = await self.testSubject.shouldShowNotificationPermissionExplainer()
        XCTAssertFalse(blocked)

        self.defaultsManager.sessionCounter = 4
        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()
        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.notificationExplainerDismissTitle, "autoFilter_notificationExplainer_notNow"~)
    }

    func test_shouldShow_thirdAsk_stopAskingTitle() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount = 2
        self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession = 1
        self.defaultsManager.sessionCounter = 10

        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()
        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.notificationExplainerDismissTitle, "autoFilter_notificationExplainer_stopAsking"~)
    }

    func test_shouldShow_afterMaxAsks_false() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount = 3
        self.defaultsManager.sessionCounter = 20

        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()
        XCTAssertFalse(shouldShow)
    }

    func test_recordDecline_notFinal_incrementsAndStoresSession() {
        self.defaultsManager.sessionCounter = 5
        self.testSubject.recordNotificationExplainerDecline()
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerAskCount, 1)
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession, 5)
    }

    func test_recordDecline_final_setsMaxAsks() {
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount = 2
        self.testSubject.recordNotificationExplainerDecline()
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerAskCount, 3)
    }

    func test_shouldShow_revoke_resetsAndShowsFirstAsk() async {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .denied
        self.defaultsManager.automaticFiltersNotificationPermissionWasGranted = true
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount = 3
        self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession = 2
        self.defaultsManager.sessionCounter = 9

        let shouldShow = await self.testSubject.shouldShowNotificationPermissionExplainer()
        XCTAssertTrue(shouldShow)
        XCTAssertEqual(self.testSubject.notificationExplainerDismissTitle, "autoFilter_notificationExplainer_notNow"~)
        XCTAssertFalse(self.defaultsManager.automaticFiltersNotificationPermissionWasGranted)
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerAskCount, 0)
        XCTAssertEqual(self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession, 0)
    }
}
