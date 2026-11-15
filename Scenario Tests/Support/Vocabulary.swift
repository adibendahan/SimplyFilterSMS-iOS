//
//  Vocabulary.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import Foundation

struct Message: CustomStringConvertible {
    let sender: String
    let body: String

    init(from sender: String, _ body: String) {
        self.sender = sender
        self.body = body
    }

    var description: String {
        return "\(self.sender): \"\(self.body)\""
    }
}

enum Verdict: String {
    case allowed
    case junk
    case promotion
    case transaction

    var element: TestIdentifier {
        switch self {
        case .allowed:
            return .testResultAllowed
        case .junk:
            return .testResultJunk
        case .promotion:
            return .testResultPromotion
        case .transaction:
            return .testResultTransaction
        }
    }
}

enum SmartFilter: String {
    case allUnknownSenders
    case links
    case numbersOnly
    case shortSenders
    case emails
    case emojis

    var element: TestIdentifier {
        switch self {
        case .allUnknownSenders:
            return .allUnknownToggle
        case .links:
            return .linksToggle
        case .numbersOnly:
            return .numbersOnlyToggle
        case .shortSenders:
            return .shortSenderToggle
        case .emails:
            return .emailToggle
        case .emojis:
            return .emojisToggle
        }
    }
}

enum Language: String {
    case english = "en"
    case hebrew = "he"

    var element: String {
        return "\(TestIdentifier.filterListLanguageToggle.rawValue)-\(self.rawValue)"
    }
}

enum Folder {
    case junk
    case promotions
    case transactions

    var element: TestIdentifier {
        switch self {
        case .junk:
            return .folderJunkOption
        case .promotions:
            return .folderPromotionsOption
        case .transactions:
            return .folderTransactionsOption
        }
    }
}

enum Target {
    case all
    case sender
    case body

    var element: TestIdentifier {
        switch self {
        case .all:
            return .targetAllOption
        case .sender:
            return .targetSenderOption
        case .body:
            return .targetBodyOption
        }
    }
}

enum Matching {
    case contains
    case exact
    case regex

    var element: TestIdentifier {
        switch self {
        case .contains:
            return .matchingContainsOption
        case .exact:
            return .matchingExactOption
        case .regex:
            return .matchingRegexOption
        }
    }
}

enum LetterCase {
    case insensitive
    case sensitive

    var element: TestIdentifier {
        switch self {
        case .insensitive:
            return .caseInsensitiveOption
        case .sensitive:
            return .caseSensitiveOption
        }
    }
}

enum TestLists {
    static let curatedPromotions = "UI Test Promotions"
    static let subscriptionName = "UI Test Subscription"
    static let subscriptionURL = Self.url(of: "subscribe.sfsfilters")
    static let notAFilterListURL = Self.url(of: "invalid.sfsfilters")

    private static func url(of fileName: String) -> String {
        return "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/ui-tests/\(fileName)"
    }
}
