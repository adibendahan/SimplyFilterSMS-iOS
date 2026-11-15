//
//  AIFilteringTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
class AIFilteringTestCase: ApplicationTestCase {

    func testLanguageListAppliesItsRulesOnlyWhileTheLanguageIsOn() {
        let app = TestApplication(testCase: self, launchArguments: ["-UITestData"])
        let phoneNumber = "+15551234567"
        let prizeMessage = "Claim your winner prize now"
        app.dismissCallToActionViewIfPresented()

        app.assertVerdict(.testResultAllowed, sender: phoneNumber, body: prizeMessage)

        app.setFilterListLanguage(.english, isOn: true)

        app.assertVerdict(.testResultJunk, sender: phoneNumber, body: prizeMessage)
        app.assertVerdict(.testResultTransaction, sender: phoneNumber, body: "Your verification code 482913")
        app.assertVerdict(.testResultAllowed, sender: "TrustedBank", body: prizeMessage)

        app.setFilterListLanguage(.english, isOn: false)

        app.assertVerdict(.testResultAllowed, sender: phoneNumber, body: prizeMessage)
    }

}
