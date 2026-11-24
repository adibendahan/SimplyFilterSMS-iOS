//
//  FilterTransferScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

final class FilterTransferScenarios: ScenarioTestCase {

    func testExportedFiltersComeBackWithTheirOptionsAfterImport() {
        let fileName = "ui-test-\(UUID().uuidString.prefix(8))"
        let bitcoinOffer = Message(from: "Store", "Buy Bitcoin today")
        let fromApple = Message(from: "Apple", "Buy Bitcoin today")
        let fromLowercaseApple = Message(from: "apple", "Buy Bitcoin today")

        let appWithFilters = self.launchApp(startingData: .debug)
        appWithFilters.filterTransfer.exportToFiles(named: fileName)

        let app = self.launchApp()
        app.expect(bitcoinOffer, toBe: .allowed)

        app.filterTransfer.importFromFiles(named: fileName)

        app.testYourFilters { tester in
            tester.expect(bitcoinOffer, toBe: .transaction)
            tester.expect(fromApple, toBe: .allowed)
            tester.expect(fromLowercaseApple, toBe: .transaction)
        }
    }
}
