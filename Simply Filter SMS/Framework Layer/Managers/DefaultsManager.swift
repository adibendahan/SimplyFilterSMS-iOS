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
    
    @StoredDefault("sessionCounter", defaultValue: 0)
    var sessionCounter: Int
    
    @StoredDefault("didPromptForReview", defaultValue: false)
    var didPromptForReview: Bool
    
    @StoredDefault("selectedSubFolders", defaultValue: [DenyFolderType.transactionalFinance.rawValue,
                                                        DenyFolderType.transactionalOrders.rawValue,
                                                        DenyFolderType.transactionalHealth.rawValue,
                                                        DenyFolderType.promotionalCoupons.rawValue,
                                                        DenyFolderType.promotionalOffers.rawValue])
    var selectedSubFolders: [Int64]
    
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
        let keysToRemove: [String] = ["isAppFirstRun", "isExpandedAddFilter", "sessionCounter", "didPromptForReview", "appAge"]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
#endif
}
