//
//  SmartFiltersTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
class SmartFiltersTestCase: ApplicationTestCase {

    func testSmartFiltersJunkOnlyWhatTheyTarget() {
        let app = TestApplication(testCase: self)
        let phoneNumber = "+15551234567"
        let linkMessage = "Track your parcel at https://example.com/track"
        app.dismissCallToActionViewIfPresented()

        app.setSmartFilter(.links, isOn: true)
        app.setSmartFilter(.numbersOnly, isOn: true)
        app.setSmartFilter(.emojis, isOn: true)

        app.assertVerdict(.testResultJunk, sender: phoneNumber, body: linkMessage)
        app.assertVerdict(.testResultJunk, sender: "Bank", body: "Your code is 1234")
        app.assertVerdict(.testResultJunk, sender: phoneNumber, body: "Happy birthday 🎉")
        app.assertVerdict(.testResultAllowed, sender: phoneNumber, body: "See you at 5")

        app.setSmartFilter(.links, isOn: false)

        app.assertVerdict(.testResultAllowed, sender: phoneNumber, body: linkMessage)
    }

}
