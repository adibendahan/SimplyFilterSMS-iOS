//
//  AutomaticFilterManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation
import XCTest
import CoreData
import NaturalLanguage
@testable import Simply_Filter_SMS

class AutomaticFilterManagerTests: XCTestCase {
    
    var persistanceManager = mock_PersistanceManager()
    var filterListService = mock_FilterListService()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        
        self.filterListService = mock_FilterListService()
        self.testSubject = AutomaticFilterManager(persistanceManager: self.persistanceManager,
                                                  filterListService: self.filterListService)
        self.persistanceManager.resetCounters()
        self.filterListService.resetCounters()
        self.automaticFiltersUpdatedCount = 0
        self.automaticFiltersUpdatedObserver = NotificationCenter.default.addObserver(forName: .automaticFiltersUpdated, object: nil, queue: nil) { [weak self] _ in
            self?.automaticFiltersUpdatedCount += 1
        }
    }
    
    override func tearDown() {
        super.tearDown()

        if let observer = self.automaticFiltersUpdatedObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        self.persistanceManager = mock_PersistanceManager()
        self.filterListService = mock_FilterListService()
    }
    
    
    //MARK: Tests
    func test_isAutomaticFilteringOn_on() {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = {
            return self.cache(["he"])
        }
        
        self.persistanceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguage = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguage.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguage.isActive = true
            return [automaticFiltersLanguage]
        }
        
        // Act
        let isAutomaticFilteringOnResult = self.testSubject.isAutomaticFilteringOn
        
        // Verify
        XCTAssertTrue(isAutomaticFilteringOnResult)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistanceManager.cachedFilterListsCounter, 1)
    }
    
    func test_isAutomaticFilteringOn_off() {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = {
            return self.cache(["he"])
        }
        
        self.persistanceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguage = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguage.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguage.isActive = false
            return [automaticFiltersLanguage]
        }
        
        // Act
        let isAutomaticFilteringOnResult = self.testSubject.isAutomaticFilteringOn
        
        // Verify
        XCTAssertFalse(isAutomaticFilteringOnResult)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistanceManager.cachedFilterListsCounter, 1)
    }
    
    func test_activeAutomaticFiltersTitle_twoLanguages() {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = {
            return self.cache(["he", "en"])
        }
        
        self.persistanceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguageHebrew = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguageHebrew.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguageHebrew.isActive = true
            let automaticFiltersLanguageEnglish = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguageEnglish.lang = NLLanguage.english.rawValue
            automaticFiltersLanguageEnglish.isActive = true
            return [automaticFiltersLanguageEnglish, automaticFiltersLanguageHebrew]
        }
        
        // Act
        let activeAutomaticFiltersTitleResult = self.testSubject.activeAutomaticFiltersTitle
        
        // Verify
        XCTAssertEqual(activeAutomaticFiltersTitleResult, "\(NLLanguage.english.localizedName!), \(NLLanguage.hebrew.localizedName!).")
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistanceManager.cachedFilterListsCounter, 1)
    }
    
    func test_activeAutomaticFiltersTitle_off() {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = {
            return self.cache(["he", "en"])
        }
        
        self.persistanceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguageHebrew = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguageHebrew.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguageHebrew.isActive = false
            let automaticFiltersLanguageEnglish = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguageEnglish.lang = NLLanguage.english.rawValue
            automaticFiltersLanguageEnglish.isActive = false
            return [automaticFiltersLanguageEnglish, automaticFiltersLanguageHebrew]
        }
        
        // Act
        let activeAutomaticFiltersTitleResult = self.testSubject.activeAutomaticFiltersTitle
        
        // Verify
        XCTAssertNil(activeAutomaticFiltersTitleResult)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistanceManager.cachedFilterListsCounter, 1)
    }
    
    func test_automaticFiltersCacheAge() {
        // Prepare
        let expectedCacheAge = Date()
        
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = expectedCacheAge
            
            return [cacheRecord]
        }
        
        
        // Act
        let cacheAgeResult = self.testSubject.automaticFiltersCacheAge
        
        // Verify
        XCTAssertEqual(expectedCacheAge, cacheAgeResult)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersCacheRecordsCounter, 1)
    }
    
    func test_languagesForBlockLanguage() {
        // Prepare
        self.persistanceManager.isDuplicateFilterLanguageClosure = { (_) in return true }
        
        // Act
        let emptyResult = self.testSubject.languages(for: .blockLanguage)
        
        // Verify
        XCTAssertTrue(emptyResult.isEmpty)
        
        // Prepare
        self.persistanceManager.isDuplicateFilterLanguageClosure = { (_) in return false }
        
        // Act
        let fullResult = self.testSubject.languages(for: .blockLanguage)
        
        // Verify
        XCTAssertEqual(fullResult.count, NLLanguage.allSupportedCases.count)
        // First result depends on current locale — verify English is always in the top 2 (either first or after the current locale language)
        let currentLocale = Locale.current.language.languageCode.map { NLLanguage(rawValue: $0.identifier) }
        let isCurrentLocaleSpecial = currentLocale == .english || currentLocale == .hebrew
        if isCurrentLocaleSpecial {
            XCTAssertEqual(fullResult[0], .english, "English locale should place English first")
        } else if let current = currentLocale {
            XCTAssertEqual(fullResult[0], current, "Non-English/Hebrew locale should appear first")
            XCTAssertEqual(fullResult[1], .english, "English should appear second after current locale")
        }
        XCTAssertEqual(self.persistanceManager.isDuplicateFilterLanguageCounter, NLLanguage.allSupportedCases.count * 2)
    }
    
    func test_languagesForAutomaticBlocking() {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = {
            return self.cache(["he", "en"])
        }
        
        // Act
        let languagesResult = self.testSubject.languages(for: .automaticBlocking)
        
        // Verify
        XCTAssertEqual(Set(languagesResult), [.hebrew, .english])
        XCTAssertEqual(self.persistanceManager.cachedFilterListsCounter, 1)
    }
    
    func test_languageAutomaticState() {
        // Prepare
        self.persistanceManager.ensuredAutomaticFiltersLanguageRecordClosure = { language in
            let automaticFiltersLanguageRecord = AutomaticFiltersLanguage(context: self.persistanceManager.context)
            automaticFiltersLanguageRecord.lang = language.rawValue
            automaticFiltersLanguageRecord.isActive = language == .hebrew
            return automaticFiltersLanguageRecord
        }
        
        // Act
        let resultExpectedTrue = self.testSubject.languageAutomaticState(for: .hebrew)
        let resultExpectedFalse = self.testSubject.languageAutomaticState(for: .english)
        
        // Verify
        XCTAssertTrue(resultExpectedTrue)
        XCTAssertFalse(resultExpectedFalse)
        XCTAssertEqual(self.persistanceManager.ensuredAutomaticFiltersLanguageRecordCounter, 2)
    }
    
    func test_setLanguageAtumaticState() {
        // Act
        self.testSubject.setLanguageAutomaticState(for: .english, value: true)
        
        // Verify
        XCTAssertEqual(self.persistanceManager.ensuredAutomaticFiltersLanguageRecordCounter, 1)
        XCTAssertEqual(self.persistanceManager.commitContextCounter, 1)
    }
    
    func test_automaticRuleState() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersRuleRecordClosure = { rule in
            let automaticFiltersRuleRecord = AutomaticFiltersRule(context: self.persistanceManager.context)
            automaticFiltersRuleRecord.ruleId = rule.rawValue
            automaticFiltersRuleRecord.isActive = rule == .email
            return automaticFiltersRuleRecord
        }
        
        // Act
        let resultExpectedTrue = self.testSubject.automaticRuleState(for: .email)
        let resultExpectedFalse = self.testSubject.automaticRuleState(for: .links)
        
        // Verify
        XCTAssertTrue(resultExpectedTrue)
        XCTAssertFalse(resultExpectedFalse)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersRuleRecordCounter, 2)
    }
    
    func test_setAutomaticRuleState() {
        // Act
        self.testSubject.setAutomaticRuleState(for: .links, value: true)
        
        // Verify
        XCTAssertEqual(self.persistanceManager.ensuredAutomaticFiltersRuleRecordCounter, 1)
        XCTAssertEqual(self.persistanceManager.commitContextCounter, 1)
    }
    
    func test_selectedChoice() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersRuleRecordClosure = { rule in
            let automaticFiltersRuleRecord = AutomaticFiltersRule(context: self.persistanceManager.context)
            automaticFiltersRuleRecord.ruleId = rule.rawValue
            automaticFiltersRuleRecord.isActive = rule == .numbersOnly
            automaticFiltersRuleRecord.selectedChoice = rule == .numbersOnly ? 5 : 0
            return automaticFiltersRuleRecord
        }
        
        // Act
        let resultExpectedFive = self.testSubject.selectedChoice(for: .numbersOnly)
        let resultExpectedZero = self.testSubject.selectedChoice(for: .links)
        
        // Verify
        XCTAssertEqual(resultExpectedFive, 5)
        XCTAssertEqual(resultExpectedZero, 0)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersRuleRecordCounter, 2)
    }
    
    func test_setSelectedChoice() {
        // Prepare
        var numbersOnlyRule: AutomaticFiltersRule?
        
        self.persistanceManager.fetchAutomaticFiltersRuleRecordClosure = { rule in
            let automaticFiltersRuleRecord = AutomaticFiltersRule(context: self.persistanceManager.context)
            automaticFiltersRuleRecord.ruleId = rule.rawValue
            automaticFiltersRuleRecord.isActive = rule == .numbersOnly
            automaticFiltersRuleRecord.selectedChoice = rule == .numbersOnly ? 5 : 0
            
            if rule == .numbersOnly {
                numbersOnlyRule = automaticFiltersRuleRecord
            }
            
            return automaticFiltersRuleRecord
        }
        
        // Act
        self.testSubject.setSelectedChoice(for: .numbersOnly, choice: 4)
        
        // Verify
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersRuleRecordCounter, 1)
        XCTAssertEqual(self.persistanceManager.commitContextCounter, 1)
        XCTAssertEqual(numbersOnlyRule?.selectedChoice, 4)
    }
    
    func test_update_noCache_downloadsEverything() async {
        // Prepare
        var catalogETag: String? = "unset"
        var listETags: [String?] = []
        self.filterListService.fetchFilterListCatalogClosure = { etag in
            catalogETag = etag
            return .modified(self.catalog(["he", "en"]), etag: "catalog-1")
        }
        self.filterListService.fetchFilterListClosure = { url, etag in
            listETags.append(etag)
            return .modified(self.payload(text: url.lastPathComponent), etag: "\(url.lastPathComponent)-1")
        }
        var savedCache: FilterListsCache?
        self.persistanceManager.saveCacheClosure = { savedCache = $0 }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertNil(catalogETag)
        XCTAssertEqual(listETags, [nil, nil])
        XCTAssertEqual(savedCache, FilterListsCache(catalogETag: "catalog-1",
                                                    catalog: self.catalog(["he", "en"]),
                                                    lists: [self.section("he", etag: "he.sfsfilters-1", text: "he.sfsfilters"),
                                                            self.section("en", etag: "en.sfsfilters-1", text: "en.sfsfilters")]))
        XCTAssertEqual(self.automaticFiltersUpdatedCount, 1)
    }

    func test_update_freshLegacyCache_downloadsEverything() async {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            return .modified(self.catalog(["he"]), etag: "catalog-1")
        }
        self.filterListService.fetchFilterListClosure = { url, _ in
            return .modified(self.payload(text: url.lastPathComponent), etag: "\(url.lastPathComponent)-1")
        }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 1)
    }

    func test_update_freshCache_skipsFetch() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = { self.cache(["he"]) }
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 0)
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 0)
    }

    func test_update_nothingChanged_touchesCache() async {
        // Prepare
        let cache = self.cache(["he", "en"])
        self.persistanceManager.cachedFilterListsClosure = { cache }
        var catalogETag: String?
        var listETags: [String?] = []
        self.filterListService.fetchFilterListCatalogClosure = { etag in
            catalogETag = etag
            return .notModified
        }
        self.filterListService.fetchFilterListClosure = { _, etag in
            listETags.append(etag)
            return .notModified
        }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(catalogETag, "catalog-1")
        XCTAssertEqual(listETags, ["he-1", "en-1"])
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistanceManager.touchCacheCounter, 1)
        XCTAssertEqual(self.automaticFiltersUpdatedCount, 0)
    }

    func test_update_oneListChanged_replacesOnlyThatSection() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { url, _ in
            url.lastPathComponent == "he.sfsfilters" ? .modified(self.payload(text: "new"), etag: "he-2") : .notModified
        }
        var savedCache: FilterListsCache?
        self.persistanceManager.saveCacheClosure = { savedCache = $0 }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(savedCache?.lists, [self.section("he", etag: "he-2", text: "new"),
                                           self.section("en", etag: "en-1", text: "en")])
        XCTAssertEqual(self.automaticFiltersUpdatedCount, 1)
    }

    func test_update_listFails_keepsSectionAndDoesNotTouch() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { url, _ in
            url.lastPathComponent == "he.sfsfilters" ? nil : .notModified
        }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCounter, 2)
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistanceManager.touchCacheCounter, 0)
    }

    func test_update_catalogFails_changesNothing() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = { self.cache(["he"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in nil }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCounter, 0)
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistanceManager.touchCacheCounter, 0)
    }

    func test_update_dropsListsNotInCatalog() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .modified(self.catalog(["he"]), etag: "catalog-2") }
        self.filterListService.fetchFilterListClosure = { _, _ in .notModified }
        var savedCache: FilterListsCache?
        self.persistanceManager.saveCacheClosure = { savedCache = $0 }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(savedCache?.lists, [self.section("he", etag: "he-1", text: "he")])
        XCTAssertEqual(self.automaticFiltersUpdatedCount, 1)
    }

    func test_update_sameRevision_savesWithoutNotification() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = {
            FilterListsCache(catalogETag: "catalog-1",
                             catalog: self.catalog(["he"]),
                             lists: [self.section("he", etag: "he-1", text: "he", revision: 2)])
        }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { _, _ in .modified(self.payload(text: "typo fix", revision: 2), etag: "he-2") }

        // Act
        await self.testSubject.updateAutomaticFiltersIfNeeded()

        // Verify
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 1)
        XCTAssertEqual(self.automaticFiltersUpdatedCount, 0)
    }

    func test_forceUpdate_sendsNoETags() async {
        // Prepare
        self.persistanceManager.cachedFilterListsClosure = { self.cache(["he"]) }
        var sentETags: [String?] = []
        self.filterListService.fetchFilterListCatalogClosure = { etag in
            sentETags.append(etag)
            return .modified(self.catalog(["he"]), etag: "catalog-1")
        }
        self.filterListService.fetchFilterListClosure = { _, etag in
            sentETags.append(etag)
            return .modified(self.payload(text: "he"), etag: "he-1")
        }

        // Act
        await self.testSubject.forceUpdateAutomaticFilters()

        // Verify
        XCTAssertEqual(sentETags, [nil, nil])
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistanceManager.touchCacheCounter, 1)
    }
    
    func test_update_concurrentCallsShareOneRefresh() async {
        // Prepare
        self.filterListService.fetchFilterListCatalogClosure = { _ in .modified(self.catalog(["he"]), etag: "catalog-1") }
        self.filterListService.fetchFilterListClosure = { _, _ in .modified(self.payload(text: "he"), etag: "he-1") }

        // Act
        async let first: Void = self.testSubject.updateAutomaticFiltersIfNeeded()
        async let second: Void = self.testSubject.forceUpdateAutomaticFilters()
        _ = await (first, second)

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 1)
    }
    
    private var testSubject: AutomaticFilterManagerProtocol = AutomaticFilterManager(persistanceManager: mock_PersistanceManager())
    private var automaticFiltersUpdatedCount = 0
    private var automaticFiltersUpdatedObserver: NSObjectProtocol?

    private func catalog(_ languages: [String]) -> FilterListCatalogResponse {
        var entries: [FilterListCatalogEntry] = []

        for language in languages {
            let entry = FilterListCatalogEntry(id: "ai-\(language)",
                                               name: language,
                                               url: "\(language).sfsfilters",
                                               language: language)
            entries.append(entry)
        }

        return FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                         version: FilterListCatalogResponse.currentVersion,
                                         lists: entries)
    }

    private func payload(text: String, revision: Int? = nil) -> FilterExportPayload {
        return FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                   version: FilterExportPayload.currentVersion,
                                   exportedAt: Date(timeIntervalSince1970: 1_800_000_000),
                                   appVersion: "3.3.0",
                                   name: nil,
                                   revision: revision,
                                   filters: [FilterExportRecord(text: text, type: "deny", folder: "junk", target: "all", matching: "contains", caseSensitivity: "insensitive")],
                                   forceClearBeforeImport: nil)
    }

    private func section(_ language: String, etag: String, text: String, revision: Int? = nil) -> FilterListsCacheSection {
        return FilterListsCacheSection(url: URL(string: "\(language).sfsfilters", relativeTo: .filterListCatalogURL)!.absoluteString,
                                       etag: etag,
                                       payload: self.payload(text: text, revision: revision))
    }

    private func cache(_ languages: [String]) -> FilterListsCache {
        return FilterListsCache(catalogETag: "catalog-1",
                                catalog: self.catalog(languages),
                                lists: languages.map({ self.section($0, etag: "\($0)-1", text: $0) }))
    }
}
