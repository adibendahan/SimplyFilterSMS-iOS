//
//  Screen+Studio.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

extension Screen {
    func hideKeyboard(from field: XCUIElement) {
        field.typeText("\n")
        let unfocused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == false"), object: field)
        XCTAssertEqual(XCTWaiter.wait(for: [unfocused], timeout: 5), .completed, "\(field) kept the keyboard open")
    }
}
