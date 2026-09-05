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
    private var notifications: mock_UserNotificationCenterService!
    private var isAutomaticFilteringOn = false
    private var testSubject: SchedulingManager!

    override func setUp() {
        super.setUp()
        self.isAutomaticFilteringOn = false
        self.automaticFilterManager = mock_AutomaticFilterManager()
        self.notifications = mock_UserNotificationCenterService()
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { [unowned self] in
            return self.isAutomaticFilteringOn
        }
        self.testSubject = SchedulingManager(automaticFilterManager: self.automaticFilterManager,
                                             userNotificationCenterService: self.notifications)
    }

    override func tearDown() {
        self.testSubject = nil
        self.notifications = nil
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

    func test_requestAuthorizationFromExplainer_denied_doesNotSchedule() {
        self.notifications.requestAlertAuthorizationGranted = false
        let expectation = self.expectation(description: "auth")

        self.testSubject.requestNotificationAuthorizationFromExplainer { granted in
            XCTAssertFalse(granted)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
        XCTAssertEqual(self.notifications.requestAlertAuthorizationCounter, 1)
        XCTAssertEqual(self.notifications.addCounter, 0)
    }

    func test_requestAuthorizationFromExplainer_granted_schedules() {
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
}
