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
    }

    //MARK: Tests
    func test_showNotification_lowerPriorityWhileObstructed_keepsHigherPending() {
        // Prepare
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .whatsNew

        // Act
        testSubject.showNotification(.cloudSyncOperationComplete)
        testSubject.showNotification(.filterListsUpdated)
        testSubject.sheetScreen = nil

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.cloudSyncOperationComplete.title)
    }

    func test_showNotification_higherPriorityWhileObstructed_replacesPending() {
        // Prepare
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .whatsNew

        // Act
        testSubject.showNotification(.filterListsUpdated)
        testSubject.showNotification(.filtersImported(added: 1, skipped: 0))
        testSubject.sheetScreen = nil

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.filtersImported(added: 1, skipped: 0).title)
    }

    func test_showNotification_importResultAfterSaveFailed_keepsSaveFailed() {
        // Prepare
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Act
        testSubject.showNotification(.saveFailed)
        testSubject.showNotification(.filtersImported(added: 1, skipped: 0))

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.saveFailed.title)
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
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.tipPromotion.title)
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
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.offline.title)
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
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.offline.title)
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
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.tipPromotion.title)
    }
}
