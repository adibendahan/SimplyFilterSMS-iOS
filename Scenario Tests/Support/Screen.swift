//
//  Screen.swift
//  Scenario Tests
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

    func openFilterTool(_ label: String) {
        self.app.buttons[.appMenuButton].tap()
        self.app.buttons[.filterToolsMenuButton].tap()
        self.app.buttons[label].firstMatch.tap()
    }

    func setSwitch(_ toggle: XCUIElement, isOn: Bool, timeout: TimeInterval = 8) {
        let expectedValue = isOn ? "1" : "0"
        XCTAssertTrue(toggle.waitForExistence(timeout: timeout), "Missing switch \(toggle)")
        if toggle.value as? String != expectedValue {
            toggle.switches.firstMatch.tap()
        }
        XCTAssertTrue(toggle.waitForValue(expectedValue), "\(toggle) did not switch to \(expectedValue)")
    }

    func swipeToDelete(_ row: XCUIElement) {
        row.swipeLeft()
        self.app.collectionViews.buttons["Delete"].firstMatch.tap()
    }

    func type(_ text: String, into field: XCUIElement) {
        field.tap()
        field.typeText(text)
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

extension XCUIElement {
    func waitForValue(_ value: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    func waitUntil(_ keyPath: KeyPath<XCUIElement, Bool>, timeout: TimeInterval = 8) -> Bool {
        guard self.waitForExistence(timeout: timeout) else { return false }
        return self.wait(for: keyPath, toEqual: true, timeout: timeout)
    }
}
