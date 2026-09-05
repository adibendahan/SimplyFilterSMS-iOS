//
//  SchedulingManagerProtocol.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks

protocol SchedulingManagerProtocol {
    var notificationExplainerDismissTitle: String { get }

    func scheduleAutomaticFiltersProcessing()
    func handleAutomaticFiltersProcessing(task: BGProcessingTask)
    func syncInactivityReminder()
    func cancelInactivityReminder()
    func shouldShowNotificationPermissionExplainer() async -> Bool
    func recordNotificationExplainerDecline()
    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void)
}
