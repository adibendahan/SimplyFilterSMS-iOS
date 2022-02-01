//
//  Constsants.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import Foundation
import IdentityLookup
import SwiftUI

//MARK: Localization
postfix operator ~
postfix func ~ (string: String) -> String {
    return NSLocalizedString(string, comment: "")
}


//MARK: Constants
let kAppWorkingDirectory = "Simply-Filter-SMS"
let kDatabaseFilename = "CoreData.sqlite"
let kAppGroupContainer = "group.com.grizz.apps.dev.simply-filter-sms"
let kSupportEmail = "grizz.apps.dev@gmail.com"
let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "#ERROR#"
let appBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "#ERROR#"

//MARK: Enums
enum FilterType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case deny=0, allow, denyLanguage
    
    var sortIndex: Int {
        switch self {
        case .deny:
            return 1
        case .allow:
            return 0
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
            return Color(.sRGB, red: 231/255, green: 76/255, blue: 60/255, opacity: 1.0)
        case .allow:
            return Color(.sRGB, red: 39/255, green: 174/255, blue: 96/255, opacity: 1.0)
        case .denyLanguage:
            return Color(.sRGB, red: 41/255, green: 128/255, blue: 185/255, opacity: 1.0)
        }
    }
}

enum DenyFolderType: Int64, CaseIterable, Identifiable {
    var id: Int64 { return self.rawValue }
    
    case junk=0, transaction, promotion
    
    var iconName: String {
        switch self {
        case .junk:
            return "xmark.bin"
        case .transaction:
            return "arrow.left.arrow.right"
        case .promotion:
            return "megaphone"
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
        }
    }
    
    var action: ILMessageFilterAction {
        switch self {
        case .junk:
            return .junk
        case .transaction:
            return .transaction
        case .promotion:
            return .promotion
        }
    }
}

enum RuleType: Int64, CaseIterable, Equatable, Identifiable {
    case allUnknown=0, links, numbersOnly, shortSender
    
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
        }
    }
    
    var sortIndex: Int {
        switch self {
        case .allUnknown:
            return 0
        case .links:
            return 1
        case .numbersOnly:
            return 3
        case .shortSender:
            return 2
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
        }
    }
    
    var iconColor: Color {
        switch self {
        case .allUnknown:
            return Color(.sRGB, red: 192/255, green: 57/255, blue: 43/255, opacity: 1.0)
        case .links:
            return .accentColor
        case .numbersOnly:
            return .primary.opacity(0.4)//Color(.sRGB, red: 165/255, green: 177/255, blue: 194/255, opacity: 1.0)
        case .shortSender:
            return Color(.sRGB, red: 230/255, green: 126/255, blue: 34/255, opacity: 1.0)
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
        }
    }

    var isDestructive: Bool {
        return self == .allUnknown
    }
}
