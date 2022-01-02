//
//  UserDefaults.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2022.
//

import Foundation

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
}
