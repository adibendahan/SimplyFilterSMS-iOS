//
//  SchedulingManagerProtocol.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks

protocol SchedulingManagerProtocol: AnyObject {
    var isFinalInactivityNotificationAsk: Bool { get }

    func scheduleAutomaticFiltersProcessing()
    func handleAutomaticFiltersProcessing(task: BGProcessingTask)
    func refreshInactivityReminder()
    func shouldShowInactivityNotificationAlert() async -> Bool
    func requestInactivityNotificationPermission() async
    func recordInactivityNotificationDecline()

    #if DEBUG
    func reset()
    func scheduleInactivityReminderSoon()
    func scheduleAutomaticFiltersProcessingSoon()
    #endif // DEBUG
}
