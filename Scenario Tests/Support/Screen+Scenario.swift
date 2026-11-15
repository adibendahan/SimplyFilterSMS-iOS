//
//  Screen+Scenario.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

extension Screen {
    func swipeToDelete(_ row: XCUIElement) {
        row.swipeLeft()
        self.app.collectionViews.buttons["Delete"].firstMatch.tap()
    }

    func dismissKeyboard() {
        let keyboard = self.app.keyboards.firstMatch
        guard keyboard.exists else { return }
        let done = self.app.buttons["Done"].firstMatch
        if done.exists {
            done.tap()
        }
        else {
            self.app.navigationBars.firstMatch.tap()
        }
        XCTAssertTrue(keyboard.waitForNonExistence(timeout: 5), "The keyboard did not close")
    }
}
