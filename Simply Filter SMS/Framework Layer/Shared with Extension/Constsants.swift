//
//  Constsants.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import Foundation
import IdentityLookup
import SwiftUI


//MARK: Constants
let kAppWorkingDirectory = "Simply-Filter-SMS"
let kDatabaseFilename = "CoreData.sqlite"
let kAppGroupContainer = "group.com.grizz.apps.dev.simply-filter-sms"
let kSupportEmail = "grizz.apps.dev@gmail.com"
let kUpdateAutomaticFiltersMinDays = 3
let kMinimumFilterLength = 3
let kHideiClouldStatusMemory = 60
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "#ERROR#"
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "#ERROR#"

let kMaximumFoldersSelected = 5
let kDefaultSubActions = [DenyFolderType.transactionalFinance,
                       DenyFolderType.transactionalOrders,
                       DenyFolderType.transactionalHealth,
                       DenyFolderType.promotionalCoupons,
                       DenyFolderType.promotionalOffers]
// URLs
extension URL {
    static let appBaseURL = URL(string: "https://grizz-apps-dev.s3.us-east-2.amazonaws.com")!
    static let reportMessageURL = URL(string: "https://qezcp0b7pc.execute-api.us-east-1.amazonaws.com/prod")!
    static let appReviewURL = URL(string: "https://apps.apple.com/app/id1603222959?action=write-review")!
    static let appTwitterURL = URL(string: "https://twitter.com/a_bd")!
    static let appGithubURL = URL(string: "https://github.com/adibendahan/SimplyFilterSMS-iOS")!
    static let iconDesignerURL = URL(string: "https://instagram.com/eighteeneleven_by_rkl")!
}

//MARK: Enums
enum FilterType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case deny=0, allow, denyLanguage
    
    var sortIndex: Int {
        switch self {
        case .allow:
            return 0
        case .deny:
            return 1
        case .denyLanguage:
            return 2
        }
    }
    
    var name: String {
        switch self {
        case .deny:
            return "filterList_denied"~
        case .allow:
            return "filterList_allowed"~
        case .denyLanguage:
            return "filterList_deniedLanguage"~
        }
    }
    
    var supportsFolders: Bool {
        switch self {
        case .allow:
            return false
        default:
            return true
        }
    }
    
    var supportsAdvancedOptions: Bool {
        switch self {
        case .deny, .allow:
            return true
        case .denyLanguage:
            return false
        }
    }
    
    var allowedWhenAllSendersBlocked: Bool {
        return self == .allow
    }
    
    var iconName: String {
        switch self {
        case .deny:
            return "person.crop.circle.badge.xmark"
        case .allow:
            return "person.crop.circle.badge.checkmark"
        case .denyLanguage:
            return "globe"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .deny:
            return .red
        case .allow:
            return .green
        case .denyLanguage:
            return .cyan
        }
    }
    
    var testIdentifier: TestIdentifier {
        switch self {
        case .deny:
            return .denyFiltersLink
        case .allow:
            return .allowFiltersLink
        case .denyLanguage:
            return .denyLanguageLink
        }
    }
}

