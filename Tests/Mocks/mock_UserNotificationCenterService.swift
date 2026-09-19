//
//  mock_UserNotificationCenterService.swift
//  Tests
//

import Foundation
import UserNotifications
@testable import Simply_Filter_SMS

class mock_UserNotificationCenterService: UserNotificationCenterServiceProtocol {

    var authorizationStatusCounter = 0
    var requestAlertAuthorizationCounter = 0
    var scheduleCounter = 0
    var cancelPendingNotificationCounter = 0

    var authorizationStatusClosure: (() -> (UNAuthorizationStatus))?
    var requestAlertAuthorizationClosure: (() -> (Bool))?
    var scheduleClosure: ((UNNotificationRequest) -> ())?
    var cancelPendingNotificationClosure: ((String) -> ())?

    private(set) var scheduledRequest: UNNotificationRequest?

    func authorizationStatus() async -> UNAuthorizationStatus {
        self.authorizationStatusCounter += 1
        return self.authorizationStatusClosure?() ?? .notDetermined
    }

    func requestAlertAuthorization() async -> Bool {
        self.requestAlertAuthorizationCounter += 1
        return self.requestAlertAuthorizationClosure?() ?? false
    }

    func schedule(_ request: UNNotificationRequest) async {
        self.scheduleCounter += 1
        self.scheduledRequest = request
        self.scheduleClosure?(request)
    }

    func cancelPendingNotification(withIdentifier identifier: String) {
        self.cancelPendingNotificationCounter += 1
        self.scheduledRequest = nil
        self.cancelPendingNotificationClosure?(identifier)
    }

    func resetCounters() {
        self.authorizationStatusCounter = 0
        self.requestAlertAuthorizationCounter = 0
        self.scheduleCounter = 0
        self.cancelPendingNotificationCounter = 0
    }
}
