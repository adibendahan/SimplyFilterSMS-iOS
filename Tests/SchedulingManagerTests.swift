//
//  SchedulingManagerTests.swift
//  Tests
//

import Foundation
import XCTest
import UserNotifications
@testable import Simply_Filter_SMS

class SchedulingManagerTests: XCTestCase {

    private var automaticFilterManager: mock_AutomaticFilterManager!
    private var defaultsManager: mock_DefaultsManager!
    private var userNotificationCenterService: mock_UserNotificationCenterService!
    private var testSubject: SchedulingManager!

    private var isAutomaticFilteringOn = true
    private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private var sessionCounter = 0

    override func setUp() {
        super.setUp()
        self.isAutomaticFilteringOn = true
        self.authorizationStatus = .notDetermined
        self.sessionCounter = 2

        self.automaticFilterManager = mock_AutomaticFilterManager()
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { [unowned self] in
            return self.isAutomaticFilteringOn
        }

        self.defaultsManager = mock_DefaultsManager()
        self.defaultsManager.sessionCounterClosure = { [unowned self] in
            return self.sessionCounter
        }

        self.userNotificationCenterService = mock_UserNotificationCenterService()
        self.userNotificationCenterService.authorizationStatusClosure = { [unowned self] in
            return self.authorizationStatus
        }

        self.testSubject = SchedulingManager(automaticFilterManager: self.automaticFilterManager,
                                             defaultsManager: self.defaultsManager,
                                             userNotificationCenterService: self.userNotificationCenterService)
    }

    override func tearDown() {
        self.testSubject = nil
        self.userNotificationCenterService = nil
        self.defaultsManager = nil
        self.automaticFilterManager = nil
        super.tearDown()
    }


    //MARK: - Asking -
    func test_neverAsksInTheFirstSession() async {
        self.sessionCounter = 1

        let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()

        XCTAssertFalse(shouldShow)
    }

    func test_asksWhenFilteringIsOnAndAlertsAreNotAllowed() async {
        let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()

        XCTAssertTrue(shouldShow)
    }

    func test_doesNotAskWhenAutomaticFilteringIsOff() async {
        self.isAutomaticFilteringOn = false

        let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()

        XCTAssertFalse(shouldShow)
    }

    func test_doesNotAskWhenAlertsAreAlreadyAllowed() async {
        self.authorizationStatus = .authorized

        let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()

        XCTAssertFalse(shouldShow)
    }

