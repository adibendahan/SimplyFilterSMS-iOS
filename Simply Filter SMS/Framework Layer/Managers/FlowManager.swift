//
//  FlowManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation

class FlowManager: FlowManagerProtocol {

    //MARK: - Initialization -
    init(defaultsManager: DefaultsManagerProtocol,
         networkSyncManager: NetworkSyncManagerProtocol,
         filterListManager: FilterListManagerProtocol) {
        self.defaultsManager = defaultsManager
        self.networkSyncManager = networkSyncManager
        self.filterListManager = filterListManager
        self.startedAsFirstRun = defaultsManager.isAppFirstRun
    }


    //MARK: - Public API (FlowManagerProtocol) -
    private(set) var didShowNotificationThisSession = false

    var isNotificationShowing: Bool {
        return self.shownNotification != nil
    }

    func recordLaunch(_ screen: Screen) -> Bool {
        if screen == .enableExtension && self.defaultsManager.isAppFirstRun {
            return false
        }

        self.pendingLaunchScreen = screen
        self.launchActionClaimedSession = true
        return true
    }

    func request(_ screen: Screen) {
        self.pendingUserRequest = screen
        NotificationCenter.default.post(name: .flowRequested, object: nil)
    }

    func enableWhatsNew() {
        self.whatsNewEnabled = true
    }

    func next() -> Screen? {
        if self.activeScreen != nil {
            return nil
        }

        if self.defaultsManager.isAppFirstRun {
            self.activeScreen = .enableExtension
            return .enableExtension
        }

        if let screen = self.pendingLaunchScreen {
            self.activeScreen = screen
            return screen
        }

        if self.whatsNewEnabled && self.shouldShowWhatsNew {
            self.activeScreen = .whatsNew
            return .whatsNew
        }

        if let screen = self.pendingUserRequest {
            self.activeScreen = screen
            return screen
        }

        return nil
    }

    func complete(_ screen: Screen) {
        if self.activeScreen == screen {
            self.activeScreen = nil
        }

        if self.pendingLaunchScreen == screen {
            self.pendingLaunchScreen = nil
        }

        if self.pendingUserRequest == screen {
            self.pendingUserRequest = nil
        }
    }

    func resetSession() {
        self.pendingLaunchScreen = nil
        self.pendingUserRequest = nil
        self.activeScreen = nil
        self.launchActionClaimedSession = false
        self.whatsNewEnabled = false
        self.startedAsFirstRun = self.defaultsManager.isAppFirstRun
        self.shownNotification = nil
        self.pendingNotification = nil
        self.waitingNotification = nil
        self.didShowNotificationThisSession = false
        self.isSessionNudgeWaitingForCheck = false
    }


    //MARK: - Notifications -
    func startMonitoring() {
        self.showOfflineIfStillOffline()

        guard !self.didAddObservers else { return }
        self.didAddObservers = true

        NotificationCenter.default.addObserver(forName: .cloudSyncOperationComplete, object: nil, queue: .main) { [weak self] _ in
            self?.requestNotification(.cloudSyncOperationComplete)
        }

        NotificationCenter.default.addObserver(forName: .filtersSaveFailed, object: nil, queue: .main) { [weak self] _ in
            self?.requestNotification(.saveFailed)
        }

        NotificationCenter.default.addObserver(forName: .networkStatusChange, object: nil, queue: .main) { [weak self] notification in
            guard let networkStatus = notification.object as? NetworkStatus else { return }
            self?.networkStatusChanged(to: networkStatus)
        }

        NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.filterListManager.hasActiveFilterLists else { return }
            self.requestNotification(.filterListsUpdated)
        }

