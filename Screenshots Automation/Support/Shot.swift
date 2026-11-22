//
//  Shot.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import Foundation

enum Shot: Int, CaseIterable {
    case home = 1
    case aiFiltering
    case blockedTexts
    case allowedTexts
    case addFilter
    case blockedLanguages
    case testYourFilters
    case countries
    case communityLists

    func attachmentName(on device: ShotDevice) -> String {
        let number = String(format: "%02d", self.rawValue)
        return "screenshot~\(StudioLanguage.current.rawValue)~\(device.rawValue)~\(number)-\(self.slug)"
    }

    func fileName(on device: ShotDevice) -> String {
        let number = String(format: "%02d", self.rawValue)
        return "\(device.rawValue)-\(number)-\(self.slug).png"
    }

    //MARK: - Private -
    private var slug: String {
        switch self {
        case .home:
            return "home"
        case .aiFiltering:
            return "ai-filtering"
        case .blockedTexts:
            return "blocked-texts"
        case .allowedTexts:
            return "allowed-texts"
        case .addFilter:
            return "add-filter"
        case .blockedLanguages:
            return "blocked-languages"
        case .testYourFilters:
            return "test-your-filters"
        case .countries:
            return "countries"
        case .communityLists:
            return "community-lists"
        }
    }
}