    func test_askingChangesNothing() async {
        _ = await self.testSubject.shouldShowInactivityNotificationAlert()

        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclineCount, 0)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationLastDeclineSession, 0)
        XCTAssertFalse(self.defaultsManager.inactivityNotificationWasGranted)
        XCTAssertEqual(self.userNotificationCenterService.scheduleCounter, 0)
    }

    func test_aDeclineWaitsOutTheSessionGap() async {
        self.testSubject.recordInactivityNotificationDecline()

        var shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()
        XCTAssertFalse(shouldShow)

        self.sessionCounter += kInactivityNotificationMinSessionsBetweenAsks - 1
        shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()
        XCTAssertFalse(shouldShow)

        self.sessionCounter += 1
        shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()
        XCTAssertTrue(shouldShow)
    }

    func test_theThirdDeclineEndsTheAsking() async {
        for ask in 1...kInactivityNotificationMaxAsks {
            let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()
            XCTAssertTrue(shouldShow, "expected ask #\(ask) to be offered")

            self.testSubject.recordInactivityNotificationDecline()
            self.sessionCounter += kInactivityNotificationMinSessionsBetweenAsks
        }

        let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()
        XCTAssertFalse(shouldShow)
    }

    func test_onlyTheLastAskIsFinal() {
        XCTAssertFalse(self.testSubject.isFinalInactivityNotificationAsk)

        self.defaultsManager.inactivityNotificationDeclineCount = kInactivityNotificationMaxAsks - 1
        XCTAssertTrue(self.testSubject.isFinalInactivityNotificationAsk)
    }


    //MARK: - Permission -
    func test_continueArmsTheReminderWhenAlertsAreGranted() async {
        self.userNotificationCenterService.requestAlertAuthorizationClosure = { [unowned self] in
            self.authorizationStatus = .authorized
            return true
        }
        let scheduled = self.expectReminderScheduled()

        await self.testSubject.requestInactivityNotificationPermission()

        await self.fulfillment(of: [scheduled], timeout: 1)
        XCTAssertTrue(self.defaultsManager.inactivityNotificationWasGranted)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclineCount, 0)
    }

    func test_continueCountsAsADeclineWhenAlertsAreDenied() async {
        self.userNotificationCenterService.requestAlertAuthorizationClosure = { return false }
        self.sessionCounter = 7

        await self.testSubject.requestInactivityNotificationPermission()

        XCTAssertFalse(self.defaultsManager.inactivityNotificationWasGranted)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclineCount, 1)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationLastDeclineSession, 7)
    }

    func test_revokingAlertsInSettingsStartsTheConversationOver() async {
        self.defaultsManager.inactivityNotificationWasGranted = true
        self.defaultsManager.inactivityNotificationDeclineCount = kInactivityNotificationMaxAsks
        self.defaultsManager.inactivityNotificationLastDeclineSession = 4
        self.authorizationStatus = .denied
        let settled = self.expectNoReminderScheduled()

        self.testSubject.refreshInactivityReminder()

        await self.fulfillment(of: [settled], timeout: 0.5)
        XCTAssertFalse(self.defaultsManager.inactivityNotificationWasGranted)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclineCount, 0)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationLastDeclineSession, 0)

        let shouldShow = await self.testSubject.shouldShowInactivityNotificationAlert()
        XCTAssertTrue(shouldShow)
    }

    func test_aDeclinerWhoNeverGrantedKeepsTheirHistory() async {
        self.testSubject.recordInactivityNotificationDecline()
        self.authorizationStatus = .denied
        let settled = self.expectNoReminderScheduled()

        self.testSubject.refreshInactivityReminder()

        await self.fulfillment(of: [settled], timeout: 0.5)
        XCTAssertEqual(self.defaultsManager.inactivityNotificationDeclineCount, 1)
    }


    //MARK: - Reminder -
    func test_refreshSchedulesOneMonthOutWhenAlertsAreAllowed() async {
        self.authorizationStatus = .authorized
        let scheduled = self.expectReminderScheduled()

        self.testSubject.refreshInactivityReminder()

        await self.fulfillment(of: [scheduled], timeout: 1)
        let request = self.userNotificationCenterService.scheduledRequest
        XCTAssertEqual(request?.identifier, kInactivityReminderNotificationIdentifier)
        XCTAssertTrue(self.defaultsManager.inactivityNotificationWasGranted)

        let trigger = request?.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertEqual(trigger?.repeats, true)
        XCTAssertEqual(trigger?.timeInterval ?? 0, 30 * 24 * 60 * 60, accuracy: 2 * 24 * 60 * 60)
    }

    func test_refreshOnlyCancelsWhenAlertsAreNotAllowed() async {
        let settled = self.expectNoReminderScheduled()

        self.testSubject.refreshInactivityReminder()

        await self.fulfillment(of: [settled], timeout: 0.5)
        XCTAssertEqual(self.userNotificationCenterService.cancelPendingNotificationCounter, 1)
    }

    func test_refreshOnlyCancelsWhenAutomaticFilteringIsOff() async {
        self.authorizationStatus = .authorized
        self.isAutomaticFilteringOn = false
        let settled = self.expectNoReminderScheduled()

        self.testSubject.refreshInactivityReminder()

        await self.fulfillment(of: [settled], timeout: 0.5)
        XCTAssertEqual(self.userNotificationCenterService.cancelPendingNotificationCounter, 1)
    }

    func test_turningAutomaticFilteringOffCancelsTheReminder() async {
        self.isAutomaticFilteringOn = false
        let cancelled = self.expectation(description: "reminder cancelled")
        self.userNotificationCenterService.cancelPendingNotificationClosure = { _ in cancelled.fulfill() }

        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)

        await self.fulfillment(of: [cancelled], timeout: 1)
    }

    func test_editingFiltersWhileFilteringIsOnLeavesTheReminderAlone() async {
        let cancelled = self.expectation(description: "reminder cancelled")
        cancelled.isInverted = true
        self.userNotificationCenterService.cancelPendingNotificationClosure = { _ in cancelled.fulfill() }

        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)

        await self.fulfillment(of: [cancelled], timeout: 0.5)
    }


    //MARK: - Private -
    private func expectReminderScheduled() -> XCTestExpectation {
        let expectation = self.expectation(description: "inactivity reminder scheduled")
        self.userNotificationCenterService.scheduleClosure = { _ in expectation.fulfill() }
        return expectation
    }

    private func expectNoReminderScheduled() -> XCTestExpectation {
        let expectation = self.expectReminderScheduled()
        expectation.isInverted = true
        return expectation
    }
}
