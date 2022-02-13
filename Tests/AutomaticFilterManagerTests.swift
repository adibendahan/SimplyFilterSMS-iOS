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
    var amazonS3Service = mock_AmazonS3Service()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        
        self.testSubject = AutomaticFilterManager(persistanceManager: self.persistanceManager,
                                                  amazonS3Service: self.amazonS3Service)
        self.persistanceManager.resetCounters()
        self.amazonS3Service.resetCounters()
    }
    
    override func tearDown() {
        super.tearDown()

        self.persistanceManager = mock_PersistanceManager()
        self.amazonS3Service = mock_AmazonS3Service()
    }
    
    
    //MARK: Tests
    func test_isAutomaticFilteringOn_on() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let response = AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.filtersData = response.hashed
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()
            cacheRecord.filtersData = response.encoded
            
            return [cacheRecord]
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
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersCacheRecordsCounter, 1)
    }
    
    func test_isAutomaticFilteringOn_off() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let response = AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.filtersData = response.hashed
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()
            cacheRecord.filtersData = response.encoded
            
            return [cacheRecord]
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
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersCacheRecordsCounter, 1)
    }
    
    func test_activeAutomaticFiltersTitle_twoLanguages() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let response = AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: []), "en" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.filtersData = response.hashed
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()
            cacheRecord.filtersData = response.encoded
            
            return [cacheRecord]
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
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersCacheRecordsCounter, 1)
    }
    
    func test_activeAutomaticFiltersTitle_off() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let response = AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: []), "en" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.filtersData = response.hashed
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()
            cacheRecord.filtersData = response.encoded
            
            return [cacheRecord]
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
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersCacheRecordsCounter, 1)
    }
    
    func test_automaticFiltersCacheAge() {
        // Prepare
        let expectedCacheAge = Date()
        
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {
            let response = AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: []), "en" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.filtersData = response.hashed
            cacheRecord.uuid = UUID()
            cacheRecord.age = expectedCacheAge
            cacheRecord.filtersData = response.encoded
            
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
        XCTAssertEqual(fullResult[0].rawValue, NLLanguage.arabic.rawValue)
        XCTAssertEqual(self.persistanceManager.isDuplicateFilterLanguageCounter, NLLanguage.allSupportedCases.count * 2)
    }
    
    func test_languagesForAutomaticBlocking() {
        // Prepare
        let response = AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: []), "en" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
        
        self.persistanceManager.fetchAutomaticFiltersCacheRecordsClosure = {

            let cacheRecord = AutomaticFiltersCache(context: self.persistanceManager.context)
            cacheRecord.filtersData = response.hashed
            cacheRecord.uuid = UUID()
            cacheRecord.age = Date()
            cacheRecord.filtersData = response.encoded
            
            return [cacheRecord]
        }
        
        // Act
        let languagesResult = self.testSubject.languages(for: .automaticBlocking)
        
        // Verify
        XCTAssertEqual(languagesResult.count, response.filterLists.count)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersCacheRecordsCounter, 1)
    }
    
    func test_languageAutomaticState() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersLanguageRecordClosure = { language in
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
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersLanguageRecordCounter, 2)
    }
    
    func test_setLanguageAtumaticState() {
        // Act
        self.testSubject.setLanguageAutmaticState(for: .english, value: true)
        
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
    
    func test_forceUpdateAutomaticFilters() {
        // Prepare
        let expectation = self.expectation(description: "URLRequest")
        self.amazonS3Service.fetchAutomaticFiltersClosure = {
            return AutomaticFilterListsResponse(filterLists: ["he" : LanguageFilterListResponse(allowSenders: [], allowBody: [], denySender: [], denyBody: [])])
        }
        
        
        // Act
        Task (priority: .userInitiated) {
            let _ = await self.testSubject.forceUpdateAutomaticFilters()
            expectation.fulfill()
        }
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.persistanceManager.saveCacheCounter, 1)

    }
    
    private var testSubject: AutomaticFilterManagerProtocol = AutomaticFilterManager(persistanceManager: mock_PersistanceManager())
}
