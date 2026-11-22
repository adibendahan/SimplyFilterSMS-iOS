//
//  Screen+Studio.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

enum HomeSwipe {
    case up
    case down
}

extension Screen {
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

    func hideKeyboard(from field: XCUIElement) {
        field.typeText("\n")
        let unfocused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == false"), object: field)
        XCTAssertEqual(XCTWaiter.wait(for: [unfocused], timeout: 5), .completed, "\(field) kept the keyboard open")
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
}
