//
//  AppStoreShots.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

final class AppStoreShots: ScreenshotTestCase {

    func testHome() throws {
        try XCTSkipIf(self.isPad, "iPad shows Home next to every other shot")
        self.launchStudio()
        self.capture(.home)
    }

    func testAIFiltering() {
        let studio = self.launchStudio()
        studio.aiFiltering.show(activeLanguage: .current)
        self.capture(.aiFiltering)
    }

    func testBlockedTexts() {
        let studio = self.launchStudio()
        studio.blockedTexts.show()
        self.capture(.blockedTexts)
    }

    func testAllowedTexts() {
        let studio = self.launchStudio()
        studio.allowedTexts.show()
        self.capture(.allowedTexts)
    }

    func testAddFilter() {
        let studio = self.launchStudio()
        studio.blockedTexts.showAddFilter(StudioLanguage.current.blockedText, folder: .junk, target: .body, matching: .exact, letterCase: .insensitive)
        self.capture(.addFilter)
    }

    func testBlockedLanguages() {
        let studio = self.launchStudio()
        studio.blockedLanguages.show()
        self.capture(.blockedLanguages)
    }

    func testFilterTester() {
        let studio = self.launchStudio()
        studio.filterTester.show(Message(from: "Apple", "Your Apple ID Code is: 444291. Don't share it with anyone."))
        self.capture(.testYourFilters)
    }

    func testCountries() {
        let studio = self.launchStudio()
        studio.countries.show()
        self.capture(.countries)
    }

    func testCommunityLists() {
        let studio = self.launchStudio()
        studio.communityLists.show(subscribingTo: StudioLanguage.current.subscribedListURLs)
        self.capture(.communityLists)
    }
}
