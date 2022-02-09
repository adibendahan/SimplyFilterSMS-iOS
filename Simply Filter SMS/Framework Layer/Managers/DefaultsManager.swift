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
    
    
    //MARK: - Session Defaults -
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
}
