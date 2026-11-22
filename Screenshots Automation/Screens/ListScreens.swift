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
        let showsRuleCount = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label MATCHES %@", ".*\\d.*"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [showsRuleCount], timeout: self.downloadTimeout), .completed, "AI Filtering did not download \(language.aiFilteringLanguage)")
    }

    //MARK: - Private -
    private let downloadTimeout: TimeInterval = 30
}

struct CommunityListsScreen: Screen {
    let app: XCUIApplication

    func show(subscribingTo urls: [String]) {
        self.reveal(self.app.buttons[.communityListsLink])
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
        let expand = self.app.buttons[.communityListExpandButton]
        self.swipe(self.list, .down, until: expand)
        expand.tap()
        self.scrollToTop()
        self.revealTopOfHome()
    }

    //MARK: - Private -
    private let downloadTimeout: TimeInterval = 30

    private func scrollToTop() {
        self.list.swipeDown(velocity: .fast)
        self.list.swipeDown(velocity: .fast)
    }

    private var list: XCUIElement {
        let isListToggle = NSPredicate(format: "identifier == %@", TestIdentifier.communityListToggle.rawValue)
        return self.app.collectionViews.containing(isListToggle).firstMatch
    }

    private var listNames: Set<String> {
        return Set(self.app.switches.matching(identifier: TestIdentifier.communityListToggle.rawValue).allElementsBoundByIndex.map(\.label))
    }

    private func subscribe(to url: String) {
        let add = self.app.buttons[.addCommunityListButton]
        self.swipe(self.list, .up, until: add)
        add.tap()
        self.type(url + "\n", into: self.app.textFields[.communityListURLField])
        let subscribe = self.app.buttons[.subscribeCommunityListButton]
        XCTAssertTrue(subscribe.waitUntil(\.isEnabled, timeout: self.downloadTimeout), "\(url) was not accepted")
        subscribe.tap()
        XCTAssertTrue(subscribe.waitForNonExistence(timeout: 10), "Subscribe from URL did not close")
    }
}
