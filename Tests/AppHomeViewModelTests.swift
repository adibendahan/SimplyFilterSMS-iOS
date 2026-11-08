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
                                                  filterListManager: self.appManager.filterListManager)
    }

    //MARK: Tests
    func test_nudgeWhileSheetOpen_waitsUntilDismissed() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .about

        // Act
        self.appManager.flowManager.requestToast(.tipPromotion)
        let titleWhileSheetOpen = testSubject.overlayWindow.toastViewModel.title
        testSubject.sheetScreen = nil

        // Verify
        XCTAssertNotEqual(titleWhileSheetOpen, ToastView.Toast.tipPromotion.title)
        XCTAssertEqual(testSubject.overlayWindow.toastViewModel.title, ToastView.Toast.tipPromotion.title)
    }

    func test_resultWhileSheetOpen_showsImmediately() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)
        testSubject.sheetScreen = .about

        // Act
        self.appManager.flowManager.requestToast(.filtersImported(added: 1, skipped: 0))

        // Verify
        XCTAssertEqual(testSubject.overlayWindow.toastViewModel.title, ToastView.Toast.filtersImported(added: 1, skipped: 0).title)
    }

    func test_screenRequest_presentsSheet() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .online }
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestScreen(.tipJar)

        // Verify
        XCTAssertEqual(testSubject.sheetScreen, .tipJar)
    }

    func test_launch_offlineDismissedRecently_noOfflineToast() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineToastDismissClosure = { Date().addingTimeInterval(-10 * 60) }

        // Act
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Verify
        withExtendedLifetime(testSubject) {
            XCTAssertFalse(self.appManager.flowManager.isToastShowing)
        }
    }

    func test_launch_offlineDismissedOverAnHourAgo_showsOffline() {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }
        self.defaultsManager.lastOfflineToastDismissClosure = { Date().addingTimeInterval(-61 * 60) }

        // Act
        let testSubject = AppHomeView.ViewModel(appManager: self.appManager)

        // Verify
        withExtendedLifetime(testSubject) {
            XCTAssertTrue(self.appManager.flowManager.isToastShowing)
        }
    }
}
