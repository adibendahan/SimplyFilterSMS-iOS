//
//  mock_PersistenceManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 28/01/2022.
//

import Foundation
import XCTest
import CoreData
import NaturalLanguage
@testable import Simply_Filter_SMS

class PersistenceManagerTests: XCTestCase {
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(contextSaved(notification:)),
                                                name: NSNotification.Name.NSManagedObjectContextDidSave ,
                                                object: nil )
        
        self.testSubject = PersistenceManager(inMemory: true)
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.saveNotificationCompleteHandler = nil
        self.flushPersistenceManager()
    }
    
    
    //MARK: Tests
    
    func test_fetchFilterRecords() {
        // Prepare
        self.testSubject.addFilter(text: "1", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.testSubject.addFilter(text: "2", type: .allow, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        
        // Act
        let filters = self.testSubject.fetchFilterRecords()
        
        // Verify
        XCTAssertEqual(filters.count, 2)
        XCTAssertEqual(filters[1].text, "1")
        XCTAssertEqual(filters[1].filterType, .deny)
        XCTAssertEqual(filters[1].messageFolder, .junk)
        XCTAssertEqual(filters[0].text, "2")
        XCTAssertEqual(filters[0].filterType, .allow)
    }
    
    func test_fetchFilterRecordsForType() {
        // Prepare
        self.testSubject.addFilter(text: "1", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.testSubject.addFilter(text: "2", type: .allow, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.testSubject.addFilter(text: "3", type: .allow, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        
        // Act
        let allowFilters = self.testSubject.fetchFilterRecords(for: .allow)
        let denyFilters = self.testSubject.fetchFilterRecords(for: .deny)
        
        // Verify
        XCTAssertEqual(allowFilters.count, 2)
        XCTAssertEqual(denyFilters.count, 1)
        XCTAssertEqual(denyFilters[0].text, "1")
        XCTAssertEqual(denyFilters[0].filterType, .deny)
        XCTAssertEqual(denyFilters[0].messageFolder, .junk)
        XCTAssertEqual(allowFilters[0].text, "2")
        XCTAssertEqual(allowFilters[0].filterType, .allow)
        XCTAssertEqual(allowFilters[1].text, "3")
        XCTAssertEqual(allowFilters[1].filterType, .allow)
    }
    
    
    func test_fetchAutomaticFiltersLanguageRecords() {
        // Prepare
        let lang1 = AutomaticFiltersLanguage(context: self.testSubject.context)
        lang1.lang = NLLanguage.hebrew.rawValue
        lang1.isActive = false
        
        let lang2 = AutomaticFiltersLanguage(context: self.testSubject.context)
        lang2.lang = NLLanguage.english.rawValue
        lang2.isActive = false
        
        // Act
        let languages = self.testSubject.fetchAutomaticFiltersLanguageRecords()
        
        // Verify
        XCTAssertEqual(languages.count, 2)
        XCTAssertEqual(languages[0].lang, NLLanguage.english.rawValue)
        XCTAssertFalse(languages[0].isActive)
        XCTAssertEqual(languages[1].lang, NLLanguage.hebrew.rawValue)
        XCTAssertFalse(languages[1].isActive)
    }
    
    func test_fetchAutomaticFiltersRuleRecords() {
        // Prepare
        let rule1 = AutomaticFiltersRule(context: self.testSubject.context)
        rule1.ruleId = SmartFilterType.links.rawValue
        rule1.isActive = false
        
        let rule2 = AutomaticFiltersRule(context: self.testSubject.context)
        rule2.ruleId = SmartFilterType.shortSender.rawValue
        rule2.isActive = false

        // Act
        let rules = self.testSubject.fetchAutomaticFiltersRuleRecords()

        // Verify
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules[0].smartFilterType, .links)
        XCTAssertEqual(rules[1].smartFilterType, .shortSender)
    }
    
    func test_fetchFilterListsCacheRecords() {
        // Prepare
        let cacheAge = Date()
        let data = self.filterListsCache(records: [self.record(text: "word")]).encoded

        let existingCache = FilterListsCache(context: self.testSubject.context)
        existingCache.uuid = UUID()
        existingCache.data = data
        existingCache.age = cacheAge

        // Act
        let cache = self.testSubject.fetchFilterListsCacheRecords()

        // Verify
        XCTAssertEqual(cache.count, 1)
        XCTAssertEqual(cache[0].data, data)
        XCTAssertEqual(cache[0].age, cacheAge)
    }
    
    func test_fetchAutomaticFiltersLanguageRecord() {
        // Prepare
        let supported = AutomaticFiltersLanguage(context: self.testSubject.context)
        supported.lang = NLLanguage.hebrew.rawValue
        supported.isActive = false
        
        // Act
        let hebrew = self.testSubject.fetchAutomaticFiltersLanguageRecord(for: .hebrew)
        let english = self.testSubject.fetchAutomaticFiltersLanguageRecord(for: .english)
        
        // Verify
        XCTAssertFalse(hebrew?.isActive ?? true)
        XCTAssertEqual(hebrew?.lang, NLLanguage.hebrew.rawValue)
        XCTAssertFalse(hebrew?.isActive ?? true)
        XCTAssertNil(english)
    }
    
    func test_fetchAutomaticFiltersRuleRecord() {
        // Prepare
        let supported = AutomaticFiltersRule(context: self.testSubject.context)
        supported.ruleId = SmartFilterType.links.rawValue
        supported.isActive = false
        
        // Act
        let links = self.testSubject.fetchAutomaticFiltersRuleRecord(for: .links)
        let shortSender = self.testSubject.fetchAutomaticFiltersRuleRecord(for: .shortSender)
        
        // Verify
        XCTAssertFalse(links?.isActive ?? true)
        XCTAssertEqual(links?.ruleId, SmartFilterType.links.rawValue)
        XCTAssertNil(shortSender)
    }
    
    func test_isDuplicateFilter() {
        // Prepare
        let filterName = "filterName"
        var isDuplicateFilter = true
        
        // Act
        isDuplicateFilter = self.testSubject.isDuplicateFilter(text: filterName, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        
        // Verify
        XCTAssertFalse(isDuplicateFilter)
        
        // Prepare
        self.testSubject.addFilter(text: filterName, type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        
        // Act
        isDuplicateFilter = self.testSubject.isDuplicateFilter(text: filterName, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        
        // Verify
        XCTAssertTrue(isDuplicateFilter)
    }
    
    func test_addFilter_deny() {
        // Prepare
        let filterName = "filterName"
        self.expectingSaveContext()

        // Execute
        self.testSubject.addFilter(text: filterName, type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(self.testSubject.isDuplicateFilter(text: filterName, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive))
    }
    
    func test_addFilter_allow() {
        // Prepare
        let filterName = "filterName"
        self.expectingSaveContext()

        // Act
        self.testSubject.addFilter(text: filterName, type: .allow, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)

        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(self.testSubject.isDuplicateFilter(text: filterName, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive))
    }
    
    func test_deleteFiltersWithOffsets() {
        // Prepare
        self.testSubject.addFilter(text: "1", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.testSubject.addFilter(text: "2", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.testSubject.addFilter(text: "3", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        let filters = self.testSubject.fetchFilterRecords()
        let indexSetToDelete = IndexSet(arrayLiteral: 0, 2)
        self.expectingSaveContext()
        
        // Act
        self.testSubject.deleteFilters(withOffsets: indexSetToDelete, in: filters)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(self.testSubject.isDuplicateFilter(text: "1", filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive) == false)
        XCTAssert(self.testSubject.isDuplicateFilter(text: "2", filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive) == true)
        XCTAssert(self.testSubject.isDuplicateFilter(text: "3", filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive) == false)
    }
    
    func test_deleteFiltersSet() {
        // Prepare
        self.testSubject.addFilter(text: "1", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.testSubject.addFilter(text: "2", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        let filters = self.testSubject.fetchFilterRecords()
        let setToDelete: Set<Filter> = Set(arrayLiteral: filters[0], filters[1])
        self.testSubject.addFilter(text: "3", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.expectingSaveContext()
        
        // Act
        self.testSubject.deleteFilters(setToDelete)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(self.testSubject.isDuplicateFilter(text: "1", filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive) == false)
        XCTAssert(self.testSubject.isDuplicateFilter(text: "2", filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive) == false)
        XCTAssert(self.testSubject.isDuplicateFilter(text: "3", filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive) == true)
    }

    
    func test_updateFilter() {
        // Prepare
        self.testSubject.addFilter(text: "1", type: .deny, denyFolder: .junk, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        let filter = self.testSubject.fetchFilterRecords().first!
        self.expectingSaveContext()
        
        // Act
        self.testSubject.updateFilter(filter, denyFolder: .promotion)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        let updatedFilter = self.testSubject.fetchFilterRecords().first!
        XCTAssert(updatedFilter.messageFolder == .promotion)
    }

    func test_saveCache_filterLists() throws {
        // Prepare
        let oldDate = Date(timeIntervalSince1970: 0)
        for _ in 0..<2 {
            let existingCache = FilterListsCache(context: self.testSubject.context)
            existingCache.uuid = UUID()
            existingCache.data = self.filterListsCache(records: [self.record(text: "old")]).encoded
            existingCache.age = oldDate
        }
        let legacyCache = self.insertLegacyCache(age: oldDate)
        let cache = self.filterListsCache(records: [self.record(text: "spam")])

        self.expectingSaveContext()

        // Act
        let saved = self.testSubject.saveCache(cache)

        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        let rows = try self.testSubject.context.fetch(FilterListsCache.fetchRequest())
        let legacyRows = try self.testSubject.context.fetch(AutomaticFiltersCache.fetchRequest())
        XCTAssertTrue(saved)
        XCTAssertEqual(rows.count, 1)
        XCTAssertNotNil(rows.first?.uuid)
        XCTAssert(rows.first?.age ?? oldDate > oldDate)
        XCTAssertEqual(self.testSubject.cachedFilterLists(), cache)
        XCTAssertEqual(legacyRows, [legacyCache], "the 3.2 row belongs to 3.2 devices")
        XCTAssertEqual(legacyCache.filtersData, self.legacyFiltersData)
        XCTAssertEqual(legacyCache.age, oldDate)
    }

    func test_saveCache_keepsRecordsAsDownloaded() {
        // Prepare
        let cache = self.filterListsCache(records: [self.record(text: "spam"),
                                                    self.record(text: "spam", folder: "inbox"),
                                                    self.record(text: "(unclosed", matching: "regex", caseSensitivity: nil)])

        // Act
        _ = self.testSubject.saveCache(cache)

        // Verify
        XCTAssertEqual(self.testSubject.cachedFilterLists(), cache)
    }

    func test_cachedFilterLists_noCache() {
        XCTAssertNil(self.testSubject.cachedFilterLists())
    }

    func test_cachedFilterLists_onlyLegacyCache_readsItConverted() {
        // Prepare
        _ = self.insertLegacyCache(age: Date())

        // Act
        let cache = self.testSubject.cachedFilterLists()

        // Verify
        XCTAssertEqual(cache, FilterListsSnapshot(legacyEncoded: self.legacyFiltersData))
        XCTAssertEqual(cache?.catalog.lists.map(\.language), ["en"])
    }

    func test_cachedFilterLists_newCacheWinsOverLegacy() {
        // Prepare
        _ = self.insertLegacyCache(age: Date())
        let cache = self.filterListsCache(records: [self.record(text: "spam")])
        _ = self.testSubject.saveCache(cache)

        // Act + Verify
        XCTAssertEqual(self.testSubject.cachedFilterLists(), cache)
    }

    func test_cachedFilterListCatalog() {
        // Prepare
        let cache = self.filterListsCache(records: [self.record(text: "spam")])
        _ = self.testSubject.saveCache(cache)

        // Act
        let catalog = self.testSubject.cachedFilterListCatalog()

        // Verify
        XCTAssertEqual(catalog, cache.catalog)
    }

    func test_cachedFilterListCatalog_onlyLegacyCache_readsItConverted() {
        // Prepare
        _ = self.insertLegacyCache(age: Date())

        // Act
        let catalog = self.testSubject.cachedFilterListCatalog()

        // Verify
        XCTAssertEqual(catalog?.lists.map(\.language), ["en"])
    }

    func test_touchCache() {
        // Prepare
        let oldDate = Date(timeIntervalSince1970: 0)
        let cache = self.filterListsCache(records: [self.record(text: "spam")])
        _ = self.testSubject.saveCache(cache)
        let cacheRecord = self.testSubject.fetchFilterListsCacheRecords().first
        cacheRecord?.age = oldDate
        let legacyCache = self.insertLegacyCache(age: oldDate)

        self.expectingSaveContext()

        // Act
        self.testSubject.touchCache()

        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(cacheRecord?.age ?? oldDate > oldDate)
        XCTAssertEqual(self.testSubject.cachedFilterLists(), cache)
        XCTAssertEqual(legacyCache.age, oldDate, "the 3.2 row belongs to 3.2 devices")
    }

    func test_selectedCountries_roundTrip() {
        // Prepare + Act
        self.expectingSaveContext()
        self.testSubject.setSelectedCountries(["+972", "+1"], for: .countryAllowlist)

        // Verify save happened
        self.waitForExpectations(timeout: 1, handler: nil)

        // Verify round-trip (order-independent)
        let result = self.testSubject.selectedCountries(for: .countryAllowlist)
        XCTAssertEqual(Set(result), Set(["+972", "+1"]))
    }

    func test_selectedCountries_emptyWhenNoRule() {
        // No rule record exists for countryAllowlist
        let result = self.testSubject.selectedCountries(for: .countryAllowlist)
        XCTAssertTrue(result.isEmpty)
    }

    func test_setSelectedCountries_overwritesPrevious() {
        // Prepare
        self.testSubject.setSelectedCountries(["+972", "+1"], for: .countryAllowlist)

        self.expectingSaveContext()

        // Act
        self.testSubject.setSelectedCountries(["+44"], for: .countryAllowlist)

        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        let result = self.testSubject.selectedCountries(for: .countryAllowlist)
        XCTAssertEqual(result, ["+44"])
    }

    // MARK: Private Variables and Helpers
    private var testSubject: PersistenceManagerProtocol = PersistenceManager(inMemory: true)
    private var saveNotificationCompleteHandler: ((Notification)->())?
    private let legacyFiltersData = "eyJmaWx0ZXJfbGlzdHMiOnsiZW4iOnsiYWxsb3dfYm9keSI6WyJ5b3VyIGNvZGUiXSwiYWxsb3dfc2VuZGVyIjpbIkFtYmVyLklUIl0sImRlbnlfYm9keSI6WyJDbGFpbSBub3ciXSwiZGVueV9zZW5kZXIiOlsiU3BhbUNvIl19fX0="

    private func waitForSavedNotification(completeHandler: @escaping ((Notification)->()) ) {
        self.saveNotificationCompleteHandler = completeHandler
    }
    
    private func expectingSaveContext() {
        let expectASave = self.expectation(description: "expectASave")

        self.waitForSavedNotification { (notification) in
            expectASave.fulfill()
        }
    }
    
    private func record(text: String,
                        folder: String = "junk",
                        matching: String = "contains",
                        caseSensitivity: String? = "insensitive") -> FilterExportRecord {
        return FilterExportRecord(text: text,
                                  type: "deny",
                                  folder: folder,
                                  target: "all",
                                  matching: matching,
                                  caseSensitivity: caseSensitivity)
    }

    private func insertLegacyCache(age: Date) -> AutomaticFiltersCache {
        let legacyCache = AutomaticFiltersCache(context: self.testSubject.context)
        legacyCache.uuid = UUID()
        legacyCache.filtersData = self.legacyFiltersData
        legacyCache.age = age
        return legacyCache
    }

    private func filterListsCache(records: [FilterExportRecord]) -> FilterListsSnapshot {
        let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                          version: FilterExportPayload.currentVersion,
                                          exportedAt: Date(timeIntervalSince1970: 1_800_000_000),
                                          appVersion: "3.3.0",
                                          name: "Hebrew",
                                          revision: 1,
                                          filters: records,
                                          forceClearBeforeImport: nil)
        let entry = FilterListCatalogEntry(id: "ai-he",
                                           name: "Hebrew",
                                           url: "he.sfsfilters",
                                           language: "he")
        let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                version: FilterListCatalogResponse.currentVersion,
                                                lists: [entry])
        let section = FilterListsCacheSection(url: "https://example.com/he.sfsfilters",
                                              etag: "he-etag",
                                              payload: payload)
        return FilterListsSnapshot(catalogETag: "catalog-etag",
                                catalog: catalog,
                                lists: [section])
    }

    private func flushEntity(name: String) {
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let objs = try! self.testSubject.context.fetch(fetchRequest)
        
        for case let obj as NSManagedObject in objs {
            self.testSubject.context.delete(obj)
        }
    }
    
    private func flushPersistenceManager() {
        self.flushEntity(name: "Filter")
        self.flushEntity(name: "AutomaticFiltersCache")
        self.flushEntity(name: "FilterListsCache")
        self.flushEntity(name: "AutomaticFiltersLanguage")
        self.flushEntity(name: "AutomaticFiltersRule")
        
        do {
            try self.testSubject.context.save()
        } catch {
            XCTAssert(false, "flushPersistenceManager failed")
        }
    }
    
    @objc func contextSaved(notification: Notification) {
        self.saveNotificationCompleteHandler?(notification)
    }
}
