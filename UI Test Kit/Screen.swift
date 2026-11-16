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
    var usesSplitLayout: Bool {
        return self.app.hasWideWindow
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
        guard !self.usesSplitLayout else { return }
        self.app.buttons["BackButton"].firstMatch.tap()
    }

    func openFilterTool(_ tool: FilterTool) {
        let item = self.app.images[tool.symbol].firstMatch
        self.openFilterToolsMenu()
        if !item.waitForExistence(timeout: 5) {
            self.openFilterToolsMenu()
        }
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
        if !self.waitForKeyboardFocus(on: field) {
            field.tap()
        }
        XCTAssertTrue(self.waitForKeyboardFocus(on: field), "\(field) did not take the keyboard")
        field.typeText(text)
    }


    //MARK: - Private -
    private func openFilterToolsMenu() {
        let filterTools = self.app.buttons[.filterToolsMenuButton]
        if !filterTools.exists {
            self.app.buttons[.appMenuButton].tap()
        }
        XCTAssertTrue(filterTools.waitForExistence(timeout: 5), "The app menu did not open")
        filterTools.tap()
    }

    private func waitForKeyboardFocus(on field: XCUIElement) -> Bool {
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: field)
        let result = XCTWaiter.wait(for: [focused], timeout: 3)
        return result == .completed
    }
}
