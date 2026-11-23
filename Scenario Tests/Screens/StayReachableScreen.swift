//
//  StayReachableScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 19/11/2026.
//

import XCTest

struct StayReachableScreen: Screen {
    let app: XCUIApplication
    let phoneLanguages: [Language]

    private let toastTitle = "Never miss a delivery!"
    private let menuSymbol = "person.badge.shield.checkmark"

    func openFromToast() -> StayReachableSheet {
        let toast = self.app.descendants(matching: .any)[.toast]
        self.step("Open Stay Reachable from its toast") {
            XCTAssertTrue(toast.waitForExistence(timeout: 5), "No toast showed")
            XCTAssertTrue(toast.label.contains(self.toastTitle), "The toast showing is not Stay Reachable's: \(toast.label)")
            toast.tap()
        }
        return self.sheet()
    }

    func openFromMenu() -> StayReachableSheet {
        let item = self.app.images[self.menuSymbol].firstMatch
        self.step("Open Stay Reachable from the Add Filter menu") {
            self.openAddFilterMenu()
            if !item.waitForExistence(timeout: 5) {
                self.openAddFilterMenu()
            }
            XCTAssertTrue(item.waitForExistence(timeout: 5), "Stay Reachable is not in the Add Filter menu")
            item.tap()
        }
        return self.sheet()
    }


    //MARK: - Private -
    private func sheet() -> StayReachableSheet {
        let sheet = StayReachableSheet(app: self.app, phoneLanguages: self.phoneLanguages)
        sheet.expectOpen()
        return sheet
    }

    private func openAddFilterMenu() {
        let addFilter = self.app.buttons[.addFilterMenuButton]
        XCTAssertTrue(addFilter.waitForExistence(timeout: 5), "The add filter button is missing")
        addFilter.tap()
    }
}

struct StayReachableSheet: Screen {
    enum Field: String {
        case firstName
        case surname
        case street

        var element: TestIdentifier {
            switch self {
            case .firstName:
                return .stayReachableFirstNameField
            case .surname:
                return .stayReachableSurnameField
            case .street:
                return .stayReachableStreetField
            }
        }
    }

    let app: XCUIApplication
    let phoneLanguages: [Language]

    private let maxRevealSwipes = 5

    private var addButton: XCUIElement {
        return self.app.buttons[.stayReachableAddButton]
    }

    private var sections: [Language] {
        let appLanguage = self.phoneLanguages.first ?? .english
        let otherLanguages = self.phoneLanguages.filter { $0 != appLanguage && $0 != .english }
        let sections: [Language]
        if appLanguage == .english {
            sections = [.english] + otherLanguages
        } else {
            sections = [appLanguage, .english] + otherLanguages
        }
        return sections
    }

    func expectOpen(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(self.addButton.waitForExistence(timeout: 5), "Stay Reachable did not open", file: file, line: line)
    }

    func expect(_ language: Language, header: String, firstNameLabel: String, file: StaticString = #filePath, line: UInt = #line) {
        self.step("The \(language.rawValue) section reads \"\(header)\" and \"\(firstNameLabel)\"") {
            self.reveal(self.field(.firstName, in: language))
            let fieldLabel = self.app.staticTexts[firstNameLabel].firstMatch
            XCTAssertTrue(fieldLabel.exists, "The \(language.rawValue) section's first name is not labeled in its language", file: file, line: line)

            let headerPredicate = NSPredicate(format: "label CONTAINS %@", header)
            let headerElement = self.app.buttons.matching(headerPredicate).firstMatch
            XCTAssertTrue(headerElement.exists, "No \"\(header)\" section header", file: file, line: line)
        }
    }

    func fill(_ language: Language, firstName: String = "", surname: String = "", street: String = "", file: StaticString = #filePath, line: UInt = #line) {
        let texts: [(Field, String)] = [(.firstName, firstName), (.surname, surname), (.street, street)]
        self.step("Fill the \(language.rawValue) section: \(firstName) \(surname), \(street)") {
            for (field, text) in texts {
                guard !text.isEmpty else { continue }
                let element = self.field(field, in: language)
                self.reveal(element)
                self.type(text + "\n", into: element)
                XCTAssertEqual(element.value as? String, text, "The \(language.rawValue) \(field.rawValue) did not take \"\(text)\"", file: file, line: line)
            }
        }
    }

    func expectFilled(_ language: Language, firstName: String, surname: String, street: String, file: StaticString = #filePath, line: UInt = #line) {
        let texts: [(Field, String)] = [(.firstName, firstName), (.surname, surname), (.street, street)]
        self.step("The \(language.rawValue) section is filled in: \(firstName) \(surname), \(street)") {
            for (field, text) in texts {
                let element = self.field(field, in: language)
                self.reveal(element)
                XCTAssertEqual(element.value as? String, text, "The \(language.rawValue) \(field.rawValue) is not \"\(text)\"", file: file, line: line)
            }
        }
    }

    func expectSkipped(_ text: String, because reason: String, file: StaticString = #filePath, line: UInt = #line) {
        self.step("\"\(text)\" is skipped: \(reason)") {
            let predicate = NSPredicate(format: "identifier == %@ AND label CONTAINS %@ AND label CONTAINS %@",
                                        TestIdentifier.stayReachableSkippedNote.rawValue, text, reason)
            let note = self.app.staticTexts.matching(predicate).firstMatch
            XCTAssertTrue(note.waitForExistence(timeout: 5), "No note says \"\(text)\" \(reason)", file: file, line: line)
        }
    }

    func expectNoSkippedNotes(file: StaticString = #filePath, line: UInt = #line) {
        self.step("No text is marked as skipped") {
            let notes = self.app.staticTexts.matching(identifier: TestIdentifier.stayReachableSkippedNote.rawValue)
            XCTAssertEqual(notes.count, 0, "A skipped note shows: \(notes.firstMatch.label)", file: file, line: line)
        }
    }

    func expectAddButton(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        self.step("The add button reads \"\(title)\"") {
            XCTAssertTrue(self.addButton.wait(for: \.label, toEqual: title, timeout: 5), "The add button reads \"\(self.addButton.label)\"", file: file, line: line)
            XCTAssertTrue(self.addButton.isEnabled, "The add button is disabled", file: file, line: line)
        }
    }

    func expectNothingToAdd(file: StaticString = #filePath, line: UInt = #line) {
        self.step("Nothing is left to add") {
            XCTAssertTrue(self.addButton.waitForExistence(timeout: 5), "The add button is missing", file: file, line: line)
            XCTAssertTrue(self.addButton.wait(for: \.isEnabled, toEqual: false, timeout: 5), "The add button is enabled with nothing new to add", file: file, line: line)
        }
    }

    func add() {
        self.step("Add the allowed texts") {
            self.addButton.tap()
            XCTAssertTrue(self.addButton.waitForNonExistence(timeout: 5), "Stay Reachable did not close")
        }
    }

    func close() {
        self.step("Close Stay Reachable") {
            self.app.buttons[.closeButton].tap()
            XCTAssertTrue(self.addButton.waitForNonExistence(timeout: 5), "Stay Reachable did not close")
        }
    }


    //MARK: - Private -
    private func field(_ field: Field, in language: Language) -> XCUIElement {
        let index = self.sections.firstIndex(of: language) ?? 0
        let fields = self.app.textFields.matching(identifier: field.element.rawValue)
        return fields.element(boundBy: index)
    }

    private func reveal(_ element: XCUIElement) {
        let list = self.app.collectionViews.firstMatch
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < self.maxRevealSwipes {
            list.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(element.isHittable, "\(element) is not on screen")
    }
}
