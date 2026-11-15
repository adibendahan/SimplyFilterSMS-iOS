//
//  TestApplication.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 18/06/2022.
//

import XCTest
import NaturalLanguage

@MainActor
class TestApplication: XCUIApplication {
    private var testCase: ApplicationTestCase
    
    init(testCase: ApplicationTestCase, launchArguments: [String] = []) {
        self.testCase = testCase
        super.init()

        self.launchArguments.append("-Testing")
        self.launchArguments.append(contentsOf: launchArguments)
//        setupSnapshot(self)
        self.launch()
    }
    
    func dismissCallToActionViewIfPresented() {
        while self.buttonExists(.callToActionButton) {
            if self.buttonExists(.cancelButton) {
                self.tap(.cancelButton)
            }
            else {
                self.tap(.callToActionButton)
            }
            self.testCase.sleep(seconds: 1)
        }
    }
    
    func addFilter(type: FilterType,
                   text: String,
                   messageFolder: MessageFolder? = nil,
                   filterTarget: FilterTarget,
                   filterMatching: FilterMatching,
                   filterCase: FilterCase,
                   screenshotName: String? = nil) {
        
        if self.button(type.testIdentifier).exists {
            self.tap(type.testIdentifier)
        }
        else if !self.staticTexts[type.name].exists {
            self.buttons["filterList_filters"~].firstMatch.forceTap()
            self.tap(type.testIdentifier)
        }
        
        XCTAssert(self.staticTexts[type.name].exists)
        
        self.tap(.addFilterButton)
        self.waitForHittable(self.button(.expandButton))
        self.testCase.waitForUIToSettle()
        self.tap(.expandButton)
        self.testCase.waitForUIToSettle()
        
        if let messageFolder = messageFolder {
            self.buttonContaining(messageFolder.name).forceTap()
        }

        self.buttonContaining(filterTarget.name).forceTap()
        self.buttonContaining(filterMatching.name).forceTap()
        self.buttonContaining(filterCase.name).forceTap()
        self.textField(.filterText).forceTap()
        self.testCase.sleep(seconds: 1)
        
        self.textField(.filterText).typeText(text + "\n")
        self.waitForKeyboardToDismiss()
        self.waitForHittable(self.button(.addFilterConfirmButton))
        
        if let screenshotName = screenshotName {
            testCase.snapshotSettled(screenshotName)
        }
        
        self.tap(.addFilterConfirmButton)
        self.testCase.waitForUIToSettle()
    }

    var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    func setSmartFilter(_ smartFilter: SmartFilterType, isOn: Bool) {
        let toggle = self.switches[smartFilter.testIdentifier.rawValue].firstMatch
        self.setSwitch(toggle, isOn: isOn, timeout: 8)
    }

    func setFilterListLanguage(_ language: NLLanguage, isOn: Bool) {
        self.button(.filterListsLink).tap()
        let toggle = self.switches[language~].firstMatch
        self.setSwitch(toggle, isOn: isOn, timeout: 20)
        self.buttons["BackButton"].firstMatch.conditionalTap(!self.isPad)
    }

