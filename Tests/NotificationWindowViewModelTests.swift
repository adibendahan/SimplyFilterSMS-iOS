//
//  NotificationWindowViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 06/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class NotificationWindowViewModelTests: XCTestCase {

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
        let testSubject = NotificationWindowView.ViewModel(appManager: self.appManager)

        // Act
        self.appManager.flowManager.requestNotification(.saveFailed)

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.saveFailed.title)
    }

    func test_init_presentsNotificationRequestedBefore() {
        // Prepare
        self.appManager.flowManager.requestNotification(.filterExportFailed)

        // Act
        let testSubject = NotificationWindowView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(testSubject.notification.title, NotificationView.Notification.filterExportFailed.title)
    }

    func test_hide_hidesToast() {
        // Prepare
        let testSubject = NotificationWindowView.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestNotification(.offline)
        testSubject.notification.show = true

        // Act
        testSubject.hide()

        // Verify
        XCTAssertFalse(testSubject.notification.show)
    }

    func test_tipPromotionTap_requestsTipJar() {
        // Prepare
        let testSubject = NotificationWindowView.ViewModel(appManager: self.appManager)
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
        let testSubject = NotificationWindowView.ViewModel(appManager: self.appManager)
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
        let testSubject = NotificationWindowView.ViewModel(appManager: self.appManager)
        self.appManager.flowManager.requestNotification(.offline)

        // Act
        testSubject.notification.onButtonTap?()

        // Verify
        XCTAssertEqual(self.defaultsManager.lastOfflineNotificationDismissSetCounter, 1)
    }
}
