//
//  SchedulingManagerProtocol.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks

protocol SchedulingManagerProtocol {
    func authorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void)
    func scheduleAutomaticFiltersProcessing()
    func handleAutomaticFiltersProcessing(task: BGProcessingTask)
    func syncInactivityReminder()
    func cancelInactivityReminder()
    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void)
}
