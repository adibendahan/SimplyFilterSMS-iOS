//
//  StudioLanguage.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import Foundation

enum StudioLanguage: String, CaseIterable {
    case english = "en"
    case hebrew = "he"
    case german = "de"
    case spanish = "es"
    case french = "fr"
    case italian = "it"
    case portuguese = "pt-BR"
    case arabic = "ar"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh-Hans"

    static var current: StudioLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let exact = Self.allCases.first { preferred == $0.rawValue || preferred.hasPrefix($0.rawValue + "-") }
        let sameLanguage = Self.allCases.first { preferred.hasPrefix($0.rawValue.prefix(2) + "-") }
        return exact ?? sameLanguage ?? .english
    }

    var aiFilteringLanguage: String {
        switch self {
        case .portuguese:
            return "pt"
        case .chinese:
            return "en"
        default:
            return self.rawValue
        }
    }

    var blockedText: String {
        switch self {
        case .english:
            return "Weed"
        case .hebrew:
            return "הלוואה"
        case .german:
            return "Kredit"
        case .spanish:
            return "Préstamo"
        case .french:
            return "Promo"
        case .italian:
            return "Prestito"
        case .portuguese:
            return "Empréstimo"
        case .arabic:
            return "قرض"
        case .japanese:
            return "ローン"
        case .korean:
            return "대출"
        case .chinese:
            return "贷款"
        }
    }

    var subscribedListURLs: [String] {
        return ["parcel", "deals"].map {
            "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/screenshots/\(self.rawValue)/\($0).sfsfilters"
        }
    }
}
