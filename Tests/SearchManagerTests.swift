//
//  SearchManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS

class SearchManagerTests: XCTestCase {

    private var persistenceManager = mock_PersistenceManager()
    private var smartFilterManager = mock_SmartFilterManager()
    private var filterListManager = mock_FilterListManager()
    private var defaultsManager = mock_DefaultsManager()
    private var testSubject: SearchManager!

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistenceManager = mock_PersistenceManager()
        self.smartFilterManager = mock_SmartFilterManager()
        self.filterListManager = mock_FilterListManager()
        self.defaultsManager = mock_DefaultsManager()
        self.testSubject = SearchManager(persistenceManager: self.persistenceManager,
                                         defaultsManager: self.defaultsManager,
                                         smartFilterManager: self.smartFilterManager,
                                         filterListManager: self.filterListManager)
    }


    //MARK: Tests
    func test_sections_emptyQuery_searchesNothing() {
        // Act
        let sections = self.testSubject.sections(matching: "   ")

        // Verify
        XCTAssertTrue(sections.isEmpty)
        XCTAssertEqual(self.persistenceManager.fetchFilterRecordsForTypeCounter, 0)
        XCTAssertEqual(self.smartFilterManager.smartFilterTypesGetCounter, 0)
    }

    func test_sections_followHomeOrder() {
        // Prepare
        let query = "zeta"
        let denyFilter = self.makeFilter(text: "zeta deal", type: .deny)
        let allowFilter = self.makeFilter(text: "ZetaBank", type: .allow)
        self.filterListManager.communityListsClosure = { [self.makeCommunityList(name: "Zeta Scams")] }
        self.persistenceManager.fetchFilterRecordsForTypeClosure = { filterType in
            switch filterType {
            case .deny:
                return [denyFilter]
            case .allow:
                return [allowFilter]
            case .denyLanguage:
                return []
            }
        }

        // Act
        let sections = self.testSubject.sections(matching: query)

        // Verify
        XCTAssertEqual(sections.map(\.kind), [.communityList, .allowFilter, .denyFilter])
    }

    func test_filters_matchIgnoringCaseAndAccents() {
        // Prepare
        let filter = self.makeFilter(text: "Café Promo", type: .deny)
        self.persistenceManager.fetchFilterRecordsForTypeClosure = { $0 == .deny ? [filter] : [] }

        // Act
        let sections = self.testSubject.sections(matching: "cafe promo")

        // Verify
        XCTAssertEqual(sections.map(\.kind), [.denyFilter])
        XCTAssertEqual(sections.first?.results.count, 1)
    }

    func test_languageFilter_matchesTheLanguageName() {
        // Prepare
        let filter = self.makeFilter(text: NLLanguage.russian.filterText, type: .denyLanguage)
        self.persistenceManager.fetchFilterRecordsForTypeClosure = { $0 == .denyLanguage ? [filter] : [] }
        let languageName = NLLanguage.russian.localizedName ?? ""

        // Act
        let sections = self.testSubject.sections(matching: languageName)

        // Verify
        XCTAssertTrue(sections.contains { $0.kind == .languageFilter })
    }

    func test_smartFilters_matchTheirTitle() {
        // Prepare
        self.smartFilterManager.smartFilterTypesClosure = { SmartFilterType.allCases }

        // Act
        let sections = self.testSubject.sections(matching: SmartFilterType.links.title)
        let smartSection = sections.first { $0.kind == .smartFilter }

        // Verify
        XCTAssertEqual(smartSection?.results.map(\.id), [SearchResult.smartFilter(.links).id])
    }

    func test_lists_matchTheirTitle() {
        // Act
        let sections = self.testSubject.sections(matching: SearchList.allow.title)
        let listSection = sections.first { $0.kind == .list }

        // Verify
        XCTAssertEqual(listSection?.results.map(\.id), [SearchResult.list(.allow).id])
    }

    func test_spotlightResult_mapsEveryIndexedScreen() {
        // Prepare
        let listIDs = SearchList.allCases.map { SearchResult.list($0).id }
        let actionIDs = [SearchResult.action(.testFilters).id, SearchResult.action(.reportMessage).id]

        // Act
        let resolvedIDs = (listIDs + actionIDs).map { self.testSubject.spotlightResult(for: $0)?.id }

        // Verify
        XCTAssertEqual(resolvedIDs, listIDs + actionIDs)
        XCTAssertNil(self.testSubject.spotlightResult(for: SearchResult.action(.tipJar).id))
    }

    func test_exportAction_onlyWithFilters() {
        // Prepare
        let query = SearchAction.exportFilters.title

        // Act
        let withoutFilters = self.testSubject.sections(matching: query)
        self.persistenceManager.fetchFilterRecordsClosure = { [self.makeFilter(text: "x", type: .deny)] }
        let withFilters = self.testSubject.sections(matching: query)

        // Verify
        let exportID = SearchResult.action(.exportFilters).id
        XCTAssertFalse(withoutFilters.flatMap(\.results).contains { $0.id == exportID })
        XCTAssertTrue(withFilters.flatMap(\.results).contains { $0.id == exportID })
    }

    func test_focus_isTakenOnceByItsOwnKind() {
        // Prepare
        self.testSubject.setPendingFocus(.communityList("list-1"))

        // Act
        let filterFocus = self.testSubject.takeFocus(\.filterID)
        let faqFocus = self.testSubject.takeFocus(\.faq)
        let languageFocus = self.testSubject.takeFocus(\.language)
        let listFocus = self.testSubject.takeFocus(\.communityListID)
        let secondListFocus = self.testSubject.takeFocus(\.communityListID)

        // Verify
        XCTAssertNil(filterFocus)
        XCTAssertNil(faqFocus)
        XCTAssertNil(languageFocus)
        XCTAssertEqual(listFocus, "list-1")
        XCTAssertNil(secondListFocus)
    }


    func test_recordSearch_keepsNewestFirstWithoutDuplicates() {
        // Act
        self.testSubject.recordSearch("promo")
        self.testSubject.recordSearch("bank")
        self.testSubject.recordSearch("Promo ")

        // Verify
        XCTAssertEqual(self.testSubject.recentQueries, ["Promo", "bank"])
        XCTAssertEqual(self.testSubject.lastQuery, "Promo")
    }

    func test_recordSearch_keepsOnlyTheNewest() {
        // Act
        for index in 0..<(kSearchHistoryMaxCount + 2) {
            self.testSubject.recordSearch("query \(index)")
        }

        // Verify
        XCTAssertEqual(self.testSubject.recentQueries.count, kSearchHistoryMaxCount)
        XCTAssertEqual(self.testSubject.recentQueries.first, "query \(kSearchHistoryMaxCount + 1)")
    }

    func test_resetSession_forgetsTheLastSearch() {
        // Prepare
        self.testSubject.recordSearch("promo")

        // Act
        self.testSubject.resetSession()

        // Verify
        XCTAssertNil(self.testSubject.lastQuery)
        XCTAssertEqual(self.testSubject.recentQueries.isEmpty, !kSearchHistoryKeepsAcrossLaunches)
    }

    func test_clearRecentQueries_forgetsEverything() {
        // Prepare
        self.testSubject.recordSearch("promo")

        // Act
        self.testSubject.clearRecentQueries()

        // Verify
        XCTAssertTrue(self.testSubject.recentQueries.isEmpty)
        XCTAssertNil(self.testSubject.lastQuery)
    }

    func test_forgetLastQuery_keepsRecents() {
        // Prepare
        self.testSubject.recordSearch("promo")

        // Act
        self.testSubject.forgetLastQuery()

        // Verify
        XCTAssertNil(self.testSubject.lastQuery)
        XCTAssertEqual(self.testSubject.recentQueries, ["promo"])
    }


    func test_suggestions_areDistinctPicksFromThePool() {
        // Prepare
        self.defaultsManager.didTipClosure = { true }
        self.smartFilterManager.smartFilterTypesClosure = { SmartFilterType.allCases }

        // Act
        let ids = self.testSubject.suggestions.map(\.id)

        // Verify
        XCTAssertEqual(ids.count, kSearchSuggestionCount)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func test_suggestions_neverOfferWhatIsAlreadyOn() {
        // Prepare
        self.defaultsManager.didTipClosure = { true }
        self.defaultsManager.didOpenStayReachable = true
        self.smartFilterManager.smartFilterTypesClosure = { SmartFilterType.allCases }
        self.smartFilterManager.isSmartFilterActiveClosure = { _ in true }
        let offIDs = SmartFilterType.allCases.map { SearchResult.smartFilter($0).id } + [SearchResult.action(.stayReachable).id]

        // Act
        let drawnIDs = (0..<50).flatMap { _ in self.testSubject.suggestions.map(\.id) }

        // Verify
        XCTAssertTrue(Set(drawnIDs).isDisjoint(with: offIDs))
    }

    func test_suggestions_listHigherGradesFirst() {
        // Prepare
        self.defaultsManager.didTipClosure = { true }
        let highID = SearchResult.action(.testFilters).id
        let lowID = SearchResult.action(.accentColor).id

        // Act
        let draws = (0..<200).map { _ in self.testSubject.suggestions.map(\.id) }

        // Verify
        for ids in draws {
            guard let highIndex = ids.firstIndex(of: highID), let lowIndex = ids.firstIndex(of: lowID) else { continue }
            XCTAssertLessThan(highIndex, lowIndex)
        }
    }

    func test_suggestions_offerTheTipJarUntilTipped() {
        // Prepare
        let tipJarID = SearchResult.action(.tipJar).id

        // Act
        self.defaultsManager.didTipClosure = { false }
        let beforeTipping = self.testSubject.suggestions.map(\.id)
        self.defaultsManager.didTipClosure = { true }
        let afterTipping = self.testSubject.suggestions.map(\.id)

        // Verify
        XCTAssertEqual(beforeTipping.last, tipJarID)
        XCTAssertFalse(afterTipping.contains(tipJarID))
    }


    //MARK: Helpers
    private func makeFilter(text: String, type: FilterType) -> Filter {
        let filter = Filter(context: self.persistenceManager.context)
        filter.uuid = UUID()
        filter.text = text
        filter.filterType = type
        return filter
    }

    private func makeCommunityList(name: String) -> CommunityListItem {
        return CommunityListItem(url: "https://lists.example.com/\(UUID().uuidString).sfsfilters",
                                 name: name,
                                 description: nil,
                                 author: nil,
                                 homepage: nil,
                                 locale: nil,
                                 cacheSection: nil,
                                 isActive: false,
                                 isCurated: false)
    }
}
