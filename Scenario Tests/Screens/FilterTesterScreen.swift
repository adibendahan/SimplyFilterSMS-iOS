//
//  FilterTesterScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

struct FilterTesterScreen: Screen {
    let app: XCUIApplication

    private let debounce: TimeInterval = 1.5

    private var bodyInput: XCUIElement {
        return self.app.textFields[.testBodyInput]
    }

    private var senderInput: XCUIElement {
        return self.app.textFields[.testSenderInput]
    }

    private var shownResult: XCUIElement {
        let identifiers = Verdict.allCases.map(\.element.rawValue)
        let predicate = NSPredicate(format: "identifier IN %@", identifiers)
        return self.app.descendants(matching: .any).matching(predicate).firstMatch
    }

    func open() {
        self.step("Open Test Your Filters") {
            self.openFilterTool(.testYourFilters)
            XCTAssertTrue(self.bodyInput.waitForExistence(timeout: 5), "Test Your Filters did not open")
        }
    }

    func expect(_ message: Message, toBe verdict: Verdict, file: StaticString = #filePath, line: UInt = #line) {
        self.step("\(message) is \(verdict.rawValue)") {
            self.clear(self.bodyInput)
            self.clear(self.senderInput)
            XCTAssertTrue(self.shownResult.waitForNonExistence(timeout: 5), "The previous result stayed after clearing", file: file, line: line)

            self.type(message.body, into: self.bodyInput)
            self.type(message.sender + "\n", into: self.senderInput)

            let result = self.app.descendants(matching: .any)[verdict.element]
            XCTAssertTrue(result.waitForExistence(timeout: 5), "\(message) is not \(verdict.rawValue)", file: file, line: line)
            XCTAssertFalse(result.waitForNonExistence(timeout: self.debounce), "\(message) changed from \(verdict.rawValue) once fully typed", file: file, line: line)
        }
    }

    func close() {
        self.step("Close Test Your Filters") {
            self.dismissKeyboard()
            self.app.buttons[.closeButton].tap()
            XCTAssertTrue(self.bodyInput.waitForNonExistence(timeout: 5), "Test Your Filters did not close")
        }
    }
}
