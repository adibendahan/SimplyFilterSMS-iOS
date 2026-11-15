//
//  FiltersTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
class FiltersTestCase: ApplicationTestCase {

    func testAllowedSenderPassesWhenAllUnknownSendersAreBlocked() {
        let app = TestApplication(testCase: self)
        let sender = "Pharmacy"
        let message = "Your prescription is ready"
        app.dismissCallToActionViewIfPresented()

        app.setSmartFilter(.allUnknown, isOn: true)
        app.assertVerdict(.testResultJunk, sender: sender, body: message)

        app.addFilter(.allow, sender, target: .sender)

        app.assertVerdict(.testResultAllowed, sender: sender, body: message)
        app.assertVerdict(.testResultJunk, sender: "Clinic", body: "\(sender) hours have changed")
    }

    func testDenyFilterSendsMatchingMessagesToItsFolderUntilDeleted() {
        let app = TestApplication(testCase: self)
        let sender = "Store"
        let message = "Big SALE today only"
        app.dismissCallToActionViewIfPresented()

        app.addFilter(.deny, "SALE", folder: .promotion, filterCase: .caseSensitive)

        app.assertVerdict(.testResultPromotion, sender: sender, body: message)
        app.assertVerdict(.testResultAllowed, sender: sender, body: message.lowercased())

        app.deleteFilter("SALE", from: .deny)

        app.assertVerdict(.testResultAllowed, sender: sender, body: message)
    }

}
