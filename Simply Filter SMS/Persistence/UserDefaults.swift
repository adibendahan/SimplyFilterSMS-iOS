//
//  UserDefaults.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2022.
//

import Foundation
import NaturalLanguage

extension UserDefaults {
    static var isAppFirstRun: Bool {
        get {
            guard let _ = UserDefaults.standard.object(forKey: "isAppFirstRun") else { return true }
            return UserDefaults.standard.bool(forKey: "isAppFirstRun")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isAppFirstRun")
        }
    }
    
    static func languageAutomaticState(for language: NLLanguage) -> Bool {
        let languageKey = "$state(for: \(language.rawValue))"
        guard let _ = UserDefaults.standard.object(forKey: languageKey) else { return false }
        return UserDefaults.standard.bool(forKey: languageKey)
    }
    
    static func setLanguageAtumaticState(for language: NLLanguage, value: Bool) {
        let languageKey = "$state(for: \(language.rawValue))"
        UserDefaults.standard.set(value, forKey: languageKey)
    }
}
