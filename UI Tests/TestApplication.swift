//
//  TestApplication.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 18/06/2022.
//

import XCTest

class TestApplication: XCUIApplication {
    private var testCase: ApplicationTestCase
    
    init(testCase: ApplicationTestCase) {
        self.testCase = testCase
        super.init()
        
        self.launchArguments.append("-Testing")
        setupSnapshot(self)
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
                   denyFolderType: DenyFolderType? = nil,
                   filterTarget: FilterTarget,
                   filterMatching: FilterMatching,
                   filterCase: FilterCase,
                   screenshotName: String? = nil) {
        
        if self.button(type.testIdentifier).exists {
            self.tap(type.testIdentifier)
        }
        else if !self.staticTexts[type.name].exists {
            self.buttonContaining("filterList_filters"~).forceTap()
            self.tap(type.testIdentifier)
        }
        
        XCTAssert(self.staticTexts[type.name].exists)
        
        self.tap(.addFilterButton)
        
        if !self.buttonContaining(filterTarget.name).exists {
            self.tap(.expandButton)
        }
        
        if let denyFolderType = denyFolderType {
            self.buttonContaining(denyFolderType.name).forceTap()
        }

        self.buttonContaining(filterTarget.name).forceTap()
        self.buttonContaining(filterMatching.name).forceTap()
        self.buttonContaining(filterCase.name).forceTap()
        
        self.textField(.filterText).typeText(text + "\n")
        
        if let screenshotName = screenshotName {
            Snapshot.snapshot(screenshotName)
        }
        
        self.tap(.addFilteraddFilterButton)
        
        self.buttonContaining("filterList_filters"~).forceTap()
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
            return self.tables.textFields[testIdentifier.rawValue].firstMatch
        case .testBodyInput:
            return self.tables.textViews[testIdentifier.rawValue].firstMatch
        default:
            return self.textFields.element(matching: .textField, identifier: testIdentifier.rawValue).firstMatch
        }
    }

    func buttonContaining(_ label: String) -> XCUIElement {
        return self.buttons.element(matching: NSPredicate(format: "label CONTAINS %@", argumentArray: [label])).firstMatch
    }
    
    func switchContaining(_ label: String) -> XCUIElement {
        return self.switches.element(matching: NSPredicate(format: "label CONTAINS %@", argumentArray: [label])).firstMatch
    }
    
    func tap(_ testIdentifier: TestIdentifier) {
        let button = self.button(testIdentifier)
        if button.exists {
            button.forceTap()
        }
    }
    
    func assertLabel(of testIdentifier: TestIdentifier, contains string: String) {
        let button = self.button(.automaticFilterLink)
        XCTAssert(button.exists, "Cannot find button for \(testIdentifier.rawValue)")
        XCTAssert(button.label.contains(string), "\(testIdentifier.rawValue) expected: \(string), found: \(button.label).")
    }
}
