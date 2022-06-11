//
//  DefaultsManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage

protocol DefaultsManagerProtocol {
    // Stored:
    var isAppFirstRun: Bool { get set }
    var isExpandedAddFilter: Bool { get set }
    var sessionCounter: Int { get set }
    var didPromptForReview: Bool { get set }
    var appAge: Date { get }
    
    // Session:
    var lastOfflineNotificationDismiss: Date? { get set }
    var sessionAge: Date? { get set }
    
#if DEBUG
    func reset()
#endif
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
            if let val = UserDefaults.standard.object(forKey: self.key) as? T {
                return val
            }
            else {
                UserDefaults.standard.set(self.defaultValue, forKey: self.key)
                return self.defaultValue
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey:self.key)
        }
    }
}
