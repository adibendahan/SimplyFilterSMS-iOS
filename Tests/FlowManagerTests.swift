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
    private var filterListManager: mock_FilterListManager!
    private var isFirstRun = false
    private var lastSeenWhatsNewVersion = 0
    private var networkStatus: NetworkStatus = .online
    private var testSubject: FlowManager!

    override func setUp() {
        super.setUp()
        self.isFirstRun = false
        self.lastSeenWhatsNewVersion = 0
        self.networkStatus = .online
        self.defaultsManager = mock_DefaultsManager()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.filterListManager = mock_FilterListManager()
        self.networkSyncManager.networkStatusClosure = { [unowned self] in
            return self.networkStatus
        }
        self.defaultsManager.lastOfflineToastDismissClosure = { Date.distantPast }
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
        self.filterListManager = nil
        super.tearDown()
    }

    private func makeTestSubject() -> FlowManager {
        return FlowManager(defaultsManager: self.defaultsManager,
                           networkSyncManager: self.networkSyncManager,
                           filterListManager: self.filterListManager)
    }

    private func postNetworkStatus(_ networkStatus: NetworkStatus) {
        self.networkStatus = networkStatus
        NotificationCenter.default.post(name: .networkStatusChange, object: networkStatus)
    }

    func test_firstRun_winsOverFileAndWhatsNew() {
        self.isFirstRun = true
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.nextScreen(), .enableExtension)
        XCTAssertNil(self.testSubject.nextScreen())
    }

    func test_importWaitsUntilFirstRunCompletes() {
        self.isFirstRun = true
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))

        XCTAssertEqual(self.testSubject.nextScreen(), .enableExtension)

        self.isFirstRun = false
        XCTAssertNil(self.testSubject.nextScreen())

        self.testSubject.completeScreen(.enableExtension)
        XCTAssertEqual(self.testSubject.nextScreen(), .filterImport)
    }

    func test_afterFirstRun_fileBeatsWhatsNew() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.nextScreen(), .filterImport)
    }

    func test_whatsNew_waitsUntilEnabled() {
        XCTAssertNil(self.testSubject.nextScreen())
        self.testSubject.enableWhatsNew()
        XCTAssertEqual(self.testSubject.nextScreen(), .whatsNew)
    }

    func test_whatsNew_skippedWhenLaunchClaimedSession() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.completeScreen(.filterImport)
        self.testSubject.enableWhatsNew()

        XCTAssertNil(self.testSubject.nextScreen())
    }

    func test_lastLaunchURLWins() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        XCTAssertTrue(self.testSubject.recordLaunch(.tipJar))

        XCTAssertEqual(self.testSubject.nextScreen(), .tipJar)
    }

    func test_userRequest_doesNotBeatFirstRun() {
        self.isFirstRun = true
        self.testSubject.requestScreen(.about)

        XCTAssertEqual(self.testSubject.nextScreen(), .enableExtension)
    }

    func test_userRequest_afterFirstRun() {
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion
        self.testSubject.requestScreen(.about)

        XCTAssertEqual(self.testSubject.nextScreen(), .about)
    }

    func test_userRequest_whatsNew_afterLaunchClaimedSession() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.completeScreen(.filterImport)
        self.testSubject.requestScreen(.whatsNew)

        XCTAssertEqual(self.testSubject.nextScreen(), .whatsNew)
    }

    func test_enableExtensionDeepLink_ignoredDuringFirstRun() {
        self.isFirstRun = true
        XCTAssertFalse(self.testSubject.recordLaunch(.enableExtension))
        XCTAssertEqual(self.testSubject.nextScreen(), .enableExtension)

        self.isFirstRun = false
        self.testSubject.completeScreen(.enableExtension)
        XCTAssertNil(self.testSubject.nextScreen())
    }

    func test_recordLaunch_returnsTrueWhenQueued() {
        XCTAssertTrue(self.testSubject.recordLaunch(.tipJar))
    }

    func test_toast_lowerPriorityWhilePending_keepsHigher() {
        self.testSubject.requestToast(.cloudSyncOperationComplete)
        self.testSubject.requestToast(.filterListsUpdated(.aiFilteringLanguage))

        XCTAssertEqual(self.testSubject.nextToast(), .cloudSyncOperationComplete)
        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_toast_higherPriorityWhilePending_replaces() {
        self.testSubject.requestToast(.filterListsUpdated(.aiFilteringLanguage))
        self.testSubject.requestToast(.filtersImported(added: 1, skipped: 0))

        XCTAssertEqual(self.testSubject.nextToast(), .filtersImported(added: 1, skipped: 0))
    }

    func test_toast_samePriority_newerReplaces() {
        self.testSubject.requestToast(.filtersImported(added: 1, skipped: 0))
        self.testSubject.requestToast(.filtersImported(added: 2, skipped: 0))

        XCTAssertEqual(self.testSubject.nextToast(), .filtersImported(added: 2, skipped: 0))
    }

    func test_toast_lowerPriorityWhileShown_dropped() {
        self.testSubject.requestToast(.offline)
        _ = self.testSubject.nextToast()
        self.testSubject.requestToast(.tipPromotion)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_toast_failureWhileImportResultShown_replaces() {
        self.testSubject.requestToast(.filtersImported(added: 1, skipped: 0))
        _ = self.testSubject.nextToast()
        self.testSubject.requestToast(.saveFailed)

        XCTAssertEqual(self.testSubject.nextToast(), .saveFailed)
    }

    func test_toast_completed_freesSlot() {
        self.testSubject.requestToast(.offline)
        _ = self.testSubject.nextToast()
        self.testSubject.completeToast(.offline)
        self.testSubject.requestToast(.tipPromotion)

        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_backOnline_offlineShown_freesSlot() {
        self.testSubject.startAppEventToasts()
        self.postNetworkStatus(.offline)
        _ = self.testSubject.nextToast()

        self.postNetworkStatus(.online)

        XCTAssertFalse(self.testSubject.isToastShowing)
        self.testSubject.requestToast(.tipPromotion)
        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_backOnline_offlinePending_dropsIt() {
        self.testSubject.startAppEventToasts()
        self.postNetworkStatus(.offline)

        self.postNetworkStatus(.online)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_backOnline_otherShown_keepsIt() {
        self.testSubject.startAppEventToasts()
        self.testSubject.requestToast(.filtersImported(added: 1, skipped: 0))
        _ = self.testSubject.nextToast()

        self.postNetworkStatus(.online)

        XCTAssertTrue(self.testSubject.isToastShowing)
    }

    func test_offline_snoozed_notShown() {
        self.defaultsManager.lastOfflineToastDismissClosure = { Date() }
        self.testSubject.startAppEventToasts()

        self.postNetworkStatus(.offline)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_startAppEventToasts_alreadyOffline_showsOffline() {
        self.networkStatus = .offline

        self.testSubject.startAppEventToasts()

        XCTAssertEqual(self.testSubject.nextToast(), .offline)
    }

    func test_toast_staleCompletion_keepsNewerToast() {
        self.testSubject.requestToast(.cloudSyncOperationComplete)
        _ = self.testSubject.nextToast()
        self.testSubject.requestToast(.saveFailed)
        _ = self.testSubject.nextToast()

        self.testSubject.completeToast(.cloudSyncOperationComplete)
        self.testSubject.requestToast(.tipPromotion)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_higherPriorityToastCompletes_stillOffline_showsOfflineAgain() {
        self.networkStatus = .offline
        self.testSubject.requestToast(.saveFailed)
        _ = self.testSubject.nextToast()
        self.testSubject.requestToast(.offline)

        self.testSubject.completeToast(.saveFailed)

        XCTAssertEqual(self.testSubject.nextToast(), .offline)
    }

    func test_toastCompletes_online_showsNothing() {
        self.testSubject.requestToast(.saveFailed)
        _ = self.testSubject.nextToast()

        self.testSubject.completeToast(.saveFailed)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_appEvents_becomeToasts() {
        self.testSubject.startAppEventToasts()

        NotificationCenter.default.post(name: .filterListsUpdated, object: FilterListCatalogEntryType.aiFilteringLanguage)
        XCTAssertEqual(self.testSubject.nextToast(), .filterListsUpdated(.aiFilteringLanguage))
        self.testSubject.completeToast(.filterListsUpdated(.aiFilteringLanguage))

        NotificationCenter.default.post(name: .cloudSyncOperationComplete, object: nil)
        XCTAssertEqual(self.testSubject.nextToast(), .cloudSyncOperationComplete)
        self.testSubject.completeToast(.cloudSyncOperationComplete)

        NotificationCenter.default.post(name: .filtersSaveFailed, object: nil)
        XCTAssertEqual(self.testSubject.nextToast(), .saveFailed)
    }

    func test_filterListsUpdated_noActiveListUpdated_noToast() {
        self.testSubject.startAppEventToasts()

        NotificationCenter.default.post(name: .filterListsUpdated, object: nil)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_filterListsUpdated_communityList_namesCommunityLists() {
        self.testSubject.startAppEventToasts()

        NotificationCenter.default.post(name: .filterListsUpdated, object: FilterListCatalogEntryType.curatedCommunityList)

        XCTAssertEqual(self.testSubject.nextToast(), .filterListsUpdated(.curatedCommunityList))
        XCTAssertEqual(ToastView.Toast.filterListsUpdated(.curatedCommunityList).title, "communityLists_title"~)
    }

    func test_nudge_homeBusy_waitsUntilIdle() {
        var isHomeIdle = false
        self.testSubject.setHomeIdleCheck { isHomeIdle }

        self.testSubject.requestToast(.tipPromotion)
        XCTAssertNil(self.testSubject.nextToast())

        isHomeIdle = true
        self.testSubject.showWaitingToast()
        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_result_homeBusy_showsImmediately() {
        self.testSubject.setHomeIdleCheck { false }

        self.testSubject.requestToast(.filtersImported(added: 1, skipped: 0))

        XCTAssertEqual(self.testSubject.nextToast(), .filtersImported(added: 1, skipped: 0))
    }

    func test_tapTipPromotion_requestsTipJar() {
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion
        var presentNextScreenCount = 0
        self.testSubject.setScreenPresenter { presentNextScreenCount += 1 }

        self.testSubject.didTapToast(.tipPromotion)

        XCTAssertEqual(presentNextScreenCount, 1)
        XCTAssertEqual(self.testSubject.nextScreen(), .tipJar)
    }

    func test_tapReportingNudge_dismissesItAndRequestsSheet() {
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion

        self.testSubject.didTapToast(.enableReportingExtension)

        XCTAssertEqual(self.defaultsManager.didDismissReportingExtensionNudgeSetCounter, 1)
        XCTAssertEqual(self.testSubject.nextScreen(), .enableReportingExtension)
    }

    func test_offerStayReachable_firstRun_showsNothing() {
        self.isFirstRun = true
        self.testSubject.offerStayReachable()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_offerStayReachable_due_showsToastAndRecordsSession() {
        self.defaultsManager.sessionCounterClosure = { 4 }

        self.testSubject.offerStayReachable()

        XCTAssertEqual(self.testSubject.nextToast(), .stayReachable)
        XCTAssertEqual(self.defaultsManager.stayReachableToastSessions, [4])
    }

    func test_offerStayReachable_homeBusy_showsImmediately() {
        self.testSubject.setHomeIdleCheck { false }

        self.testSubject.offerStayReachable()

        XCTAssertEqual(self.testSubject.nextToast(), .stayReachable)
    }

    func test_offerStayReachable_shownThisSession_showsNothing() {
        self.defaultsManager.sessionCounterClosure = { 4 }
        self.defaultsManager.stayReachableToastSessions = [4]

        self.testSubject.offerStayReachable()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_offerStayReachable_shownInEarlierSession_showsAgain() {
        self.defaultsManager.sessionCounterClosure = { 6 }
        self.defaultsManager.stayReachableToastSessions = [4]

        self.testSubject.offerStayReachable()

        XCTAssertEqual(self.testSubject.nextToast(), .stayReachable)
        XCTAssertEqual(self.defaultsManager.stayReachableToastSessions, [4, 6])
    }

    func test_offerStayReachable_shownMaxTimes_showsNothing() {
        self.defaultsManager.sessionCounterClosure = { 9 }
        self.defaultsManager.stayReachableToastSessions = [4, 6]

        self.testSubject.offerStayReachable()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_offerStayReachable_sheetOpened_showsNothing() {
        self.defaultsManager.didOpenStayReachable = true

        self.testSubject.offerStayReachable()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_tapStayReachable_marksOpenedAndRequestsSheet() {
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion

        self.testSubject.didTapToast(.stayReachable)

        XCTAssertTrue(self.defaultsManager.didOpenStayReachable)
        XCTAssertEqual(self.testSubject.nextScreen(), .stayReachable)
    }

    func test_requestStayReachableFromMenu_marksOpened() {
        self.testSubject.requestScreen(.stayReachable)

        XCTAssertTrue(self.defaultsManager.didOpenStayReachable)
    }

    func test_dismissOffline_recordsSnooze() {
        self.testSubject.didDismissToast(.offline)

        XCTAssertEqual(self.defaultsManager.lastOfflineToastDismissSetCounter, 1)
    }

    func test_showSessionNudges_tipDue_showsTip() {
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }

        self.testSubject.showSessionNudges()

        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_showSessionNudges_offlineShowing_keepsOffline() {
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }
        self.testSubject.requestToast(.offline)
        _ = self.testSubject.nextToast()

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_sessionNudge_shown_recordsSession() {
        self.defaultsManager.sessionCounterClosure = { 7 }
        self.defaultsManager.didTipClosure = { false }
        self.testSubject.showSessionNudges()

        _ = self.testSubject.nextToast()

        XCTAssertEqual(self.defaultsManager.sessionNudgeLastShownSessions["tipPromotion"], 7)
    }

    func test_sessionNudge_requestedButNotShown_recordsNothing() {
        self.defaultsManager.sessionCounterClosure = { 7 }
        self.defaultsManager.didTipClosure = { false }

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.defaultsManager.sessionNudgeLastShownSessions["tipPromotion"])
    }

    func test_tipPromotion_dueCountsFromLastShown() {
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionNudgeLastShownSessions["tipPromotion"] = 7
        self.defaultsManager.sessionCounterClosure = { 11 }

        self.testSubject.showSessionNudges()
        XCTAssertNil(self.testSubject.nextToast())

        self.defaultsManager.sessionCounterClosure = { 12 }
        self.testSubject.resetSession()
        self.testSubject.showSessionNudges()
        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_tipPromotion_tipped_neverDue() {
        self.defaultsManager.didTipClosure = { true }
        self.defaultsManager.sessionCounterClosure = { 50 }

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_skippedNudge_dueNextSession() {
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.testSubject.requestToast(.filterListsUpdated(.aiFilteringLanguage))
        _ = self.testSubject.nextToast()
        self.testSubject.showSessionNudges()
        self.testSubject.completeToast(.filterListsUpdated(.aiFilteringLanguage))
        XCTAssertNil(self.testSubject.nextToast())

        self.defaultsManager.sessionCounterClosure = { 6 }
        self.testSubject.resetSession()
        self.testSubject.showSessionNudges()

        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_bothNudgesDue_tipFirstReportingNextSession() {
        self.filterListManager.hasActiveFilterListsClosure = { true }
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 6 }

        self.testSubject.showSessionNudges()
        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
        self.testSubject.completeToast(.tipPromotion)
        XCTAssertNil(self.testSubject.nextToast())

        self.defaultsManager.sessionCounterClosure = { 7 }
        self.testSubject.resetSession()
        self.testSubject.showSessionNudges()
        XCTAssertEqual(self.testSubject.nextToast(), .enableReportingExtension)
    }

    func test_reportingNudge_noActiveFilterLists_neverDue() {
        self.filterListManager.hasActiveFilterListsClosure = { false }
        self.defaultsManager.didTipClosure = { true }
        self.defaultsManager.sessionCounterClosure = { 9 }

        self.testSubject.showSessionNudges()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_sessionNudge_filterListsUpdateInProgress_waitsForIt() {
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 5 }
        var finishFilterListsUpdate: (() -> Void)?
        self.filterListManager.onFilterListsUpdateFinishedClosure = { finishFilterListsUpdate = $0 }
        self.testSubject.startAppEventToasts()

        self.testSubject.showSessionNudges()
        XCTAssertNil(self.testSubject.nextToast())

        finishFilterListsUpdate?()
        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_sessionNudge_filterListsUpdateShowedToast_skipsNudge() {
        self.filterListManager.hasActiveFilterListsClosure = { true }
        self.defaultsManager.didTipClosure = { false }
        self.defaultsManager.sessionCounterClosure = { 5 }
        var finishFilterListsUpdate: (() -> Void)?
        self.filterListManager.onFilterListsUpdateFinishedClosure = { finishFilterListsUpdate = $0 }
        self.testSubject.startAppEventToasts()
        self.testSubject.showSessionNudges()

        NotificationCenter.default.post(name: .filterListsUpdated, object: FilterListCatalogEntryType.aiFilteringLanguage)
        XCTAssertEqual(self.testSubject.nextToast(), .filterListsUpdated(.aiFilteringLanguage))
        finishFilterListsUpdate?()
        self.testSubject.completeToast(.filterListsUpdated(.aiFilteringLanguage))

        XCTAssertNil(self.testSubject.nextToast())
        XCTAssertNil(self.defaultsManager.sessionNudgeLastShownSessions["tipPromotion"])
    }

    func test_waitingNudge_otherToastShowedMeanwhile_skipped() {
        var isHomeIdle = false
        self.testSubject.setHomeIdleCheck { isHomeIdle }
        self.testSubject.requestToast(.tipPromotion)
        self.testSubject.requestToast(.cloudSyncOperationComplete)
        _ = self.testSubject.nextToast()
        self.testSubject.completeToast(.cloudSyncOperationComplete)

        isHomeIdle = true
        self.testSubject.showWaitingToast()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_firstRun_toastWaitsUntilFirstRunFinishes() {
        self.isFirstRun = true

        self.testSubject.requestToast(.cloudSyncOperationComplete)
        XCTAssertNil(self.testSubject.nextToast())

        self.testSubject.showWaitingToast()
        XCTAssertNil(self.testSubject.nextToast())

        self.testSubject.finishFirstRun(openedSettings: false)
        self.isFirstRun = false
        self.testSubject.showWaitingToast()
        XCTAssertEqual(self.defaultsManager.isAppFirstRunSetCounter, 1)
        XCTAssertEqual(self.testSubject.nextToast(), .cloudSyncOperationComplete)
    }

    func test_firstRun_openedSettings_waitsUntilAppIsActive() {
        self.isFirstRun = true
        self.testSubject.requestToast(.cloudSyncOperationComplete)

        self.testSubject.finishFirstRun(openedSettings: true)
        self.isFirstRun = false
        self.testSubject.showWaitingToast()
        XCTAssertNil(self.testSubject.nextToast())

        self.testSubject.appBecameActive()
        XCTAssertEqual(self.testSubject.nextToast(), .cloudSyncOperationComplete)
    }

    func test_firstRun_openedSettings_toastWhileAway_waitsUntilAppIsActive() {
        self.isFirstRun = true
        self.testSubject.finishFirstRun(openedSettings: true)
        self.isFirstRun = false

        self.testSubject.requestToast(.cloudSyncOperationComplete)
        XCTAssertNil(self.testSubject.nextToast())

        self.testSubject.appBecameActive()
        XCTAssertEqual(self.testSubject.nextToast(), .cloudSyncOperationComplete)
    }

    func test_appBecameActive_notBackFromSettings_nudgeKeepsWaiting() {
        self.testSubject.setHomeIdleCheck { false }
        self.testSubject.requestToast(.tipPromotion)

        self.testSubject.appBecameActive()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_firstRun_waitingToast_shownEvenAfterAnotherToast() {
        self.testSubject.requestToast(.onClipboardSet("Email"))
        _ = self.testSubject.nextToast()
        self.testSubject.completeToast(.onClipboardSet("Email"))
        self.isFirstRun = true
        self.testSubject.requestToast(.cloudSyncOperationComplete)

        self.isFirstRun = false
        self.testSubject.showWaitingToast()

        XCTAssertEqual(self.testSubject.nextToast(), .cloudSyncOperationComplete)
    }

    func test_firstRun_offlineWaiting_backOnline_dropsIt() {
        self.isFirstRun = true
        self.testSubject.startAppEventToasts()
        self.postNetworkStatus(.offline)

        self.postNetworkStatus(.online)
        self.isFirstRun = false
        self.testSubject.showWaitingToast()

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_tipShown_reportingNudgeCannotReplaceIt() {
        self.testSubject.requestToast(.tipPromotion)
        _ = self.testSubject.nextToast()

        self.testSubject.requestToast(.enableReportingExtension)

        XCTAssertNil(self.testSubject.nextToast())
    }

    func test_dismissOtherToast_recordsNothing() {
        self.testSubject.didDismissToast(.saveFailed)

        XCTAssertEqual(self.defaultsManager.lastOfflineToastDismissSetCounter, 0)
    }

    func test_resetSession_clearsToasts() {
        self.testSubject.requestToast(.offline)
        _ = self.testSubject.nextToast()
        self.testSubject.requestToast(.saveFailed)
        self.testSubject.resetSession()

        XCTAssertNil(self.testSubject.nextToast())
        self.testSubject.requestToast(.tipPromotion)
        XCTAssertEqual(self.testSubject.nextToast(), .tipPromotion)
    }

    func test_requestToast_accepted_showsNextToast() {
        var showNextToastCount = 0
        self.testSubject.setToastPresenter { showNextToastCount += 1 }

        self.testSubject.requestToast(.offline)

        XCTAssertEqual(showNextToastCount, 1)
    }

    func test_requestToast_dropped_doesNotShowNextToast() {
        self.testSubject.requestToast(.saveFailed)
        var showNextToastCount = 0
        self.testSubject.setToastPresenter { showNextToastCount += 1 }

        self.testSubject.requestToast(.tipPromotion)

        XCTAssertEqual(showNextToastCount, 0)
    }

    func test_didShowToastThisSession_requestedAndDropped_false() {
        self.testSubject.requestToast(.saveFailed)

        self.testSubject.requestToast(.filterListsUpdated(.aiFilteringLanguage))

        XCTAssertFalse(self.testSubject.didShowToastThisSession)
    }

    func test_didShowToastThisSession_shown_true() {
        self.testSubject.requestToast(.onClipboardSet("Email"))

        _ = self.testSubject.nextToast()

        XCTAssertTrue(self.testSubject.didShowToastThisSession)
    }

    func test_resetSession_clearsDidShowToast() {
        self.testSubject.requestToast(.onClipboardSet("Email"))
        _ = self.testSubject.nextToast()

        self.testSubject.resetSession()

        XCTAssertFalse(self.testSubject.didShowToastThisSession)
    }
}
