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
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < self.maxRevealSwipes {
            self.swipeAlongMargin(of: self.homeList, direction)
            swipes += 1
        }
        XCTAssertTrue(element.exists && element.isHittable, "\(element) is not reachable")
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
