//
//  AIFilteringScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

struct AIFilteringScreen: Screen {
    let app: XCUIApplication

    private let downloadTimeout: TimeInterval = 20

    func turnOn(_ language: Language) {
        self.step("Turn on AI Filtering for \(language)") {
            self.setLanguage(language, isOn: true)
        }
    }

    func turnOff(_ language: Language) {
        self.step("Turn off AI Filtering for \(language)") {
            self.setLanguage(language, isOn: false)
        }
    }

    //MARK: - Private -
    private func setLanguage(_ language: Language, isOn: Bool) {
        self.open(.filterListsLink)
        self.setSwitch(self.app.switches[language.element].firstMatch, isOn: isOn, timeout: self.downloadTimeout)
        self.backToHome()
    }
}
