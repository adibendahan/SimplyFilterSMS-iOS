//
//  Screen.swift
//  UI Test Kit
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
protocol Screen {
    var app: XCUIApplication { get }
}

extension Screen {
    var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    func step(_ name: String, _ actions: () -> Void) {
        XCTContext.runActivity(named: name) { _ in
            actions()
        }
    }

    func open(_ link: TestIdentifier) {
        self.app.buttons[link].tap()
    }

    func backToHome() {
        guard !self.isPad else { return }
        self.app.buttons["BackButton"].firstMatch.tap()
    }

    func openFilterTool(_ tool: FilterTool) {
        self.app.buttons[.appMenuButton].tap()
        self.app.buttons[.filterToolsMenuButton].tap()
        let item = self.app.images[tool.symbol].firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 5), "\(tool) is not in the Filter Tools menu")
        item.tap()
    }

    func setSwitch(_ toggle: XCUIElement, isOn: Bool, timeout: TimeInterval = 8) {
        let expectedValue = isOn ? "1" : "0"
        XCTAssertTrue(toggle.waitForExistence(timeout: timeout), "Missing switch \(toggle)")
        if toggle.value as? String != expectedValue {
            toggle.switches.firstMatch.tap()
        }
        XCTAssertTrue(toggle.waitForValue(expectedValue), "\(toggle) did not switch to \(expectedValue)")
    }

    func type(_ text: String, into field: XCUIElement) {
        field.tap()
        field.typeText(text)
    }
}
