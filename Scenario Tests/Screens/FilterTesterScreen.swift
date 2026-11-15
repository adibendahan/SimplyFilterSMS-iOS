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

    func expect(_ message: Message, toBe verdict: Verdict, file: StaticString, line: UInt) {
        self.step("\(message) is \(verdict.rawValue)") {
            self.openFilterTool(.testYourFilters)
            let bodyInput = self.app.textViews[.testBodyInput]
            self.type(message.body, into: bodyInput)
            self.type(message.sender + "\n", into: self.app.textFields[.testSenderInput])

            let result = self.app.descendants(matching: .any)[verdict.element]
            XCTAssertTrue(result.waitForExistence(timeout: 5), "\(message) is not \(verdict.rawValue)", file: file, line: line)
            XCTAssertFalse(result.waitForNonExistence(timeout: self.debounce), "\(message) changed from \(verdict.rawValue) once fully typed", file: file, line: line)

            self.dismissKeyboard()
            self.app.buttons[.closeButton].tap()
            XCTAssertTrue(bodyInput.waitForNonExistence(timeout: 5), "Filter Tester did not close")
        }
    }
}