enum DenyFolderType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case junk=0, transaction, promotion

    case transactionalOthers
    case transactionalFinance
    case transactionalOrders
    case transactionalReminders
    case transactionalHealth
    case transactionalWeather
    case transactionalCarrier
    case transactionalRewards
    case transactionalPublicServices
    case promotionalOthers
    case promotionalOffers
    case promotionalCoupons
    
    var iconName: String {
        switch self {
        case .junk:
            return "xmark.bin"
        case .transaction:
            return "arrow.left.arrow.right"
        case .promotion:
            return "megaphone"
        case .transactionalOthers:
            return "ellipsis.circle"
        case .transactionalFinance:
            return "creditcard"
        case .transactionalOrders:
            return "shippingbox"
        case .transactionalReminders:
            return "calendar.badge.clock"
        case .transactionalHealth:
            return "heart"
        case .transactionalWeather:
            return "cloud.sun"
        case .transactionalCarrier:
            return "antenna.radiowaves.left.and.right"
        case .transactionalRewards:
            return "star"
        case .transactionalPublicServices:
            return "building.2"
        case .promotionalOthers:
            return "ellipsis.circle"
        case .promotionalOffers:
            return "tag"
        case .promotionalCoupons:
            return "wallet.pass"
        }
    }
    
    var name: String {
        switch self {
        case .junk:
            return "addFilter_folder_junk"~
        case .transaction:
            return "addFilter_folder_transactions"~
        case .promotion:
            return "addFilter_folder_promotions"~
        case .transactionalOthers:
            return "Others"
        case .transactionalFinance:
            return "Finance"
        case .transactionalOrders:
            return "Orders"
        case .transactionalReminders:
            return "Reminders"
        case .transactionalHealth:
            return "Health"
        case .transactionalWeather:
            return "Weather"
        case .transactionalCarrier:
            return "Carrier"
        case .transactionalRewards:
            return "Rewards"
        case .transactionalPublicServices:
            return "Public Services"
        case .promotionalOthers:
            return "Others"
        case .promotionalOffers:
            return "Offers"
        case .promotionalCoupons:
            return "Coupons"
        }
    }
    
    var fullName: String {
        switch self {
        case .junk, .transaction, .promotion:
            return self.name
            
        default:
            return "\(self.parent?.name ?? ""): \(self.name)"
        }
    }
    
    var action: ILMessageFilterAction {
        switch self {
        case .junk:
            return .junk
        case .transaction, .transactionalOthers, .transactionalFinance, .transactionalOrders, .transactionalReminders,
                .transactionalHealth, .transactionalWeather, .transactionalCarrier, .transactionalRewards, .transactionalPublicServices:
            return .transaction
        case .promotion, .promotionalOthers, .promotionalOffers, .promotionalCoupons:
            return .promotion
        }
    }
    
    var isSubFolder: Bool {
        switch self {
        case .junk, .transaction, .promotion:
            return false
        default:
            return true
        }
    }
    
    var parent: DenyFolderType? {
        switch self {
        case .transactionalOthers, .transactionalFinance, .transactionalOrders,
                .transactionalReminders, .transactionalHealth, .transactionalWeather,
                .transactionalCarrier, .transactionalRewards, .transactionalPublicServices:
            return .transaction
            
        case .promotionalOthers, .promotionalOffers, .promotionalCoupons:
            return .promotion
            
        default:
            return nil
        }
    }
    
    @available(iOS 16.0, *)
    var subAction: ILMessageFilterSubAction? {
        switch self {
        case .transactionalOthers:
            return .transactionalOthers
        case .transactionalFinance:
            return .transactionalFinance
        case .transactionalOrders:
            return .transactionalOrders
        case .transactionalReminders:
            return .transactionalReminders
        case .transactionalHealth:
            return .transactionalHealth
        case .transactionalWeather:
            return .transactionalWeather
        case .transactionalCarrier:
            return .transactionalCarrier
        case .transactionalRewards:
            return .transactionalRewards
        case .transactionalPublicServices:
            return .transactionalPublicServices
        case .promotionalOthers:
            return .promotionalOthers
        case .promotionalOffers:
            return .promotionalOffers
        case .promotionalCoupons:
            return .promotionalCoupons
        default:
            return nil
        }
    }
    
    static var title: String {
        return "addFilter_folder_caption"~
    }
}

enum FilterTarget: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case all=0, sender, body
    
    var name: String {
        switch self {
        case .all:
            return "addFilter_target_all"~
        case .sender:
            return "addFilter_target_sender"~
        case .body:
            return "addFilter_target_body"~
        }
    }
    
    var multilineName: String {
        switch self {
        case .all:
            return "addFilter_target_all_multiline"~
        default:
            return self.name
        }
    }
    
    static var title: String {
        return "addFilter_target_title"~
    }
}

