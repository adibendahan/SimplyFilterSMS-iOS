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

    private var isFinalInactivityNotificationAsk: Bool {
        self.defaultsManager.inactivityNotificationAskCount
            == kInactivityNotificationMaxAsks - 1
    }

    var inactivityNotificationDismissTitle: String {
        self.isFinalInactivityNotificationAsk
            ? "inactivityNotification_stopAsking"~
            : "inactivityNotification_notNow"~
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

    func shouldShowInactivityNotification() async -> Bool {
        let status = await self.notificationAuthorizationStatus()
        guard self.automaticFilterManager.isAutomaticFilteringOn else { return false }
        if status.allowsAlerts {
            self.markInactivityNotificationGranted()
            return false
        }
        if self.defaultsManager.inactivityNotificationWasGranted {
            self.resetInactivityNotificationAsks()
        }
        let askCount = self.defaultsManager.inactivityNotificationAskCount
        let sessionsSinceDecline = self.defaultsManager.sessionCounter
            - self.defaultsManager.inactivityNotificationDeclinedSession
        guard askCount < kInactivityNotificationMaxAsks,
              askCount == 0 || sessionsSinceDecline >= kInactivityNotificationMinSessionsBetweenAsks else {
            return false
        }
        return true
    }

    func recordInactivityNotificationDecline() {
        if self.isFinalInactivityNotificationAsk {
            self.defaultsManager.inactivityNotificationAskCount = kInactivityNotificationMaxAsks
        } else {
            self.defaultsManager.inactivityNotificationAskCount += 1
            self.defaultsManager.inactivityNotificationDeclinedSession = self.defaultsManager.sessionCounter
        }
    }

    func requestInactivityNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        self.userNotificationCenterService.requestAlertAuthorization { [weak self] granted in
            guard let self else {
                completion(granted)
                return
            }
            if granted {
                self.markInactivityNotificationGranted()
            } else {
                self.recordInactivityNotificationDecline()
            }
            completion(granted)
        }
    }

    private func markInactivityNotificationGranted() {
        self.defaultsManager.inactivityNotificationWasGranted = true
        self.syncInactivityReminder()
    }

    private func resetInactivityNotificationAsks() {
        self.defaultsManager.inactivityNotificationWasGranted = false
        self.defaultsManager.inactivityNotificationAskCount = 0
        self.defaultsManager.inactivityNotificationDeclinedSession = 0
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
        content.title = "inactivityNotification_reminder_title"~
        content.body = "inactivityNotification_reminder_body"~
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
