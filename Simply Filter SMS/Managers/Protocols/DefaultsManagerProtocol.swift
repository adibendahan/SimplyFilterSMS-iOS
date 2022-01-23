//
//  DefaultsManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage

protocol DefaultsManagerProtocol {
    var isAppFirstRun: Bool { get set }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool
    func setLanguageAtumaticState(for language: NLLanguage, value: Bool)
}

protocol PropertyListValue {}

extension String: PropertyListValue {}
extension Date: PropertyListValue {}
extension Bool: PropertyListValue {}
extension Int: PropertyListValue {}
extension Double: PropertyListValue {}
extension Float: PropertyListValue {}
extension Array: PropertyListValue where Element: PropertyListValue {}
extension Dictionary: PropertyListValue where Key == String, Value: PropertyListValue {}

@propertyWrapper
struct StoredDefault<T: PropertyListValue> {
    let key: String
    let defaultValue: T
    
    init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            if let val = UserDefaults.standard.object(forKey: key) as? T {
                return val
            }
            else {
                UserDefaults.standard.set(defaultValue, forKey: key)
                return defaultValue
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey:key)
            }
    }
}
