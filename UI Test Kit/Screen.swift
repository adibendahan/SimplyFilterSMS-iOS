//
//  Screen.swift
//  UI Test Kit
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

enum HomeSwipe {
    case up
    case down
}

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
        let element = self.app.buttons[link]
        self.reveal(element)
        element.tap()
    }

    func reveal(_ element: XCUIElement) {
        self.swipeHome(.up, until: element)
    }

    func revealTopOfHome() {
        guard self.usesSplitLayout else { return }
        self.swipeHome(.down, until: self.app.buttons[.filterListsLink])
    }

    func swipe(_ list: XCUIElement, _ direction: HomeSwipe, until element: XCUIElement) {
        self.repeatSwipes(until: element) {
            switch direction {
            case .up:
                list.swipeUp(velocity: .slow)
            case .down:
                list.swipeDown(velocity: .slow)
            }
        }
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

    func clear(_ field: XCUIElement) {
        for edge in [CGFloat(0.99), CGFloat(0.01)] {
            let text = field.value as? String ?? ""
            guard !text.isEmpty else { break }
            field.coordinate(withNormalizedOffset: CGVector(dx: edge, dy: 0.9)).tap()
            XCTAssertTrue(self.waitForKeyboardFocus(on: field), "\(field) did not take the keyboard")
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: text.count)
            field.typeText(deletes)
        }
        let remaining = field.value as? String ?? ""
        XCTAssertTrue(remaining.isEmpty, "\(field) still reads \"\(remaining)\" after clearing")
    }


    //MARK: - Private -
    private var maxRevealSwipes: Int {
        return 3
    }

    private var homeList: XCUIElement {
        let homeRows: [TestIdentifier] = [.filterListsLink, .allUnknownToggle, .linksToggle, .shortSenderToggle, .emailToggle,
                                          .numbersOnlyToggle, .countryAllowlistToggle, .emojisToggle,
                                          .communityListsLink, .allowFiltersLink, .denyFiltersLink, .denyLanguageLink]
        let identifiers = homeRows.map(\.rawValue)
        let isHomeRow = NSPredicate(format: "identifier IN %@", identifiers)
        return self.app.collectionViews.containing(isHomeRow).firstMatch
    }

    private func swipeHome(_ direction: HomeSwipe, until element: XCUIElement) {
        self.repeatSwipes(until: element) {
            self.swipeAlongMargin(of: self.homeList, direction)
        }
    }

    private func repeatSwipes(until element: XCUIElement, _ swipe: () -> Void) {
        var swipes = 0
        while !self.isReachable(element) && swipes < self.maxRevealSwipes {
            swipe()
            swipes += 1
        }
        XCTAssertTrue(self.isReachable(element), "\(element) is not reachable")
    }

    private func isReachable(_ element: XCUIElement) -> Bool {
        guard element.exists && element.isHittable else { return false }
        let window = self.app.windows.firstMatch.frame
        guard window.contains(element.frame) else { return false }
        let searchField = self.app.searchFields.firstMatch
        guard searchField.exists else { return true }
        let searchBar = searchField.frame.insetBy(dx: 0, dy: -self.searchBarMargin)
        return !element.frame.intersects(searchBar)
    }

    private var searchBarMargin: CGFloat {
        return 16
    }

    private func swipeAlongMargin(of list: XCUIElement, _ direction: HomeSwipe) {
        let lower = list.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.8))
        let upper = list.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.2))
        switch direction {
        case .up:
            lower.press(forDuration: 0.1, thenDragTo: upper)
        case .down:
            upper.press(forDuration: 0.1, thenDragTo: lower)
        }
    }

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
