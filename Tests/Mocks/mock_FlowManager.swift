//
//  mock_FlowManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FlowManager: FlowManagerProtocol {

    var recordLaunchCounter = 0
    var requestCounter = 0
    var enableWhatsNewCounter = 0
    var nextCounter = 0
    var completeCounter = 0
    var resetSessionCounter = 0
    var requestNotificationCounter = 0
    var nextNotificationCounter = 0
    var completeNotificationCounter = 0
    var cancelNotificationCounter = 0

    var didShowNotificationThisSessionGetCounter = 0
    var didShowNotificationThisSessionClosure: (() -> Bool)?

    var didShowNotificationThisSession: Bool {
        self.didShowNotificationThisSessionGetCounter += 1
        return self.didShowNotificationThisSessionClosure?() ?? false
    }

    var nextScreen: Screen?
    var recordLaunchClosure: ((Screen) -> Bool)?
    var requestClosure: ((Screen) -> ())?
    var nextClosure: (() -> Screen?)?
    var completeClosure: ((Screen) -> ())?
    var requestNotificationClosure: ((NotificationView.Notification) -> ())?
    var nextNotificationClosure: (() -> NotificationView.Notification?)?
    var cancelNotificationClosure: ((NotificationView.Notification) -> Bool)?

    func recordLaunch(_ screen: Screen) -> Bool {
        self.recordLaunchCounter += 1
        return self.recordLaunchClosure?(screen) ?? true
    }

    func request(_ screen: Screen) {
        self.requestCounter += 1
        self.requestClosure?(screen)
    }

    func enableWhatsNew() {
        self.enableWhatsNewCounter += 1
    }

    func next() -> Screen? {
        self.nextCounter += 1
        if let nextClosure = self.nextClosure {
            return nextClosure()
        }
        return self.nextScreen
    }

    func complete(_ screen: Screen) {
        self.completeCounter += 1
        self.completeClosure?(screen)
    }

    func resetSession() {
        self.resetSessionCounter += 1
    }

    func requestNotification(_ notification: NotificationView.Notification) {
        self.requestNotificationCounter += 1
        self.requestNotificationClosure?(notification)
    }

    func nextNotification() -> NotificationView.Notification? {
        self.nextNotificationCounter += 1
        return self.nextNotificationClosure?()
    }

    func completeNotification() {
        self.completeNotificationCounter += 1
    }

    func cancelNotification(_ notification: NotificationView.Notification) -> Bool {
        self.cancelNotificationCounter += 1
        return self.cancelNotificationClosure?(notification) ?? false
    }
}