enum FilterMatching: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case contains=0, exact
    
    var name: String {
        switch self {
        case .contains:
            return "addFilter_match_contains"~
        case .exact:
            return "addFilter_match_exact"~
        }
    }
    
    var icon: String {
        switch self {
        case .contains:
            return "equal.circle"
        case .exact:
            return "equal.circle.fill"
        }
    }
    
    var other: FilterMatching {
        switch self {
        case .contains:
            return .exact
        case .exact:
            return .contains
        }
    }
    
    static var title: String {
        return "addFilter_match_title"~
    }
}

enum FilterCase: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case caseInsensitive=0, caseSensitive
    
    var name: String {
        switch self {
        case .caseInsensitive:
            return "addFilter_case_insensitive"~
        case .caseSensitive:
            return "addFilter_case_sensitive"~
        }
    }
    
    var compareOption: NSString.CompareOptions {
        switch self {
        case .caseInsensitive:
            return .caseInsensitive
        case .caseSensitive:
            return .literal
        }
    }
    
    var other: FilterCase {
        switch self {
        case .caseInsensitive:
            return .caseSensitive
        case .caseSensitive:
            return .caseInsensitive
        }
    }
    
    static var title: String {
        return "addFilter_case_title"~
    }
}

enum ReportType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case junk=0, notJunk
    
    var name: String {
        switch self {
        case .junk:
            return "reportMessage_junk"~
        case .notJunk:
            return "reportMessage_notJunk"~
        }
    }
    
    var type: String {
        switch self {
        case .junk:
            return "deny"
        case .notJunk:
            return "allow"
        }
    }
}

enum RuleType: Int64, CaseIterable, Equatable, Identifiable {
    case allUnknown=0, links, numbersOnly, shortSender, email, emojis
    
    var id: Self { self }
    
    var title: String {
        switch self {
        case .allUnknown:
            return "autoFilter_allUnknown"~
        case .links:
            return "autoFilter_links"~
        case .numbersOnly:
            return "autoFilter_numbersOnly"~
        case .shortSender:
            return "autoFilter_shortSender"~
        case .email:
            return "autoFilter_email"~
        case .emojis:
            return "autoFilter_emojis"~
        }
    }
    
    var sortIndex: Int {
        switch self {
        case .allUnknown:
            return 0
        case .links:
            return 1
        case .shortSender:
            return 2
        case .email:
            return 3
        case .numbersOnly:
            return 4
        case .emojis:
            return 5
        }
    }
    
    var icon: String {
        switch self {
        case .allUnknown:
            return "nosign"
        case .links:
            return "link"
        case .numbersOnly:
            return "number.circle.fill"
        case .shortSender:
            return "textformat.123"
        case .email:
            return "envelope.fill"
        case .emojis:
            return "🙄"
        }
    }
    
    var isTextIcon: Bool {
        return self == .emojis
    }
    
    var iconColor: Color {
        switch self {
        case .allUnknown:
            return .red
        case .links:
            return .blue
        case .numbersOnly:
            return .purple.opacity(0.8)
        case .shortSender:
            return .orange
        case .email:
            return .brown
        case .emojis:
            return .orange
        }
    }
    
    var subtitle: String? {
        switch self {
        case .shortSender:
            return "autoFilter_shortSender_desc"~
        default:
            return nil
        }
    }
    
    var action: String? {
        switch self {
        case .shortSender:
            return "autoFilter_shortSender_change"~
        default:
            return nil
        }
    }
    
    var actionTitle: String? {
        switch self {
        case .shortSender:
            return "autoFilter_shortSender_action"~
        default:
            return nil
        }
    }
    
    var shortTitle: String? {
        switch self {
        case .allUnknown:
            return "autoFilter_allUnknown_shortTitle"~
        case .links:
            return "autoFilter_links_shortTitle"~
        case .numbersOnly:
            return "autoFilter_numbersOnly_shortTitle"~
        case .shortSender:
            return "autoFilter_shortSender_shortTitle"~
        case .email:
            return "autoFilter_email_shortTitle"~
        case .emojis:
            return "autoFilter_emojis_shortTitle"~
        }
    }

    var isDestructive: Bool {
        return self == .allUnknown
    }
}
