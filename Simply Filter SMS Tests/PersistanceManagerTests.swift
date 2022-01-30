//
//  mock_PersistanceManager.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 28/01/2022.
//

import Foundation
import XCTest
import CoreData
import NaturalLanguage
@testable import Simply_Filter_SMS

class PersistanceManagerTests: XCTestCase {
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        
        NotificationCenter.default.addObserver(self,
                                                selector: #selector(contextSaved(notification:)),
                                                name: NSNotification.Name.NSManagedObjectContextDidSave ,
                                                object: nil )
        
        self.persistanceManager = PersistanceManager(inMemory: true)
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.saveNotificationCompleteHandler = nil
        self.flushPersistanceManager()
    }
    
    
    //MARK: Tests
    
    func test_fetchFilterRecords() {
        // Prepare
        self.persistanceManager.addFilter(text: "1", type: .deny, denyFolder: .junk)
        self.persistanceManager.addFilter(text: "2", type: .allow, denyFolder: .junk)
        
        // Act
        let filters = self.persistanceManager.fetchFilterRecords()
        
        // Verify
        XCTAssertEqual(filters.count, 2)
        XCTAssertEqual(filters[1].text, "1")
        XCTAssertEqual(filters[1].filterType, .deny)
        XCTAssertEqual(filters[1].denyFolderType, .junk)
        XCTAssertEqual(filters[0].text, "2")
        XCTAssertEqual(filters[0].filterType, .allow)
    }
    
    
    func test_fetchAutomaticFiltersLanguageRecords() {
        // Prepare
        self.persistanceManager.initAutomaticFiltering(languages: [.hebrew, .english], rules: [])
        
        // Act
        let languages = self.persistanceManager.fetchAutomaticFiltersLanguageRecords()
        
        // Verify
        XCTAssertEqual(languages.count, 2)
        XCTAssertEqual(languages[0].lang, NLLanguage.english.rawValue)
        XCTAssertFalse(languages[0].isActive)
        XCTAssertEqual(languages[1].lang, NLLanguage.hebrew.rawValue)
        XCTAssertFalse(languages[1].isActive)
    }
    
    func test_fetchAutomaticFiltersRuleRecords() {
        // Prepare
        self.persistanceManager.initAutomaticFiltering(languages: [], rules: [.shortSender, .links])

        // Act
        let rules = self.persistanceManager.fetchAutomaticFiltersRuleRecords()

        // Verify
        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(rules[0].ruleType, .links)
        XCTAssertEqual(rules[1].ruleType, .shortSender)
    }
    
    func test_fetchAutomaticFiltersCacheRecords() {
        // Prepare
        let cacheAge = Date()
        let filtersList = AutomaticFilterList(filterList: ["he" : ["word"]])
        
        let existingCache = AutomaticFiltersCache(context: self.persistanceManager.context)
        existingCache.uuid = UUID()
        existingCache.hashed = filtersList.hashed
        existingCache.filtersData = filtersList.encoded
        existingCache.age = cacheAge

        // Act
        let cache = self.persistanceManager.fetchAutomaticFiltersCacheRecords()

        // Verify
        XCTAssertEqual(cache.count, 1)
        XCTAssertEqual(cache[0].hashed, filtersList.hashed)
        XCTAssertEqual(cache[0].filtersData, filtersList.encoded)
        XCTAssertEqual(cache[0].age, cacheAge)
    }
    
    func test_fetchAutomaticFiltersLanguageRecord() {
        // Prepare
        self.persistanceManager.initAutomaticFiltering(languages: [.hebrew], rules: [])
        
        // Act
        let hebrew = self.persistanceManager.fetchAutomaticFiltersLanguageRecord(for: .hebrew)
        let english = self.persistanceManager.fetchAutomaticFiltersLanguageRecord(for: .english)
        
        // Verify
        XCTAssertFalse(hebrew?.isActive ?? true)
        XCTAssertEqual(hebrew?.lang, NLLanguage.hebrew.rawValue)
        XCTAssertFalse(hebrew?.isActive ?? true)
        XCTAssertNil(english)
    }
    
    func test_fetchAutomaticFiltersRuleRecord() {
        // Prepare
        self.persistanceManager.initAutomaticFiltering(languages: [], rules: [.links])
        
        // Act
        let links = self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: .links)
        let shortSender = self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: .shortSender)
        
        // Verify
        XCTAssertFalse(links?.isActive ?? true)
        XCTAssertEqual(links?.ruleId, RuleType.links.rawValue)
        XCTAssertNil(shortSender)
    }
    
    func test_initAutomaticFiltering_languages() {
        // Prepare
        let unsupportedLanguage = NLLanguage.german
        let context = self.persistanceManager.context
        let unsupported = AutomaticFiltersLanguage(context: context)
        unsupported.lang = unsupportedLanguage.rawValue
        unsupported.isActive = true
        
        let supported = AutomaticFiltersLanguage(context: context)
        supported.lang = NLLanguage.hebrew.rawValue
        supported.isActive = true
        
        self.expectingSaveContext()
        
        // Act
        self.persistanceManager.initAutomaticFiltering(languages: [.hebrew, .english], rules: [])
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertNil(self.persistanceManager.fetchAutomaticFiltersLanguageRecord(for: .german))
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersLanguageRecord(for: .hebrew)?.lang, NLLanguage.hebrew.rawValue)
        
        let languages = try? self.persistanceManager.context.fetch(AutomaticFiltersLanguage.fetchRequest())
        XCTAssertEqual(languages?.count, 2)
        
        let unsupportedLanguageFetch = AutomaticFiltersLanguage.fetchRequest()
        unsupportedLanguageFetch.predicate = NSPredicate(format: "lang == %@", unsupportedLanguage.rawValue)
        let result = try? self.persistanceManager.context.fetch(unsupportedLanguageFetch)
        XCTAssertTrue(result?.isEmpty ?? false)
    }
    
    func test_initAutomaticFiltering_rules() {
        // Prepare
        let unsupportedRuleId = Int64(1000)
        let context = self.persistanceManager.context
        let unsupported = AutomaticFiltersRule(context: context)
        unsupported.ruleId = unsupportedRuleId
        unsupported.isActive = true
        
        let supported = AutomaticFiltersRule(context: context)
        supported.ruleId = RuleType.links.rawValue
        supported.isActive = true
        
        self.expectingSaveContext()
        
        // Act
        self.persistanceManager.initAutomaticFiltering(languages: [], rules: [.links, .numbersOnly])
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: .links)?.ruleId, supported.ruleId)
        XCTAssertTrue(self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: .links)?.isActive ?? false)
        
        let rules = try? self.persistanceManager.context.fetch(AutomaticFiltersRule.fetchRequest())
        XCTAssertEqual(rules?.count, 2)
        
        let unsupportedRuleFetch = AutomaticFiltersRule.fetchRequest()
        unsupportedRuleFetch.predicate = NSPredicate(format: "ruleId == %ld", unsupportedRuleId)
        let result = try? self.persistanceManager.context.fetch(unsupportedRuleFetch)
        XCTAssertTrue(result?.isEmpty ?? false)
    }
    
    func test_isDuplicateFilter() {
        // Prepare
        let filterName = "filterName"
        var isDuplicateFilter = true
        
        // Act
        isDuplicateFilter = self.persistanceManager.isDuplicateFilter(text: filterName)
        
        // Verify
        XCTAssertFalse(isDuplicateFilter)
        
        // Prepare
        self.persistanceManager.addFilter(text: filterName, type: .deny, denyFolder: .junk)
        
        // Act
        isDuplicateFilter = self.persistanceManager.isDuplicateFilter(text: filterName)
        
        // Verify
        XCTAssertTrue(isDuplicateFilter)
    }
    
    func test_addFilter_deny() {
        // Prepare
        let filterName = "filterName"
        self.expectingSaveContext()

        // Execute
        self.persistanceManager.addFilter(text: filterName, type: .deny, denyFolder: .junk)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(self.persistanceManager.isDuplicateFilter(text: filterName))
    }
    
    func test_addFilter_allow() {
        // Prepare
        let filterName = "filterName"
        self.expectingSaveContext()

        // Act
        self.persistanceManager.addFilter(text: filterName, type: .allow, denyFolder: .junk)

        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(self.persistanceManager.isDuplicateFilter(text: filterName))
    }
    
    func test_deleteFiltersWithOffsets() {
        // Prepare
        self.persistanceManager.addFilter(text: "1", type: .deny, denyFolder: .junk)
        self.persistanceManager.addFilter(text: "2", type: .deny, denyFolder: .junk)
        self.persistanceManager.addFilter(text: "3", type: .deny, denyFolder: .junk)
        let filters = self.persistanceManager.fetchFilterRecords()
        let indexSetToDelete = IndexSet(arrayLiteral: 0, 2)
        self.expectingSaveContext()
        
        // Act
        self.persistanceManager.deleteFilters(withOffsets: indexSetToDelete, in: filters)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(self.persistanceManager.isDuplicateFilter(text: "1") == false)
        XCTAssert(self.persistanceManager.isDuplicateFilter(text: "2") == true)
        XCTAssert(self.persistanceManager.isDuplicateFilter(text: "3") == false)
    }
    
    func test_deleteFiltersSet() {
        // Prepare
        self.persistanceManager.addFilter(text: "1", type: .deny, denyFolder: .junk)
        self.persistanceManager.addFilter(text: "2", type: .deny, denyFolder: .junk)
        let filters = self.persistanceManager.fetchFilterRecords()
        let setToDelete: Set<Filter> = Set(arrayLiteral: filters[0], filters[1])
        self.persistanceManager.addFilter(text: "3", type: .deny, denyFolder: .junk)
        self.expectingSaveContext()
        
        // Act
        self.persistanceManager.deleteFilters(setToDelete)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssert(self.persistanceManager.isDuplicateFilter(text: "1") == false)
        XCTAssert(self.persistanceManager.isDuplicateFilter(text: "2") == false)
        XCTAssert(self.persistanceManager.isDuplicateFilter(text: "3") == true)
    }

    
    func test_updateFilter() {
        // Prepare
        self.persistanceManager.addFilter(text: "1", type: .deny, denyFolder: .junk)
        let filter = self.persistanceManager.fetchFilterRecords().first!
        self.expectingSaveContext()
        
        // Act
        self.persistanceManager.updateFilter(filter, denyFolder: .promotion)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        let updatedFilter = self.persistanceManager.fetchFilterRecords().first!
        XCTAssert(updatedFilter.denyFolderType == .promotion)
    }

    func test_saveCache() {
        // Prepare
        let filtersList = AutomaticFilterList(filterList: ["he" : ["word"]])
        let newerfiltersList = AutomaticFilterList(filterList: ["he" : ["word", "word2"]])
        let oldDate = Date()
        
        let existingCache = AutomaticFiltersCache(context: self.persistanceManager.context)
        existingCache.uuid = UUID()
        existingCache.hashed = filtersList.hashed
        existingCache.filtersData = filtersList.encoded
        existingCache.age = oldDate
        
        self.expectingSaveContext()
        
        // Act
        self.persistanceManager.saveCache(with: newerfiltersList)
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        
        let newCache = try? self.persistanceManager.context.fetch(AutomaticFiltersCache.fetchRequest()).first
        
        XCTAssertEqual(newCache?.filtersData, newerfiltersList.encoded)
        XCTAssertEqual(newCache?.hashed, newerfiltersList.hashed)
        XCTAssert(newCache?.age ?? oldDate > oldDate)
    }
    
    func test_isCacheStale() {
        // Prepare
        let filtersList = AutomaticFilterList(filterList: ["he" : ["word"]])
        let filtersList_same = AutomaticFilterList(filterList: ["he" : ["word"]])
        let filtersList_diff = AutomaticFilterList(filterList: ["he" : ["word", "word2"]])
        let oldDate = Date()
        let existingCache = AutomaticFiltersCache(context: self.persistanceManager.context)
        existingCache.uuid = UUID()
        existingCache.hashed = filtersList.hashed
        existingCache.filtersData = filtersList.encoded
        existingCache.age = oldDate
        
        // Act
        let expectFalse = self.persistanceManager.isCacheStale(comparedTo: filtersList_same)
        let expectTrue = self.persistanceManager.isCacheStale(comparedTo: filtersList_diff)
        
        // Verify
        XCTAssertFalse(expectFalse)
        XCTAssertTrue(expectTrue)
    }
    
    
    // MARK: Private Variables and Helpers
    private var persistanceManager: PersistanceManagerProtocol = PersistanceManager(inMemory: true)
    private var saveNotificationCompleteHandler: ((Notification)->())?

    private func waitForSavedNotification(completeHandler: @escaping ((Notification)->()) ) {
        self.saveNotificationCompleteHandler = completeHandler
    }
    
    private func expectingSaveContext() {
        let expectASave = self.expectation(description: "expectASave")

        self.waitForSavedNotification { (notification) in
            expectASave.fulfill()
        }
    }
    private func flushEntity(name: String) {
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let objs = try! self.persistanceManager.context.fetch(fetchRequest)
        
        for case let obj as NSManagedObject in objs {
            self.persistanceManager.context.delete(obj)
        }
    }
    private func flushPersistanceManager() {
        self.flushEntity(name: "Filter")
        self.flushEntity(name: "AutomaticFiltersCache")
        self.flushEntity(name: "AutomaticFiltersLanguage")
        
        do {
            try self.persistanceManager.context.save()
        } catch {
            XCTAssert(false, "flushPersistanceManager failed")
        }
        
    }
    
    @objc func contextSaved(notification: Notification) {
        self.saveNotificationCompleteHandler?(notification)
    }
}



