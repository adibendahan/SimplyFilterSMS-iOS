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
        self.revealTopOfHome()
    }

    func showAddFilter(_ text: String, folder: Folder, target: Target, matching: Matching, letterCase: LetterCase) {
        self.show()
        self.app.buttons[.addFilterButton].tap()
        self.showAllOptions(probe: target.element)
        self.select(folder.element)
        self.select(target.element)
        self.select(matching.element)
        self.select(letterCase.element)
        let field = self.app.textFields[.filterText]
        self.type(text, into: field)
        self.hideKeyboard(from: field)
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
        self.revealTopOfHome()
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
        self.type(message.body, into: self.app.textFields[.testBodyInput])
        self.waitForVerdict(on: message)
        let senderField = self.app.textFields[.testSenderInput]
        self.type(message.sender, into: senderField)
        self.waitForVerdict(on: message)
        self.hideKeyboard(from: senderField)
    }

    //MARK: - Private -
    private func waitForVerdict(on message: Message) {
        let identifiers = [Verdict.allowed, .junk, .promotion, .transaction].map(\.element.rawValue)
        let isVerdict = NSPredicate(format: "identifier IN %@", identifiers)
        let verdict = self.app.descendants(matching: .any).matching(isVerdict).firstMatch
        XCTAssertTrue(verdict.waitForExistence(timeout: 10), "\(message) shows no verdict")
    }
}
