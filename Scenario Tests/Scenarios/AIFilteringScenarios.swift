//
//  AIFilteringScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

final class AIFilteringScenarios: ScenarioTestCase {

    func testLanguageListAppliesItsRulesOnlyWhileTheLanguageIsOn() {
        let app = self.launchApp(remoteLists: .testCatalog)
        let prize = Message(from: "+15551234567", "Claim your winner prize now")
        let verificationCode = Message(from: "+15551234567", "Your verification code 482913")
        let prizeFromTrustedSender = Message(from: "TrustedBank", "Claim your winner prize now")

        app.expect(prize, toBe: .allowed)

        app.aiFiltering.turnOn(.english)

        app.expect(prize, toBe: .junk)
        app.expect(verificationCode, toBe: .transaction)
        app.expect(prizeFromTrustedSender, toBe: .allowed)

        app.aiFiltering.turnOff(.english)

        app.expect(prize, toBe: .allowed)
    }
}