#warning("Adi - Move to AppFilterManagerTests.")
//    func test_languagesForBlockLanguage() {
//        // Prepare
//        let supportedLanguagesForBlocking = NLLanguage.allSupportedCases
//        var availableLanguagesForBlocikng: [NLLanguage] = []
//
//        // Act
//        availableLanguagesForBlocikng = self.persistanceManager.languages(for: .blockLanguage)
//
//        // Verify
//        XCTAssert(Set(supportedLanguagesForBlocking).isSubset(of: Set(availableLanguagesForBlocikng)))
//        XCTAssert(supportedLanguagesForBlocking.count == availableLanguagesForBlocikng.count)
//
//        // Prepare
//        self.persistanceManager.addFilter(text: NLLanguage.arabic.filterText, type: .denyLanguage, denyFolder: .junk)
//
//        // Act
//        availableLanguagesForBlocikng = self.persistanceManager.languages(for: .blockLanguage)
//
//        // Verify
//        XCTAssert(Set(availableLanguagesForBlocikng).isSubset(of: Set(supportedLanguagesForBlocking)))
//        XCTAssert(supportedLanguagesForBlocking.count-1 == availableLanguagesForBlocikng.count)
//
//    }
    
//    func test_languagesForAutomaticBlocking() {
//        // Prepare
//        let supportedLanguagesForAutomaticBlocking = [NLLanguage.english, .hebrew]
//        var availableLanguagesForAutomaticBlocking: [NLLanguage] = []
//
//        // Act
//        availableLanguagesForAutomaticBlocking = self.persistanceManager.languages(for: .automaticBlocking)
//
//        // Verify
//        XCTAssert(Set(supportedLanguagesForAutomaticBlocking).isSubset(of: Set(availableLanguagesForAutomaticBlocking)))
//        XCTAssert(supportedLanguagesForAutomaticBlocking.count == availableLanguagesForAutomaticBlocking.count)
//        XCTAssert(supportedLanguagesForAutomaticBlocking.first == availableLanguagesForAutomaticBlocking.first)
//    }
    
