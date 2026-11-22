//
//  SearchScreen.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import XCTest

struct SearchScreen: Screen {
    enum ResultKind: String {
        case aiLanguage
        case smartFilter
        case communityList
        case allowFilter
        case denyFilter
        case languageFilter
        case help
        case action
    }

    enum Destination {
        case filter(String)
        case screenTitled(String)
        case expandedCommunityList
        case faqAnswer(String)
        case aiFiltering(Language)
        case filterTester
        case home(SmartFilter)
    }

    let app: XCUIApplication

    private let landingTimeout: TimeInterval = 8

    func drillDown(searching query: String, to title: String, kind: ResultKind, landsOn destination: Destination) {
        self.step("Search \"\(query)\" and open the \(kind.rawValue) result \"\(title)\"") {
            self.search(query)
            let result = self.app.buttons["\(TestIdentifier.searchResult.rawValue)-\(kind.rawValue)-\(title)"].firstMatch
            XCTAssertTrue(result.waitForExistence(timeout: 5), "No \(kind.rawValue) result \"\(title)\" for \"\(query)\"")
            result.tap()

            XCTAssertTrue(self.element(of: destination).waitForExistence(timeout: self.landingTimeout),
                          "Opening \"\(title)\" did not land on \(destination)")
            self.leave(destination)
            self.expectSearchClosed()
        }
    }

    func reopen(expecting query: String) {
        self.step("Reopen search and find \"\(query)\" restored") {
            let field = self.searchField
            field.tap()
            XCTAssertTrue(field.waitForValue(query), "Search reopened with \"\(field.value as? String ?? "")\" instead of \"\(query)\"")
            XCTAssertTrue(self.anyResult.waitForExistence(timeout: 5), "The restored search shows no results")
        }
    }


    //MARK: - Private -
    private var searchField: XCUIElement {
        return self.app.searchFields.firstMatch
    }

    private var anyResult: XCUIElement {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", TestIdentifier.searchResult.rawValue)
        return self.app.buttons.matching(predicate).firstMatch
    }

    private func search(_ query: String) {
        XCTAssertTrue(self.searchField.waitForExistence(timeout: 5), "Home has no search field")
        self.type(query, into: self.searchField)
    }

    private func element(of destination: Destination) -> XCUIElement {
        let element: XCUIElement
        switch destination {
        case .filter(let text):
            element = self.app.collectionViews.textFields[text].firstMatch
        case .screenTitled(let title):
            element = self.app.navigationBars[title].firstMatch
        case .expandedCommunityList:
            element = self.app.descendants(matching: .any)[.communityListDetails]
        case .faqAnswer(let faq):
            element = self.app.descendants(matching: .any)["\(TestIdentifier.faqAnswer.rawValue)-\(faq)"].firstMatch
        case .aiFiltering(let language):
            element = self.app.switches[language.element].firstMatch
        case .filterTester:
            element = self.app.textFields[.testSenderInput]
        case .home(let smartFilter):
            element = self.app.switches[smartFilter.element]
        }
        return element
    }

    private func leave(_ destination: Destination) {
        switch destination {
        case .filter, .screenTitled, .expandedCommunityList, .aiFiltering:
            self.backToHome()
        case .faqAnswer, .filterTester:
            self.app.buttons[.closeButton].tap()
        case .home:
            break
        }
    }

    private func expectSearchClosed() {
        XCTAssertTrue(self.anyResult.waitForNonExistence(timeout: 5), "Search results are still showing after the drill-down")
    }
}
