//
//  CommunityListsTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
class CommunityListsTestCase: ApplicationTestCase {

    private let testDataURL = "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/ui-tests/"

    func testCuratedAndSubscribedListsFilterUntilRemoved() {
        let app = TestApplication(testCase: self, launchArguments: ["-UITestData"])
        let phoneNumber = "+15551234567"
        let finesMessage = "Pay your parking fine today"
        app.dismissCallToActionViewIfPresented()

        app.setCommunityList("UI Test Promotions", isOn: true)
        app.assertVerdict(.testResultPromotion, sender: phoneNumber, body: "Get your crypto bonus now")

        app.assertVerdict(.testResultAllowed, sender: phoneNumber, body: finesMessage)
        app.subscribeToCommunityList(at: self.testDataURL + "subscribe.sfsfilters", named: "UI Test Subscription")
        app.assertVerdict(.testResultJunk, sender: phoneNumber, body: finesMessage)

        app.removeCommunityList("UI Test Subscription")
        app.assertVerdict(.testResultAllowed, sender: phoneNumber, body: finesMessage)
    }

    func testSubscribeRefusesAFileThatIsNotAFilterListUntilTheLinkIsFixed() {
        let app = TestApplication(testCase: self, launchArguments: ["-UITestData"])
        let invalidURL = self.testDataURL + "invalid.sfsfilters"
        let subscribe = app.button(.subscribeCommunityListButton)
        let error = app.descendants(matching: .any)[TestIdentifier.communityListError.rawValue]
        app.dismissCallToActionViewIfPresented()

        app.button(.communityListsLink).tap()
        app.button(.addCommunityListButton).tap()
        app.typeCommunityListURL(invalidURL)

        XCTAssertTrue(error.waitForExistence(timeout: 15), "No error for a file that isn't a filter list")
        XCTAssertFalse(subscribe.isEnabled, "Subscribe is enabled for an invalid file")

        app.clearCommunityListURL(invalidURL)
        app.typeCommunityListURL(self.testDataURL + "subscribe.sfsfilters")

        XCTAssertTrue(subscribe.wait(for: \.isEnabled, toEqual: true, timeout: 15), "Subscribe stayed disabled for a valid list")
        XCTAssertFalse(error.exists, "The error stayed after the link was fixed")
    }

}
