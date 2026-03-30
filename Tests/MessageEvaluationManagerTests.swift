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
        let testCases: [MessageTestCase] = [
            MessageTestCase(sender: "1234567", body: "מה המצב עדי?", expectedAction: .allow),
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
            MessageTestCase(sender: "1234567", body: "htTp://link.com", expectedAction: .junk),
            MessageTestCase(sender: "1234567", body: "Bet", expectedAction: .transaction)
        ]
        
        for testCase in testCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender).action
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
    }
    
    func test_evaluateMessage_allUnknownFilteringOn() {
        let automaticFilterRule = AutomaticFiltersRule(context: self.testSubject.context)
        automaticFilterRule.ruleId = RuleType.allUnknown.rawValue
        automaticFilterRule.isActive = true
        automaticFilterRule.selectedChoice = 0
        
        let testCases: [MessageTestCase] = [
            MessageTestCase(sender: "1234567", body: "עברית וערבית ביחד, הרוב בעברית العربي الى", expectedAction: .junk),
            MessageTestCase(sender: "1234567", body: "סינון אוטומטי spam", expectedAction: .junk)
        ]
        
        for testCase in testCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender).action
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
    }
    
    func test_evaluateMessage_advanced() {
        self.flushPersistanceManager()
        
        let advancedFilter = Filter(context: self.testSubject.context)
        advancedFilter.filterMatching = .exact
        advancedFilter.filterTarget = .body
        advancedFilter.filterCase = .caseSensitive
        advancedFilter.text = "Discount"
        advancedFilter.denyFolderType = .transaction
        advancedFilter.filterType = .deny
        
        let advancedFilter2 = Filter(context: self.testSubject.context)
        advancedFilter2.filterMatching = .exact
        advancedFilter2.filterTarget = .sender
        advancedFilter2.filterCase = .caseInsensitive
        advancedFilter2.text = "Apple"
        advancedFilter2.filterType = .allow
        
        let advancedFilter3 = Filter(context: self.testSubject.context)
        advancedFilter3.filterMatching = .contains
        advancedFilter3.filterTarget = .sender
        advancedFilter3.filterCase = .caseSensitive
        advancedFilter3.text = "Wallmart"
        advancedFilter3.filterType = .allow
        
        
        let testCases: [MessageTestCase] = [
            MessageTestCase(sender: "1234567", body: "A message from @##43432@Discount2 Banks! Store", expectedAction: .transaction),
            MessageTestCase(sender: "1234567", body: "A message from @##4@1 Discount", expectedAction: .transaction),
            MessageTestCase(sender: "1234567", body: "A message from @##4@1 Discounted", expectedAction: .allow),
            MessageTestCase(sender: "1234567", body: "Discount", expectedAction: .transaction),
            MessageTestCase(sender: "1234567", body: "discount", expectedAction: .allow),
            MessageTestCase(sender: "Apple", body: "discount", expectedAction: .allow),
            MessageTestCase(sender: "Wallmart", body: "Discount", expectedAction: .allow),
            MessageTestCase(sender: "Wallmart Store", body: "Discount", expectedAction: .allow),
            MessageTestCase(sender: "Apple Store", body: "Discount", expectedAction: .allow),
            MessageTestCase(sender: "WallmarT Store", body: "Discount", expectedAction: .transaction)
        ]
        
        for testCase in testCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender).action
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
    }
    
    func test_evaluateMessage_automatic() {
        self.flushPersistanceManager()
        
        let automaticFilterLists = AutomaticFilterListsResponse(filterLists: [
            "he" : LanguageFilterListResponse(allowSenders: ["BituahLeumi", "Taasuka", "bit", "100", "ontopo"],
                                              allowBody: [],
                                              denySender: [],
                                              denyBody: ["הלוואה"])
        ])
        
        let cacheRecord = AutomaticFiltersCache(context: self.testSubject.context)
        cacheRecord.uuid = UUID()
        cacheRecord.filtersData = automaticFilterLists.encoded
        cacheRecord.hashed = automaticFilterLists.hashed
        cacheRecord.age = Date()
        
        let noLinks = AutomaticFiltersRule(context: self.testSubject.context)
        noLinks.isActive = true
        noLinks.ruleType = .links
        noLinks.selectedChoice = 0
        
        let numbersOnly = AutomaticFiltersRule(context: self.testSubject.context)
        numbersOnly.isActive = true
        numbersOnly.ruleType = .numbersOnly
        numbersOnly.selectedChoice = 0
        
        let noEmojis = AutomaticFiltersRule(context: self.testSubject.context)
        noEmojis.isActive = true
        noEmojis.ruleType = .emojis
        noEmojis.selectedChoice = 0
        
        let automaticFiltersLanguageHE = AutomaticFiltersLanguage(context: self.testSubject.context)
        automaticFiltersLanguageHE.lang = NLLanguage.hebrew.rawValue
        automaticFiltersLanguageHE.isActive = true
        
        try? self.testSubject.context.save()
        
        let testCases: [MessageTestCase] = [
            MessageTestCase(sender: "BituahLeumi", body: "בלה בלה בלה https://link.com", expectedAction: .allow),
            MessageTestCase(sender: "100", body: "בלה בלה בלה https://link.com", expectedAction: .allow),
            MessageTestCase(sender: "BituahLeumit", body: "בלה בלה בלה https://link.com", expectedAction: .junk),
            MessageTestCase(sender: "1000", body: "בלה בלה בלה https://link.com", expectedAction: .junk),
            MessageTestCase(sender: "bit", body: "הלוואה ולינק https://link.com", expectedAction: .allow),
            MessageTestCase(sender: "bit ", body: "הלוואה ולינק https://link.com", expectedAction: .junk),
            MessageTestCase(sender: "054123465", body: "bla bla btl.gov.il/asdasdf", expectedAction: .junk),
            MessageTestCase(sender: "054123465", body: "bla bla bit.ly/1224dsf4 bla", expectedAction: .junk),
            MessageTestCase(sender: "054123465", body: "bla bla adi@gmail.com bla", expectedAction: .allow),
            MessageTestCase(sender: "054123465", body: "bla bla 054-123456 bla", expectedAction: .allow),
            MessageTestCase(sender: "Taasuka", body: "bla bla btl.gov.il/asdasdf", expectedAction: .allow),
            MessageTestCase(sender: "Ontopo", body: "אנא אשרו הזמנתכם לשילה בקישור. tinyurl.com/ycq952f לחצו לצפייה", expectedAction: .allow),
            MessageTestCase(sender: "054123465", body: "bla bla 💀 bla", expectedAction: .junk)
        ]
        
        
        for testCase in testCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender).action
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
        
        numbersOnly.isActive = false
        noEmojis.isActive = false
        
        try? self.testSubject.context.save()
        
        let secondTestCases: [MessageTestCase] = [
            MessageTestCase(sender: "not a number", body: "אנא אשרו הזמנתכם לשילה בקישור.לחצו לצפייה", expectedAction: .allow),
            MessageTestCase(sender: "054123465", body: "bla bla 💀 bla", expectedAction: .allow)
        ]
        
        
        for testCase in secondTestCases {
            
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender).action
            
            XCTAssert(testCase.expectedAction == actualAction,
                      "sender \"\(testCase.sender)\", body \"\(testCase.body)\": \(testCase.expectedAction.debugName) != \(actualAction.debugName).")
        }
    }
    
    func test_evaluateMessage_countryAllowlist() {
        self.flushPersistanceManager()

        // Allow only Israel (+972)
        let allowedJSON = try! String(data: JSONEncoder().encode(["+972"]), encoding: .utf8)!
        let rule = AutomaticFiltersRule(context: self.testSubject.context)
        rule.ruleId = RuleType.countryAllowlist.rawValue
        rule.isActive = true
        rule.selectedChoice = 0
        rule.selectedCountries = allowedJSON
        try? self.testSubject.context.save()

        let testCases: [MessageTestCase] = [
            // Israeli number → in allowlist → allow
            MessageTestCase(sender: "+972-50-123-4567", body: "hello", expectedAction: .allow),
            // US number → not in allowlist → junk
            MessageTestCase(sender: "+1-800-555-1234", body: "hello", expectedAction: .junk),
            // No + prefix → rule skipped → allow
            MessageTestCase(sender: "0501234567", body: "hello", expectedAction: .allow),
        ]

        for testCase in testCases {
            let actualAction = self.testSubject.evaluateMessage(body: testCase.body, sender: testCase.sender).action
            XCTAssert(testCase.expectedAction == actualAction,
                      "countryAllowlist sender \"\(testCase.sender)\": expected \(testCase.expectedAction.debugName), got \(actualAction.debugName).")
        }
    }

    func test_evaluateMessage_countryAllowlist_emptyCountries_skipsRule() {
        self.flushPersistanceManager()

        // Rule active but no countries selected — should be skipped (allow)
        let rule = AutomaticFiltersRule(context: self.testSubject.context)
        rule.ruleId = RuleType.countryAllowlist.rawValue
        rule.isActive = true
        rule.selectedChoice = 0
        rule.selectedCountries = try! String(data: JSONEncoder().encode([String]()), encoding: .utf8)!
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "hello", sender: "+1-800-555-1234").action
        XCTAssertEqual(result, .allow, "countryAllowlist with empty countries list should skip the rule and allow")
    }

    func test_evaluateMessage_countryAllowlist_disabledRule_skipsRule() {
        self.flushPersistanceManager()

        // Rule exists but isActive = false — should be skipped (allow)
        let allowedJSON = try! String(data: JSONEncoder().encode(["+972"]), encoding: .utf8)!
        let rule = AutomaticFiltersRule(context: self.testSubject.context)
        rule.ruleId = RuleType.countryAllowlist.rawValue
        rule.isActive = false
        rule.selectedChoice = 0
        rule.selectedCountries = allowedJSON
        try? self.testSubject.context.save()

        // US number — would be blocked if rule were active, but rule is disabled
        let result = self.testSubject.evaluateMessage(body: "hello", sender: "+1-800-555-1234").action
        XCTAssertEqual(result, .allow, "countryAllowlist with isActive=false should skip the rule and allow")
    }

    // P1 allUnknown overrides P2 allow filters — even an explicit allow match must not escape allUnknown
    func test_priorityOrder_allUnknownBeatsAllowFilters() {
        self.flushPersistanceManager()

        let allowFilter = Filter(context: self.testSubject.context)
        allowFilter.filterType = .allow
        allowFilter.filterTarget = .body
        allowFilter.filterMatching = .contains
        allowFilter.filterCase = .caseInsensitive
        allowFilter.text = "hello"

        let allUnknown = AutomaticFiltersRule(context: self.testSubject.context)
        allUnknown.ruleId = RuleType.allUnknown.rawValue
        allUnknown.isActive = true
        allUnknown.selectedChoice = 0
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "hello world", sender: "1234567").action
        XCTAssertEqual(result, .junk, "allUnknown must override allow filters")
    }

    // P3 automatic allowSenders overrides P4 rules — trusted sender with a link must not be blocked by links rule
    func test_priorityOrder_automaticAllowSendersBeatsRules() {
        self.flushPersistanceManager()

        let filterLists = AutomaticFilterListsResponse(filterLists: [
            NLLanguage.hebrew.rawValue: LanguageFilterListResponse(allowSenders: ["BituahLeumi"],
                                                                   allowBody: [],
                                                                   denySender: [],
                                                                   denyBody: [])
        ])
        let cache = AutomaticFiltersCache(context: self.testSubject.context)
        cache.uuid = UUID()
        cache.filtersData = filterLists.encoded
        cache.hashed = filterLists.hashed
        cache.age = Date()

        let langRecord = AutomaticFiltersLanguage(context: self.testSubject.context)
        langRecord.lang = NLLanguage.hebrew.rawValue
        langRecord.isActive = true

        let linksRule = AutomaticFiltersRule(context: self.testSubject.context)
        linksRule.ruleId = RuleType.links.rawValue
        linksRule.isActive = true
        linksRule.selectedChoice = 0
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "check https://link.com", sender: "BituahLeumi").action
        XCTAssertEqual(result, .allow, "automatic allowSenders must override links rule")
    }

    // P3 automatic allowBody overrides P4 rules — trusted body phrase with a link must not be blocked by links rule
    func test_priorityOrder_automaticAllowBodyBeatsRules() {
        self.flushPersistanceManager()

        let filterLists = AutomaticFilterListsResponse(filterLists: [
            NLLanguage.hebrew.rawValue: LanguageFilterListResponse(allowSenders: [],
                                                                   allowBody: ["trusted phrase"],
                                                                   denySender: [],
                                                                   denyBody: [])
        ])
        let cache = AutomaticFiltersCache(context: self.testSubject.context)
        cache.uuid = UUID()
        cache.filtersData = filterLists.encoded
        cache.hashed = filterLists.hashed
        cache.age = Date()

        let langRecord = AutomaticFiltersLanguage(context: self.testSubject.context)
        langRecord.lang = NLLanguage.hebrew.rawValue
        langRecord.isActive = true

        let linksRule = AutomaticFiltersRule(context: self.testSubject.context)
        linksRule.ruleId = RuleType.links.rawValue
        linksRule.isActive = true
        linksRule.selectedChoice = 0
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "trusted phrase https://link.com", sender: "1234567").action
        XCTAssertEqual(result, .allow, "automatic allowBody must override links rule")
    }

    // P1 allUnknown overrides P3 automatic allowSenders — even a trusted sender must not escape allUnknown
    func test_priorityOrder_allUnknownBeatsAutomaticAllow() {
        self.flushPersistanceManager()

        let filterLists = AutomaticFilterListsResponse(filterLists: [
            NLLanguage.hebrew.rawValue: LanguageFilterListResponse(allowSenders: ["BituahLeumi"],
                                                                   allowBody: [],
                                                                   denySender: [],
                                                                   denyBody: [])
        ])
        let cache = AutomaticFiltersCache(context: self.testSubject.context)
        cache.uuid = UUID()
        cache.filtersData = filterLists.encoded
        cache.hashed = filterLists.hashed
        cache.age = Date()

        let langRecord = AutomaticFiltersLanguage(context: self.testSubject.context)
        langRecord.lang = NLLanguage.hebrew.rawValue
        langRecord.isActive = true

        let allUnknown = AutomaticFiltersRule(context: self.testSubject.context)
        allUnknown.ruleId = RuleType.allUnknown.rawValue
        allUnknown.isActive = true
        allUnknown.selectedChoice = 0
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "hello", sender: "BituahLeumi").action
        XCTAssertEqual(result, .junk, "allUnknown must override automatic allowSenders")
    }

    // Regression: block filter "Test" (all) must not be bypassed by unrelated allow filter "2" (all)
    // Repro: body="Test", sender="" → expected .junk, was .allow (reason "2")
    func test_blockFilterNotBypassedByUnrelatedAllowFilter() {
        self.flushPersistanceManager()

        let blockFilter = Filter(context: self.testSubject.context)
        blockFilter.uuid = UUID()
        blockFilter.filterType = .deny
        blockFilter.denyFolderType = .junk
        blockFilter.filterTarget = .all
        blockFilter.filterMatching = .contains
        blockFilter.filterCase = .caseInsensitive
        blockFilter.text = "Test"

        let allowFilter = Filter(context: self.testSubject.context)
        allowFilter.uuid = UUID()
        allowFilter.filterType = .allow
        allowFilter.filterTarget = .all
        allowFilter.filterMatching = .contains
        allowFilter.filterCase = .caseInsensitive
        allowFilter.text = "2"

        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "Test", sender: "")
        XCTAssertEqual(result.action, .junk,
                       "Block filter 'Test' must not be bypassed by allow filter '2' when body='Test' sender=''. Got: \(result.action.debugName), reason: '\(result.reason ?? "nil")'")
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
                 AllowEntry(text: "Bet", folder: .transaction)].map { entry -> Filter in
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
        
        let filtersList = AutomaticFilterListsResponse(filterLists: [
            NLLanguage.hebrew.rawValue : LanguageFilterListResponse(allowSenders: [],
                                                                    allowBody: [],
                                                                    denySender: [],
                                                                    denyBody: ["קורונה", "חדשות"]),
            
            NLLanguage.english.rawValue : LanguageFilterListResponse(allowSenders: [],
                                                                     allowBody: [],
                                                                     denySender: [],
                                                                     denyBody: ["test1", "spam"])
        ])
        
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
