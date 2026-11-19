//
//  SiriIntentsTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 20/11/2026.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS

class SiriIntentsTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistenceManager = PersistenceManager(inMemory: true)
        self.filterListManager = mock_FilterListManager()
        let appManager = mock_AppManager()
        appManager.persistenceManager = self.persistenceManager
        appManager.filterListManager = self.filterListManager
        appManager.messageEvaluationManager = MessageEvaluationManager(persistenceManager: self.persistenceManager)
        SimplyFilterSMSShortcuts.appManager = appManager
    }


    //MARK: Tests
    func test_checkMessage_reply_namesFolderAndFilter() {
        let result = MessageEvaluationResult(action: .junk, match: .userFilter("casino"))
        let reply = CheckMessageIntent.reply(for: result)
        let expectedVerdict = String(format: "siri_checkMessage_folder"~, "addFilter_folder_junk"~)
        XCTAssertTrue(reply.hasPrefix(expectedVerdict))
        XCTAssertTrue(reply.contains("casino"))
    }

    func test_checkMessage_reply_noMatchSaysInboxOnly() {
        let result = MessageEvaluationResult(action: .allow, match: .noMatch)
        XCTAssertEqual(CheckMessageIntent.reply(for: result), "siri_checkMessage_inbox"~)
    }

    func test_evaluateMessageBody_usesUserFilters() {
        _ = self.persistenceManager.addFilter(text: "casino", type: .deny, denyFolder: .junk,
                                              filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        let evaluator = SimplyFilterSMSShortcuts.appManager.messageEvaluationManager

        XCTAssertEqual(evaluator.evaluateMessage(body: "Win big at the casino").action, .junk)
        XCTAssertEqual(evaluator.evaluateMessage(body: "See you at dinner").action, .allow)
    }

    @MainActor
    func test_filterQuery_matchesSpokenText() async throws {
        _ = self.persistenceManager.addFilter(text: "Casino", type: .deny, denyFolder: .junk,
                                              filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        _ = self.persistenceManager.addFilter(text: "bank", type: .allow, denyFolder: .junk,
                                              filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)

        let matches = try await FilterEntityQuery().entities(matching: "casino.")

        XCTAssertEqual(matches.map(\.name), ["Casino"])
        XCTAssertEqual(matches.first?.listName, FilterType.deny.name)
    }

    @MainActor
    func test_filterEntity_languageFilterUsesLanguageName() async throws {
        _ = self.persistenceManager.addFilter(text: NLLanguage.german.filterText, type: .denyLanguage, denyFolder: .junk,
                                              filterTarget: .body, filterMatching: .contains, filterCase: .caseInsensitive)

        let entities = try await FilterEntityQuery().suggestedEntities()

        XCTAssertEqual(entities.map(\.name), [NLLanguage.german.localizedName])
    }

    @MainActor
    func test_blockLanguage_addsLanguageFilterOnce() async throws {
        let intent = BlockLanguageIntent()
        intent.language = LanguageEntity(id: NLLanguage.german.rawValue)

        _ = try await intent.perform()
        _ = try await intent.perform()

        let filters = self.persistenceManager.fetchFilterRecords(for: .denyLanguage)
        XCTAssertEqual(filters.map({ $0.text }), [NLLanguage.german.filterText])
    }

    func test_languageQuery_listsEverySupportedLanguage() async throws {
        let entities = try await LanguageEntityQuery().allEntities()
        XCTAssertEqual(Set(entities.map(\.id)), Set(NLLanguage.allSupportedCases.map(\.rawValue)))
    }

    @MainActor
    func test_updateLists_refreshes() async throws {
        var lastUpdated: Date? = nil
        self.filterListManager.filterListsLastUpdatedClosure = { lastUpdated }
        self.filterListManager.refreshFilterListsClosure = { lastUpdated = Date() }

        _ = try await UpdateFilterListsIntent().perform()

        XCTAssertEqual(self.filterListManager.refreshFilterListsCounter, 1)
    }


    //MARK: Private
    private var persistenceManager: PersistenceManager!
    private var filterListManager: mock_FilterListManager!
}
