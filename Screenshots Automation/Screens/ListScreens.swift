//
//  ListScreens.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

struct AIFilteringScreen: Screen {
    let app: XCUIApplication

    func show(activeLanguage language: StudioLanguage) {
        self.open(.filterListsLink)
        let toggle = self.app.switches["\(TestIdentifier.filterListLanguageToggle.rawValue)-\(language.aiFilteringLanguage)"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: self.downloadTimeout), "AI Filtering did not list \(language.aiFilteringLanguage)")
        XCTAssertTrue(toggle.waitForValue("1", timeout: self.downloadTimeout), "AI Filtering is off for \(language.aiFilteringLanguage)")
    }

    //MARK: - Private -
    private let downloadTimeout: TimeInterval = 30
}

struct CommunityListsScreen: Screen {
    let app: XCUIApplication

    func show(subscribingTo urls: [String]) {
        self.open(.communityListsLink)
        let downloaded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.listNames.count == 1 }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [downloaded], timeout: self.downloadTimeout), .completed, "The curated list did not download")
        let curated = self.listNames
        for url in urls {
            self.subscribe(to: url)
        }
        for name in self.listNames {
            let toggle = self.app.switches.matching(identifier: TestIdentifier.communityListToggle.rawValue).matching(NSPredicate(format: "label == %@", name)).firstMatch
            self.setSwitch(toggle, isOn: curated.contains(name))
        }
        self.app.buttons[.communityListExpandButton].tap()
    }

    //MARK: - Private -
    private let downloadTimeout: TimeInterval = 30

    private var listNames: Set<String> {
        return Set(self.app.switches.matching(identifier: TestIdentifier.communityListToggle.rawValue).allElementsBoundByIndex.map(\.label))
    }

    private func subscribe(to url: String) {
        self.app.buttons[.addCommunityListButton].tap()
        self.type(url, into: self.app.textFields[.communityListURLField])
        let subscribe = self.app.buttons[.subscribeCommunityListButton]
        XCTAssertTrue(subscribe.waitUntil(\.isEnabled, timeout: self.downloadTimeout), "\(url) was not accepted")
        subscribe.tap()
        XCTAssertTrue(subscribe.waitForNonExistence(timeout: 10), "Subscribe from URL did not close")
    }
}
