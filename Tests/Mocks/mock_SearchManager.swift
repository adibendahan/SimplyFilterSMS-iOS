//
//  mock_SearchManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS


class mock_SearchManager: SearchManagerProtocol {

    var recentQueries: [String] = []
    var lastQuery: String?
    var suggestions: [SearchResult] = []

    var sectionsCounter = 0
    var recordSearchCounter = 0
    var clearRecentQueriesCounter = 0
    var resetSessionCounter = 0
    var setPendingFocusCounter = 0
    var takeFocusCounter = 0
    var pendingFocus: SearchFocus?
    var indexSpotlightItemsCounter = 0
    var spotlightResultCounter = 0

    var sectionsClosure: ((String) -> ([SearchResultSection]))?
    var setPendingFocusClosure: ((SearchFocus) -> ())?
    var spotlightResultClosure: ((String) -> (SearchResult?))?

    func sections(matching query: String) -> [SearchResultSection] {
        self.sectionsCounter += 1
        return self.sectionsClosure?(query) ?? []
    }

    func recordSearch(_ query: String) {
        self.recordSearchCounter += 1
    }

    func clearRecentQueries() {
        self.clearRecentQueriesCounter += 1
    }

    func resetSession() {
        self.resetSessionCounter += 1
    }

    func setPendingFocus(_ focus: SearchFocus) {
        self.setPendingFocusCounter += 1
        self.setPendingFocusClosure?(focus)
    }

    func takeFocus<Value>(_ value: KeyPath<SearchFocus, Value?>) -> Value? {
        self.takeFocusCounter += 1
        return self.pendingFocus?[keyPath: value]
    }

    func indexSpotlightItems() {
        self.indexSpotlightItemsCounter += 1
    }

    func spotlightResult(for identifier: String) -> SearchResult? {
        self.spotlightResultCounter += 1
        return self.spotlightResultClosure?(identifier)
    }

    func resetCounters() {
        self.sectionsCounter = 0
        self.recordSearchCounter = 0
        self.clearRecentQueriesCounter = 0
        self.resetSessionCounter = 0
        self.setPendingFocusCounter = 0
        self.takeFocusCounter = 0
        self.indexSpotlightItemsCounter = 0
        self.spotlightResultCounter = 0
    }
}
