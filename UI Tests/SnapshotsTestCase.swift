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
        let langCode = Locale.current.languageCode ?? "unknown"
        app.dismissCallToActionViewIfPresented()


        // MARK: automaticFilters Screenshot
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_OFF"~)
        app.tap(.automaticFilterLink)
        let currentLanguage = NLLanguage(rawValue: langCode)
        let activeLang = currentLanguage != .undetermined ? currentLanguage : .english
        app.switches[activeLang~].switches["0"].firstMatch.tap()
        snapshot("02.automaticFilters")

        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)
        self.sleep(seconds: 1)
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_ON"~)

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


        // MARK: applicationHome Screenshot
        for rule in RuleType.allCases.filter({ $0 != .allUnknown }) {
            let ruleSwitch = app.switchContaining(rule.title)
            XCTAssert(ruleSwitch.switches["0"].firstMatch.value as? String == "0")
            ruleSwitch.switches["0"].firstMatch.tap()
            XCTAssert(ruleSwitch.switches["1"].firstMatch.value as? String == "1")
        }
        app.tap(.appMenuButton)
        app.tap(.loadDebugDataMenuButton)
        snapshot("01.applicationHome")


        // MARK: denyFilters Screenshot
        app.tap(.denyFiltersLink)
        snapshot("03.denyFilters")


        // MARK: allowFilters Screenshot
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)
        app.tap(.allowFiltersLink)
        snapshot("04.allowFilters")
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)


        // MARK: denyLanguages Screenshot
        app.conditionalSwipeUp(!isPad)
        app.tap(.denyLanguageLink)
        app.tap(.addFilterButton)
        snapshot("06.denyLanguages")
        app.tap(.closeButton)
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)


        // MARK: testFilters Screenshot
        app.tap(.appMenuButton)
        app.tap(.testYourFiltersMenuButton)
        app.textViews[TestIdentifier.testBodyInput.rawValue].firstMatch.typeText("Your Apple ID Code is: 444291. Don't share it with anyone.")
        app.textFields[TestIdentifier.testSenderInput.rawValue].firstMatch.tap()
        app.textFields[TestIdentifier.testSenderInput.rawValue].firstMatch.typeText("Apple\n")
        app.tap(.testYourFiltersButton)
        snapshot("07.testFilters")
    }
}