//    func test_isAutomaticFilteringOn() {
//        // Prepare
//        self.persistanceManager.initAutomaticFiltering()
//        var isAutomaticFilteringOn = true
//
//        // Act
//        isAutomaticFilteringOn = self.persistanceManager.isAutomaticFilteringOn
//
//        // Verify
//        XCTAssert(isAutomaticFilteringOn == false)
//
//        // Prepare
//
//        self.persistanceManager.setLanguageAtumaticState(for: .hebrew, value: true)
//
//        // Act
//        isAutomaticFilteringOn = self.persistanceManager.isAutomaticFilteringOn
//
//        // Verify
//        XCTAssert(isAutomaticFilteringOn == true)
//
//        // Prepare
//        self.persistanceManager.setLanguageAtumaticState(for: .hebrew, value: false)
//
//        // Act
//        isAutomaticFilteringOn = self.persistanceManager.isAutomaticFilteringOn
//
//        // Verify
//        XCTAssert(isAutomaticFilteringOn == false)
//    }
    
//    func test_automaticFiltersCacheAge() {
//        // Prepare
//        var automaticFiltersCacheAge: Date? = Date()
//
//        // Act
//        automaticFiltersCacheAge = self.persistanceManager.automaticFiltersCacheAge
//
//        // Verify
//        XCTAssert(automaticFiltersCacheAge == nil)
//
//        // Prepare
//        self.persistanceManager.saveCache(with: AutomaticFilterList(filterList: ["he": ["word"]]))
//
//        // Act
//        automaticFiltersCacheAge = self.persistanceManager.automaticFiltersCacheAge
//
//        // Verify
//        if let automaticFiltersCacheAge = automaticFiltersCacheAge {
//            print(abs(automaticFiltersCacheAge.timeIntervalSinceNow))
//            XCTAssert(abs(automaticFiltersCacheAge.timeIntervalSinceNow) < 1)
//        }
//        else {
//            XCTAssert(false, "automaticFiltersCacheAge is nil")
//        }
//    }
    
