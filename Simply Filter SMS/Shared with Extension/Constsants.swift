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
    case deny=0, allow
}
