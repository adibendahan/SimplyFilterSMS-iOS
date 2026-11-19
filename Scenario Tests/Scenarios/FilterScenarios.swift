//
//  FilterScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

final class FilterScenarios: ScenarioTestCase {

    func testAllowedSenderPassesWhenAllUnknownSendersAreBlocked() {
        let app = self.launchApp()
        let prescription = Message(from: "Pharmacy", "Your prescription is ready")
        let mentionsPharmacy = Message(from: "Clinic", "Pharmacy hours have changed")

        app.home.turnOn(.allUnknownSenders)
        app.expect(prescription, toBe: .junk)

        app.allowList.add("Pharmacy", target: .sender)

        app.testYourFilters { tester in
            tester.expect(prescription, toBe: .allowed)
            tester.expect(mentionsPharmacy, toBe: .junk)
        }
    }

    func testDenyFilterSendsMatchingMessagesToItsFolderUntilDeleted() {
        let app = self.launchApp()
        let sale = Message(from: "Store", "Big SALE today only")
        let lowercaseSale = Message(from: "Store", "big sale today only")

        app.denyList.add("SALE", folder: .promotions, letterCase: .sensitive)

        app.testYourFilters { tester in
            tester.expect(sale, toBe: .promotion)
            tester.expect(lowercaseSale, toBe: .allowed)
        }

        app.denyList.delete("SALE")

        app.expect(sale, toBe: .allowed)
    }
}
