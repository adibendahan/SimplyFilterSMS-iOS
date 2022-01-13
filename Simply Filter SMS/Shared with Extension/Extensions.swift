//
//  Extensions.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import Foundation
import NaturalLanguage

extension Collection {
    
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Filter {
    
    var filterType: FilterType {
        get {
            return FilterType(rawValue: self.type) ?? .deny
        }
        set {
            self.type = newValue.rawValue
        }
    }
    
    var denyFolderType: DenyFolderType {
        get {
            return DenyFolderType(rawValue: self.folderType) ?? .junk
        }
        set {
            self.folderType = newValue.rawValue
        }
    }
}

extension NLLanguage: Identifiable {
    
    init(filterText: String) {
        var language = NLLanguage.undetermined
        let langName = filterText.split(separator: ":")[safe: 1] ?? "unknown"
        for supportedLanguage in NLLanguage.allSupportedCases {
            let realLangName = Locale(identifier: "en_US").localizedString(forIdentifier: supportedLanguage.rawValue)?.lowercased() ?? "unknown"
            
            if langName == realLangName {
                language = supportedLanguage
                break
            }
        }
        self = language
    }
    
    public var id: Int { self.hashValue }
    public static var allSupportedCases: [NLLanguage] = [.hebrew, .arabic, .english, .spanish, .simplifiedChinese, .traditionalChinese, .russian,
                                                         .french, .german, .italian, .japanese, .persian, .turkish]
    public static func dominantLanguage(for string: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        return recognizer.dominantLanguage
    }
    
    public var filterText: String {
        guard NLLanguage.allSupportedCases.contains(self) else { return "$lang:unknown" }
        let langName = Locale(identifier: "en_US").localizedString(forIdentifier: self.rawValue) ?? "unknown"
        return "$lang:\(langName.lowercased())"
    }
}
