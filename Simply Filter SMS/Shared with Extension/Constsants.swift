//
//  Constsants.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 27/12/2021.
//

import Foundation

let kAppWorkingDirectory = "Simply-Filter-SMS"
let kDatabaseFilename = "CoreData.sqlite"
let kAppGroupContainer = "group.\(kAppWorkingDirectory)"

enum FilterType: Int {
    case deny=0, allow
}
