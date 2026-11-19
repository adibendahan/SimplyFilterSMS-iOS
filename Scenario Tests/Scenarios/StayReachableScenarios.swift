//
//  StayReachableScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 19/11/2026.
//

import XCTest

final class StayReachableScenarios: ScenarioTestCase {

    func testStayReachableAllowsNameAndStreetInEveryLanguageAndSkipsWhatsAlreadyAllowed() {
        let app = self.launchApp(phoneLanguages: [.english, .hebrew])
        let hebrewName = Message(from: "+15551234567", "דנה, החבילה שלך הגיעה")
        let surname = Message(from: "Courier", "Delivery for Levi")
        let street = Message(from: "+15551234567", "Package left on Herzl Street")
        let longerWord = Message(from: "+15551234567", "Danaher sale ends tonight")
        let noName = Message(from: "+15551234567", "Your parcel is at the door")

        app.allowList.add("Dana", matching: .exact)

        let sheet = app.stayReachable.openFromToast()
        sheet.expect(.hebrew, header: "עברית", firstNameLabel: "שם פרטי")
        sheet.fill(.english, firstName: "dana", surname: "Levi", street: "Herzl")
        sheet.expectSkipped("dana", because: "is already allowed")
        sheet.fill(.hebrew, firstName: "דנה", surname: "לוי", street: "herzl")
        sheet.expectSkipped("herzl", because: "הוזן פעמיים")
        sheet.expectAddButton("Add 4 Allowed Texts")
        sheet.add()

        app.home.turnOn(.allUnknownSenders)
        app.testYourFilters { tester in
            tester.expect(hebrewName, toBe: .allowed)
            tester.expect(surname, toBe: .allowed)
            tester.expect(street, toBe: .allowed)
            tester.expect(longerWord, toBe: .junk)
            tester.expect(noName, toBe: .junk)
        }

        let reopenedSheet = app.stayReachable.openFromMenu()
        reopenedSheet.fill(.english, surname: "LEVI")
        reopenedSheet.expectSkipped("LEVI", because: "is already allowed")
        reopenedSheet.expectNothingToAdd()
        reopenedSheet.close()
    }
}
