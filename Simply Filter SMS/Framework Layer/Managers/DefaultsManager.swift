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

    @StoredDefault("isExpandedAddFilter", defaultValue: false)
    var isExpandedAddFilter: Bool

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

    @StoredDefault("automaticFiltersNotificationExplainerAskCount", defaultValue: 0)
    var automaticFiltersNotificationExplainerAskCount: Int

    @StoredDefault("automaticFiltersNotificationExplainerLastDeclinedSession", defaultValue: 0)
    var automaticFiltersNotificationExplainerLastDeclinedSession: Int

    @StoredDefault("automaticFiltersNotificationPermissionWasGranted", defaultValue: false)
    var automaticFiltersNotificationPermissionWasGranted: Bool

    @StoredDefault("accentColorRGB", defaultValue: kNoColorDict)
    var accentColorRGB: [String: Double]

    @StoredDefault("appAge", defaultValue: Date())
    private(set) var appAge: Date
    
    //MARK: - Session Defaults -
    var sessionAge: Date?
    var lastOfflineNotificationDismiss: Date?
    
    //MARK: - Stored Defaults Removal -
    init() {
        self.removeDeletedKeys()
    }
    
    private func removeDeletedKeys() {
        let keysToRemove: [String] = []
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    #if DEBUG
    func reset() {
        let keysToRemove: [String] = ["isAppFirstRun", "isExpandedAddFilter", "isFilterOptionsCollapsed", "sessionCounter", "didPromptForReview", "didTip", "lastSeenWhatsNewVersion", "appAge", "didDismissReportingExtensionNudge", "automaticFiltersNotificationExplainerAskCount", "automaticFiltersNotificationExplainerLastDeclinedSession", "automaticFiltersNotificationPermissionWasGranted", "accentColorRGB"]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    #endif // DEBUG
}
