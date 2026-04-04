//
//  SharedUITestsHelpers.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/06/2022.
//

import UIKit

extension ProcessInfo {
    var isInTestingMode: Bool {
        return arguments.contains("-Testing")
    }
}

#if DEBUG
extension UIApplication {
    var isInTestingMode: Bool {
        return ProcessInfo.processInfo.isInTestingMode
    }
}
#endif // DEBUG


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
    case debugToolsButton = "debugToolsButton"
    case loadDebugDataMenuButton = "loadDebugDataMenuButton"
    case testYourFiltersMenuButton = "testYourFiltersMenuButton"
    case testYourFiltersButton = "testYourFiltersButton"
    case filterToolsMenuButton = "filterToolsMenuButton"
    case testSenderInput = "testSenderInput"
    case testBodyInput = "testBodyInput"
    case countryAllowlistButton = "countryAllowlistButton"
    case countryRow = "countryRow"
}
