//
//  MessageEvaluationManagerTests.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import Foundation
import XCTest
import CoreData
import NaturalLanguage
import IdentityLookup
@testable import Simply_Filter_SMS

class MessageEvaluationManagerTests: XCTestCase {
    
    struct MessageTestCase {
        let sender: String
        let body: String
        let expectedAction: ILMessageFilterAction
    }
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        
        self.testSubject = MessageEvaluationManager(inMemory: true)
        self.loadTestingData()
    }
    
    override func tearDown() {
        super.tearDown()
        
        self.flushPersistanceManager()
    }
    
    
    //MARK: Tests
    func test_evaluateMessage() {
        struct MessageTestCase {
            let sender: String
            let body: String
            let expectedAction: ILMessageFilterAction
        }
        
        let testCases: [MessageTestCase] = [MessageTestCase(sender: "1234567", body: "מה המצב עדי?", expectedAction: .allow),
                                            MessageTestCase(sender: "1234567", body: "מה המצב עדי? רוצה לקנות weed?", expectedAction: .allow),
                                            MessageTestCase(sender: "1234567", body: "הלוואה חינם התקשר עכשיו", expectedAction: .promotion),
                                            MessageTestCase(sender: "1234567", body: "הודעה עם לינק http://123.com", expectedAction: .junk),
                                            MessageTestCase(sender: "1234567", body: "הודעה עם לינק http://adi.com", expectedAction: .allow),
                                            MessageTestCase(sender: "123", body: "מה המצב עדי?", expectedAction: .allow),
                                            MessageTestCase(sender: "123", body: "מה המצב?", expectedAction: .junk),
                                            MessageTestCase(sender: "text", body: "מה המצב?", expectedAction: .junk),
                                            MessageTestCase(sender: "text", body: "מה המצב עדי?", expectedAction: .allow),
                                            MessageTestCase(sender: "random@email.com", body: "מה המצב?", expectedAction: .junk),
                                            MessageTestCase(sender: "random@email.com", body: "מה המצב עדי?", expectedAction: .allow),
                                            MessageTestCase(sender: "1234567", body: "مح لزواره الكرام بتحويل الكتابة العربي الى", expectedAction: .junk),
                                            MessageTestCase(sender: "1234567", body: "עברית וערבית ביחד, הרוב בעברית العربي الى", expectedAction: .allow),
                                            MessageTestCase(sender: "1234567", body: "مح لزواره الكرام بتحويل الكتابة العربي الى עם עברית", expectedAction: .junk),
                                            MessageTestCase(sender: "", body: "asdasdasdasd", expectedAction: .junk),
                                            MessageTestCase(sender: "1234567", body: "סינון אוטומטי קורונה", expectedAction: .junk),
                                            MessageTestCase(sender: "1234567", body: "סינון אוטומטי spam", expectedAction: .allow),
                                            MessageTestCase(sender: "1234567", body: "htTp://", expectedAction: .junk)]
        
        for testCase in testCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender)
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
    }
    
    func test_evaluateMessage_allUnknownFilteringOn() {
        let automaticFilterRule = AutomaticFiltersRule(context: self.testSubject.context)
        automaticFilterRule.ruleId = RuleType.allUnknown.rawValue
        automaticFilterRule.isActive = true
        automaticFilterRule.selectedChoice = 0
        
        let testCases: [MessageTestCase] = [MessageTestCase(sender: "1234567", body: "עברית וערבית ביחד, הרוב בעברית العربي الى", expectedAction: .junk),
                                            MessageTestCase(sender: "1234567", body: "סינון אוטומטי spam", expectedAction: .junk)]
        
        for testCase in testCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender)
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
    }
    
    // MARK: Private Variables and Helpers
    private var testSubject: MessageEvaluationManagerProtocol = MessageEvaluationManager(inMemory: true)
    
    private func flushEntity(name: String) {
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest<NSFetchRequestResult>(entityName: name)
        let objs = try! self.testSubject.context.fetch(fetchRequest)
        
        for case let obj as NSManagedObject in objs {
            self.testSubject.context.delete(obj)
        }
    }
    
    private func flushPersistanceManager() {
        self.flushEntity(name: "Filter")
        self.flushEntity(name: "AutomaticFiltersCache")
        self.flushEntity(name: "AutomaticFiltersLanguage")
        self.flushEntity(name: "AutomaticFiltersRule")
        
        do {
            try self.testSubject.context.save()
        } catch {
            XCTAssert(false, "flushMessageEvaluationManager failed")
        }
    }
    
    private func loadTestingData() {
        struct AllowEntry {
            let text: String
            let folder: DenyFolderType
        }
        
        let _ = [AllowEntry(text: "נתניהו", folder: .junk),
                 AllowEntry(text: "הלוואה", folder: .promotion),
                 AllowEntry(text: "הימור", folder: .transaction),
                 AllowEntry(text: "גנץ", folder: .junk),
                 AllowEntry(text: "Weed", folder: .junk),
                 AllowEntry(text: "Bet", folder: .junk)].map { entry -> Filter in
            let newFilter = Filter(context: self.testSubject.context)
            newFilter.uuid = UUID()
            newFilter.filterType = .deny
            newFilter.denyFolderType = entry.folder
            newFilter.text = entry.text
            return newFilter
        }
        
        let _ = ["Adi", "דהאן", "דהן", "עדי"].map { allowText -> Filter in
            let newFilter = Filter(context: self.testSubject.context)
            newFilter.uuid = UUID()
            newFilter.filterType = .allow
            newFilter.text = allowText
            return newFilter
        }
        
        let langFilter = Filter(context: self.testSubject.context)
        langFilter.uuid = UUID()
        langFilter.filterType = .denyLanguage
        langFilter.text = NLLanguage.arabic.filterText
        
        for rule in RuleType.allCases {
            let automaticFilterRule = AutomaticFiltersRule(context: self.testSubject.context)
            automaticFilterRule.ruleId = rule.rawValue
            automaticFilterRule.isActive = rule != .allUnknown
            automaticFilterRule.selectedChoice = rule == .shortSender ? 5 : 0
        }
        
        let filtersList = AutomaticFilterList(filterList: [NLLanguage.hebrew.rawValue : ["קורונה", "חדשות"],
                                                           NLLanguage.english.rawValue : ["test1", "spam"]])
        let cache = AutomaticFiltersCache(context: self.testSubject.context)
        cache.uuid = UUID()
        cache.hashed = filtersList.hashed
        cache.filtersData = filtersList.encoded
        cache.age = Date()
        
        let automaticFiltersLanguageHE = AutomaticFiltersLanguage(context: self.testSubject.context)
        automaticFiltersLanguageHE.lang = NLLanguage.hebrew.rawValue
        automaticFiltersLanguageHE.isActive = true
        
        let automaticFiltersLanguageEN = AutomaticFiltersLanguage(context: self.testSubject.context)
        automaticFiltersLanguageEN.lang = NLLanguage.english.rawValue
        automaticFiltersLanguageEN.isActive = false

        try? self.testSubject.context.save()
    }
}
