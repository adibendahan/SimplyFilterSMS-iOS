//
//  mock_SchedulingManager.swift
//  Tests
//

import Foundation
import BackgroundTasks
@testable import Simply_Filter_SMS

class mock_SchedulingManager: SchedulingManagerProtocol {

    var notificationExplainerDismissTitle = "autoFilter_notificationExplainer_notNow"~
    var requestNotificationAuthorizationFromExplainerGranted = false
    var shouldShowNotificationPermissionExplainerValue = false

    var scheduleAutomaticFiltersProcessingCounter = 0
    var handleAutomaticFiltersProcessingCounter = 0
    var syncInactivityReminderCounter = 0
    var cancelInactivityReminderCounter = 0
    var shouldShowNotificationPermissionExplainerCounter = 0
    var recordNotificationExplainerDeclineCounter = 0
    var requestNotificationAuthorizationFromExplainerCounter = 0

    func scheduleAutomaticFiltersProcessing() {
        self.scheduleAutomaticFiltersProcessingCounter += 1
    }

    func handleAutomaticFiltersProcessing(task: BGProcessingTask) {
        self.handleAutomaticFiltersProcessingCounter += 1
        task.setTaskCompleted(success: true)
    }

    func syncInactivityReminder() {
        self.syncInactivityReminderCounter += 1
    }

    func cancelInactivityReminder() {
        self.cancelInactivityReminderCounter += 1
    }

    func shouldShowNotificationPermissionExplainer() async -> Bool {
        self.shouldShowNotificationPermissionExplainerCounter += 1
        return self.shouldShowNotificationPermissionExplainerValue
    }

    func recordNotificationExplainerDecline() {
        self.recordNotificationExplainerDeclineCounter += 1
    }

    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void) {
        self.requestNotificationAuthorizationFromExplainerCounter += 1
        completion(self.requestNotificationAuthorizationFromExplainerGranted)
    }

    func resetCounters() {
        self.scheduleAutomaticFiltersProcessingCounter = 0
        self.handleAutomaticFiltersProcessingCounter = 0
        self.syncInactivityReminderCounter = 0
        self.cancelInactivityReminderCounter = 0
        self.shouldShowNotificationPermissionExplainerCounter = 0
        self.recordNotificationExplainerDeclineCounter = 0
        self.requestNotificationAuthorizationFromExplainerCounter = 0
    }
}
