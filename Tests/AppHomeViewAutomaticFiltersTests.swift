//
//  AppHomeViewAutomaticFiltersTests.swift
//  Tests
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AppHomeViewAutomaticFiltersTests: XCTestCase {

    private var appManager: mock_AppManager!
    private var defaultsManager: mock_DefaultsManager!
    private var automaticFilterManager: mock_AutomaticFilterManager!
    private var notifications: mock_UserNotificationScheduling!
    private var flowManager: mock_FlowManager!
    private var isAutomaticFilteringOn = false

    override func setUp() {
        super.setUp()
        self.isAutomaticFilteringOn = false
        self.appManager = mock_AppManager()
        self.defaultsManager = mock_DefaultsManager()
        self.automaticFilterManager = mock_AutomaticFilterManager()
        self.notifications = mock_UserNotificationScheduling()
        self.flowManager = mock_FlowManager()

        self.defaultsManager.isAppFirstRunClosure = { false }
        self.automaticFilterManager.isAutomaticFilteringOnClosure = { [unowned self] in
            self.isAutomaticFilteringOn
        }
        self.automaticFilterManager.rulesClosure = { [] }
        self.automaticFilterManager.automaticRuleStateClosure = { _ in false }
        self.automaticFilterManager.selectedChoiceClosure = { _ in 0 }
        self.automaticFilterManager.selectedCountriesClosure = { _ in [] }

        self.appManager.defaultsManager = self.defaultsManager
        self.appManager.automaticFilterManager = self.automaticFilterManager
        self.appManager.userNotificationScheduling = self.notifications
        self.appManager.flowManager = self.flowManager
    }

    override func tearDown() {
        self.flowManager = nil
        self.notifications = nil
        self.automaticFilterManager = nil
        self.defaultsManager = nil
        self.appManager = nil
        super.tearDown()
    }

    func test_alreadyAuthorized_setsExplainerFlagAndSyncsWithoutAlert() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .authorized

        let model = AppHomeView.ViewModel(appManager: self.appManager)
        self.appManager.resetCounters()
        model.handleSceneBecameActive()

        XCTAssertTrue(self.defaultsManager.didShowAutomaticFiltersNotificationExplainer)
        XCTAssertFalse(model.showNotificationPermissionAlert)
        XCTAssertGreaterThan(self.appManager.syncInactivityReminderCounter, 0)
        XCTAssertEqual(self.appManager.requestNotificationAuthorizationFromExplainerCounter, 0)
    }

    func test_explainerAlreadyShown_skipsAlert() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined
        self.defaultsManager.didShowAutomaticFiltersNotificationExplainer = true

        let model = AppHomeView.ViewModel(appManager: self.appManager)
        model.handleSceneBecameActive()

        XCTAssertFalse(model.showNotificationPermissionAlert)
        XCTAssertEqual(self.appManager.requestNotificationAuthorizationFromExplainerCounter, 0)
    }

    func test_notNow_doesNotRequestAuthorization() {
        self.isAutomaticFilteringOn = true
        self.notifications.authorizationStatusValue = .notDetermined

        let model = AppHomeView.ViewModel(appManager: self.appManager)
        model.showNotificationPermissionAlert = true
        model.dismissNotificationPermissionExplainer()

        XCTAssertFalse(model.showNotificationPermissionAlert)
        XCTAssertTrue(self.defaultsManager.didShowAutomaticFiltersNotificationExplainer)
        XCTAssertEqual(self.appManager.requestNotificationAuthorizationFromExplainerCounter, 0)
    }
}
