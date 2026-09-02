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
    var isFilterOptionsCollapsed: Bool { get set }
    var sessionCounter: Int { get set }
    var didPromptForReview: Bool { get set }
    var didTip: Bool { get set }
    var lastSeenWhatsNewVersion: Int { get set }
    var didDismissReportingExtensionNudge: Bool { get set }
    var didShowAutomaticFiltersNotificationExplainer: Bool { get set }
    var accentColorRGB: [String: Double] { get set }
    var appAge: Date { get }
    
    // Session:
    var lastOfflineNotificationDismiss: Date? { get set }
    var sessionAge: Date? { get set }
    
    #if DEBUG
    func reset()
    #endif // DEBUG
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
            guard let object = UserDefaults.standard.object(forKey: self.key) else {
                UserDefaults.standard.set(self.defaultValue, forKey: self.key)
                return self.defaultValue
            }
            if let val = object as? T {
                return val
            }
            if let anyDict = object as? [String: Any] {
                var converted: [String: Double] = [:]
                for (key, value) in anyDict {
                    if let number = value as? NSNumber {
                        converted[key] = number.doubleValue
                    } else if let double = value as? Double {
                        converted[key] = double
                    }
                }
                if let typed = converted as? T {
                    return typed
                }
            }
            return self.defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey:self.key)
        }
    }
}
