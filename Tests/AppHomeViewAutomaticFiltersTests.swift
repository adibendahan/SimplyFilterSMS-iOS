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
    private var schedulingManager: mock_SchedulingManager!
    private var flowManager: mock_FlowManager!
    private var isAutomaticFilteringOn = false

    override func setUp() {
        super.setUp()
        self.isAutomaticFilteringOn = false
        self.appManager = mock_AppManager()
        self.defaultsManager = mock_DefaultsManager()
        self.automaticFilterManager = mock_AutomaticFilterManager()
        self.schedulingManager = mock_SchedulingManager()
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
        self.appManager.schedulingManager = self.schedulingManager
        self.appManager.flowManager = self.flowManager
    }

    override func tearDown() {
        self.flowManager = nil
        self.schedulingManager = nil
        self.automaticFilterManager = nil
        self.defaultsManager = nil
        self.appManager = nil
        super.tearDown()
    }

    @MainActor
    private func makeModel() async -> AppHomeView.ViewModel {
        self.schedulingManager.shouldShowInactivityNotificationValue = false
        let model = AppHomeView.ViewModel(appManager: self.appManager)
        await Task.yield()
        await Task.yield()
        self.appManager.resetCounters()
        self.flowManager.enableInactivityNotificationCounter = 0
        self.schedulingManager.resetCounters()
        return model
    }

    @MainActor
    func test_shouldShowFalse_doesNotEnableInactivityNotification() async {
        self.isAutomaticFilteringOn = true
        let model = await self.makeModel()
        self.schedulingManager.shouldShowInactivityNotificationValue = false

        await model.presentInactivityNotificationIfNeeded()

        XCTAssertFalse(model.showInactivityNotificationAlert)
        XCTAssertEqual(self.flowManager.enableInactivityNotificationCounter, 0)
        XCTAssertEqual(self.schedulingManager.requestInactivityNotificationAuthorizationCounter, 0)
    }

    @MainActor
    func test_shouldShowTrue_enablesInactivityNotification() async {
        self.isAutomaticFilteringOn = true
        let model = await self.makeModel()
        self.schedulingManager.shouldShowInactivityNotificationValue = true
        self.flowManager.enableInactivityNotificationCounter = 0

        await model.presentInactivityNotificationIfNeeded()

        XCTAssertGreaterThanOrEqual(self.flowManager.enableInactivityNotificationCounter, 1)
    }

    @MainActor
    func test_dismiss_recordsDecline() async {
        self.isAutomaticFilteringOn = true
        let model = await self.makeModel()
        model.showInactivityNotificationAlert = true
        model.dismissInactivityNotification()

        XCTAssertFalse(model.showInactivityNotificationAlert)
        XCTAssertEqual(self.schedulingManager.recordInactivityNotificationDeclineCounter, 1)
        XCTAssertEqual(self.schedulingManager.requestInactivityNotificationAuthorizationCounter, 0)
    }

    @MainActor
    func test_continue_requestsAuthorization() async {
        let model = await self.makeModel()
        model.showInactivityNotificationAlert = true
        model.continueInactivityNotification()

        XCTAssertEqual(self.schedulingManager.requestInactivityNotificationAuthorizationCounter, 1)
        XCTAssertEqual(self.schedulingManager.recordInactivityNotificationDeclineCounter, 0)
    }
}
