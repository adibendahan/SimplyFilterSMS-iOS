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

    func hideKeyboard() {
        let keyboard = self.app.keyboards.firstMatch
        guard keyboard.exists else { return }
        self.app.typeText("\n")
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5), "The keyboard did not close")
    }

    //MARK: - Private -
    private var maxRevealSwipes: Int {
        return 3
    }
}
