//
//  FilterListScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

struct FilterListScreen: Screen {
    enum Kind: String {
        case allow
        case deny

        var link: TestIdentifier {
            switch self {
            case .allow:
                return .allowFiltersLink
            case .deny:
                return .denyFiltersLink
            }
        }
    }

    let app: XCUIApplication
    let kind: Kind

    func add(_ text: String,
             folder: Folder? = nil,
             target: Target = .all,
             matching: Matching = .contains,
             letterCase: LetterCase = .insensitive) {
        self.step("Add \(self.kind.rawValue) filter \"\(text)\"") {
            self.open(self.kind.link)
            self.app.buttons[.addFilterButton].tap()
            self.showAllOptions(probe: target.element)

            if let folder {
                self.select(folder.element)
            }
            self.select(target.element)
            self.select(matching.element)
            if matching != .regex {
                self.select(letterCase.element)
            }
            self.type(text + "\n", into: self.app.textFields[.filterText])
            self.dismissKeyboard()

            let confirm = self.app.buttons[.addFilterConfirmButton]
            confirm.tap()
            XCTAssertTrue(confirm.waitForNonExistence(timeout: 5), "Add Filter did not close")
            XCTAssertTrue(self.row(text).waitForExistence(timeout: 5), "\"\(text)\" is not in the \(self.kind.rawValue) list")
            self.backToHome()
        }
    }

    func delete(_ text: String) {
        self.step("Delete \(self.kind.rawValue) filter \"\(text)\"") {
            self.open(self.kind.link)
            let cell = self.app.collectionViews.cells.containing(.textField, identifier: text).firstMatch
            XCTAssertTrue(cell.waitForExistence(timeout: 5), "\"\(text)\" is not in the \(self.kind.rawValue) list")
            self.swipeToDelete(cell)
            XCTAssertTrue(self.row(text).waitForNonExistence(timeout: 5), "\"\(text)\" is still in the \(self.kind.rawValue) list")
            self.backToHome()
        }
    }

    //MARK: - Private -
    private func row(_ text: String) -> XCUIElement {
        return self.app.collectionViews.textFields[text].firstMatch
    }

    private func showAllOptions(probe option: TestIdentifier) {
        let option = self.app.segmentedControls.buttons[option]
        if !option.waitForExistence(timeout: 3) {
            self.app.buttons[.expandButton].tap()
        }
    }

    private func select(_ identifier: TestIdentifier) {
        let option = self.app.segmentedControls.buttons[identifier]
        option.tap()
        XCTAssertTrue(option.waitUntil(\.isSelected, timeout: 5), "\(identifier.rawValue) was not selected")
    }
}