//    func test_activeAutomaticLanguages() {
//        // Prepare
//        self.persistanceManager.initAutomaticFiltering()
//        var activeAutomaticLanguages: String? = ""
//
//        // Act
//        activeAutomaticLanguages = self.persistanceManager.activeAutomaticLanguages
//
//        // Verify
//        XCTAssert(activeAutomaticLanguages == nil)
//
//        // Prepare
//        self.persistanceManager.setLanguageAtumaticState(for: .hebrew, value: true)
//        self.persistanceManager.setLanguageAtumaticState(for: .english, value: true)
//
//        // Act
//        activeAutomaticLanguages = self.persistanceManager.activeAutomaticLanguages
//
//        // Verify
//        XCTAssert(activeAutomaticLanguages == "\(NLLanguage.english.localizedName!), \(NLLanguage.hebrew.localizedName!).")
//
//        // Prepare
//        self.persistanceManager.setLanguageAtumaticState(for: .hebrew, value: false)
//
//        // Act
//        activeAutomaticLanguages = self.persistanceManager.activeAutomaticLanguages
//
//        // Verify
//        XCTAssert(activeAutomaticLanguages == NLLanguage.english.localizedName)
//    }
//    func test_initAutomaticFiltering() {
//        // Prepare
//        let unsupportedLanguage = NLLanguage.german
//        let context = self.persistanceManager.context
//        let unsupported = AutomaticFiltersLanguage(context: context)
//        unsupported.lang = unsupportedLanguage.rawValue
//        unsupported.isActive = true
//
//        let supported = AutomaticFiltersLanguage(context: context)
//        supported.lang = NLLanguage.hebrew.rawValue
//        supported.isActive = true
//
//        self.expectingSaveContext()
//
//        // Act
//        self.persistanceManager.initAutomaticFiltering()
//
//        // Verify
//        self.waitForExpectations(timeout: 1, handler: nil)
//        XCTAssert(self.persistanceManager.isAutomaticFilteringOn == true)
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .hebrew) == true)
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .english) == false)
//
//        let languages = try? self.persistanceManager.context.fetch(AutomaticFiltersLanguage.fetchRequest())
//        XCTAssert(languages?.count == 2)
//
//        let unsupportedLanguageFetch = AutomaticFiltersLanguage.fetchRequest()
//        unsupportedLanguageFetch.predicate = NSPredicate(format: "lang == %@", unsupportedLanguage.rawValue)
//        let result = try? self.persistanceManager.context.fetch(unsupportedLanguageFetch)
//        XCTAssert(result?.isEmpty == true)
//    }
    
//    func test_languageAutomaticState() {
//        // Prepare
//        let supported = AutomaticFiltersLanguage(context: self.persistanceManager.context)
//        supported.lang = NLLanguage.hebrew.rawValue
//        supported.isActive = true
//
//        self.persistanceManager.initAutomaticFiltering()
//
//        // Verify
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .english) == false)
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .hebrew) == true)
//    }
//
//    func test_setLanguageAtumaticState() {
//        // Prepare
//        self.persistanceManager.initAutomaticFiltering()
//        self.expectingSaveContext()
//
//        // Verify
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .english) == false)
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .hebrew) == false)
//
//        // Act
//        self.persistanceManager.setLanguageAtumaticState(for: .hebrew, value: true)
//        self.persistanceManager.setLanguageAtumaticState(for: .english, value: true)
//
//        // Verify
//        self.waitForExpectations(timeout: 1, handler: nil)
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .english) == true)
//        XCTAssert(self.persistanceManager.languageAutomaticState(for: .hebrew) == true)
//    }
