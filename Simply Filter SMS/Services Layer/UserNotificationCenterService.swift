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
            Log.error("alert authorization request failed", error: error)
            return false
        }
    }
    
    func schedule(_ request: UNNotificationRequest) async {
        do {
            try await self.notificationCenter.add(request)
            let trigger = request.trigger
            let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger
            let calendarTrigger = trigger as? UNCalendarNotificationTrigger
            let nextFire = timeIntervalTrigger?.nextTriggerDate() ?? calendarTrigger?.nextTriggerDate()
            Log.debug("notification scheduled, identifier: \(request.identifier), nextFire: \(nextFire), interval: \(duration: timeIntervalTrigger?.timeInterval), repeats: \(trigger?.repeats)")
        }
        catch {
            Log.error("notification schedule failed, identifier: \(request.identifier)", error: error)
        }
    }
    
    func cancelPendingNotification(withIdentifier identifier: String) {
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        Log.debug("pending notification cancelled, identifier: \(identifier)")
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
