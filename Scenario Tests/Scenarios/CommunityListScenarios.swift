//
//  CommunityListScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

final class CommunityListScenarios: ScenarioTestCase {

    func testCuratedAndSubscribedListsFilterUntilRemoved() {
        let app = self.launchApp(remoteLists: .testCatalog)
        let cryptoBonus = Message(from: "+15551234567", "Get your crypto bonus now")
        let parkingFine = Message(from: "+15551234567", "Pay your parking fine today")

        app.communityLists.turnOn(TestLists.curatedPromotions)
        app.expect(cryptoBonus, toBe: .promotion)

        app.expect(parkingFine, toBe: .allowed)
        app.communityLists.subscribe(to: TestLists.subscriptionURL, expecting: TestLists.subscriptionName)
        app.expect(parkingFine, toBe: .junk)

        app.communityLists.remove(TestLists.subscriptionName)
        app.expect(parkingFine, toBe: .allowed)
    }

    func testSubscribeRefusesAFileThatIsNotAFilterListUntilTheLinkIsFixed() {
        let app = self.launchApp(remoteLists: .testCatalog)

        let subscribeSheet = app.communityLists.openSubscribeFromURL()
        subscribeSheet.enterLink(TestLists.notAFilterListURL)
        subscribeSheet.expectRefused()

        subscribeSheet.replaceLink(with: TestLists.subscriptionURL)
        subscribeSheet.expectAccepted()
    }
}
