//
//  FilterTransferScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

final class FilterTransferScenarios: ScenarioTestCase {

    func testExportedFiltersComeBackWithTheirOptionsAfterImport() {
        let app = self.launchApp()
        let fileName = "ui-test-\(UUID().uuidString.prefix(8))"
        let sale = Message(from: "Store", "Big SALE today only")
        let lowercaseSale = Message(from: "Store", "big sale today only")
        let fromPharmacy = Message(from: "Pharmacy", "Big SALE today only")

        app.denyList.add("SALE", folder: .promotions, letterCase: .sensitive)
        app.allowList.add("Pharmacy", target: .sender)
        app.filterTransfer.exportToFiles(named: fileName)

        app.denyList.delete("SALE")
        app.allowList.delete("Pharmacy")
        app.expect(sale, toBe: .allowed)

        app.filterTransfer.importFromFiles(named: fileName)

        app.testYourFilters { tester in
            tester.expect(sale, toBe: .promotion)
            tester.expect(lowercaseSale, toBe: .allowed)
            tester.expect(fromPharmacy, toBe: .allowed)
        }
    }
}
