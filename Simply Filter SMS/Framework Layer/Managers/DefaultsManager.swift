//
//  DefaultsManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage

class DefaultsManager: DefaultsManagerProtocol {

    //MARK: - Stored Defaults -
    
    @StoredDefault("isAppFirstRun", defaultValue: true)
    var isAppFirstRun: Bool

    @StoredDefault("isAddFilterExpanded", defaultValue: false)
    var isAddFilterExpanded: Bool

    @StoredDefault("isFilterOptionsCollapsed", defaultValue: false)
    var isFilterOptionsCollapsed: Bool
    
    @StoredDefault("sessionCounter", defaultValue: 0)
    var sessionCounter: Int
    
    @StoredDefault("didPromptForReview", defaultValue: false)
    var didPromptForReview: Bool

    @StoredDefault("didTip", defaultValue: false)
    var didTip: Bool

    @StoredDefault("lastSeenWhatsNewVersion", defaultValue: 0)
    var lastSeenWhatsNewVersion: Int

    @StoredDefault("didDismissReportingExtensionNudge", defaultValue: false)
    var didDismissReportingExtensionNudge: Bool

    @StoredDefault("sessionNudgeLastShownSessions", defaultValue: [:])
    var sessionNudgeLastShownSessions: [String: Int]

    @StoredDefault("inactivityNotificationDeclineCount", defaultValue: 0)
    var inactivityNotificationDeclineCount: Int

    @StoredDefault("inactivityNotificationLastDeclineSession", defaultValue: 0)
    var inactivityNotificationLastDeclineSession: Int

    @StoredDefault("inactivityNotificationWasGranted", defaultValue: false)
    var inactivityNotificationWasGranted: Bool

    @StoredDefault("accentColorRGB", defaultValue: kNoColorDict)
    var accentColorRGB: [String: Double]

    @StoredDefault("installDate", defaultValue: Date())
    private(set) var installDate: Date
    
    //MARK: - Session Defaults -
    var sessionStartDate: Date?
    var lastOfflineNotificationDismiss: Date?
    
    //MARK: - Stored Defaults Migration -
    init() {
        self.migrateRenamedKeys()
        self.removeDeletedKeys()
    }

    private func migrateRenamedKeys() {
        let renamedKeys: [String: String] = [
            "appAge": "installDate",
            "isExpandedAddFilter": "isAddFilterExpanded"
        ]

        for (oldKey, newKey) in renamedKeys {
            guard let value = UserDefaults.standard.object(forKey: oldKey) else { continue }

            if UserDefaults.standard.object(forKey: newKey) == nil {
                UserDefaults.standard.set(value, forKey: newKey)
            }
            UserDefaults.standard.removeObject(forKey: oldKey)
        }
    }
    
    private func removeDeletedKeys() {
        let keysToRemove: [String] = []
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    #if DEBUG
    func reset() {
        let keysToRemove: [String] = ["isAppFirstRun", "isAddFilterExpanded", "isFilterOptionsCollapsed", "sessionCounter", "didPromptForReview", "didTip", "lastSeenWhatsNewVersion", "installDate", "didDismissReportingExtensionNudge", "sessionNudgeLastShownSessions", "inactivityNotificationDeclineCount", "inactivityNotificationLastDeclineSession", "inactivityNotificationWasGranted", "accentColorRGB"]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    #endif // DEBUG
}
