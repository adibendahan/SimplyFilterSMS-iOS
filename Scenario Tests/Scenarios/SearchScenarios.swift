//
//  SearchScenarios.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import XCTest

final class SearchScenarios: ScenarioTestCase {

    func testAllowFilterResultOpensItsList() {
        let app = self.launchApp(startingData: .debug)

        app.search.drillDown(searching: "Apple", to: "Apple", kind: .allowFilter, landsOn: .filter("Apple"))
    }

    func testBlockFilterResultOpensItsList() {
        let app = self.launchApp(startingData: .debug)

        app.search.drillDown(searching: "Bitcoin", to: "Bitcoin", kind: .denyFilter, landsOn: .filter("Bitcoin"))
    }

    func testBlockedLanguageResultOpensBlockedLanguages() {
        let app = self.launchApp(startingData: .debug)

        app.search.drillDown(searching: "Arabic", to: "Arabic", kind: .languageFilter, landsOn: .screenTitled("Blocked Languages"))
    }

    func testCommunityListResultOpensTheListExpanded() {
        let app = self.launchApp(remoteLists: .testCatalog)

        app.search.drillDown(searching: "UI Test",
                             to: TestLists.curatedPromotions,
                             kind: .communityList,
                             landsOn: .expandedCommunityList)
    }

    func testAIFilteringLanguageResultOpensAIFiltering() {
        let app = self.launchApp()

        app.search.drillDown(searching: "Hebrew", to: "Hebrew", kind: .aiLanguage, landsOn: .aiFiltering(.hebrew))
    }

    func testHelpResultOpensTheAnswer() {
        let app = self.launchApp()

        app.search.drillDown(searching: "Community Lists",
                             to: "What are Community Lists?",
                             kind: .help,
                             landsOn: .faqAnswer("communityLists"))
    }

    func testMenuResultOpensItsScreen() {
        let app = self.launchApp()

        app.search.drillDown(searching: "Test Your", to: "Test Your Filters", kind: .action, landsOn: .filterTester)
    }

    func testSmartFilterResultReturnsToHome() {
        let app = self.launchApp()

        app.search.drillDown(searching: "Links", to: "Block Links", kind: .smartFilter, landsOn: .home(.links))
    }

    func testReopeningSearchRestoresTheLastSearch() {
        let app = self.launchApp(startingData: .debug)

        app.search.drillDown(searching: "Apple", to: "Apple", kind: .allowFilter, landsOn: .filter("Apple"))
        app.search.reopen(expecting: "Apple")
    }
}
