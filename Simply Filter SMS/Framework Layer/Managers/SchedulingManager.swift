//
//  SchedulingManager.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks
import UserNotifications

class SchedulingManager: SchedulingManagerProtocol {

    var automaticFilterManager: AutomaticFilterManagerProtocol
    var defaultsManager: DefaultsManagerProtocol
    var userNotificationCenterService: UserNotificationCenterServiceProtocol

    private var filtersStateObserver: NSObjectProtocol?

    init(automaticFilterManager: AutomaticFilterManagerProtocol,
         defaultsManager: DefaultsManagerProtocol,
         userNotificationCenterService: UserNotificationCenterServiceProtocol = UserNotificationCenterService()) {
        self.automaticFilterManager = automaticFilterManager
        self.defaultsManager = defaultsManager
        self.userNotificationCenterService = userNotificationCenterService
        self.filtersStateObserver = NotificationCenter.default.addObserver(forName: .filtersStateChanged,
                                                                            object: nil,
                                                                            queue: .main) { [weak self] _ in
            guard let self, !self.automaticFilterManager.isAutomaticFilteringOn else { return }
            self.cancelInactivityReminder()
        }
    }

    deinit {
        if let filtersStateObserver {
            NotificationCenter.default.removeObserver(filtersStateObserver)
        }
    }

    private var isFinalNotificationExplainerAsk: Bool {
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount
            == kAutomaticFiltersNotificationExplainerMaxAsks - 1
    }

    var notificationExplainerDismissTitle: String {
        self.isFinalNotificationExplainerAsk
            ? "autoFilter_notificationExplainer_stopAsking"~
            : "autoFilter_notificationExplainer_notNow"~
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
            guard let self,
                  self.automaticFilterManager.isAutomaticFilteringOn,
                  status.allowsAlerts else { return }
            self.scheduleInactivityReminder()
        }
    }

    func cancelInactivityReminder() {
        self.userNotificationCenterService.removePendingNotificationRequests(
            withIdentifiers: [kAutomaticFiltersInactivityNotificationId])
    }

    func shouldShowNotificationPermissionExplainer() async -> Bool {
        let status = await self.notificationAuthorizationStatus()
        guard self.automaticFilterManager.isAutomaticFilteringOn else { return false }
        if status.allowsAlerts {
            self.markNotificationPermissionGranted()
            return false
        }
        if self.defaultsManager.automaticFiltersNotificationPermissionWasGranted {
            self.resetNotificationExplainerAsks()
        }
        let askCount = self.defaultsManager.automaticFiltersNotificationExplainerAskCount
        let sessionsSinceDecline = self.defaultsManager.sessionCounter
            - self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession
        guard askCount < kAutomaticFiltersNotificationExplainerMaxAsks,
              askCount == 0 || sessionsSinceDecline >= kAutomaticFiltersNotificationExplainerMinSessionsBetweenAsks else {
            return false
        }
        return true
    }

    func recordNotificationExplainerDecline() {
        if self.isFinalNotificationExplainerAsk {
            self.defaultsManager.automaticFiltersNotificationExplainerAskCount = kAutomaticFiltersNotificationExplainerMaxAsks
        } else {
            self.defaultsManager.automaticFiltersNotificationExplainerAskCount += 1
            self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession = self.defaultsManager.sessionCounter
        }
    }

    func requestNotificationAuthorizationFromExplainer(completion: @escaping (Bool) -> Void) {
        self.userNotificationCenterService.requestAlertAuthorization { [weak self] granted in
            guard let self else {
                completion(granted)
                return
            }
            if granted {
                self.markNotificationPermissionGranted()
            } else {
                self.recordNotificationExplainerDecline()
            }
            completion(granted)
        }
    }

    private func markNotificationPermissionGranted() {
        self.defaultsManager.automaticFiltersNotificationPermissionWasGranted = true
        self.syncInactivityReminder()
    }

    private func resetNotificationExplainerAsks() {
        self.defaultsManager.automaticFiltersNotificationPermissionWasGranted = false
        self.defaultsManager.automaticFiltersNotificationExplainerAskCount = 0
        self.defaultsManager.automaticFiltersNotificationExplainerLastDeclinedSession = 0
    }

    private func notificationAuthorizationStatus() async -> NotificationAuthorizationStatus {
        await withCheckedContinuation { continuation in
            self.userNotificationCenterService.authorizationStatus { status in
                continuation.resume(returning: status)
            }
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
