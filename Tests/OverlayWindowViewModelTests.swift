//
//  OverlayWindowViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 06/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class OverlayWindowViewModelTests: XCTestCase {

    private var appManager = mock_AppManager()
    private var defaultsManager = mock_DefaultsManager()
    private var networkSyncManager = mock_NetworkSyncManager()

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.appManager = mock_AppManager()
        self.defaultsManager = mock_DefaultsManager()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.defaultsManager.isAppFirstRunClosure = { false }
        self.defaultsManager.lastSeenWhatsNewVersionClosure = { currentWhatsNewVersion }
        self.appManager.defaultsManager = self.defaultsManager
        self.appManager.networkSyncManager = self.networkSyncManager
        self.appManager.flowManager = FlowManager(defaultsManager: self.defaultsManager,
                                                  networkSyncManager: self.networkSyncManager,
                                                  filterListManager: self.appManager.filterListManager)
    }

    //MARK: Tests
    func test_requestToast_presentsIt() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestToast(.saveFailed)

        // Verify
        XCTAssertEqual(testSubject.toastViewModel.title, ToastView.Toast.saveFailed.title)
    }

    func test_init_presentsToastRequestedBefore() {
        // Prepare
        self.appManager.flowManager.requestToast(.filterExportFailed)

        // Act
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(testSubject.toastViewModel.title, ToastView.Toast.filterExportFailed.title)
    }

    func test_hide_hidesToast() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.offline)
        testSubject.toastViewModel.show = true

        // Act
        testSubject.hideToast()

        // Verify
        XCTAssertFalse(testSubject.toastViewModel.show)
    }

    func test_tipPromotionTap_requestsTipJar() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.tipPromotion)

        // Act
        testSubject.toastViewModel.onTap?()

        // Verify
        XCTAssertEqual(self.appManager.flowManager.nextScreen(), .tipJar)
    }

    func test_reportingExtensionTap_dismissesNudgeAndRequestsSheet() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.enableReportingExtension)

        // Act
        testSubject.toastViewModel.onTap?()

        // Verify
        XCTAssertEqual(self.appManager.flowManager.nextScreen(), .enableReportingExtension)
        XCTAssertEqual(self.defaultsManager.didDismissReportingExtensionNudgeSetCounter, 1)
    }

    func test_offlineCancelled_hidesToast() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineToastDismissClosure = { Date.distantPast }
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.startAppEventToasts()
        testSubject.toastViewModel.show = true

        // Act
        self.networkSyncManager.networkStatusClosure = { .online }
        NotificationCenter.default.post(name: .networkStatusChange, object: NetworkStatus.online)

        // Verify
        XCTAssertFalse(testSubject.toastViewModel.show)
    }

    func test_offlineHideButton_recordsDismiss() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.offline)
        testSubject.toastViewModel.show = true

        // Act
        testSubject.toastViewModel.onButtonTap?()

        // Verify
        XCTAssertEqual(self.defaultsManager.lastOfflineToastDismissSetCounter, 1)
    }

    func test_offlineHideButton_repeatedCalls_recordDismissOnce() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.offline)
        testSubject.toastViewModel.show = true

        // Act
        testSubject.toastViewModel.onButtonTap?()
        testSubject.toastViewModel.onButtonTap?()
        testSubject.toastViewModel.onButtonTap?()

        // Verify
        XCTAssertEqual(self.defaultsManager.lastOfflineToastDismissSetCounter, 1)
        XCTAssertFalse(testSubject.toastViewModel.show)
    }

    func test_requestToast_showsAfterItsDelay() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        let syncDelay = ToastView.Toast.cloudSyncOperationComplete.showDelay
        let beforeDelay = expectation(description: "before the sync delay")
        let afterDelay = expectation(description: "after the sync delay")
        var shownBeforeDelay = true
        var shownAfterDelay = false

        // Act
        self.appManager.flowManager.requestToast(.cloudSyncOperationComplete)
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay / 2) {
            shownBeforeDelay = testSubject.toastViewModel.show
            beforeDelay.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay + 0.5) {
            shownAfterDelay = testSubject.toastViewModel.show
            afterDelay.fulfill()
        }
        wait(for: [beforeDelay, afterDelay], timeout: syncDelay + 2)

        // Verify
        XCTAssertFalse(shownBeforeDelay)
        XCTAssertTrue(shownAfterDelay)
    }

    func test_requestToast_noDelay_showsBeforeDelayedOnesWould() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        let syncDelay = ToastView.Toast.cloudSyncOperationComplete.showDelay
        let beforeSyncDelay = expectation(description: "before the sync delay")
        var shownBeforeSyncDelay = false

        // Act
        self.appManager.flowManager.requestToast(.onClipboardSet("Email"))
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay / 2) {
            shownBeforeSyncDelay = testSubject.toastViewModel.show
            beforeSyncDelay.fulfill()
        }
        wait(for: [beforeSyncDelay], timeout: syncDelay + 2)

        // Verify
        XCTAssertTrue(shownBeforeSyncDelay)
    }

    func test_tipSuccessful_playsConfettiForItsTier() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestToast(.tipSuccessful(.large))

        // Verify
        XCTAssertEqual(testSubject.confettiTier, .large)
    }

    func test_tipSuccessfulHidden_stopsConfetti() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.tipSuccessful(.small))

        // Act
        testSubject.toastViewModel.onHide?()

        // Verify
        XCTAssertNil(testSubject.confettiTier)
    }

    func test_otherToast_noConfetti() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestToast(.onClipboardSet("Email"))

        // Verify
        XCTAssertNil(testSubject.confettiTier)
    }

    func test_replacingShownToast_slidesOldOutThenNewIn() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.offline)
        testSubject.toastViewModel.show = true
        let afterReplace = expectation(description: "after the replace delay")

        // Act
        self.appManager.flowManager.requestToast(.saveFailed)
        let shownDuringExit = testSubject.toastViewModel.show
        let titleDuringExit = testSubject.toastViewModel.title
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            afterReplace.fulfill()
        }
        wait(for: [afterReplace], timeout: 3)

        // Verify
        XCTAssertFalse(shownDuringExit)
        XCTAssertEqual(titleDuringExit, ToastView.Toast.offline.title)
        XCTAssertTrue(testSubject.toastViewModel.show)
        XCTAssertEqual(testSubject.toastViewModel.title, ToastView.Toast.saveFailed.title)
    }

    func test_replacingShownToast_oldExitDoesNotFinishNew() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.offline)
        testSubject.toastViewModel.show = true
        self.appManager.flowManager.requestToast(.saveFailed)

        // Act
        testSubject.toastViewModel.onHide?()
        self.appManager.flowManager.requestToast(.tipPromotion)

        // Verify
        XCTAssertNil(self.appManager.flowManager.nextToast())
    }

    func test_replacingShownToast_usesNewTimeout() {
        // Prepare
        let testSubject = OverlayWindowModifier.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestToast(.offline)
        testSubject.toastViewModel.show = true
        let clipboardTimeout = ToastView.Toast.onClipboardSet("").timeout ?? 0
        let afterTimeout = expectation(description: "after the clipboard timeout")

        // Act
        self.appManager.flowManager.requestToast(.onClipboardSet("Email"))
        DispatchQueue.main.asyncAfter(deadline: .now() + clipboardTimeout + 1) {
            afterTimeout.fulfill()
        }
        wait(for: [afterTimeout], timeout: clipboardTimeout + 3)

        // Verify
        XCTAssertFalse(testSubject.toastViewModel.show)
    }
}
