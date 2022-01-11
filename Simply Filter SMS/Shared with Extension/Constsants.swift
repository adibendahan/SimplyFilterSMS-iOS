//
//  Constsants.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import Foundation
import IdentityLookup

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

//MARK: Enums
@objc enum FilterType: Int64 {
    case deny=0, allow, denyLanguage
}

@objc enum DenyFolderType: Int64, CaseIterable, Identifiable {
    case junk=0, transaction, promotion
    
    var id: Int64 {
        return self.rawValue
    }
    
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

enum FilteredLanguage: String {
    case arabic="$lang:arabic",
         hebrew="$lang:hebrew",
         unknown="$lang:unknown"
    
    var name: String {
        switch (self) {
        case .arabic:
            return "lang_arabic"~
        case .hebrew:
            return "lang_hebrew"~
        case .unknown:
            return "lang_unknown"~
        }
    }
    
    var charcterSet: CharacterSet {
        switch (self) {
        case .arabic:
            return CharacterSet(charactersIn: Unicode.Scalar(UInt16(0x0600))!...Unicode.Scalar(UInt16(0x06ff))!)
        case .hebrew:
            return CharacterSet(charactersIn: Unicode.Scalar(UInt16(0x0590))!...Unicode.Scalar(UInt16(0x05ff))!)
        case .unknown:
            return CharacterSet()
        }
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
