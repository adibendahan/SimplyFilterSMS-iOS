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
        self.appManager.flowManager = FlowManager(defaultsManager: self.defaultsManager)
    }

    //MARK: Tests
    func test_showNotification_nudgeWhileSheetOpen_waitsUntilDismissed() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .about

        // Act
        testSubject.showNotification(.tipPromotion)
        let titleWhileSheetOpen = testSubject.overlayWindow.notification.title
        testSubject.sheetScreen = nil

        // Verify
        XCTAssertNotEqual(titleWhileSheetOpen, NotificationView.Notification.tipPromotion.title)
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.tipPromotion.title)
    }

    func test_showNotification_resultWhileSheetOpen_showsImmediately() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .about

        // Act
        testSubject.showNotification(.filtersImported(added: 1, skipped: 0))

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.filtersImported(added: 1, skipped: 0).title)
    }

    func test_startMonitoring_offlineDismissedRecently_hidesOffline() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date().addingTimeInterval(-10 * 60) }
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }

        // Act
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.tryShowTipPromotion()

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.tipPromotion.title)
    }

    func test_startMonitoring_offlineDismissedOverAnHourAgo_showsOffline() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date().addingTimeInterval(-61 * 60) }
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }

        // Act
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.tryShowTipPromotion()

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.offline.title)
    }

    func test_higherPriorityToastHides_stillOffline_showsOfflineAgain() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineNotificationDismissClosure = { Date().addingTimeInterval(-61 * 60) }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.showNotification(.saveFailed)
        testSubject.showNotification(.offline)

        // Act
        testSubject.overlayWindow.notification.onHide?()

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.offline.title)
    }

    func test_higherPriorityToastHides_backOnline_doesNotShowOffline() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.showNotification(.saveFailed)

        // Act
        testSubject.overlayWindow.notification.onHide?()

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.saveFailed.title)
    }

    func test_tryShowTipPromotion_offlineShowing_keepsOffline() {
        // Prepare
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Act
        testSubject.showNotification(.offline)
        testSubject.tryShowTipPromotion()

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.offline.title)
    }

    func test_tryShowTipPromotion_nothingShowing_showsTip() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        self.defaultsManager.sessionCounterClosure = { 5 }
        self.defaultsManager.didTipClosure = { false }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Act
        testSubject.tryShowTipPromotion()

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.notification.title, NotificationView.Notification.tipPromotion.title)
    }
}
