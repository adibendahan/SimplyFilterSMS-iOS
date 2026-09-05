//
//  mock_SchedulingManager.swift
//  Tests
//

import Foundation
import BackgroundTasks
@testable import Simply_Filter_SMS

class mock_SchedulingManager: SchedulingManagerProtocol {

    var inactivityNotificationDismissTitle = "inactivityNotification_notNow"~
    var requestInactivityNotificationAuthorizationGranted = false
    var shouldShowInactivityNotificationValue = false

    var scheduleAutomaticFiltersProcessingCounter = 0
    var handleAutomaticFiltersProcessingCounter = 0
    var syncInactivityReminderCounter = 0
    var cancelInactivityReminderCounter = 0
    var shouldShowInactivityNotificationCounter = 0
    var recordInactivityNotificationDeclineCounter = 0
    var requestInactivityNotificationAuthorizationCounter = 0

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

    func shouldShowInactivityNotification() async -> Bool {
        self.shouldShowInactivityNotificationCounter += 1
        return self.shouldShowInactivityNotificationValue
    }

    func recordInactivityNotificationDecline() {
        self.recordInactivityNotificationDeclineCounter += 1
    }

    func requestInactivityNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        self.requestInactivityNotificationAuthorizationCounter += 1
        completion(self.requestInactivityNotificationAuthorizationGranted)
    }

    func resetCounters() {
        self.scheduleAutomaticFiltersProcessingCounter = 0
        self.handleAutomaticFiltersProcessingCounter = 0
        self.syncInactivityReminderCounter = 0
        self.cancelInactivityReminderCounter = 0
        self.shouldShowInactivityNotificationCounter = 0
        self.recordInactivityNotificationDeclineCounter = 0
        self.requestInactivityNotificationAuthorizationCounter = 0
    }
}
