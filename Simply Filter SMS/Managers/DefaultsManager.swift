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

    
    //MARK: - Helpers -
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        let languageKey = "$state(for: \(language.rawValue))"
        guard let _ = UserDefaults.standard.object(forKey: languageKey) else { return false }
        return UserDefaults.standard.bool(forKey: languageKey)
    }
    
    func setLanguageAtumaticState(for language: NLLanguage, value: Bool) {
        let languageKey = "$state(for: \(language.rawValue))"
        UserDefaults.standard.set(value, forKey: languageKey)
    }
    
    
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
