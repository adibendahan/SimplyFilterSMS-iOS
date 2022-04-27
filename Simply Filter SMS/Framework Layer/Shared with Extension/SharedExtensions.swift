//
//  Extensions.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import Foundation
import NaturalLanguage
import SwiftUI
import IdentityLookup

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
    
    var filterMatching: FilterMatching {
        get {
            return FilterMatching(rawValue: self.matchingValue) ?? .contains
        }
        set {
            self.matchingValue = newValue.rawValue
        }
    }
    
    var filterCase: FilterCase {
        get {
            return FilterCase(rawValue: self.caseValue) ?? .caseInsensitive
        }
        set {
            self.caseValue = newValue.rawValue
        }
    }
    
    var filterTarget: FilterTarget {
        get {
            return FilterTarget(rawValue: self.targetValue) ?? .all
        }
        set {
            self.targetValue = newValue.rawValue
        }
    }
}

extension AutomaticFiltersRule {
    var ruleType: RuleType? {
        get {
            return RuleType(rawValue: self.ruleId)
        }
        set {
            self.ruleId = newValue?.rawValue ?? -1
        }
    }
}


extension NLLanguage: Identifiable {
    public var id: String {
        self.rawValue
    }
    
    
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
    
    static var allSupportedCases: [NLLanguage] = [.hebrew, .arabic, .english, .spanish, .simplifiedChinese, .traditionalChinese, .russian,
                                                         .french, .german, .italian, .japanese, .persian, .turkish]
    static func dominantLanguage(for string: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        return recognizer.dominantLanguage
    }
        
    var filterText: String {
        guard NLLanguage.allSupportedCases.contains(self) else { return "$lang:unknown" }
        let langName = Locale(identifier: "en_US").localizedString(forIdentifier: self.rawValue) ?? "unknown"
        return "$lang:\(langName.lowercased())"
    }
    
    var localizedName: String? {
        return Locale.current.localizedString(forIdentifier: self.rawValue)
    }
}


extension ILMessageFilterAction {
    var isFiltered: Bool {
        switch self {
        case .none:
            return false
        case .allow, .junk, .filter, .promotion, .transaction:
            return true
        @unknown default:
            return false
        }
    }
    
    var testResult: String {
        switch self {
        case .none, .allow:
            return "testFilters_resultAllowed"~
            
        case .junk, .filter:
            return "testFilters_resultJunk"~
            
        case .promotion:
            return "testFilters_resultPromotion"~
            
        case .transaction:
            return "testFilters_resultTransaction"~
            
        @unknown default:
            return "🧐"
        }
    }
    
#if DEBUG
    var debugName: String {
        switch self {
        case .none:
            return "None"
        case .allow:
            return "Allow"
        case .junk:
            return "Junk"
        case .filter:
            return "Filter"
        case .promotion:
            return "Promotion"
        case .transaction:
            return "Transaction"
        @unknown default:
            return "Unknown"
        }
    }
#endif
}

extension String {
    func index(at position: Int, from start: Index? = nil) -> Index? {
        let startingIndex = start ?? startIndex
        return index(startingIndex, offsetBy: position, limitedBy: endIndex)
    }
    
    var containsLink: Bool {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return false }
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        let filteredMatches = matches.filter({ $0.url?.isMailToScheme == false })
        
        return !filteredMatches.isEmpty
    }
    
    var containsEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    var containsEmoji: Bool { self.contains { $0.isEmoji } }
}

extension URL {
    var isMailToScheme: Bool {
        return self.scheme?.lowercased() == "mailto"
    }
}

extension Character {

    var isSimpleEmoji: Bool {
        guard let firstScalar = self.unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }

    var isCombinedIntoEmoji: Bool {
        return self.unicodeScalars.count > 1 && self.unicodeScalars.first?.properties.isEmoji ?? false
    }

    var isEmoji: Bool { self.isSimpleEmoji || self.isCombinedIntoEmoji }
}
