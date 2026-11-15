//
//  SmartFilterScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

final class SmartFilterScenarios: ScenarioTestCase {

    func testSmartFiltersJunkOnlyWhatTheyTarget() {
        let app = self.launchApp()
        let parcelLink = Message(from: "+15551234567", "Track your parcel at https://example.com/track")
        let namedSender = Message(from: "Bank", "Your code is 1234")
        let birthday = Message(from: "+15551234567", "Happy birthday 🎉")
        let plainText = Message(from: "+15551234567", "See you at 5")

        app.home.turnOn(.links)
        app.home.turnOn(.numbersOnly)
        app.home.turnOn(.emojis)

        app.expect(parcelLink, toBe: .junk)
        app.expect(namedSender, toBe: .junk)
        app.expect(birthday, toBe: .junk)
        app.expect(plainText, toBe: .allowed)

        app.home.turnOff(.links)

        app.expect(parcelLink, toBe: .allowed)
    }
}
