//
//  FilterTransferScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

struct FilterTransferScreen: Screen {
    let app: XCUIApplication

    private let exportTitle = "Export Filters"
    private let importTitle = "Import Filters"
    private let saveToFiles = "Save to Files"

    private var confirmButton: XCUIElement {
        return self.app.buttons[.transferConfirmButton]
    }

    func exportToFiles(named fileName: String) {
        self.step("Export all filters to \(fileName)") {
            self.openFilterTool(self.exportTitle)
            self.confirmButton.tap()
            let saveToFiles = self.app.cells[self.saveToFiles].firstMatch
            let fileNameField = self.app.textFields["DOCPicker.filenameTextField"].firstMatch
            saveToFiles.tap()
            if !fileNameField.waitForExistence(timeout: 4) && saveToFiles.exists {
                saveToFiles.tap()
            }
            XCTAssertTrue(fileNameField.waitForExistence(timeout: 8), "Save to Files did not open")
            fileNameField.tap()
            let suggestedName = fileNameField.value as? String ?? ""
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: suggestedName.count)
            fileNameField.typeText(deletes + fileName)

            let save = self.app.buttons["DOCPicker.actionButton"].firstMatch
            XCTAssertTrue(save.waitUntil(\.isHittable), "Save is not tappable")
            save.tap()
            XCTAssertTrue(save.waitForNonExistence(timeout: 8), "Save to Files did not close")
            XCTAssertTrue(self.confirmButton.waitForNonExistence(timeout: 8), "Export Filters did not close")
        }
    }

    func importFromFiles(named fileName: String) {
        self.step("Import all filters from \(fileName)") {
            self.openFilterTool(self.importTitle)
            let file = self.app.cells.matching(NSPredicate(format: "identifier BEGINSWITH %@", fileName)).firstMatch
            XCTAssertTrue(file.waitForExistence(timeout: 10), "\(fileName) is not in the file picker")
            file.tap()

            XCTAssertTrue(self.confirmButton.waitUntil(\.isEnabled, timeout: 10), "Import Filters did not open with filters selected")
            self.confirmButton.tap()
            XCTAssertTrue(self.confirmButton.waitForNonExistence(timeout: 8), "Import Filters did not close")
        }
    }
}
