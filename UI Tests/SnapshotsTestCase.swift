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
        app.waitForHittable(app.button(.automaticFilterLink))
        let allowLink = app.button(.allowFiltersLink)
        XCTAssertTrue(allowLink.waitForExistence(timeout: 8))
        let populated = self.expectation(for: NSPredicate(format: "label MATCHES %@", ".*[1-9].*"), evaluatedWith: allowLink)
        XCTAssertEqual(XCTWaiter.wait(for: [populated], timeout: 15), .completed, "Debug filters did not appear on Home")
        self.waitForUIToSettle()

        if !isPad {
            snapshotSettled("01.applicationHome")
        }
        
        app.assertLabel(of: .automaticFilterLink, contains: "autoFilter_ON"~)
        app.tap(.automaticFilterLink)
        app.waitForHittable(app.switches.firstMatch)
        snapshotSettled("02.automaticFilters")
        app.tap(.closeButton)
        app.buttons["BackButton"].firstMatch.conditionalTap(!isPad)
        self.waitForUIToSettle()

        app.tap(.countryAllowlistButton)
        app.waitForHittable(app.button(.closeButton))
        snapshotSettled("08.countryList")
        app.tap(.closeButton)
        self.waitForUIToSettle()


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
        snapshotSettled("03.denyFilters")


        // MARK: allowFilters Screenshot
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)
        app.tap(.allowFiltersLink)
        snapshotSettled("04.allowFilters")
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)


        // MARK: denyLanguages Screenshot
        app.conditionalSwipeUp(!isPad)
        app.tap(.denyLanguageLink)
        app.waitForHittable(app.button(.addFilterButton))
        self.waitForUIToSettle()
        app.tap(.addFilterButton)
        app.waitForHittable(app.button(.closeButton))
        snapshotSettled("06.denyLanguages")
        app.tap(.closeButton)
        app.buttons["filterList_filters"~].firstMatch.conditionalTap(!isPad)
        self.waitForUIToSettle()


        // MARK: testFilters Screenshot
        app.tap(.appMenuButton)
        app.tap(.filterToolsMenuButton)
        app.tap(.testYourFiltersMenuButton)

        let senderField = app.textField(.testSenderInput)
        let bodyView = app.textField(.testBodyInput)
        XCTAssertTrue(bodyView.waitForExistence(timeout: 5), "Test Filters message field missing")
        self.sleep(seconds: 1)

        bodyView.tap()
        bodyView.typeText("Your Apple ID Code is: 444291. Don't share it with anyone.")
        senderField.tap()
        senderField.typeText("Apple\n")

        let resultVisible =
            app.staticTexts["testFilters_resultJunk"~].waitForExistence(timeout: 5) ||
            app.staticTexts["testFilters_resultPromotion"~].waitForExistence(timeout: 2) ||
            app.staticTexts["testFilters_resultTransaction"~].waitForExistence(timeout: 2) ||
            app.staticTexts["testFilters_resultAllowed"~].waitForExistence(timeout: 2)
        XCTAssertTrue(resultVisible, "Live test result did not appear")
        app.waitForKeyboardToDismiss()
        snapshotSettled("07.testFilters")
    }
    
}
