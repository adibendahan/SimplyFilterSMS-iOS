//
//  SchedulingManagerProtocol.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks

protocol SchedulingManagerProtocol {
    var inactivityNotificationDismissTitle: String { get }

    func scheduleAutomaticFiltersProcessing()
    func handleAutomaticFiltersProcessing(task: BGProcessingTask)
    func syncInactivityReminder()
    func cancelInactivityReminder()
    func shouldShowInactivityNotification() async -> Bool
    func recordInactivityNotificationDecline()
    func requestInactivityNotificationAuthorization(completion: @escaping (Bool) -> Void)
}
