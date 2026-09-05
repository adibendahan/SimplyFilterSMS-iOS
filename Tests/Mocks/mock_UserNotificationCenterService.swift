//
//  mock_UserNotificationCenterService.swift
//  Tests
//

import Foundation
import UserNotifications
@testable import Simply_Filter_SMS

class mock_UserNotificationCenterService: UserNotificationCenterServiceProtocol {

    var authorizationStatusValue: NotificationAuthorizationStatus = .notDetermined
    var requestAlertAuthorizationGranted = false

    var authorizationStatusCounter = 0
    var requestAlertAuthorizationCounter = 0
    var addCounter = 0
    var removePendingCounter = 0

    var lastAddedRequest: UNNotificationRequest?
    var lastRemovedIdentifiers: [String] = []
    var addedRequests: [UNNotificationRequest] = []
    var authorizationStatusDelay: (() -> Void)?

    func authorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        self.authorizationStatusCounter += 1
        self.authorizationStatusDelay?()
        completion(self.authorizationStatusValue)
    }

    func requestAlertAuthorization(completion: @escaping (Bool) -> Void) {
        self.requestAlertAuthorizationCounter += 1
        if self.requestAlertAuthorizationGranted {
            self.authorizationStatusValue = .authorized
        } else {
            self.authorizationStatusValue = .denied
        }
        completion(self.requestAlertAuthorizationGranted)
    }

    func add(_ request: UNNotificationRequest, completion: ((Error?) -> Void)?) {
        self.addCounter += 1
        self.lastAddedRequest = request
        self.addedRequests.append(request)
        completion?(nil)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        self.removePendingCounter += 1
        self.lastRemovedIdentifiers = identifiers
        self.addedRequests.removeAll { identifiers.contains($0.identifier) }
        if identifiers.contains(self.lastAddedRequest?.identifier ?? "") {
            self.lastAddedRequest = nil
        }
    }

    func resetCounters() {
        self.authorizationStatusCounter = 0
        self.requestAlertAuthorizationCounter = 0
        self.addCounter = 0
        self.removePendingCounter = 0
        self.lastAddedRequest = nil
        self.lastRemovedIdentifiers = []
        self.addedRequests = []
    }
}
