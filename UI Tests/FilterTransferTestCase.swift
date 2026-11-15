//
//  FilterTransferTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
class FilterTransferTestCase: ApplicationTestCase {

    func testExportedFiltersComeBackWithTheirOptionsAfterImport() {
        let app = TestApplication(testCase: self)
        let fileName = "ui-test-\(UUID().uuidString.prefix(8))"
        let sender = "Store"
        let message = "Big SALE today only"
        app.dismissCallToActionViewIfPresented()

        app.addFilter(.deny, "SALE", folder: .promotion, filterCase: .caseSensitive)
        app.addFilter(.allow, "Pharmacy", target: .sender)
        app.exportFilters(toFileNamed: fileName)

        app.deleteFilter("SALE", from: .deny)
        app.deleteFilter("Pharmacy", from: .allow)
        app.assertVerdict(.testResultAllowed, sender: sender, body: message)

        app.importFilters(fromFileNamed: fileName)

        app.assertVerdict(.testResultPromotion, sender: sender, body: message)
        app.assertVerdict(.testResultAllowed, sender: sender, body: message.lowercased())
        app.assertVerdict(.testResultAllowed, sender: "Pharmacy", body: message)
    }

}
