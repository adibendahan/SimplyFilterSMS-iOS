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
    func recordLaunch(_ screen: Screen) -> Bool {
        if screen == .enableExtension && self.defaultsManager.isAppFirstRun {
            return false
        }

        self.pendingLaunchScreen = screen
        self.launchActionClaimedSession = true
        return true
    }

    func setScreenPresenter(_ presentNextScreen: @escaping () -> Void) {
        self.presentNextScreen = presentNextScreen
    }

    func requestScreen(_ screen: Screen) {
        self.pendingUserRequest = screen
        self.presentNextScreen()
    }

    func enableWhatsNew() {
        self.whatsNewEnabled = true
    }

    func nextScreen() -> Screen? {
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

    func completeScreen(_ screen: Screen) {
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
        self.shownToast = nil
        self.pendingToast = nil
        self.waitingNudge = nil
        self.didShowToastThisSession = false
    }


    //MARK: - Toasts -
    private(set) var didShowToastThisSession = false

    var isToastShowing: Bool {
        return self.shownToast != nil
    }

    func startAppEventToasts() {
        self.showOfflineIfStillOffline()

        guard !self.didAddObservers else { return }
        self.didAddObservers = true

        NotificationCenter.default.addObserver(forName: .cloudSyncOperationComplete, object: nil, queue: .main) { [weak self] _ in
            self?.requestToast(.cloudSyncOperationComplete)
        }

        NotificationCenter.default.addObserver(forName: .filtersSaveFailed, object: nil, queue: .main) { [weak self] _ in
            self?.requestToast(.saveFailed)
        }

        NotificationCenter.default.addObserver(forName: .networkStatusChange, object: nil, queue: .main) { [weak self] notification in
            guard let networkStatus = notification.object as? NetworkStatus else { return }
            self?.networkStatusChanged(to: networkStatus)
        }

        NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: .main) { [weak self] _ in
            guard let self, self.filterListManager.hasActiveFilterLists else { return }
            self.requestToast(.filterListsUpdated)
        }
    }

    func setToastPresenter(_ showNextToast: @escaping () -> Void) {
        self.showNextToast = showNextToast
    }

    func setHomeIdleCheck(_ isHomeIdle: @escaping () -> Bool) {
        self.isHomeIdle = isHomeIdle
    }

    func requestToast(_ toast: ToastView.Toast) {
        let mustWait = toast.isNudge && !self.isHomeIdle()
        guard mustWait else {
            self.enqueue(toast)
            return
        }

        guard !toast.isOutranked(by: self.waitingNudge) else { return }
        let toastName = String(describing: toast)
        AppManager.logger.debug("FlowManager — toast waiting (Home busy): \(toastName, privacy: .public)")
        self.waitingNudge = toast
    }

    func nextToast() -> ToastView.Toast? {
        guard let toast = self.pendingToast else { return nil }
        self.pendingToast = nil
        self.shownToast = toast
        self.didShowToastThisSession = true
        self.recordShownNudge(toast)
        return toast
    }

    func completeToast(_ toast: ToastView.Toast) {
        guard self.shownToast == toast else { return }
        self.shownToast = nil
        self.showOfflineIfStillOffline()
    }

    func didTapToast(_ toast: ToastView.Toast) {
        switch toast {
        case .enableReportingExtension:
            self.defaultsManager.didDismissReportingExtensionNudge = true
            self.requestScreen(.enableReportingExtension)

        case .tipPromotion:
            self.requestScreen(.tipJar)

        default:
            break
        }
    }

    func didDismissToast(_ toast: ToastView.Toast) {
        switch toast {
        case .offline:
            self.defaultsManager.lastOfflineToastDismiss = Date()

        default:
            break
        }
    }

    func showSessionNudges() {
        self.filterListManager.onFilterListsUpdateFinished { [weak self] in
            self?.tryShowSessionNudge()
        }
    }

    func showWaitingNudge() {
        guard self.isHomeIdle(),
              let waitingNudge = self.waitingNudge else { return }
        self.waitingNudge = nil

        guard !self.didShowToastThisSession else {
            AppManager.logger.debug("FlowManager — nudge skipped, another toast showed this session: \(String(describing: waitingNudge), privacy: .public)")
            return
        }
        self.enqueue(waitingNudge)
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
    private var shownToast: ToastView.Toast?
    private var pendingToast: ToastView.Toast?
    private var waitingNudge: ToastView.Toast?
    private var presentNextScreen: () -> Void = {}
    private var showNextToast: () -> Void = {}
    private var isHomeIdle: () -> Bool = { true }
    private var didAddObservers = false

    private var shouldShowWhatsNew: Bool {
        return self.startedAsFirstRun == false
            && self.defaultsManager.isAppFirstRun == false
            && self.launchActionClaimedSession == false
            && WhatsNewEntry.allCases.isEmpty == false
            && currentWhatsNewVersion > self.defaultsManager.lastSeenWhatsNewVersion
    }

    private var isOfflineToastSnoozed: Bool {
        guard let lastDismissDate = self.defaultsManager.lastOfflineToastDismiss,
              let snoozeDuration = ToastView.Toast.offline.snoozeAfterHide else { return false }
        return lastDismissDate.addingTimeInterval(snoozeDuration) > Date()
    }

    private func enqueue(_ toast: ToastView.Toast) {
        guard !toast.isOutranked(by: self.shownToast, self.pendingToast) else {
            let toastName = String(describing: toast)
            let shownDescription = self.shownToast.map { String(describing: $0) } ?? "nil"
            let pendingDescription = self.pendingToast.map { String(describing: $0) } ?? "nil"
            AppManager.logger.debug("FlowManager — toast dropped: \(toastName, privacy: .public) (shown: \(shownDescription, privacy: .public), pending: \(pendingDescription, privacy: .public))")
            return
        }
        self.pendingToast = toast
        self.showNextToast()
    }

    private func cancel(_ toast: ToastView.Toast) {
        if self.pendingToast == toast {
            self.pendingToast = nil
        }

        guard self.shownToast == toast else { return }
        self.shownToast = nil
        AppManager.logger.debug("FlowManager — toast cancelled: \(String(describing: toast), privacy: .public)")
        self.showNextToast()
    }

    private func networkStatusChanged(to networkStatus: NetworkStatus) {
        guard networkStatus == .online else {
            guard !self.isOfflineToastSnoozed else { return }
            self.requestToast(.offline)
            return
        }
        self.cancel(.offline)
    }

    private func showOfflineIfStillOffline() {
        guard self.networkSyncManager.networkStatus == .offline,
              !self.isOfflineToastSnoozed else { return }
        self.requestToast(.offline)
    }

    private func isDue(_ nudge: ToastView.Toast) -> Bool {
        guard let key = nudge.nudgeKey,
              let interval = nudge.nudgeSessionInterval else { return false }
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
        guard !self.didShowToastThisSession else {
            AppManager.logger.debug("FlowManager — session nudge skipped, another toast showed this session")
            return
        }

        let dueNudges = ToastView.Toast.allNudges.filter { self.isDue($0) }
        let mostUrgentNudge = dueNudges.min { $0.priority < $1.priority }
        guard let mostUrgentNudge else { return }
        self.requestToast(mostUrgentNudge)
    }

    private func recordShownNudge(_ toast: ToastView.Toast) {
        guard let key = toast.nudgeKey else { return }
        self.defaultsManager.sessionNudgeLastShownSessions[key] = self.defaultsManager.sessionCounter
    }
}
