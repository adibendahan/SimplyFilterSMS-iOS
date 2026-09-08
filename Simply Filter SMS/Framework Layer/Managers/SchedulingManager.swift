//
//  SchedulingManager.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks
import UserNotifications

/// Keeps automatic filtering worth having for people who never open the app: a background
/// task refreshes the filter lists whenever iOS is willing to run us, and a monthly banner
/// asks them to come back when it is not.
class SchedulingManager: SchedulingManagerProtocol {
    
    //MARK: - Initialization -
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
            AppManager.logger.debug("SchedulingManager — AI Filtering is off, dropping the inactivity reminder")
            self.cancelInactivityReminder()
        }
    }
    
    deinit {
        if let filtersStateObserver = self.filtersStateObserver {
            NotificationCenter.default.removeObserver(filtersStateObserver)
        }
    }
    
    
    //MARK: - Public API (SchedulingManagerProtocol) -
    
    //MARK: Background refresh
    func scheduleAutomaticFiltersProcessing() {
        let request = BGProcessingTaskRequest(identifier: kAutomaticFiltersProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Calendar.current.date(byAdding: .day,
                                                         value: kUpdateAutomaticFiltersMinDays,
                                                         to: Date())
        do {
            try BGTaskScheduler.shared.submit(request)
            AppManager.logger.debug("scheduleAutomaticFiltersProcessing — queued, not before \(request.earliestBeginDate?.description ?? "now", privacy: .public)")
        }
        catch {
            AppManager.logger.error("scheduleAutomaticFiltersProcessing — submit failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func handleAutomaticFiltersProcessing(task: BGProcessingTask) {
        AppManager.logger.debug("handleAutomaticFiltersProcessing — iOS granted a background window")
        
        // Claim the next window first: a slow fetch below must not drop us out of the queue.
        self.scheduleAutomaticFiltersProcessing()
        
        let refresh = Task {
            await self.automaticFilterManager.updateAutomaticFiltersIfNeeded()
            task.setTaskCompleted(success: !Task.isCancelled)
        }
        
        task.expirationHandler = {
            AppManager.logger.debug("handleAutomaticFiltersProcessing — window expired before the fetch finished")
            refresh.cancel()
        }
    }
    
    //MARK: Inactivity reminder
    func refreshInactivityReminder() {
        self.cancelInactivityReminder()
        
        Task { @MainActor in
            let alertsAreAllowed = await self.alertsAreAllowed
            self.recordAlertPermission(alertsAreAllowed)
            
            guard alertsAreAllowed,
                  self.automaticFilterManager.isAutomaticFilteringOn else { return }
            
            await self.userNotificationCenterService.schedule(self.inactivityReminderRequest)
        }
    }
    
    //MARK: Inactivity notification
    var isFinalInactivityNotificationAsk: Bool {
        return self.defaultsManager.inactivityNotificationDeclineCount + 1 == kInactivityNotificationMaxAsks
    }
    
    func shouldShowInactivityNotificationAlert() async -> Bool {
        guard self.automaticFilterManager.isAutomaticFilteringOn,
              self.hasAsksLeft,
              self.hasWaitedSinceLastDecline else { return false }
        
        return await self.alertsAreAllowed == false
    }
    
    /// The user tapped Continue. A denial from iOS is still a "no", so it counts as a decline.
    func requestInactivityNotificationPermission() async {
        guard await self.userNotificationCenterService.requestAlertAuthorization() else {
            AppManager.logger.debug("requestInactivityNotificationPermission — iOS denied alerts, counting it as a decline")
            self.recordInactivityNotificationDecline()
            return
        }
        
        AppManager.logger.debug("requestInactivityNotificationPermission — alerts allowed, arming the monthly reminder")
        self.refreshInactivityReminder()
    }
    
    func recordInactivityNotificationDecline() {
        self.defaultsManager.inactivityNotificationDeclineCount += 1
        self.defaultsManager.inactivityNotificationLastDeclineSession = self.defaultsManager.sessionCounter
    }
    
    #if DEBUG
    func reset() {
        self.cancelInactivityReminder()
    }
    #endif // DEBUG
    
    
    //MARK: - Private -
    private let automaticFilterManager: AutomaticFilterManagerProtocol
    private let userNotificationCenterService: UserNotificationCenterServiceProtocol
    private var defaultsManager: DefaultsManagerProtocol
    private var filtersStateObserver: NSObjectProtocol?
    
    private var alertsAreAllowed: Bool {
        get async {
            return await self.userNotificationCenterService.authorizationStatus().allowsAlerts
        }
    }
    
    private var hasAsksLeft: Bool {
        return self.defaultsManager.inactivityNotificationDeclineCount < kInactivityNotificationMaxAsks
    }
    
    /// The first ask waits for nothing; every later one sits out a few sessions, so that
    /// answering "Not Now" is not met with the same question tomorrow.
    private var hasWaitedSinceLastDecline: Bool {
        guard self.defaultsManager.inactivityNotificationDeclineCount > 0 else { return true }
        
        let sessionsSinceDecline = self.defaultsManager.sessionCounter - self.defaultsManager.inactivityNotificationLastDeclineSession
        return sessionsSinceDecline >= kInactivityNotificationMinSessionsBetweenAsks
    }
    
    private var inactivityReminderRequest: UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "inactivityNotification_reminder_title"~
        content.body = "inactivityNotification_reminder_body"~
        
        return UNNotificationRequest(identifier: kInactivityReminderNotificationIdentifier,
                                     content: content,
                                     trigger: Self.monthlyTrigger)
    }
    
    /// A month from now at an hour nobody minds, and every month after that.
    ///
    /// A calendar trigger cannot say "skip this month", so one matching today's day of month
    /// would fire again this evening rather than in a month. An interval keeps the promise.
    private static var monthlyTrigger: UNNotificationTrigger {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        let fireDate = calendar.date(bySettingHour: kInactivityReminderHour, minute: 0, second: 0, of: nextMonth) ?? nextMonth
        
        return UNTimeIntervalNotificationTrigger(timeInterval: fireDate.timeIntervalSinceNow, repeats: true)
    }
    
    /// Remembering a grant is what lets us notice a revoke in Settings later — and when we do,
    /// the decline history goes with it, so the conversation may start over.
    private func recordAlertPermission(_ alertsAreAllowed: Bool) {
        guard alertsAreAllowed else {
            if self.defaultsManager.inactivityNotificationWasGranted {
                AppManager.logger.debug("recordAlertPermission — alerts were revoked in Settings, forgetting the decline history")
                self.forgetDeclineHistory()
            }
            return
        }
        
        self.defaultsManager.inactivityNotificationWasGranted = true
    }
    
    private func forgetDeclineHistory() {
        self.defaultsManager.inactivityNotificationWasGranted = false
        self.defaultsManager.inactivityNotificationDeclineCount = 0
        self.defaultsManager.inactivityNotificationLastDeclineSession = 0
    }
    
    private func cancelInactivityReminder() {
        self.userNotificationCenterService.cancelPendingNotification(withIdentifier: kInactivityReminderNotificationIdentifier)
    }
}
