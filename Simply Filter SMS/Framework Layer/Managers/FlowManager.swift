//
//  FlowManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation

class FlowManager: FlowManagerProtocol {

    //MARK: - Initialization -
    init(defaultsManager: DefaultsManagerProtocol) {
        self.defaultsManager = defaultsManager
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

    func request(_ screen: Screen) {
        self.pendingUserRequest = screen
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
    }

    func requestNotification(_ notification: NotificationView.Notification) {
        guard !notification.isOutranked(by: self.shownNotification, self.pendingNotification) else {
            let shown = self.shownNotification.map { String(describing: $0) } ?? "nil"
            let pending = self.pendingNotification.map { String(describing: $0) } ?? "nil"
            AppManager.logger.debug("FlowManager — notification dropped: \(String(describing: notification), privacy: .public) (shown: \(shown, privacy: .public), pending: \(pending, privacy: .public))")
            return
        }
        self.pendingNotification = notification
    }

    func nextNotification() -> NotificationView.Notification? {
        guard let notification = self.pendingNotification else { return nil }
        self.pendingNotification = nil
        self.shownNotification = notification
        return notification
    }

    func completeNotification() {
        self.shownNotification = nil
    }

    func cancelNotification(_ notification: NotificationView.Notification) -> Bool {
        if self.pendingNotification == notification {
            self.pendingNotification = nil
        }

        guard self.shownNotification == notification else { return false }
        self.shownNotification = nil
        return true
    }


    //MARK: - Private -
    private let defaultsManager: DefaultsManagerProtocol
    private var startedAsFirstRun: Bool
    private var launchActionClaimedSession = false
    private var whatsNewEnabled = false
    private var activeScreen: Screen?
    private var pendingLaunchScreen: Screen?
    private var pendingUserRequest: Screen?
    private var shownNotification: NotificationView.Notification?
    private var pendingNotification: NotificationView.Notification?

    private var shouldShowWhatsNew: Bool {
        return self.startedAsFirstRun == false
            && self.defaultsManager.isAppFirstRun == false
            && self.launchActionClaimedSession == false
            && WhatsNewEntry.allCases.isEmpty == false
            && currentWhatsNewVersion > self.defaultsManager.lastSeenWhatsNewVersion
    }
}
