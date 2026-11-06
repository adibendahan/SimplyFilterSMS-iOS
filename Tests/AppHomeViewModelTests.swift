//
//  AppHomeViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 03/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AppHomeViewModelTests: XCTestCase {

    private var appManager = mock_AppManager()
    private var defaultsManager = mock_DefaultsManager()
    private var networkSyncManager = mock_NetworkSyncManager()

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.appManager = mock_AppManager()
        self.defaultsManager = mock_DefaultsManager()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.appManager.defaultsManager = self.defaultsManager
        self.appManager.networkSyncManager = self.networkSyncManager
        self.defaultsManager.isAppFirstRunClosure = { false }
        self.defaultsManager.lastSeenWhatsNewVersionClosure = { currentWhatsNewVersion }
        self.appManager.flowManager = FlowManager(defaultsManager: self.defaultsManager,
                                                  networkSyncManager: self.networkSyncManager,
                                                  automaticFilterManager: self.appManager.automaticFilterManager)
    }

    //MARK: Tests
    func test_nudgeWhileSheetOpen_waitsUntilDismissed() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .about

        // Act
        self.appManager.flowManager.requestNotification(.tipPromotion)
        let titleWhileSheetOpen = testSubject.overlayWindow.notification.title
        testSubject.sheetScreen = nil

        // Verify
        XCTAssertNotEqual(titleWhileSheetOpen, NotificationView.Notification.tipPromotion.title)
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.tipPromotion.title)
    }

    func test_resultWhileSheetOpen_showsImmediately() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .about

        // Act
        self.appManager.flowManager.requestNotification(.filtersImported(added: 1, skipped: 0))

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.filtersImported(added: 1, skipped: 0).title)
    }

    func test_flowRequest_presentsSheet() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.request(.tipJar)

        // Verify
        XCTAssertEqual(testSubject.sheetScreen, .tipJar)
    }

    func test_launch_offlineDismissedRecently_noOfflineToast() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date().addingTimeInterval(-10 * 60) }

        // Act
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Verify
        withExtendedLifetime(testSubject) {
            XCTAssertFalse(self.appManager.flowManager.isNotificationShowing)
        }
    }

    func test_launch_offlineDismissedOverAnHourAgo_showsOffline() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date().addingTimeInterval(-61 * 60) }

        // Act
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Verify
        withExtendedLifetime(testSubject) {
            XCTAssertTrue(self.appManager.flowManager.isNotificationShowing)
        }
    }
}
