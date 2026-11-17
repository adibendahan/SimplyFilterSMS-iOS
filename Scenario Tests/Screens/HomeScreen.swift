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
}