        NotificationCenter.default.addObserver(forName: .filterListsCheckFinished, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.isSessionNudgeWaitingForCheck else { return }
            self.isSessionNudgeWaitingForCheck = false
            self.tryShowSessionNudge()
        }
    }

    func setHomeAvailability(_ isHomeUnobstructed: @escaping () -> Bool) {
        self.isHomeUnobstructed = isHomeUnobstructed
    }

    func homeMayBeUnobstructed() {
        guard self.isHomeUnobstructed(),
              let waitingNotification = self.waitingNotification else { return }
        self.waitingNotification = nil

        guard !self.didShowNotificationThisSession else {
            AppManager.logger.debug("FlowManager — nudge skipped, another toast showed this session: \(String(describing: waitingNotification), privacy: .public)")
            return
        }
        self.enqueue(waitingNotification)
    }

    func requestNotification(_ notification: NotificationView.Notification) {
        let mustWait = notification.isNudge && !self.isHomeUnobstructed()
        guard mustWait else {
            self.enqueue(notification)
            return
        }

        guard !notification.isOutranked(by: self.waitingNotification) else { return }
        let notificationName = String(describing: notification)
        AppManager.logger.debug("FlowManager — notification waiting (Home obstructed): \(notificationName, privacy: .public)")
        self.waitingNotification = notification
    }

    func nextNotification() -> NotificationView.Notification? {
        guard let notification = self.pendingNotification else { return nil }
        self.pendingNotification = nil
        self.shownNotification = notification
        self.didShowNotificationThisSession = true
        self.recordShownNudge(notification)
        return notification
    }

    func completeNotification() {
        self.shownNotification = nil
        self.showOfflineIfStillOffline()
    }

    func didTapNotification(_ notification: NotificationView.Notification) {
        switch notification {
        case .enableReportingExtension:
            self.defaultsManager.didDismissReportingExtensionNudge = true
            self.request(.enableReportingExtension)

        case .tipPromotion:
            self.request(.tipJar)

        default:
            break
        }
    }

    func didDismissNotification(_ notification: NotificationView.Notification) {
        switch notification {
        case .offline:
            self.defaultsManager.lastOfflineNotificationDismiss = Date()

        default:
            break
        }
    }

    func showSessionNudges() {
        guard self.filterListManager.isCheckingFilterLists else {
            self.tryShowSessionNudge()
            return
        }
        AppManager.logger.debug("FlowManager — session nudge waits for the filter lists check")
        self.isSessionNudgeWaitingForCheck = true
    }


    //MARK: - Private -
    private var defaultsManager: DefaultsManagerProtocol
    private let networkSyncManager: NetworkSyncManagerProtocol
    private let filterListManager: FilterListManagerProtocol
    private var startedAsFirstRun: Bool
    private var launchActionClaimedSession = false
    private var whatsNewEnabled = false
    private var activeScreen: Screen?
    private var pendingLaunchScreen: Screen?
    private var pendingUserRequest: Screen?
    private var shownNotification: NotificationView.Notification?
    private var pendingNotification: NotificationView.Notification?
    private var waitingNotification: NotificationView.Notification?
    private var isHomeUnobstructed: () -> Bool = { true }
    private var isSessionNudgeWaitingForCheck = false
    private var didAddObservers = false

    private var shouldShowWhatsNew: Bool {
        return self.startedAsFirstRun == false
            && self.defaultsManager.isAppFirstRun == false
            && self.launchActionClaimedSession == false
            && WhatsNewEntry.allCases.isEmpty == false
            && currentWhatsNewVersion > self.defaultsManager.lastSeenWhatsNewVersion
    }

    private var userIgnoresNetworkStatus: Bool {
        guard let lastDismissDate = self.defaultsManager.lastOfflineNotificationDismiss,
              let snoozeDuration = NotificationView.Notification.offline.snoozeAfterHide else { return false }
        return lastDismissDate.addingTimeInterval(snoozeDuration) > Date()
    }

    private func enqueue(_ notification: NotificationView.Notification) {
        guard !notification.isOutranked(by: self.shownNotification, self.pendingNotification) else {
            let notificationName = String(describing: notification)
            let shownDescription = self.shownNotification.map { String(describing: $0) } ?? "nil"
            let pendingDescription = self.pendingNotification.map { String(describing: $0) } ?? "nil"
            AppManager.logger.debug("FlowManager — notification dropped: \(notificationName, privacy: .public) (shown: \(shownDescription, privacy: .public), pending: \(pendingDescription, privacy: .public))")
            return
        }
        self.pendingNotification = notification
        NotificationCenter.default.post(name: .notificationSlotChanged, object: nil)
    }

    private func cancel(_ notification: NotificationView.Notification) {
        if self.pendingNotification == notification {
            self.pendingNotification = nil
        }

        guard self.shownNotification == notification else { return }
        self.shownNotification = nil
        AppManager.logger.debug("FlowManager — notification cancelled: \(String(describing: notification), privacy: .public)")
        NotificationCenter.default.post(name: .notificationSlotChanged, object: nil)
    }

    private func networkStatusChanged(to networkStatus: NetworkStatus) {
        guard networkStatus == .online else {
            guard !self.userIgnoresNetworkStatus else { return }
            self.requestNotification(.offline)
            return
        }
        self.cancel(.offline)
    }

    private func showOfflineIfStillOffline() {
        guard self.networkSyncManager.networkStatus == .offline,
              !self.userIgnoresNetworkStatus else { return }
        self.requestNotification(.offline)
    }

    private func isDue(_ nudge: NotificationView.Notification) -> Bool {
        guard let key = nudge.nudgeKey,
              let interval = nudge.nudgeInterval else { return false }
        let lastShownSession = self.defaultsManager.sessionNudgeLastShownSessions[key] ?? 0
        let sessionsSinceShown = self.defaultsManager.sessionCounter - lastShownSession
        guard sessionsSinceShown >= interval else { return false }

        switch nudge {
        case .tipPromotion:
            return !self.defaultsManager.didTip

        case .enableReportingExtension:
            return !self.defaultsManager.isAppFirstRun
                && !self.defaultsManager.didDismissReportingExtensionNudge
                && self.filterListManager.hasActiveFilterLists

        default:
            return false
        }
    }

    private func tryShowSessionNudge() {
        guard !self.didShowNotificationThisSession else {
            AppManager.logger.debug("FlowManager — session nudge skipped, another toast showed this session")
            return
        }

        let dueNudges = NotificationView.Notification.allNudges.filter { self.isDue($0) }
        let mostUrgentNudge = dueNudges.min { $0.priority < $1.priority }
        guard let mostUrgentNudge else { return }
        self.requestNotification(mostUrgentNudge)
    }

    private func recordShownNudge(_ notification: NotificationView.Notification) {
        guard let key = notification.nudgeKey else { return }
        self.defaultsManager.sessionNudgeLastShownSessions[key] = self.defaultsManager.sessionCounter
    }
}
