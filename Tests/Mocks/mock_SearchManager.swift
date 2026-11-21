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
    var takeFocusedFilterCounter = 0
    var takeFocusedCommunityListCounter = 0
    var takeFocusedFAQCounter = 0

    var sectionsClosure: ((String) -> ([SearchResultSection]))?
    var setPendingFocusClosure: ((SearchFocus) -> ())?
    var takeFocusedFilterClosure: (() -> (UUID?))?
    var takeFocusedCommunityListClosure: (() -> (String?))?
    var takeFocusedFAQClosure: (() -> (HelpFAQ?))?

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

    func takeFocusedFilter() -> UUID? {
        self.takeFocusedFilterCounter += 1
        return self.takeFocusedFilterClosure?()
    }

    func takeFocusedCommunityList() -> String? {
        self.takeFocusedCommunityListCounter += 1
        return self.takeFocusedCommunityListClosure?()
    }

    func takeFocusedFAQ() -> HelpFAQ? {
        self.takeFocusedFAQCounter += 1
        return self.takeFocusedFAQClosure?()
    }

    func resetCounters() {
        self.sectionsCounter = 0
        self.recordSearchCounter = 0
        self.clearRecentQueriesCounter = 0
        self.resetSessionCounter = 0
        self.setPendingFocusCounter = 0
        self.takeFocusedFilterCounter = 0
        self.takeFocusedCommunityListCounter = 0
        self.takeFocusedFAQCounter = 0
    }
}
