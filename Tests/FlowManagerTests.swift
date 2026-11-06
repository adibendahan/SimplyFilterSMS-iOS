//
//  FlowManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FlowManagerTests: XCTestCase {

    private var defaultsManager: mock_DefaultsManager!
    private var isFirstRun = true
    private var lastSeenWhatsNewVersion = 0
    private var testSubject: FlowManager!

    override func setUp() {
        super.setUp()
        self.isFirstRun = true
        self.lastSeenWhatsNewVersion = 0
        self.defaultsManager = mock_DefaultsManager()
        self.defaultsManager.isAppFirstRunClosure = { [unowned self] in
            return self.isFirstRun
        }
        self.defaultsManager.lastSeenWhatsNewVersionClosure = { [unowned self] in
            return self.lastSeenWhatsNewVersion
        }
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
    }

    override func tearDown() {
        self.testSubject = nil
        self.defaultsManager = nil
        super.tearDown()
    }

    func test_firstRun_winsOverFileAndWhatsNew() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.next(), .enableExtension)
        XCTAssertNil(self.testSubject.next())
    }

    func test_importWaitsUntilFirstRunCompletes() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))

        XCTAssertEqual(self.testSubject.next(), .enableExtension)

        self.isFirstRun = false
        XCTAssertNil(self.testSubject.next())

        self.testSubject.complete(.enableExtension)
        XCTAssertEqual(self.testSubject.next(), .filterImport)
    }

    func test_afterFirstRun_fileBeatsWhatsNew() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.next(), .filterImport)
    }

    func test_whatsNew_waitsUntilEnabled() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)

        XCTAssertNil(self.testSubject.next())
        self.testSubject.enableWhatsNew()
        XCTAssertEqual(self.testSubject.next(), .whatsNew)
    }

    func test_whatsNew_skippedWhenLaunchClaimedSession() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.complete(.filterImport)
        self.testSubject.enableWhatsNew()

        XCTAssertNil(self.testSubject.next())
    }

    func test_lastLaunchURLWins() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        XCTAssertTrue(self.testSubject.recordLaunch(.tipJar))

        XCTAssertEqual(self.testSubject.next(), .tipJar)
    }

    func test_userRequest_doesNotBeatFirstRun() {
        self.testSubject.request(.about)

        XCTAssertEqual(self.testSubject.next(), .enableExtension)
    }

    func test_userRequest_afterFirstRun() {
        self.isFirstRun = false
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        self.testSubject.request(.about)

        XCTAssertEqual(self.testSubject.next(), .about)
    }

    func test_userRequest_whatsNew_afterLaunchClaimedSession() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.complete(.filterImport)
        self.testSubject.request(.whatsNew)

        XCTAssertEqual(self.testSubject.next(), .whatsNew)
    }

    func test_enableExtensionDeepLink_ignoredDuringFirstRun() {
        XCTAssertFalse(self.testSubject.recordLaunch(.enableExtension))
        XCTAssertEqual(self.testSubject.next(), .enableExtension)

        self.isFirstRun = false
        self.testSubject.complete(.enableExtension)
        XCTAssertNil(self.testSubject.next())
    }

    func test_recordLaunch_returnsTrueWhenQueued() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.tipJar))
    }

    func test_notification_lowerPriorityWhilePending_keepsHigher() {
        self.testSubject.requestNotification(.cloudSyncOperationComplete)
        self.testSubject.requestNotification(.automaticFiltersUpdated)

        XCTAssertEqual(self.testSubject.nextNotification(), .cloudSyncOperationComplete)
        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_notification_higherPriorityWhilePending_replaces() {
        self.testSubject.requestNotification(.automaticFiltersUpdated)
        self.testSubject.requestNotification(.filtersImported(added: 1, skipped: 0))

        XCTAssertEqual(self.testSubject.nextNotification(), .filtersImported(added: 1, skipped: 0))
    }

    func test_notification_samePriority_newerReplaces() {
        self.testSubject.requestNotification(.filtersImported(added: 1, skipped: 0))
        self.testSubject.requestNotification(.filtersImported(added: 2, skipped: 0))

        XCTAssertEqual(self.testSubject.nextNotification(), .filtersImported(added: 2, skipped: 0))
    }

    func test_notification_lowerPriorityWhileShown_dropped() {
        self.testSubject.requestNotification(.offline)
        _ = self.testSubject.nextNotification()
        self.testSubject.requestNotification(.tipPromotion)

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_notification_failureWhileImportResultShown_replaces() {
        self.testSubject.requestNotification(.filtersImported(added: 1, skipped: 0))
        _ = self.testSubject.nextNotification()
        self.testSubject.requestNotification(.saveFailed)

        XCTAssertEqual(self.testSubject.nextNotification(), .saveFailed)
    }

    func test_notification_completed_freesSlot() {
        self.testSubject.requestNotification(.offline)
        _ = self.testSubject.nextNotification()
        self.testSubject.completeNotification()
        self.testSubject.requestNotification(.tipPromotion)

        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_cancelNotification_shown_returnsTrueAndFreesSlot() {
        self.testSubject.requestNotification(.offline)
        _ = self.testSubject.nextNotification()

        XCTAssertTrue(self.testSubject.cancelNotification(.offline))
        self.testSubject.requestNotification(.tipPromotion)
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_cancelNotification_pending_dropsItReturnsFalse() {
        self.testSubject.requestNotification(.offline)

        XCTAssertFalse(self.testSubject.cancelNotification(.offline))
        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_cancelNotification_otherShown_keepsIt() {
        self.testSubject.requestNotification(.filtersImported(added: 1, skipped: 0))
        _ = self.testSubject.nextNotification()

        XCTAssertFalse(self.testSubject.cancelNotification(.offline))
        self.testSubject.requestNotification(.tipPromotion)
        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_resetSession_clearsNotifications() {
        self.testSubject.requestNotification(.offline)
        _ = self.testSubject.nextNotification()
        self.testSubject.requestNotification(.saveFailed)
        self.testSubject.resetSession()

        XCTAssertNil(self.testSubject.nextNotification())
        self.testSubject.requestNotification(.tipPromotion)
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_requestNotification_accepted_postsSlotChanged() {
        let slotChanged = XCTNSNotificationExpectation(name: .notificationSlotChanged)

        self.testSubject.requestNotification(.offline)

        wait(for: [slotChanged], timeout: 1)
    }

    func test_requestNotification_dropped_doesNotPost() {
        self.testSubject.requestNotification(.saveFailed)
        let slotChanged = XCTNSNotificationExpectation(name: .notificationSlotChanged)
        slotChanged.isInverted = true

        self.testSubject.requestNotification(.tipPromotion)

        wait(for: [slotChanged], timeout: 0.1)
    }
}
