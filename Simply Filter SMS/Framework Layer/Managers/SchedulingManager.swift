//
//  SchedulingManager.swift
//  Simply Filter SMS
//

import Foundation
import BackgroundTasks
import UserNotifications

class SchedulingManager: SchedulingManagerProtocol {
    
    //MARK: - Initialization -
    init(filterListManager: FilterListManagerProtocol,
         defaultsManager: DefaultsManagerProtocol,
         userNotificationCenterService: UserNotificationCenterServiceProtocol = UserNotificationCenterService()) {
        
        self.filterListManager = filterListManager
        self.defaultsManager = defaultsManager
        self.userNotificationCenterService = userNotificationCenterService
        
        self.filtersStateObserver = NotificationCenter.default.addObserver(forName: .filtersStateChanged,
                                                                          object: nil,
                                                                          queue: .main) { [weak self] _ in
            guard let self, !self.filterListManager.hasActiveFilterLists else { return }
            Log.debug("AI Filtering is off → inactivity reminder cancelled")
            self.cancelInactivityReminder()
        }
    }
    
    deinit {
        if let filtersStateObserver = self.filtersStateObserver {
            NotificationCenter.default.removeObserver(filtersStateObserver)
        }
    }
    
    
    //MARK: - Public API (SchedulingManagerProtocol) -
    var isFinalInactivityNotificationAsk: Bool {
        return self.defaultsManager.inactivityNotificationDeclineCount + 1 == kInactivityNotificationMaxAsks
    }
    
    func scheduleFilterListsProcessing() {
        let request = BGProcessingTaskRequest(identifier: kFilterListsProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Calendar.current.date(byAdding: .day,
                                                         value: kUpdateFilterListsMinDays,
                                                         to: Date())
        do {
            try BGTaskScheduler.shared.submit(request)
            Log.debug("background refresh queued, notBefore: \(request.earliestBeginDate)")
        }
        catch {
            Log.error("background refresh submit failed", error: error)
        }
    }
    
    func handleFilterListsProcessing(task: BGProcessingTask) {
        Log.debug("background refresh window granted")
        
        self.scheduleFilterListsProcessing()
        
        let refresh = Task {
            await self.filterListManager.refreshFilterLists()
            let success = !Task.isCancelled
            Log.debug("background refresh finished, success: \(success)")
            task.setTaskCompleted(success: success)
        }
        
        task.expirationHandler = {
            Log.debug("background refresh window expired → cancelled")
            refresh.cancel()
        }
    }
    
    func refreshInactivityReminder() {
        self.cancelInactivityReminder()
        
        Task { @MainActor in
            let alertsAreAllowed = await self.alertsAreAllowed
            self.recordAlertPermission(alertsAreAllowed)
            
            let hasActiveFilterLists = self.filterListManager.hasActiveFilterLists
            guard alertsAreAllowed, hasActiveFilterLists else {
                Log.debug("inactivity reminder, alertsAllowed: \(alertsAreAllowed), aiFiltering: \(hasActiveFilterLists) → not armed")
                return
            }
            
            await self.userNotificationCenterService.schedule(self.inactivityReminderRequest)
        }
    }
    
    func shouldShowInactivityNotificationAlert() async -> Bool {
        let hasActiveFilterLists = self.filterListManager.hasActiveFilterLists
        let sessionCounter = self.defaultsManager.sessionCounter
        let hasAsksLeft = self.hasAsksLeft
        let hasWaitedSinceLastDecline = self.hasWaitedSinceLastDecline
        guard hasActiveFilterLists, sessionCounter > 1, hasAsksLeft, hasWaitedSinceLastDecline else {
            Log.debug("not eligible, aiFiltering: \(hasActiveFilterLists), session: \(sessionCounter), declines: \(self.defaultsManager.inactivityNotificationDeclineCount), lastDeclineSession: \(self.defaultsManager.inactivityNotificationLastDeclineSession), asksLeft: \(hasAsksLeft), waitedSinceDecline: \(hasWaitedSinceLastDecline) → skipped")
            return false
        }

        let alertsAreAllowed = await self.alertsAreAllowed
        guard !alertsAreAllowed else {
            Log.debug("eligible, alertsAllowed: \(alertsAreAllowed) → skipped")
            return false
        }
        Log.debug("eligible, alertsAllowed: \(alertsAreAllowed) → ask")
        return true
    }
    
    func requestInactivityNotificationPermission() async {
        guard await self.userNotificationCenterService.requestAlertAuthorization() else {
            Log.debug("alerts denied → counted as a decline")
            self.recordInactivityNotificationDecline()
            return
        }
        
        Log.debug("alerts allowed → arming the monthly reminder")
        self.refreshInactivityReminder()
    }
    
    func recordInactivityNotificationDecline() {
        self.defaultsManager.inactivityNotificationDeclineCount += 1
        self.defaultsManager.inactivityNotificationLastDeclineSession = self.defaultsManager.sessionCounter
        Log.debug("decline recorded, declines: \(self.defaultsManager.inactivityNotificationDeclineCount), session: \(self.defaultsManager.sessionCounter)")
    }
    
    #if DEBUG
    func reset() {
        self.cancelInactivityReminder()
    }

    func scheduleInactivityReminderSoon() {
        let reminder = self.inactivityReminderRequest
        let soon = UNNotificationRequest(identifier: reminder.identifier,
                                         content: reminder.content,
                                         trigger: UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false))
        Task {
            await self.userNotificationCenterService.schedule(soon)
        }
    }

    func scheduleFilterListsProcessingSoon() {
        let request = BGProcessingTaskRequest(identifier: kFilterListsProcessingTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date().addingTimeInterval(60)
        do {
            try BGTaskScheduler.shared.submit(request)
            Log.debug("background refresh queued, notBefore: \(request.earliestBeginDate)")
        }
        catch {
            Log.error("background refresh submit failed", error: error)
        }
    }
    #endif // DEBUG
    
    
    //MARK: - Private -
    private let filterListManager: FilterListManagerProtocol
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
    
    private static var monthlyTrigger: UNNotificationTrigger {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayDay = calendar.component(.day, from: yesterday)
        let fireDay = min(yesterdayDay, kInactivityReminderLatestDay)

        var fireComponents = DateComponents()
        fireComponents.day = fireDay
        fireComponents.hour = kInactivityReminderHour
        fireComponents.minute = 0
        return UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: true)
    }
    
    private func recordAlertPermission(_ alertsAreAllowed: Bool) {
        guard alertsAreAllowed else {
            if self.defaultsManager.inactivityNotificationWasGranted {
                Log.debug("alerts revoked in Settings → decline history forgotten")
                self.forgetDeclineHistory()
            }
            return
        }

        guard !self.defaultsManager.inactivityNotificationWasGranted else { return }
        self.defaultsManager.inactivityNotificationWasGranted = true
        Log.debug("alerts granted, wasGranted: \(false) → \(true)")
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
