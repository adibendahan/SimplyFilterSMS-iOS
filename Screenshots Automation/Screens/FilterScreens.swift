//
//  FilterScreens.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

struct FilterListScreen: Screen {
    let app: XCUIApplication
    let link: TestIdentifier

    func show() {
        let link = self.app.buttons[self.link]
        self.reveal(link)
        link.tap()
        XCTAssertTrue(self.app.buttons[.addFilterButton].waitForExistence(timeout: 5), "\(self.link.rawValue) did not open")
    }

    func showAddFilter(_ text: String, folder: Folder, target: Target, matching: Matching, letterCase: LetterCase) {
        self.show()
        self.app.buttons[.addFilterButton].tap()
        self.showAllOptions(probe: target.element)
        self.select(folder.element)
        self.select(target.element)
        self.select(matching.element)
        self.select(letterCase.element)
        self.type(text, into: self.app.textFields[.filterText])
        self.hideKeyboard()
    }

    //MARK: - Private -
    private func showAllOptions(probe option: TestIdentifier) {
        if !self.app.segmentedControls.buttons[option].waitForExistence(timeout: 3) {
            self.app.buttons[.expandButton].tap()
        }
    }

    private func select(_ identifier: TestIdentifier) {
        let option = self.app.segmentedControls.buttons[identifier]
        option.tap()
        XCTAssertTrue(option.waitUntil(\.isSelected, timeout: 5), "\(identifier.rawValue) was not selected")
    }
}

struct BlockedLanguagesScreen: Screen {
    let app: XCUIApplication

    func show() {
        let link = self.app.buttons[.denyLanguageLink]
        self.reveal(link)
        link.tap()
        self.app.buttons[.addFilterButton].tap()
        XCTAssertTrue(self.app.buttons[.closeButton].waitForExistence(timeout: 5), "The language picker did not open")
    }
}

struct CountriesScreen: Screen {
    let app: XCUIApplication

    func show() {
        self.app.buttons[.countryAllowlistButton].tap()
        XCTAssertTrue(self.app.buttons[.closeButton].waitForExistence(timeout: 5), "The country list did not open")
    }
}

struct FilterTesterScreen: Screen {
    let app: XCUIApplication

    func show(_ message: Message) {
        self.openFilterTool(.testYourFilters)
        self.type(message.body, into: self.app.textViews[.testBodyInput])
        self.type(message.sender, into: self.app.textFields[.testSenderInput])
        let verdicts = [Verdict.allowed, .junk, .promotion, .transaction].map { self.app.descendants(matching: .any)[$0.element] }
        let anyVerdict = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in verdicts.contains { $0.exists } }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [anyVerdict], timeout: 5), .completed, "\(message) shows no verdict")
        self.hideKeyboard()
    }
}
