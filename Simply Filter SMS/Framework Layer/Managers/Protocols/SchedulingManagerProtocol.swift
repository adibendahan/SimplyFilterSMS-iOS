//
//  SchedulingManagerProtocol.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks

protocol SchedulingManagerProtocol: AnyObject {
    /// Whether the ask on screen is the last one we are allowed to make.
    var isFinalInactivityNotificationAsk: Bool { get }

    func scheduleAutomaticFiltersProcessing()
    func handleAutomaticFiltersProcessing(task: BGProcessingTask)
    func refreshInactivityReminder()
    func shouldShowInactivityNotificationAlert() async -> Bool
    func requestInactivityNotificationPermission() async
    func recordInactivityNotificationDecline()

    #if DEBUG
    func reset()
    #endif // DEBUG
}
