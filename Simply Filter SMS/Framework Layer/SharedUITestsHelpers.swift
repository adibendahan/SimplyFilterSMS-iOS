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

    var isUsingUITestData: Bool {
        return arguments.contains("-UITestData")
    }

    var isUsingScreenshotData: Bool {
        return arguments.contains("-ScreenshotData")
    }

    var shouldSkipFilterListsUpdate: Bool {
        return self.isInTestingMode && !self.isUsingUITestData && !self.isUsingScreenshotData
    }
}

#if DEBUG
extension UIApplication {
    var isInTestingMode: Bool {
        return ProcessInfo.processInfo.isInTestingMode
    }
}
#endif // DEBUG


protocol TestIdentifiable {
    var testIdentifier: TestIdentifier { get }
}

enum TestIdentifier: String {
    case callToActionButton = "callToActionButton"
    case cancelButton = "cancelButton"
    case filterListsLink = "filterListsLink"
    case communityListsLink = "communityListsLink"
    case addCommunityListButton = "addCommunityListButton"
    case communityListURLField = "communityListURLField"
    case communityListError = "communityListError"
    case subscribeCommunityListButton = "subscribeCommunityListButton"
    case allowFiltersLink = "allowFiltersLink"
    case denyFiltersLink = "denyFiltersLink"
    case denyLanguageLink = "denyLanguageLink"
    case addFilterButton = "addFilterButton"
    case addFilterConfirmButton = "addFilterConfirmButton"
    case expandButton = "expandButton"
    case closeButton = "closeButton"
    case filterText = "filterText"
    case appMenuButton = "appMenuButton"
    case debugToolsButton = "debugToolsButton"
    case loadDebugDataMenuButton = "loadDebugDataMenuButton"
    case testYourFiltersMenuButton = "testYourFiltersMenuButton"
    case testYourFiltersButton = "testYourFiltersButton"
    case filterToolsMenuButton = "filterToolsMenuButton"
    case exportFiltersMenuButton = "exportFiltersMenuButton"
    case importFiltersMenuButton = "importFiltersMenuButton"
    case testSenderInput = "testSenderInput"
    case testBodyInput = "testBodyInput"
    case countryAllowlistButton = "countryAllowlistButton"
    case countryRow = "countryRow"
    case allUnknownToggle = "allUnknownToggle"
    case linksToggle = "linksToggle"
    case numbersOnlyToggle = "numbersOnlyToggle"
    case shortSenderToggle = "shortSenderToggle"
    case emailToggle = "emailToggle"
    case emojisToggle = "emojisToggle"
    case countryAllowlistToggle = "countryAllowlistToggle"
    case testResultAllowed = "testResultAllowed"
    case testResultJunk = "testResultJunk"
    case testResultPromotion = "testResultPromotion"
    case testResultTransaction = "testResultTransaction"
    case transferConfirmButton = "transferConfirmButton"
    case folderJunkOption = "folderJunkOption"
    case folderTransactionsOption = "folderTransactionsOption"
    case folderPromotionsOption = "folderPromotionsOption"
    case targetAllOption = "targetAllOption"
    case targetSenderOption = "targetSenderOption"
    case targetBodyOption = "targetBodyOption"
    case matchingContainsOption = "matchingContainsOption"
    case matchingExactOption = "matchingExactOption"
    case matchingRegexOption = "matchingRegexOption"
    case caseInsensitiveOption = "caseInsensitiveOption"
    case caseSensitiveOption = "caseSensitiveOption"
    case filterListLanguageToggle = "filterListLanguageToggle"
    case communityListExpandButton = "communityListExpandButton"
    case communityListToggle = "communityListToggle"
}