    private func setSwitch(_ toggle: XCUIElement, isOn: Bool, timeout: TimeInterval) {
        XCTAssertTrue(toggle.waitForExistence(timeout: timeout), "Missing toggle \(toggle)")
        toggle.switches.firstMatch.tap()
        let expectedValue = isOn ? "1" : "0"
        let switched = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expectedValue), object: toggle)
        let result = XCTWaiter.wait(for: [switched], timeout: 5)
        XCTAssertEqual(result, .completed, "\(toggle) did not switch to \(expectedValue)")
    }

    func addFilter(_ type: FilterType,
                   _ text: String,
                   folder: MessageFolder? = nil,
                   target: FilterTarget = .all,
                   matching: FilterMatching = .contains,
                   filterCase: FilterCase = .caseInsensitive) {
        self.button(type.testIdentifier).tap()
        self.button(.addFilterButton).tap()

        let targetOption = self.segmentedControls.buttons[target.name].firstMatch
        if !targetOption.waitForExistence(timeout: 3) {
            self.button(.expandButton).tap()
        }
        if let folder {
            self.selectOption(folder.name)
        }
        self.selectOption(target.name)
        self.selectOption(matching.name)
        if matching != .regex {
            self.selectOption(filterCase.name)
        }

        let filterText = self.textField(.filterText)
        filterText.tap()
        filterText.typeText(text + "\n")
        self.waitForKeyboardToDismiss()
        self.button(.addFilterConfirmButton).tap()
        XCTAssertTrue(self.button(.addFilterConfirmButton).waitForNonExistence(timeout: 5), "Add filter sheet did not close")

        XCTAssertTrue(self.filterRow(text).waitForExistence(timeout: 5), "\(text) is not in the \(type.name) list")
        self.buttons["BackButton"].firstMatch.conditionalTap(!self.isPad)
    }

    func deleteFilter(_ text: String, from type: FilterType) {
        self.button(type.testIdentifier).tap()
        let row = self.collectionViews.cells.containing(.textField, identifier: text).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(text) is not in the \(type.name) list")
        row.swipeLeft()
        self.collectionViews.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(self.filterRow(text).waitForNonExistence(timeout: 5), "\(text) is still in the \(type.name) list")
        self.buttons["BackButton"].firstMatch.conditionalTap(!self.isPad)
    }

    func setCommunityList(_ name: String, isOn: Bool) {
        self.button(.communityListsLink).tap()
        let toggle = self.switches[name].firstMatch
        self.setSwitch(toggle, isOn: isOn, timeout: 20)
        self.buttons["BackButton"].firstMatch.conditionalTap(!self.isPad)
    }

    func subscribeToCommunityList(at url: String, named name: String) {
        self.button(.communityListsLink).tap()
        self.button(.addCommunityListButton).tap()
        self.typeCommunityListURL(url)

        let subscribe = self.button(.subscribeCommunityListButton)
        XCTAssertTrue(subscribe.waitForExistence(timeout: 8), "Subscribe from URL did not open")
        XCTAssertTrue(subscribe.wait(for: \.isEnabled, toEqual: true, timeout: 15), "\(url) did not load")
        subscribe.tap()
        XCTAssertTrue(subscribe.waitForNonExistence(timeout: 10), "Subscribe from URL did not close")

        let toggle = self.switches[name].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "\(name) is not in Community Lists")
        XCTAssertEqual(toggle.value as? String, "1", "\(name) is not on after subscribing")
        self.buttons["BackButton"].firstMatch.conditionalTap(!self.isPad)
    }

    func removeCommunityList(_ name: String) {
        self.button(.communityListsLink).tap()
        let row = self.collectionViews.cells.containing(.switch, identifier: name).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(name) is not in Community Lists")
        row.swipeLeft()
        self.collectionViews.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(self.switches[name].waitForNonExistence(timeout: 5), "\(name) is still in Community Lists")
        self.buttons["BackButton"].firstMatch.conditionalTap(!self.isPad)
    }

    func typeCommunityListURL(_ url: String) {
        let urlField = self.textField(.communityListURLField)
        urlField.tap()
        urlField.typeText(url)
    }

    func clearCommunityListURL(_ url: String) {
        let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: url.count)
        self.textField(.communityListURLField).typeText(deletes)
    }

    func exportFilters(toFileNamed fileName: String) {
        self.button(.appMenuButton).tap()
        self.button(.filterToolsMenuButton).tap()
        self.buttons["menu_exportFilters"~].firstMatch.tap()
        self.button(.transferConfirmButton).tap()
        self.cells["Save to Files"].firstMatch.tap()

        let fileNameField = self.textFields["DOCPicker.filenameTextField"].firstMatch
        XCTAssertTrue(fileNameField.waitForExistence(timeout: 8), "Save to Files did not open")
        fileNameField.tap()
        let currentName = fileNameField.value as? String ?? ""
        fileNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentName.count) + fileName)

        let save = self.buttons["DOCPicker.actionButton"].firstMatch
        self.waitForHittable(save)
        save.tap()
        XCTAssertTrue(save.waitForNonExistence(timeout: 8), "Save to Files did not close")
        XCTAssertTrue(self.button(.transferConfirmButton).waitForNonExistence(timeout: 8), "Export Filters did not close")
    }

    func importFilters(fromFileNamed fileName: String) {
        self.button(.appMenuButton).tap()
        self.button(.filterToolsMenuButton).tap()
        self.buttons["menu_importFilters"~].firstMatch.tap()

        let file = self.cells.matching(NSPredicate(format: "identifier BEGINSWITH %@", fileName)).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 10), "\(fileName) is not in the file picker")
        file.tap()

        let confirm = self.button(.transferConfirmButton)
        XCTAssertTrue(confirm.waitForExistence(timeout: 10), "Import Filters did not open")
        XCTAssertTrue(confirm.wait(for: \.isEnabled, toEqual: true, timeout: 8), "Import Filters did not open with filters selected")
        confirm.tap()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 8), "Import Filters did not close")
    }

    func filterRow(_ text: String) -> XCUIElement {
        return self.collectionViews.textFields[text].firstMatch
    }

    private func selectOption(_ name: String) {
        let option = self.segmentedControls.buttons[name].firstMatch
        option.tap()
        XCTAssertTrue(option.wait(for: \.isSelected, toEqual: true, timeout: 5), "\(name) was not selected")
    }

    func assertVerdict(_ verdict: TestIdentifier, sender: String, body: String, file: StaticString = #filePath, line: UInt = #line) {
        self.button(.appMenuButton).tap()
        self.button(.filterToolsMenuButton).tap()
        self.buttons["testFilters_title"~].firstMatch.tap()

        let bodyInput = self.textField(.testBodyInput)
        bodyInput.tap()
        bodyInput.typeText(body)
        let senderInput = self.textField(.testSenderInput)
        senderInput.tap()
        senderInput.typeText(sender + "\n")

        let result = self.descendants(matching: .any)[verdict.rawValue]
        XCTAssertTrue(result.waitForExistence(timeout: 5), "\(sender): \"\(body)\" is not \(verdict.rawValue)", file: file, line: line)
        self.waitForKeyboardToDismiss()
        self.button(.closeButton).tap()
        XCTAssertTrue(bodyInput.waitForNonExistence(timeout: 5), "Filter Tester did not close")
    }

    func waitForHittable(_ element: XCUIElement, timeout: TimeInterval = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing \(element)")
        let expectation = testCase.expectation(for: NSPredicate(format: "isHittable == 1"), evaluatedWith: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Timed out waiting until hittable: \(element)")
    }

    func waitForKeyboardToDismiss(timeout: TimeInterval = 6) {
        let keyboard = self.keyboards.firstMatch
        guard keyboard.exists else { return }
        if self.buttons["Done"].exists {
            self.buttons["Done"].tap()
        } else {
            self.navigationBars.firstMatch.tap()
        }
        let dismissed = testCase.expectation(for: NSPredicate(format: "exists == 0"), evaluatedWith: keyboard)
        _ = XCTWaiter.wait(for: [dismissed], timeout: timeout)
    }
    
    func buttonExists(_ testIdentifier: TestIdentifier) -> Bool {
        return self.buttons.element(matching: .button, identifier: testIdentifier.rawValue).exists
    }
    
    func button(_ testIdentifier: TestIdentifier) -> XCUIElement {
        return self.buttons.element(matching: .button, identifier: testIdentifier.rawValue).firstMatch
    }
    
    func textField(_ testIdentifier: TestIdentifier) -> XCUIElement {
        switch testIdentifier {
        case .testSenderInput:
            return self.textFields[testIdentifier.rawValue].firstMatch
        case .testBodyInput:
            return self.textViews[testIdentifier.rawValue].firstMatch
        default:
            return self.textFields.element(matching: .textField, identifier: testIdentifier.rawValue).firstMatch
        }
    }

    func buttonContaining(_ label: String) -> XCUIElement {
        return self.buttons.element(matching: NSPredicate(format: "label CONTAINS %@", argumentArray: [label])).firstMatch
    }
    
    func switchContaining(_ label: String) -> XCUIElement {
        return self.switches.element(matching: NSPredicate(format: "label CONTAINS %@", argumentArray: [label]))
    }
    
    func tap(_ testIdentifier: TestIdentifier) {
        let button = self.button(testIdentifier)
        if button.exists {
            button.forceTap()
        }
    }
    
    func conditionalTap(_ testIdentifier: TestIdentifier,  _ condition: Bool) {
        guard condition else { return }
        let button = self.button(testIdentifier)
        if button.exists {
            button.forceTap()
        }
    }
    
    func assertLabel(of testIdentifier: TestIdentifier, contains string: String) {
        let button = self.button(testIdentifier)
        XCTAssert(button.exists, "Cannot find button for \(testIdentifier.rawValue)")
        XCTAssert(button.label.contains(string), "\(testIdentifier.rawValue) expected: \(string), found: \(button.label).")
    }
}
