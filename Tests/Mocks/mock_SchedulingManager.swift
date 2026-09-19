//
//  mock_SchedulingManager.swift
//  Tests
//

import Foundation
import BackgroundTasks
@testable import Simply_Filter_SMS

class mock_SchedulingManager: SchedulingManagerProtocol {

    var scheduleAutomaticFiltersProcessingCounter = 0
    var handleAutomaticFiltersProcessingCounter = 0
    var refreshInactivityReminderCounter = 0
    var shouldShowInactivityNotificationAlertCounter = 0
    var requestInactivityNotificationPermissionCounter = 0
    var recordInactivityNotificationDeclineCounter = 0
    var resetCounter = 0

    var isFinalInactivityNotificationAskClosure: (() -> (Bool))?
    var shouldShowInactivityNotificationAlertClosure: (() -> (Bool))?

    var isFinalInactivityNotificationAsk: Bool {
        return self.isFinalInactivityNotificationAskClosure?() ?? false
    }

    func scheduleAutomaticFiltersProcessing() {
        self.scheduleAutomaticFiltersProcessingCounter += 1
    }

    func handleAutomaticFiltersProcessing(task: BGProcessingTask) {
        self.handleAutomaticFiltersProcessingCounter += 1
    }

    func refreshInactivityReminder() {
        self.refreshInactivityReminderCounter += 1
    }

    func shouldShowInactivityNotificationAlert() async -> Bool {
        self.shouldShowInactivityNotificationAlertCounter += 1
        return self.shouldShowInactivityNotificationAlertClosure?() ?? false
    }

    func requestInactivityNotificationPermission() async {
        self.requestInactivityNotificationPermissionCounter += 1
    }

    func recordInactivityNotificationDecline() {
        self.recordInactivityNotificationDeclineCounter += 1
    }

    func reset() {
        self.resetCounter += 1
    }

    func scheduleInactivityReminderSoon() { }
    func scheduleAutomaticFiltersProcessingSoon() { }

    func resetCounters() {
        self.scheduleAutomaticFiltersProcessingCounter = 0
        self.handleAutomaticFiltersProcessingCounter = 0
        self.refreshInactivityReminderCounter = 0
        self.shouldShowInactivityNotificationAlertCounter = 0
        self.requestInactivityNotificationPermissionCounter = 0
        self.recordInactivityNotificationDeclineCounter = 0
        self.resetCounter = 0
    }
}
