//
//  SchedulingManager.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks
import UserNotifications

class SchedulingManager: SchedulingManagerProtocol {

    var automaticFilterManager: AutomaticFilterManagerProtocol
    var userNotificationCenterService: UserNotificationCenterServiceProtocol

    init(automaticFilterManager: AutomaticFilterManagerProtocol,
         userNotificationCenterService: UserNotificationCenterServiceProtocol = UserNotificationCenterService()) {
        self.automaticFilterManager = automaticFilterManager
        self.userNotificationCenterService = userNotificationCenterService
    }

    func authorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        self.userNotificationCenterService.authorizationStatus(completion: completion)
    }

    func scheduleAutomaticFiltersProcessing() {
        let request = BGProcessingTaskRequest(identifier: kAutomaticFiltersProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Calendar.current.date(byAdding: .day, value: kUpdateAutomaticFiltersMinDays, to: Date())
        do {
            try BGTaskScheduler.shared.submit(request)
            AppManager.logger.debug("scheduleAutomaticFiltersProcessing — submitted for \(request.earliestBeginDate?.description ?? "nil", privacy: .public)")
        } catch {
            AppManager.logger.error("scheduleAutomaticFiltersProcessing — failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func handleAutomaticFiltersProcessing(task: BGProcessingTask) {
        AppManager.logger.debug("handleAutomaticFiltersProcessing — started")
        let work = Task {
            await self.automaticFilterManager.updateAutomaticFiltersIfNeeded()
        }
        task.expirationHandler = {
            work.cancel()
        }
        Task {
            let success: Bool
            switch await work.result {
            case .success:
                success = true
            case .failure:
                success = false
            }
            task.setTaskCompleted(success: success)
            self.scheduleAutomaticFiltersProcessing()
        }
    }

    func syncInactivityReminder() {
        self.cancelInactivityReminder()
        guard self.automaticFilterManager.isAutomaticFilteringOn else { return }
        self.userNotificationCenterService.authorizationStatus { [weak self] status in
            guard let self else { return }
            guard self.automaticFilterManager.isAutomaticFilteringOn, status.allowsAlerts else { return }
            self.scheduleInactivityReminder()
        }
    }

    func cancelInactivityReminder() {
        self.userNotificationCenterService.removePendingNotificationRequests(
            withIdentifiers: [kAutomaticFiltersInactivityNotificationId])
    }

    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void) {
        self.userNotificationCenterService.requestAlertAuthorization { [weak self] granted in
            if granted {
                self?.syncInactivityReminder()
            }
            completion(granted)
        }
    }

    private func scheduleInactivityReminder() {
        let content = UNMutableNotificationContent()
        content.title = "autoFilter_inactivityNotification_title"~
        content.body = "autoFilter_inactivityNotification_body"~
        guard let trigger = self.monthlyRepeatingTrigger() else { return }
        let request = UNNotificationRequest(identifier: kAutomaticFiltersInactivityNotificationId,
                                            content: content,
                                            trigger: trigger)
        self.userNotificationCenterService.add(request) { error in
            if let error {
                AppManager.logger.error("scheduleInactivityReminder — failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func monthlyRepeatingTrigger() -> UNCalendarNotificationTrigger? {
        guard let fireDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) else { return nil }
        var components = Calendar.current.dateComponents([.day], from: fireDate)
        components.hour = 19
        components.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
    }
}
