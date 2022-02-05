//
//  Screen.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 05/02/2022.
//

import Foundation

enum Screen: Int, Identifiable {
    var id: Self { self }
    
    case appHome, onboarding, help, about, enableExtension, testFilters,
         addLanguageFilter, addAllowFilter, addDenyFilter, automaticBlocking,
         denyFilterList, allowFilterList, denyLanguageFilterList
    
    var tag: String {
        switch self {
        case .appHome:
            return "appHome"
        case .onboarding:
            return "onboarding"
        case .help:
            return "help"
        case .about:
            return "about"
        case .enableExtension:
            return "enableExtension"
        case .testFilters:
            return "testFilters"
        case .addLanguageFilter:
            return "addLanguageFilter"
        case .addAllowFilter:
            return "addAllowFilter"
        case .addDenyFilter:
            return "addDenyFilter"
        case .automaticBlocking:
            return "automaticBlocking"
        case .denyFilterList:
            return "denyFilterList"
        case .allowFilterList:
            return "allowFilterList"
        case .denyLanguageFilterList:
            return "denyLanguageFilterList"
        }
    }
}

extension FilterType {
    var screen: Screen {
        switch self {
        case .deny:
            return .denyFilterList
        case .allow:
            return .allowFilterList
        case .denyLanguage:
            return .denyLanguageFilterList
        }
    }
}
