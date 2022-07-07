//
//  UI_TestsLaunchTests.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 11/06/2022.
//

import XCTest
import NaturalLanguage

class SnapshotsTestCase: ApplicationTestCase {
    
    func testCreateSnapshots() throws {

        let app = TestApplication(testCase: self)
        let langCode = Locale.current.languageCode ?? "unknown"
        app.dismissCallToActionViewIfPresented()
        
        
        // MARK: denyFilters Screenshot
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_OFF"~)
        app.tap(.automaticFilterLink)
        for lang in [NLLanguage.english, NLLanguage.hebrew] {
            app.switches[lang~].firstMatch.tap()
        }
        snapshot("02.automaticFilters")
        app.buttons["filterList_filters"~].firstMatch.tap()
        self.sleep(seconds: 1)
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_ON"~)

        // MARK: addFilter Screenshot
        if langCode == "he" {
            app.addFilter(type: .deny,
                          text: "הלוואה",
                          denyFolderType: .junk,
                          filterTarget: .body,
                          filterMatching: .exact,
                          filterCase: .caseInsensitive,
                          screenshotName: "04.addFilter")
        }
        else {
            app.addFilter(type: .deny,
                          text: "Weed",
                          denyFolderType: .junk,
                          filterTarget: .body,
                          filterMatching: .exact,
                          filterCase: .caseInsensitive,
                          screenshotName: "05.addFilter")
        }


        // MARK: applicationHome Screenshot
        for rule in RuleType.allCases.filter({ $0 != .allUnknown }) {
            let ruleSwitch = app.switchContaining(rule.title)
            XCTAssert(ruleSwitch.value as? String == "0")
            ruleSwitch.tap()
            XCTAssert(ruleSwitch.value as? String == "1")
        }
        app.tap(.appMenuButton)
        app.tap(.loadDebugDataMenuButton)
        snapshot("01.applicationHome")


        // MARK: denyFilters Screenshot
        app.tap(.denyFiltersLink)
        snapshot("03.denyFilters")


        // MARK: allowFilters Screenshot
        app.buttons["filterList_filters"~].firstMatch.tap()
        app.tap(.allowFiltersLink)
        snapshot("04.allowFilters")
        app.buttons["filterList_filters"~].firstMatch.tap()

        
        // MARK: denyLanguages Screenshot
        app.swipeUp()
        app.tap(.denyLanguageLink)
        app.tap(.addFilterButton)
        snapshot("06.denyLanguages")
        app.tap(.closeButton)
        app.buttons["filterList_filters"~].firstMatch.tap()

         
        // MARK: testFilters Screenshot
        app.tap(.appMenuButton)
        app.tap(.testYourFiltersMenuButton)
        app.textField(.testBodyInput).typeText("Your Apple ID Code is: 444291. Don't share it with anyone.")
        app.textField(.testSenderInput).tap()
        app.textField(.testSenderInput).typeText("Apple\n")
        app.tap(.testYourFiltersButton)
        snapshot("07.testFilters")
    }
}
