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
        app.tap(.loadDebugDataMenuButton)
        
        // MARK: countryList Screenshot
        let ruleSwitch = app.switchContaining(RuleType.countryAllowlist.title)
        XCTAssert(ruleSwitch.switches["0"].firstMatch.value as? String == "0")
        ruleSwitch.switches["0"].firstMatch.tap()
        XCTAssert(ruleSwitch.switches["1"].firstMatch.value as? String == "1")
        
        app.tap(.countryAllowlistButton)
        self.sleep(seconds: 1)
        for i in 0..<2 {
            app.buttons.matching(identifier: TestIdentifier.countryRow.rawValue).element(boundBy: i).tap()
            self.sleep(seconds: 0.5)
        }
        app.tap(.closeButton)
        self.sleep(seconds: 0.5)

        // MARK: applicationHome Screenshot
        for rule in RuleType.allCases.filter({ $0 != .allUnknown && $0 != .countryAllowlist }) {
            let ruleSwitch = app.switchContaining(rule.title)
            XCTAssert(ruleSwitch.switches["0"].firstMatch.value as? String == "0")
            ruleSwitch.switches["0"].firstMatch.tap()
            XCTAssert(ruleSwitch.switches["1"].firstMatch.value as? String == "1")
        }
        
        // MARK: automaticFilters Screenshot
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_OFF"~)
        app.tap(.automaticFilterLink)
        let currentLanguage = NLLanguage(rawValue: langCode)
        let activeLang = currentLanguage != .undetermined ? currentLanguage : .english
        app.switches[activeLang~].switches["0"].firstMatch.tap()
        
        
        app.tap(.countryAllowlistButton)
        snapshot("08.countryList")
        app.tap(.closeButton)
        self.sleep(seconds: 0.5)
        
        if !isPad {
            snapshot("01.applicationHome")
        }

        app.tap(.automaticFilterLink)
        snapshot("02.automaticFilters")
        app.tap(.closeButton)
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
        self.sleep(seconds: 1)
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
