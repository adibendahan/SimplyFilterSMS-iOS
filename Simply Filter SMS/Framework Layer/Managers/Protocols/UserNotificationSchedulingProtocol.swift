//
//  UserNotificationSchedulingProtocol.swift
//  Simply Filter SMS
//

import Foundation
import UserNotifications

enum NotificationAuthorizationStatus {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral

    var allowsAlerts: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        }
    }
}

protocol UserNotificationSchedulingProtocol {
    func authorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void)
    func requestAlertAuthorization(completion: @escaping (Bool) -> Void)
    func add(_ request: UNNotificationRequest, completion: ((Error?) -> Void)?)
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}
