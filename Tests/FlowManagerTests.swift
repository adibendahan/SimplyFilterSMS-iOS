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
    private var networkSyncManager: mock_NetworkSyncManager!
    private var automaticFilterManager: mock_AutomaticFilterManager!
    private var isFirstRun = true
    private var lastSeenWhatsNewVersion = 0
    private var networkStatus: NetworkStatus = .online
    private var testSubject: FlowManager!

    override func setUp() {
        super.setUp()
        self.isFirstRun = true
        self.lastSeenWhatsNewVersion = 0
        self.networkStatus = .online
        self.defaultsManager = mock_DefaultsManager()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.automaticFilterManager = mock_AutomaticFilterManager()
        self.networkSyncManager.networkStatusClosure = { [unowned self] in
            return self.networkStatus
        }
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date.distantPast }
        self.defaultsManager.isAppFirstRunClosure = { [unowned self] in
            return self.isFirstRun
        }
        self.defaultsManager.lastSeenWhatsNewVersionClosure = { [unowned self] in
            return self.lastSeenWhatsNewVersion
        }
        self.testSubject = self.makeTestSubject()
    }

    override func tearDown() {
        self.testSubject = nil
        self.defaultsManager = nil
        self.networkSyncManager = nil
        self.automaticFilterManager = nil
        super.tearDown()
    }

    private func makeTestSubject() -> FlowManager {
        return FlowManager(defaultsManager: self.defaultsManager,
                           networkSyncManager: self.networkSyncManager,
                           automaticFilterManager: self.automaticFilterManager)
    }

    private func postNetworkStatus(_ networkStatus: NetworkStatus) {
        self.networkStatus = networkStatus
        NotificationCenter.default.post(name: .networkStatusChange, object: networkStatus)
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
        self.testSubject = self.makeTestSubject()
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.next(), .filterImport)
    }

    func test_whatsNew_waitsUntilEnabled() {
        self.isFirstRun = false
        self.testSubject = self.makeTestSubject()

        XCTAssertNil(self.testSubject.next())
        self.testSubject.enableWhatsNew()
        XCTAssertEqual(self.testSubject.next(), .whatsNew)
    }

    func test_whatsNew_skippedWhenLaunchClaimedSession() {
        self.isFirstRun = false
        self.testSubject = self.makeTestSubject()
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.complete(.filterImport)
        self.testSubject.enableWhatsNew()

        XCTAssertNil(self.testSubject.next())
    }

    func test_lastLaunchURLWins() {
        self.isFirstRun = false
        self.testSubject = self.makeTestSubject()
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
        self.testSubject = self.makeTestSubject()
        self.testSubject.request(.about)

        XCTAssertEqual(self.testSubject.next(), .about)
    }

    func test_userRequest_whatsNew_afterLaunchClaimedSession() {
        self.isFirstRun = false
        self.testSubject = self.makeTestSubject()
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
        self.testSubject = self.makeTestSubject()
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

    func test_backOnline_offlineShown_freesSlot() {
        self.testSubject.startMonitoring()
        self.postNetworkStatus(.offline)
        _ = self.testSubject.nextNotification()

        self.postNetworkStatus(.online)

        XCTAssertFalse(self.testSubject.isNotificationShowing)
        self.testSubject.requestNotification(.tipPromotion)
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_backOnline_offlinePending_dropsIt() {
        self.testSubject.startMonitoring()
        self.postNetworkStatus(.offline)

        self.postNetworkStatus(.online)

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_backOnline_otherShown_keepsIt() {
        self.testSubject.startMonitoring()
        self.testSubject.requestNotification(.filtersImported(added: 1, skipped: 0))
        _ = self.testSubject.nextNotification()

        self.postNetworkStatus(.online)

        XCTAssertTrue(self.testSubject.isNotificationShowing)
    }

    func test_offline_snoozed_notShown() {
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date() }
        self.testSubject.startMonitoring()

        self.postNetworkStatus(.offline)

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_startMonitoring_alreadyOffline_showsOffline() {
        self.networkStatus = .offline

        self.testSubject.startMonitoring()

        XCTAssertEqual(self.testSubject.nextNotification(), .offline)
    }

    func test_higherPriorityToastCompletes_stillOffline_showsOfflineAgain() {
        self.networkStatus = .offline
        self.testSubject.requestNotification(.saveFailed)
        _ = self.testSubject.nextNotification()
        self.testSubject.requestNotification(.offline)

        self.testSubject.completeNotification()

        XCTAssertEqual(self.testSubject.nextNotification(), .offline)
    }

    func test_toastCompletes_online_showsNothing() {
        self.testSubject.requestNotification(.saveFailed)
        _ = self.testSubject.nextNotification()

        self.testSubject.completeNotification()

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_appEvents_becomeToasts() {
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { true }
        self.testSubject.startMonitoring()

        NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)
        XCTAssertEqual(self.testSubject.nextNotification(), .automaticFiltersUpdated)
        self.testSubject.completeNotification()

        NotificationCenter.default.post(name: .cloudSyncOperationComplete, object: nil)
        XCTAssertEqual(self.testSubject.nextNotification(), .cloudSyncOperationComplete)
        self.testSubject.completeNotification()

        NotificationCenter.default.post(name: .filtersSaveFailed, object: nil)
        XCTAssertEqual(self.testSubject.nextNotification(), .saveFailed)
    }

    func test_automaticFiltersUpdated_aiFilteringOff_noToast() {
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { false }
        self.testSubject.startMonitoring()

        NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_nudge_homeObstructed_waitsUntilUnobstructed() {
        var isHomeUnobstructed = false
        self.testSubject.setHomeAvailability { isHomeUnobstructed }

        self.testSubject.requestNotification(.tipPromotion)
        XCTAssertNil(self.testSubject.nextNotification())

        isHomeUnobstructed = true
        self.testSubject.homeMayBeUnobstructed()
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_result_homeObstructed_showsImmediately() {
        self.testSubject.setHomeAvailability { false }

        self.testSubject.requestNotification(.filtersImported(added: 1, skipped: 0))

        XCTAssertEqual(self.testSubject.nextNotification(), .filtersImported(added: 1, skipped: 0))
    }

    func test_tapTipPromotion_requestsTipJar() {
        self.isFirstRun = false
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion
        self.testSubject = self.makeTestSubject()
        let flowRequested = XCTNSNotificationExpectation(name: .flowRequested)

        self.testSubject.didTapNotification(.tipPromotion)

        wait(for: [flowRequested], timeout: 1)
        XCTAssertEqual(self.testSubject.next(), .tipJar)
    }

    func test_tapReportingNudge_dismissesItAndRequestsSheet() {
        self.isFirstRun = false
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion
        self.testSubject = self.makeTestSubject()

        self.testSubject.didTapNotification(.enableReportingExtension)

        XCTAssertEqual(self.defaultsManager.didDismissReportingExtensionNudgeSetCounter, 1)
        XCTAssertEqual(self.testSubject.next(), .enableReportingExtension)
    }

    func test_dismissOffline_recordsSnooze() {
        self.testSubject.didDismissNotification(.offline)

        XCTAssertEqual(self.defaultsManager.lastOfflineNotificationDismissSetCounter, 1)
    }

    func test_showSessionNudges_tipDue_showsTip() {
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }

        self.testSubject.showSessionNudges()

        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_showSessionNudges_offlineShowing_keepsOffline() {
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }
        self.testSubject.requestNotification(.offline)
        _ = self.testSubject.nextNotification()

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_sessionNudge_shown_recordsSession() {
        self.defaultsManager.sessionCounterClosure = { 7 }
        self.defaultsManager.didTipClosure = { false }
        self.testSubject.showSessionNudges()

        _ = self.testSubject.nextNotification()

        XCTAssertEqual(self.defaultsManager.lastTipPromotionSession, 7)
    }

    func test_sessionNudge_requestedButNotShown_recordsNothing() {
        self.defaultsManager.sessionCounterClosure = { 7 }
        self.defaultsManager.didTipClosure = { false }

        self.testSubject.showSessionNudges()

        XCTAssertEqual(self.defaultsManager.lastTipPromotionSession, 0)
    }

    func test_tipPromotion_dueCountsFromLastShown() {
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.lastTipPromotionSession = 7
        self.defaultsManager.sessionCounterClosure = { 11 }

        self.testSubject.showSessionNudges()
        XCTAssertNil(self.testSubject.nextNotification())

        self.defaultsManager.sessionCounterClosure = { 12 }
        self.testSubject.resetSession()
        self.testSubject.showSessionNudges()
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_tipPromotion_tipped_neverDue() {
        self.defaultsManager.didTipClosure = { true }
        self.defaultsManager.sessionCounterClosure = { 50 }

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_skippedNudge_dueNextSession() {
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.testSubject.requestNotification(.automaticFiltersUpdated)
        _ = self.testSubject.nextNotification()
        self.testSubject.showSessionNudges()
        self.testSubject.completeNotification()
        XCTAssertNil(self.testSubject.nextNotification())

        self.defaultsManager.sessionCounterClosure = { 6 }
        self.testSubject.resetSession()
        self.testSubject.showSessionNudges()

        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_bothNudgesDue_tipFirstReportingNextSession() {
        self.isFirstRun = false
        self.testSubject = self.makeTestSubject()
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { true }
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 6 }

        self.testSubject.showSessionNudges()
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
        self.testSubject.completeNotification()
        XCTAssertNil(self.testSubject.nextNotification())

        self.defaultsManager.sessionCounterClosure = { 7 }
        self.testSubject.resetSession()
        self.testSubject.showSessionNudges()
        XCTAssertEqual(self.testSubject.nextNotification(), .enableReportingExtension)
    }

    func test_reportingNudge_aiFilteringOff_neverDue() {
        self.isFirstRun = false
        self.testSubject = self.makeTestSubject()
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { false }
        self.defaultsManager.didTipClosure = { true }
        self.defaultsManager.sessionCounterClosure = { 9 }

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_sessionNudge_checkRunning_waitsForIt() {
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 5 }
        var isChecking = true
        self.automaticFilterManager.isCheckingFilterListsClosure = { isChecking }
        self.testSubject.startMonitoring()

        self.testSubject.showSessionNudges()
        XCTAssertNil(self.testSubject.nextNotification())

        isChecking = false
        NotificationCenter.default.post(name: .filterListsCheckFinished, object: nil)
        XCTAssertEqual(self.testSubject.nextNotification(), .tipPromotion)
    }

    func test_sessionNudge_checkShowedAIToast_skipsNudge() {
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { true }
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 5 }
        var isChecking = true
        self.automaticFilterManager.isCheckingFilterListsClosure = { isChecking }
        self.testSubject.startMonitoring()
        self.testSubject.showSessionNudges()

        NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)
        XCTAssertEqual(self.testSubject.nextNotification(), .automaticFiltersUpdated)
        isChecking = false
        NotificationCenter.default.post(name: .filterListsCheckFinished, object: nil)
        self.testSubject.completeNotification()

        XCTAssertNil(self.testSubject.nextNotification())
        XCTAssertEqual(self.defaultsManager.lastTipPromotionSession, 0)
    }

    func test_waitingNudge_otherToastShowedMeanwhile_skipped() {
        var isHomeUnobstructed = false
        self.testSubject.setHomeAvailability { isHomeUnobstructed }
        self.testSubject.requestNotification(.tipPromotion)
        self.testSubject.requestNotification(.cloudSyncOperationComplete)
        _ = self.testSubject.nextNotification()
        self.testSubject.completeNotification()

        isHomeUnobstructed = true
        self.testSubject.homeMayBeUnobstructed()

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_tipShown_reportingNudgeCannotReplaceIt() {
        self.testSubject.requestNotification(.tipPromotion)
        _ = self.testSubject.nextNotification()

        self.testSubject.requestNotification(.enableReportingExtension)

        XCTAssertNil(self.testSubject.nextNotification())
    }

    func test_dismissOtherToast_recordsNothing() {
        self.testSubject.didDismissNotification(.saveFailed)

        XCTAssertEqual(self.defaultsManager.lastOfflineNotificationDismissSetCounter, 0)
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

    func test_didShowNotificationThisSession_requestedAndDropped_false() {
        self.testSubject.requestNotification(.saveFailed)

        self.testSubject.requestNotification(.automaticFiltersUpdated)

        XCTAssertFalse(self.testSubject.didShowNotificationThisSession)
    }

    func test_didShowNotificationThisSession_shown_true() {
        self.testSubject.requestNotification(.onClipboardSet("Email"))

        _ = self.testSubject.nextNotification()

        XCTAssertTrue(self.testSubject.didShowNotificationThisSession)
    }

    func test_resetSession_clearsDidShowNotification() {
        self.testSubject.requestNotification(.onClipboardSet("Email"))
        _ = self.testSubject.nextNotification()

        self.testSubject.resetSession()

        XCTAssertFalse(self.testSubject.didShowNotificationThisSession)
    }
}
