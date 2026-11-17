//
//  CommunityListsScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

struct CommunityListsScreen: Screen {
    let app: XCUIApplication

    private let downloadTimeout: TimeInterval = 20

    func turnOn(_ name: String) {
        self.step("Turn on Community List \(name)") {
            self.open(.communityListsLink)
            self.setSwitch(self.app.switches[name].firstMatch, isOn: true, timeout: self.downloadTimeout)
            self.backToHome()
        }
    }

    func subscribe(to url: String, expecting name: String) {
        self.step("Subscribe to \(name)") {
            let sheet = self.openSubscribeFromURL()
            sheet.enterLink(url)
            sheet.expectAccepted()
            sheet.subscribe()

            let toggle = self.app.switches[name].firstMatch
            XCTAssertTrue(toggle.waitForExistence(timeout: 5), "\(name) is not in Community Lists")
            XCTAssertTrue(toggle.waitForValue("1"), "\(name) is not on after subscribing")
            self.backToHome()
        }
    }

    func remove(_ name: String) {
        self.step("Remove Community List \(name)") {
            self.open(.communityListsLink)
            let cell = self.app.collectionViews.cells.containing(.switch, identifier: name).firstMatch
            XCTAssertTrue(cell.waitForExistence(timeout: 5), "\(name) is not in Community Lists")
            self.swipeToDelete(cell)
            XCTAssertTrue(self.app.switches[name].firstMatch.waitForNonExistence(timeout: 5), "\(name) is still in Community Lists")
            self.backToHome()
        }
    }

    func openSubscribeFromURL() -> SubscribeSheet {
        self.open(.communityListsLink)
        self.app.buttons[.addCommunityListButton].tap()
        return SubscribeSheet(app: self.app)
    }
}

struct SubscribeSheet: Screen {
    let app: XCUIApplication

    private let downloadTimeout: TimeInterval = 15

    private var urlField: XCUIElement {
        return self.app.textFields[.communityListURLField]
    }

    private var subscribeButton: XCUIElement {
        return self.app.buttons[.subscribeCommunityListButton]
    }

    private var error: XCUIElement {
        return self.app.descendants(matching: .any)[.communityListError]
    }

    func enterLink(_ url: String) {
        self.type(url, into: self.urlField)
    }

    func replaceLink(with url: String) {
        let currentLink = self.urlField.value as? String ?? ""
        let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentLink.count)
        self.urlField.typeText(deletes + url)
    }

    func expectRefused(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(self.error.waitForExistence(timeout: self.downloadTimeout), "No error for a file that isn't a filter list", file: file, line: line)
        XCTAssertFalse(self.subscribeButton.isEnabled, "Subscribe is enabled for a file that isn't a filter list", file: file, line: line)
    }

    func expectAccepted(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(self.subscribeButton.waitUntil(\.isEnabled, timeout: self.downloadTimeout), "Subscribe stayed disabled for a valid list", file: file, line: line)
        XCTAssertFalse(self.error.exists, "An error is showing for a valid list", file: file, line: line)
    }

    func subscribe() {
        self.subscribeButton.tap()
        XCTAssertTrue(self.subscribeButton.waitForNonExistence(timeout: 10), "Subscribe from URL did not close")
    }
}
