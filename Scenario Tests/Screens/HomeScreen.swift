//
//  HomeScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

struct HomeScreen: Screen {
    let app: XCUIApplication

    func turnOn(_ smartFilter: SmartFilter) {
        self.step("Turn on \(smartFilter.rawValue)") {
            self.setSwitch(self.app.switches[smartFilter.element], isOn: true)
        }
    }

    func turnOff(_ smartFilter: SmartFilter) {
        self.step("Turn off \(smartFilter.rawValue)") {
            self.setSwitch(self.app.switches[smartFilter.element], isOn: false)
        }
    }

    func waitUntilReady() {
        XCTAssertTrue(self.app.buttons[.appMenuButton].waitForExistence(timeout: 15), "Home did not appear")
        let callToAction = self.app.buttons[.callToActionButton]
        while callToAction.exists {
            let cancel = self.app.buttons[.cancelButton]
            if cancel.exists {
                cancel.tap()
            }
            else {
                callToAction.tap()
            }
            _ = callToAction.waitForNonExistence(timeout: 3)
            _ = callToAction.waitForExistence(timeout: 1)
        }
    }
}
