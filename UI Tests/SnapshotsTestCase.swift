//
//  UI_TestsLaunchTests.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 11/06/2022.
//

import XCTest
import NaturalLanguage

@MainActor
class SnapshotsTestCase: ApplicationTestCase {

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    func testCreateSnapshots() throws {

        if isPad {
            XCUIDevice.shared.orientation = .landscapeRight
        }

        let app = TestApplication(testCase: self)
        let langCode = Locale.current.language.languageCode?.identifier ?? "unknown"
        app.dismissCallToActionViewIfPresented()

        app.tap(.appMenuButton)
        app.tap(.debugToolsButton)
        app.tap(.loadDebugDataMenuButton)
        self.sleep(seconds: 5)

        if !isPad {
            snapshot("01.applicationHome")
        }
        
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_ON"~)
        app.tap(.automaticFilterLink)
        snapshot("02.automaticFilters")
        app.tap(.closeButton)
        app.buttons["BackButton"].firstMatch.conditionalTap(!isPad)
        self.sleep(seconds: 1)

        app.tap(.countryAllowlistButton)
        self.sleep(seconds: 2)
        snapshot("08.countryList")
        app.tap(.closeButton)
        self.sleep(seconds: isPad ? 2.0 : 0.5)


        // MARK: addFilter Screenshot
        let addFilterText: String
        let addFilterScreenshot: String
        switch langCode {
        case "he":
            addFilterText = "הלוואה"
            addFilterScreenshot = "05.addFilter"
        case "ar":
            addFilterText = "قرض"
            addFilterScreenshot = "05.addFilter"
        case "pt":
            addFilterText = "Empréstimo"
            addFilterScreenshot = "05.addFilter"
        case "fr":
            addFilterText = "Promo"
            addFilterScreenshot = "05.addFilter"
        case "de":
            addFilterText = "Kredit"
            addFilterScreenshot = "05.addFilter"
        case "es":
            addFilterText = "Préstamo"
            addFilterScreenshot = "05.addFilter"
        case "ja":
            addFilterText = "ローン"
            addFilterScreenshot = "05.addFilter"
        case "ko":
            addFilterText = "대출"
            addFilterScreenshot = "05.addFilter"
        case "it":
            addFilterText = "Prestito"
            addFilterScreenshot = "05.addFilter"
        default:
            addFilterText = "Weed"
            addFilterScreenshot = "05.addFilter"
        }
        app.addFilter(type: .deny,
                      text: addFilterText,
                      denyFolderType: .junk,
                      filterTarget: .body,
                      filterMatching: .exact,
                      filterCase: .caseInsensitive,
                      screenshotName: addFilterScreenshot)

        // MARK: denyFilters Screenshot
        app.conditionalTap(.denyFiltersLink, isPad)
        snapshot("03.denyFilters")


        // MARK: allowFilters Screenshot
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)
        app.tap(.allowFiltersLink)
        snapshot("04.allowFilters")
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)


        // MARK: denyLanguages Screenshot
        app.conditionalSwipeUp(!isPad)
        app.tap(.denyLanguageLink)
        self.sleep(seconds: 1)
        app.tap(.addFilterButton)
        snapshot("06.denyLanguages")
        app.tap(.closeButton)
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)


        // MARK: testFilters Screenshot
        app.tap(.appMenuButton)
        app.tap(.filterToolsMenuButton)
        app.tap(.testYourFiltersMenuButton)
        app.textViews[TestIdentifier.testBodyInput.rawValue].firstMatch.typeText("Your Apple ID Code is: 444291. Don't share it with anyone.")
        app.textFields[TestIdentifier.testSenderInput.rawValue].firstMatch.tap()
        app.textFields[TestIdentifier.testSenderInput.rawValue].firstMatch.typeText("Apple\n")
        app.tap(.testYourFiltersButton)
        snapshot("07.testFilters")
    }
    
}
