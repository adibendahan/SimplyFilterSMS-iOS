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

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.appManager = mock_AppManager()
        self.defaultsManager = mock_DefaultsManager()
        self.appManager.defaultsManager = self.defaultsManager
        self.appManager.flowManager = FlowManager(defaultsManager: self.defaultsManager)
    }

    //MARK: Tests
    func test_requestNotification_presentsIt() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestNotification(.saveFailed)

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.saveFailed.title)
    }

    func test_init_presentsNotificationRequestedBefore() {
        // Prepare
        self.appManager.flowManager.requestNotification(.filterExportFailed)

        // Act
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.filterExportFailed.title)
    }

    func test_hide_hidesToast() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestNotification(.offline)
        testSubject.notification.show = true

        // Act
        testSubject.hide()

        // Verify
        XCTAssertFalse(testSubject.notification.show)
    }

    func test_tipPromotionTap_requestsTipJar() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        var requestedScreen: Screen?
        testSubject.onRequestSheet = { screen in
            requestedScreen = screen
        }
        self.appManager.flowManager.requestNotification(.tipPromotion)

        // Act
        testSubject.notification.onTap?()

        // Verify
        XCTAssertEqual(requestedScreen, .tipJar)
    }

    func test_reportingExtensionTap_dismissesNudgeAndRequestsSheet() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        var requestedScreen: Screen?
        testSubject.onRequestSheet = { screen in
            requestedScreen = screen
        }
        self.appManager.flowManager.requestNotification(.enableReportingExtension)

        // Act
        testSubject.notification.onTap?()

        // Verify
        XCTAssertEqual(requestedScreen, .enableReportingExtension)
        XCTAssertEqual(self.defaultsManager.didDismissReportingExtensionNudgeSetCounter, 1)
    }

    func test_offlineHideButton_recordsDismiss() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestNotification(.offline)

        // Act
        testSubject.notification.onButtonTap?()

        // Verify
        XCTAssertEqual(self.defaultsManager.lastOfflineNotificationDismissSetCounter, 1)
    }

    func test_requestNotification_showsAfterItsDelay() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        let syncDelay = NotificationView.Notification.cloudSyncOperationComplete.showDelay
        let beforeDelay = expectation(description: "before the sync delay")
        let afterDelay = expectation(description: "after the sync delay")
        var shownBeforeDelay = true
        var shownAfterDelay = false

        // Act
        self.appManager.flowManager.requestNotification(.cloudSyncOperationComplete)
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay / 2) {
            shownBeforeDelay = testSubject.notification.show
            beforeDelay.fulfill()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay + 0.5) {
            shownAfterDelay = testSubject.notification.show
            afterDelay.fulfill()
        }
        wait(for: [beforeDelay, afterDelay], timeout: syncDelay + 2)

        // Verify
        XCTAssertFalse(shownBeforeDelay)
        XCTAssertTrue(shownAfterDelay)
    }

    func test_requestNotification_noDelay_showsBeforeDelayedOnesWould() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        let syncDelay = NotificationView.Notification.cloudSyncOperationComplete.showDelay
        let beforeSyncDelay = expectation(description: "before the sync delay")
        var shownBeforeSyncDelay = false

        // Act
        self.appManager.flowManager.requestNotification(.onClipboardSet("Email"))
        DispatchQueue.main.asyncAfter(deadline: .now() + syncDelay / 2) {
            shownBeforeSyncDelay = testSubject.notification.show
            beforeSyncDelay.fulfill()
        }
        wait(for: [beforeSyncDelay], timeout: syncDelay + 2)

        // Verify
        XCTAssertTrue(shownBeforeSyncDelay)
    }

    func test_tipSuccessful_playsConfettiForItsTier() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestNotification(.tipSuccessful(.large))

        // Verify
        XCTAssertEqual(testSubject.confettiTier, .large)
    }

    func test_tipSuccessfulHidden_stopsConfetti() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestNotification(.tipSuccessful(.small))

        // Act
        testSubject.notification.onHide?()

        // Verify
        XCTAssertNil(testSubject.confettiTier)
    }

    func test_otherToast_noConfetti() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestNotification(.onClipboardSet("Email"))

        // Verify
        XCTAssertNil(testSubject.confettiTier)
    }

    func test_replacingShownToast_usesNewTimeout() {
        // Prepare
        let testSubject = OverlayWindowView.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestNotification(.offline)
        testSubject.notification.show = true
        let clipboardTimeout = NotificationView.Notification.onClipboardSet("").timeout ?? 0
        let afterTimeout = expectation(description: "after the clipboard timeout")

        // Act
        self.appManager.flowManager.requestNotification(.onClipboardSet("Email"))
        DispatchQueue.main.asyncAfter(deadline: .now() + clipboardTimeout + 1) {
            afterTimeout.fulfill()
        }
        wait(for: [afterTimeout], timeout: clipboardTimeout + 3)

        // Verify
        XCTAssertFalse(testSubject.notification.show)
    }
}
