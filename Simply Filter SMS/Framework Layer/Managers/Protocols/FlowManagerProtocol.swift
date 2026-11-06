//
//  FlowManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation

protocol FlowManagerProtocol {
    var didShowNotificationThisSession: Bool { get }
    var isNotificationShowing: Bool { get }

    func recordLaunch(_ screen: Screen) -> Bool
    func request(_ screen: Screen)
    func enableWhatsNew()
    func next() -> Screen?
    func complete(_ screen: Screen)
    func resetSession()

    func startMonitoring()
    func setHomeAvailability(_ isHomeUnobstructed: @escaping () -> Bool)
    func homeMayBeUnobstructed()
    func requestNotification(_ notification: NotificationView.Notification)
    func nextNotification() -> NotificationView.Notification?
    func completeNotification()
    func didTapNotification(_ notification: NotificationView.Notification)
    func didDismissNotification(_ notification: NotificationView.Notification)
    func showSessionNudges()
}


extension NSNotification.Name {
    static let notificationSlotChanged: NSNotification.Name = NSNotification.Name("NotificationSlotChanged")
    static let flowRequested: NSNotification.Name = NSNotification.Name("FlowRequested")
}
