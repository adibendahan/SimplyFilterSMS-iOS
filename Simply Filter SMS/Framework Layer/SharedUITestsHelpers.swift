//
//  SharedUITestsHelpers.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/06/2022.
//

import UIKit

#if DEBUG
extension UIApplication {
    var isInTestingMode: Bool {
        return ProcessInfo.processInfo.arguments.contains("-Testing")
    }
}
#endif


enum TestIdentifier: String {
    case callToActionButton = "callToActionButton"
    case cancelButton = "cancelButton"
    case automaticFilterLink = "automaticFilterLink"
    case allowFiltersLink = "allowFiltersLink"
    case denyFiltersLink = "denyFiltersLink"
    case denyLanguageLink = "denyLanguageLink"
    case addFilterButton = "addFilterButton"
    case addFilteraddFilterButton = "addFilteraddFilterButton"
    case expandButton = "expandButton"
    case closeButton = "closeButton"
    case filterText = "filterText"
    case appMenuButton = "appMenuButton"
    case loadDebugDataMenuButton = "loadDebugDataMenuButton"
    case testYourFiltersMenuButton = "testYourFiltersMenuButton"
    case testYourFiltersButton = "testYourFiltersButton"
    case testSenderInput = "testSenderInput"
    case testBodyInput = "testBodyInput"
}
