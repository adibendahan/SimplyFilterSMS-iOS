//
//  Screen+Studio.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

extension Screen {
    func reveal(_ element: XCUIElement) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < self.maxRevealSwipes {
            self.app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.exists && element.isHittable, "\(element) is not reachable")
    }

    func hideKeyboard(from field: XCUIElement) {
        field.typeText("\n")
        let unfocused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == false"), object: field)
        XCTAssertEqual(XCTWaiter.wait(for: [unfocused], timeout: 5), .completed, "\(field) kept the keyboard open")
    }

    //MARK: - Private -
    private var maxRevealSwipes: Int {
        return 3
    }
}
