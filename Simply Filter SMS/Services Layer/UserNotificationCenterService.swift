//
//  UserNotificationCenterService.swift
//  Simply Filter SMS
//

import Foundation
import UserNotifications

protocol UserNotificationCenterServiceProtocol: AnyObject {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAlertAuthorization() async -> Bool
    func schedule(_ request: UNNotificationRequest) async
    func cancelPendingNotification(withIdentifier identifier: String)
}

class UserNotificationCenterService: UserNotificationCenterServiceProtocol {
    
    //MARK: - Initialization -
    init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }
    
    
    //MARK: - Public API (UserNotificationCenterServiceProtocol) -
    func authorizationStatus() async -> UNAuthorizationStatus {
        return await self.notificationCenter.notificationSettings().authorizationStatus
    }
    
    func requestAlertAuthorization() async -> Bool {
        do {
            return try await self.notificationCenter.requestAuthorization(options: [.alert])
        }
        catch {
            AppManager.logger.error("requestAlertAuthorization — failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
    
    func schedule(_ request: UNNotificationRequest) async {
        do {
            try await self.notificationCenter.add(request)
            AppManager.logger.debug("schedule — added \(request.identifier, privacy: .public)")
        }
        catch {
            AppManager.logger.error("schedule — could not add \(request.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    
    //MARK: - Private -
    private let notificationCenter: UNUserNotificationCenter
}


extension UNAuthorizationStatus {
    var allowsAlerts: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied:
            return false
        @unknown default:
            return false
        }
    }
}
