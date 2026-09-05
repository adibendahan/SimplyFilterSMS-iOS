//
//  mock_SchedulingManager.swift
//  Tests
//

import Foundation
import BackgroundTasks
@testable import Simply_Filter_SMS

class mock_SchedulingManager: SchedulingManagerProtocol {

    var authorizationStatusValue: NotificationAuthorizationStatus = .notDetermined
    var requestNotificationAuthorizationFromExplainerGranted = false

    var authorizationStatusCounter = 0
    var scheduleAutomaticFiltersProcessingCounter = 0
    var handleAutomaticFiltersProcessingCounter = 0
    var syncInactivityReminderCounter = 0
    var cancelInactivityReminderCounter = 0
    var requestNotificationAuthorizationFromExplainerCounter = 0

    func authorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        self.authorizationStatusCounter += 1
        completion(self.authorizationStatusValue)
    }

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

    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void) {
        self.requestNotificationAuthorizationFromExplainerCounter += 1
        completion(self.requestNotificationAuthorizationFromExplainerGranted)
    }

    func resetCounters() {
        self.authorizationStatusCounter = 0
        self.scheduleAutomaticFiltersProcessingCounter = 0
        self.handleAutomaticFiltersProcessingCounter = 0
        self.syncInactivityReminderCounter = 0
        self.cancelInactivityReminderCounter = 0
        self.requestNotificationAuthorizationFromExplainerCounter = 0
    }
}
