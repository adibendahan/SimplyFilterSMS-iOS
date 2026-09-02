//
//  UserNotificationCenterScheduler.swift
//  Simply Filter SMS
//

import Foundation
import UserNotifications

final class UserNotificationCenterScheduler: UserNotificationSchedulingProtocol {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus(completion: @escaping (NotificationAuthorizationStatus) -> Void) {
        self.center.getNotificationSettings { settings in
            let status: NotificationAuthorizationStatus
            switch settings.authorizationStatus {
            case .notDetermined:
                status = .notDetermined
            case .denied:
                status = .denied
            case .authorized:
                status = .authorized
            case .provisional:
                status = .provisional
            case .ephemeral:
                status = .ephemeral
            @unknown default:
                status = .denied
            }
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    func requestAlertAuthorization(completion: @escaping (Bool) -> Void) {
        self.center.requestAuthorization(options: [.alert]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func add(_ request: UNNotificationRequest, completion: ((Error?) -> Void)?) {
        self.center.add(request) { error in
            DispatchQueue.main.async {
                completion?(error)
            }
        }
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
