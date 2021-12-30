//
//  Constsants.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import Foundation

//MARK: Localization
postfix operator ~
postfix func ~ (string: String) -> String {
    return NSLocalizedString(string, comment: "")
}


//MARK: Constants
let kAppWorkingDirectory = "Simply-Filter-SMS"
let kDatabaseFilename = "CoreData.sqlite"
let kAppGroupContainer = "group.\(kAppWorkingDirectory)"


//MARK: Enums
enum FilterType: Int {
    case deny=0, allow, denyLanguage
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
