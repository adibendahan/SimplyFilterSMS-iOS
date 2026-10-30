//
//  FilterListsFlowTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation
import XCTest
import NaturalLanguage
import IdentityLookup
@testable import Simply_Filter_SMS

class FilterListsFlowTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistanceManager = PersistanceManager(inMemory: true)
        self.filterListService = mock_FilterListService()
        self.automaticFilterManager = AutomaticFilterManager(persistanceManager: self.persistanceManager,
                                                             filterListService: self.filterListService)
        self.messageEvaluationManager = MessageEvaluationManager(persistanceManager: self.persistanceManager)
    }


    //MARK: Tests
    @MainActor
    func test_refreshThenEvaluate() async {
        // Prepare
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            return .modified(self.catalog, etag: "catalog-1")
        }
        self.filterListService.fetchFilterListClosure = { url, _ in
            return self.listResponse(for: url)
        }
        self.automaticFilterManager.setAutomaticRuleState(for: .links, value: true)

        let beforeRefresh = self.evaluate(body: "הלוואה מהירה", sender: "1234567")
        XCTAssertEqual(beforeRefresh.action, .allow, "nothing is blocked before the lists are downloaded")

        // Act
        await self.automaticFilterManager.forceUpdateAutomaticFilters()
        self.automaticFilterManager.setLanguageAutomaticState(for: .hebrew, value: true)
        self.automaticFilterManager.setLanguageAutomaticState(for: .english, value: false)

        // Verify
        XCTAssertEqual(Set(self.automaticFilterManager.languages(for: .automaticBlocking)), [.hebrew, .english])

        let allowedSender = self.evaluate(body: "check https://link.com", sender: "BituahLeumi")
        XCTAssertEqual(allowedSender.action, .allow, "an allowed sender beats the links rule")
        XCTAssertEqual(allowedSender.match, .automaticFilter(NLLanguage.hebrew.localizedName!))

        let otherSender = self.evaluate(body: "check https://link.com", sender: "1234567")
        XCTAssertEqual(otherSender.action, .junk, "the links rule still blocks everyone else")

        let blockedPhrase = self.evaluate(body: "הלוואה מהירה", sender: "1234567")
        XCTAssertEqual(blockedPhrase.action, .junk)
        XCTAssertEqual(blockedPhrase.match, .automaticFilter(NLLanguage.hebrew.localizedName!))

        let englishOff = self.evaluate(body: "fast loan", sender: "1234567")
        XCTAssertEqual(englishOff.action, .allow, "a list whose language is off doesn't block")

        self.automaticFilterManager.setLanguageAutomaticState(for: .english, value: true)

        let englishOn = self.evaluate(body: "fast loan", sender: "1234567")
        XCTAssertEqual(englishOn.action, .promotion, "the English list lives at an absolute URL and blocks to its record's folder")
    }


    //MARK: Private Variables and Helpers
    private var persistanceManager: PersistanceManager!
    private var filterListService: mock_FilterListService!
    private var automaticFilterManager: AutomaticFilterManager!
    private var messageEvaluationManager: MessageEvaluationManager!

    private let hebrewListURL = "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/3.3.0/ai/he.sfsfilters"
    private let englishListURL = "https://lists.example.com/en.sfsfilters"

    private var catalog: FilterListCatalogResponse {
        let hebrew = FilterListCatalogEntry(id: "ai-he",
                                            name: "Hebrew",
                                            url: "he.sfsfilters",
                                            language: "he")
        let english = FilterListCatalogEntry(id: "ai-en",
                                             name: "English",
                                             url: self.englishListURL,
                                             language: "en")
        return FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                         version: FilterListCatalogResponse.currentVersion,
                                         lists: [hebrew, english])
    }

    private func listResponse(for url: URL) -> FetchResult<FilterExportPayload>? {
        switch url.absoluteString {
        case self.hebrewListURL:
            let allowSender = FilterExportRecord(text: "(?i)^BituahLeumi$",
                                                 type: "allow",
                                                 folder: nil,
                                                 target: "sender",
                                                 matching: "regex",
                                                 caseSensitivity: nil)
            let denyBody = FilterExportRecord(text: "הלוואה",
                                              type: "deny",
                                              folder: "junk",
                                              target: "body",
                                              matching: "contains",
                                              caseSensitivity: "insensitive")
            return .modified(self.payload(filters: [allowSender, denyBody]), etag: "he-1")

        case self.englishListURL:
            let denyBody = FilterExportRecord(text: "loan",
                                              type: "deny",
                                              folder: "promotion",
                                              target: "body",
                                              matching: "contains",
                                              caseSensitivity: "insensitive")
            return .modified(self.payload(filters: [denyBody]), etag: "en-1")

        default:
            XCTFail("unexpected list URL: \(url.absoluteString)")
            return nil
        }
    }

    private func payload(filters: [FilterExportRecord]) -> FilterExportPayload {
        return FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                   version: FilterExportPayload.currentVersion,
                                   exportedAt: Date(),
                                   appVersion: "3.3.0",
                                   name: nil,
                                   revision: 1,
                                   filters: filters,
                                   forceClearBeforeImport: nil)
    }

    private func evaluate(body: String, sender: String) -> MessageEvaluationResult {
        return self.messageEvaluationManager.evaluateMessage(body: body, sender: sender)
    }
}
