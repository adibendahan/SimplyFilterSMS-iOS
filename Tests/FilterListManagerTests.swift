//
//  FilterListManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation
import XCTest
import CoreData
import NaturalLanguage
@testable import Simply_Filter_SMS

class FilterListManagerTests: XCTestCase {
    
    var persistenceManager = mock_PersistenceManager()
    var filterListService = mock_FilterListService()
    var networkSyncManager = mock_NetworkSyncManager()

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.filterListService = mock_FilterListService()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.testSubject = FilterListManager(persistenceManager: self.persistenceManager,
                                             filterListService: self.filterListService,
                                             networkSyncManager: self.networkSyncManager)
        self.persistenceManager.resetCounters()
        self.filterListService.resetCounters()
        self.filterListsUpdatedCount = 0
        self.filterListsUpdatedEntryType = nil
        self.filterListsUpdatedObserver = NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: nil) { [weak self] notification in
            self?.filterListsUpdatedCount += 1
            self?.filterListsUpdatedEntryType = notification.object as? FilterListCatalogEntryType
        }
    }
    
    override func tearDown() {
        super.tearDown()

        if let observer = self.filterListsUpdatedObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        self.persistenceManager = mock_PersistenceManager()
        self.filterListService = mock_FilterListService()
    }
    
    
    //MARK: Tests
    func test_hasActiveFilterLists_on() {
        // Prepare
        self.persistenceManager.cachedFilterListCatalogClosure = {
            return self.catalog(["he"])
        }
        
        self.persistenceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguage = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguage.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguage.isActive = true
            return [automaticFiltersLanguage]
        }
        
        // Act
        let hasActiveFilterListsResult = self.testSubject.hasActiveFilterLists
        
        // Verify
        XCTAssertTrue(hasActiveFilterListsResult)
        XCTAssertEqual(self.persistenceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistenceManager.cachedFilterListCatalogCounter, 1)
    }
    
    func test_hasActiveFilterLists_off() {
        // Prepare
        self.persistenceManager.cachedFilterListCatalogClosure = {
            return self.catalog(["he"])
        }
        
        self.persistenceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguage = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguage.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguage.isActive = false
            return [automaticFiltersLanguage]
        }
        
        // Act
        let hasActiveFilterListsResult = self.testSubject.hasActiveFilterLists
        
        // Verify
        XCTAssertFalse(hasActiveFilterListsResult)
        XCTAssertEqual(self.persistenceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistenceManager.cachedFilterListCatalogCounter, 1)
    }
    
    func test_activeFilterListsTitle_twoLanguages() {
        // Prepare
        self.persistenceManager.cachedFilterListCatalogClosure = {
            return self.catalog(["he", "en"])
        }
        
        self.persistenceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguageHebrew = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguageHebrew.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguageHebrew.isActive = true
            let automaticFiltersLanguageEnglish = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguageEnglish.lang = NLLanguage.english.rawValue
            automaticFiltersLanguageEnglish.isActive = true
            return [automaticFiltersLanguageEnglish, automaticFiltersLanguageHebrew]
        }
        
        // Act
        let activeFilterListsTitleResult = self.testSubject.activeFilterListsTitle
        
        // Verify
        XCTAssertEqual(activeFilterListsTitleResult, "\(NLLanguage.english.localizedName!), \(NLLanguage.hebrew.localizedName!).")
        XCTAssertEqual(self.persistenceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistenceManager.cachedFilterListCatalogCounter, 1)
    }
    
    func test_activeFilterListsTitle_off() {
        // Prepare
        self.persistenceManager.cachedFilterListCatalogClosure = {
            return self.catalog(["he", "en"])
        }
        
        self.persistenceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguageHebrew = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguageHebrew.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguageHebrew.isActive = false
            let automaticFiltersLanguageEnglish = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguageEnglish.lang = NLLanguage.english.rawValue
            automaticFiltersLanguageEnglish.isActive = false
            return [automaticFiltersLanguageEnglish, automaticFiltersLanguageHebrew]
        }
        
        // Act
        let activeFilterListsTitleResult = self.testSubject.activeFilterListsTitle
        
        // Verify
        XCTAssertNil(activeFilterListsTitleResult)
        XCTAssertEqual(self.persistenceManager.fetchAutomaticFiltersLanguageRecordsCounter, 1)
        XCTAssertEqual(self.persistenceManager.cachedFilterListCatalogCounter, 1)
    }
    
    func test_filterListsLastUpdated() {
        // Prepare
        let expectedCacheAge = Date()
        
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = expectedCacheAge
            
            return [cacheRecord]
        }
        
        
        // Act
        let cacheAgeResult = self.testSubject.filterListsLastUpdated
        
        // Verify
        XCTAssertEqual(expectedCacheAge, cacheAgeResult)
        XCTAssertEqual(self.persistenceManager.fetchFilterListsCacheRecordsCounter, 1)
    }
    
    func test_filterListLanguages() {
        // Prepare
        self.persistenceManager.cachedFilterListCatalogClosure = {
            return self.catalog(["he", "en"])
        }
        
        // Act
        let languagesResult = self.testSubject.filterListLanguages
        
        // Verify
        XCTAssertEqual(Set(languagesResult), [.hebrew, .english])
        XCTAssertEqual(self.persistenceManager.cachedFilterListCatalogCounter, 1)
    }
    
    func test_isFilterListActive() {
        // Prepare
        self.persistenceManager.ensuredAutomaticFiltersLanguageRecordClosure = { language in
            let automaticFiltersLanguageRecord = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguageRecord.lang = language.rawValue
            automaticFiltersLanguageRecord.isActive = language == .hebrew
            return automaticFiltersLanguageRecord
        }
        
        // Act
        let resultExpectedTrue = self.testSubject.isFilterListActive(for: .hebrew)
        let resultExpectedFalse = self.testSubject.isFilterListActive(for: .english)
        
        // Verify
        XCTAssertTrue(resultExpectedTrue)
        XCTAssertFalse(resultExpectedFalse)
        XCTAssertEqual(self.persistenceManager.ensuredAutomaticFiltersLanguageRecordCounter, 2)
    }
    
    func test_setFilterListActive() {
        // Act
        self.testSubject.setFilterListActive(for: .english, value: true)
        
        // Verify
        XCTAssertEqual(self.persistenceManager.ensuredAutomaticFiltersLanguageRecordCounter, 1)
        XCTAssertEqual(self.persistenceManager.commitContextCounter, 1)
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
        var savedCache: FilterListsSnapshot?
        self.persistenceManager.saveCacheClosure = { savedCache = $0 }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertNil(catalogETag)
        XCTAssertEqual(listETags, [nil, nil])
        XCTAssertEqual(savedCache, FilterListsSnapshot(catalogETag: "catalog-1",
                                                    catalog: self.catalog(["he", "en"]),
                                                    lists: [self.section("he", etag: "he.sfsfilters-1", text: "he.sfsfilters"),
                                                            self.section("en", etag: "en.sfsfilters-1", text: "en.sfsfilters")]))
        XCTAssertEqual(self.filterListsUpdatedCount, 1)
    }

    func test_update_freshLegacyCache_downloadsEverything() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
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
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 1)
    }

    func test_update_freshCache_stillChecksWithETags() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he"]) }
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        var catalogETag: String?
        self.filterListService.fetchFilterListCatalogClosure = { etag in
            catalogETag = etag
            return .notModified
        }
        self.filterListService.fetchFilterListClosure = { _, _ in .notModified }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(catalogETag, "catalog-1")
        XCTAssertEqual(self.filterListService.fetchFilterListCounter, 1)
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 0)
    }

    func test_update_nothingChanged_touchesCache() async {
        // Prepare
        let cache = self.cache(["he", "en"])
        self.persistenceManager.cachedFilterListsClosure = { cache }
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
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(catalogETag, "catalog-1")
        XCTAssertEqual(listETags, ["he-1", "en-1"])
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistenceManager.touchCacheCounter, 1)
        XCTAssertEqual(self.filterListsUpdatedCount, 0)
    }

    func test_update_oneListChanged_replacesOnlyThatSection() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { url, _ in
            guard url.lastPathComponent == "he.sfsfilters" else { return .notModified }
            let payload = self.payload(text: "new")
            return .modified(payload, etag: "he-2")
        }
        var savedCache: FilterListsSnapshot?
        self.persistenceManager.saveCacheClosure = { savedCache = $0 }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(savedCache?.lists, [self.section("he", etag: "he-2", text: "new"),
                                           self.section("en", etag: "en-1", text: "en")])
        XCTAssertEqual(self.filterListsUpdatedCount, 1)
    }

    func test_update_activeLanguageChanged_namesAIFiltering() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.persistenceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguage = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguage.lang = NLLanguage.hebrew.rawValue
            automaticFiltersLanguage.isActive = true
            return [automaticFiltersLanguage]
        }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { url, _ in
            guard url.lastPathComponent == "he.sfsfilters" else { return .notModified }
            return .modified(self.payload(text: "new"), etag: "he-2")
        }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.filterListsUpdatedCount, 1)
        XCTAssertEqual(self.filterListsUpdatedEntryType, .aiFilteringLanguage)
    }

    func test_update_inactiveLanguageChanged_namesNothing() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.persistenceManager.fetchAutomaticFiltersLanguageRecordsClosure = {
            let automaticFiltersLanguage = AutomaticFiltersLanguage(context: self.persistenceManager.context)
            automaticFiltersLanguage.lang = NLLanguage.english.rawValue
            automaticFiltersLanguage.isActive = true
            return [automaticFiltersLanguage]
        }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { url, _ in
            guard url.lastPathComponent == "he.sfsfilters" else { return .notModified }
            return .modified(self.payload(text: "new"), etag: "he-2")
        }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.filterListsUpdatedCount, 1)
        XCTAssertNil(self.filterListsUpdatedEntryType)
    }

    func test_update_listFails_keepsSectionAndDoesNotTouch() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { url, _ in
            guard url.lastPathComponent == "he.sfsfilters" else { return .notModified }
            return nil
        }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCounter, 2)
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistenceManager.touchCacheCounter, 0)
    }

    func test_update_catalogFails_changesNothing() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in nil }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCounter, 0)
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 0)
        XCTAssertEqual(self.persistenceManager.touchCacheCounter, 0)
    }

    func test_update_dropsListsNotInCatalog() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = { self.cache(["he", "en"]) }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .modified(self.catalog(["he"]), etag: "catalog-2") }
        self.filterListService.fetchFilterListClosure = { _, _ in .notModified }
        var savedCache: FilterListsSnapshot?
        self.persistenceManager.saveCacheClosure = { savedCache = $0 }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(savedCache?.lists, [self.section("he", etag: "he-1", text: "he")])
        XCTAssertEqual(self.filterListsUpdatedCount, 1)
    }

    func test_update_filtersUnchanged_savesWithoutNotification() async {
        // Prepare
        self.persistenceManager.cachedFilterListsClosure = {
            FilterListsSnapshot(catalogETag: "catalog-1",
                             catalog: self.catalog(["he"]),
                             lists: [self.section("he", etag: "he-1", text: "he")])
        }
        self.filterListService.fetchFilterListCatalogClosure = { _ in .notModified }
        self.filterListService.fetchFilterListClosure = { _, _ in .modified(self.payload(text: "he"), etag: "he-2") }

        // Act
        await self.testSubject.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 1)
        XCTAssertEqual(self.filterListsUpdatedCount, 0)
    }

    @MainActor
    func test_update_concurrentCallsShareOneRefresh() async {
        // Prepare
        let firstCatalogRequestStarted = self.expectation(description: "first catalog request started")
        var releaseFirstCatalogRequest: CheckedContinuation<Void, Never>?
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            let isFirstRequest = self.filterListService.fetchFilterListCatalogCounter == 1
            if isFirstRequest {
                await withCheckedContinuation { continuation in
                    releaseFirstCatalogRequest = continuation
                    firstCatalogRequestStarted.fulfill()
                }
            }
            return .modified(self.catalog(["he"]), etag: "catalog-1")
        }
        self.filterListService.fetchFilterListClosure = { _, _ in .modified(self.payload(text: "he"), etag: "he-1") }

        // Act
        let firstCall = Task {
            await self.testSubject.refreshFilterLists()
        }
        await self.fulfillment(of: [firstCatalogRequestStarted], timeout: 1)
        Task {
            releaseFirstCatalogRequest?.resume()
        }
        await self.testSubject.refreshFilterLists()
        await firstCall.value

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
        XCTAssertEqual(self.persistenceManager.saveCacheCounter, 1)
    }
    
    @MainActor
    func test_updateWhenOnline_checkedToday_skips() {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        self.persistenceManager.cachedFilterListCatalogClosure = { self.catalog(["he"]) }
        self.networkSyncManager.networkStatusClosure = { .online }

        // Act
        self.testSubject.updateFilterListsWhenOnline()

        // Verify
        XCTAssertEqual(self.networkSyncManager.networkStatusGetCounter, 0)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 0)
    }

    @MainActor
    func test_updateWhenOnline_checkedTodayOlderCatalog_fetches() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        self.persistenceManager.cachedFilterListCatalogClosure = {
            FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                      version: FilterListCatalogResponse.currentVersion - 1,
                                      lists: self.catalog(["he"]).lists)
        }
        self.networkSyncManager.networkStatusClosure = { .online }
        let catalogRequested = self.expectation(description: "catalog requested")
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            catalogRequested.fulfill()
            return nil
        }

        // Act
        self.testSubject.updateFilterListsWhenOnline()

        // Verify
        await self.fulfillment(of: [catalogRequested], timeout: 1)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
    }

    @MainActor
    func test_updateWhenOnline_checkedTodayEmptyCatalog_fetches() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        self.persistenceManager.cachedFilterListCatalogClosure = {
            FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                      version: FilterListCatalogResponse.currentVersion,
                                      lists: [])
        }
        self.networkSyncManager.networkStatusClosure = { .online }
        let catalogRequested = self.expectation(description: "catalog requested")
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            catalogRequested.fulfill()
            return nil
        }

        // Act
        self.testSubject.updateFilterListsWhenOnline()

        // Verify
        await self.fulfillment(of: [catalogRequested], timeout: 1)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
    }

    @MainActor
    func test_updateWhenOnline_checkedTodayUnreadableCache_fetches() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        self.persistenceManager.cachedFilterListCatalogClosure = { nil }
        self.networkSyncManager.networkStatusClosure = { .online }
        let catalogRequested = self.expectation(description: "catalog requested")
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            catalogRequested.fulfill()
            return nil
        }

        // Act
        self.testSubject.updateFilterListsWhenOnline()

        // Verify
        await self.fulfillment(of: [catalogRequested], timeout: 1)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
    }

    @MainActor
    func test_updateWhenOnline_notCheckedToday_fetches() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Calendar.current.date(byAdding: .day, value: -1, to: Date())

            return [cacheRecord]
        }
        self.networkSyncManager.networkStatusClosure = { .online }
        let catalogRequested = self.expectation(description: "catalog requested")
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            catalogRequested.fulfill()
            return nil
        }

        // Act
        self.testSubject.updateFilterListsWhenOnline()

        // Verify
        await self.fulfillment(of: [catalogRequested], timeout: 1)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
    }

    @MainActor
    func test_updateWhenOnline_offline_fetchesOnceBackOnline() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = { [] }
        self.networkSyncManager.networkStatusClosure = { .offline }
        let catalogRequested = self.expectation(description: "catalog requested")
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            catalogRequested.fulfill()
            return nil
        }

        // Act
        self.testSubject.updateFilterListsWhenOnline()
        let fetchedWhileOffline = self.filterListService.fetchFilterListCatalogCounter
        NotificationCenter.default.post(name: .networkStatusChange, object: NetworkStatus.offline)
        NotificationCenter.default.post(name: .networkStatusChange, object: NetworkStatus.online)

        // Verify
        await self.fulfillment(of: [catalogRequested], timeout: 1)
        XCTAssertEqual(fetchedWhileOffline, 0)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 1)
    }

    @MainActor
    func test_filterListsUpdate_updatedToday_finishesImmediately() {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = {
            let cacheRecord = FilterListsCache(context: self.persistenceManager.context)
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()

            return [cacheRecord]
        }
        self.persistenceManager.cachedFilterListCatalogClosure = { self.catalog(["he"]) }
        var didFinish = false

        // Act
        self.testSubject.updateFilterListsWhenOnline()
        self.testSubject.onFilterListsUpdateFinished { didFinish = true }

        // Verify
        XCTAssertTrue(didFinish)
    }

    @MainActor
    func test_filterListsUpdate_online_finishesAfterRefresh() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = { [] }
        self.networkSyncManager.networkStatusClosure = { .online }
        var didFinish = false
        var didFinishBeforeFetch = true
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            didFinishBeforeFetch = didFinish
            return nil
        }
        let updateFinished = self.expectation(description: "updateFinished")

        // Act
        self.testSubject.updateFilterListsWhenOnline()
        self.testSubject.onFilterListsUpdateFinished {
            didFinish = true
            updateFinished.fulfill()
        }

        // Verify
        await self.fulfillment(of: [updateFinished], timeout: 1)
        XCTAssertFalse(didFinishBeforeFetch)
    }

    @MainActor
    func test_filterListsUpdate_offline_finishesImmediately() async {
        // Prepare
        self.persistenceManager.fetchFilterListsCacheRecordsClosure = { [] }
        self.networkSyncManager.networkStatusClosure = { .offline }
        let updateFinished = self.expectation(description: "updateFinished")

        // Act
        self.testSubject.updateFilterListsWhenOnline()
        self.testSubject.onFilterListsUpdateFinished { updateFinished.fulfill() }

        // Verify
        await self.fulfillment(of: [updateFinished], timeout: 1)
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 0)
    }

    private var testSubject: FilterListManagerProtocol = FilterListManager(persistenceManager: mock_PersistenceManager())
    private var filterListsUpdatedCount = 0
    private var filterListsUpdatedObserver: NSObjectProtocol?
    private var filterListsUpdatedEntryType: FilterListCatalogEntryType?

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

    private func payload(text: String) -> FilterExportPayload {
        return FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                   version: FilterExportPayload.currentVersion,
                                   exportedAt: Date(timeIntervalSince1970: 1_800_000_000),
                                   appVersion: "3.3.0",
                                   name: nil,
                                   description: nil,
                                   author: nil,
                                   homepage: nil,
                                   locale: nil,
                                   filters: [FilterExportRecord(text: text, type: "deny", folder: "junk", target: "all", matching: "contains", caseSensitivity: "insensitive")],
                                   forceClearBeforeImport: nil)
    }

    private func section(_ language: String, etag: String, text: String) -> FilterListsCacheSection {
        return FilterListsCacheSection(url: URL(string: "\(language).sfsfilters", relativeTo: .filterListCatalogURL)!.absoluteString,
                                       etag: etag,
                                       payload: self.payload(text: text))
    }

    private func cache(_ languages: [String]) -> FilterListsSnapshot {
        return FilterListsSnapshot(catalogETag: "catalog-1",
                                catalog: self.catalog(languages),
                                lists: languages.map({ self.section($0, etag: "\($0)-1", text: $0) }))
    }
}
