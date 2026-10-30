//
//  MessageEvaluationManagerTests.swift
//  Tests
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
        
        self.saveFilterLists([
            "he": [self.allowSender("BituahLeumi"),
                   self.allowSender("Taasuka"),
                   self.allowSender("bit"),
                   self.allowSender("100"),
                   self.allowSender("ontopo"),
                   self.denyBody("הלוואה")]
        ])
        
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

    // P1 allUnknown overrides P2 allow filters — explicit allow veats everything
    func test_priorityOrder_allowFiltersBeatsAllUnknown() {
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
        XCTAssertEqual(result, .allow, "allow filters must override allUnknown")
    }

    // P3 automatic allowSenders overrides P4 rules — trusted sender with a link must not be blocked by links rule
    func test_priorityOrder_automaticAllowSendersBeatsRules() {
        self.flushPersistanceManager()

        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [self.allowSender("BituahLeumi")]
        ])

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

        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [self.allowBody("trusted phrase")]
        ])

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

        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [self.allowSender("BituahLeumi")]
        ])

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

    // MARK: Regex filter tests

    func test_evaluateMessage_regexMatch() {
        self.flushPersistanceManager()

        let filter = Filter(context: self.testSubject.context)
        filter.filterType = .deny
        filter.denyFolderType = .junk
        filter.filterTarget = .body
        filter.filterMatching = .regex
        filter.filterCase = .caseInsensitive
        filter.text = #"\d{5}"#
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "Your code is 12345", sender: "1234567").action
        XCTAssertEqual(result, .junk, "regex \\d{5} should match body containing 5-digit number")
    }

    func test_evaluateMessage_regexNoMatch() {
        self.flushPersistanceManager()

        let filter = Filter(context: self.testSubject.context)
        filter.filterType = .deny
        filter.denyFolderType = .junk
        filter.filterTarget = .body
        filter.filterMatching = .regex
        filter.filterCase = .caseInsensitive
        filter.text = #"\d{5}"#
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "Hello world", sender: "1234567").action
        XCTAssertEqual(result, .allow, "regex \\d{5} should not match body with no 5-digit number")
    }

    func test_evaluateMessage_invalidRegexReturnsFalse() {
        self.flushPersistanceManager()

        let filter = Filter(context: self.testSubject.context)
        filter.filterType = .deny
        filter.denyFolderType = .junk
        filter.filterTarget = .body
        filter.filterMatching = .regex
        filter.filterCase = .caseInsensitive
        filter.text = "[unclosed"
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "Hello world [unclosed", sender: "1234567").action
        XCTAssertEqual(result, .allow, "invalid regex pattern should not match any message")
    }

    func test_evaluateMessage_regexCaseSensitive() {
        self.flushPersistanceManager()

        let filter = Filter(context: self.testSubject.context)
        filter.filterType = .deny
        filter.denyFolderType = .junk
        filter.filterTarget = .body
        filter.filterMatching = .regex
        filter.filterCase = .caseInsensitive
        filter.text = "[A-Z]{3}"
        try? self.testSubject.context.save()

        let upperResult = self.testSubject.evaluateMessage(body: "ABC", sender: "1234567").action
        XCTAssertEqual(upperResult, .junk, "pattern [A-Z]{3} should match uppercase ABC")

        let lowerResult = self.testSubject.evaluateMessage(body: "abc", sender: "1234567").action
        XCTAssertEqual(lowerResult, .allow, "pattern [A-Z]{3} should not match lowercase abc (no (?i) flag)")
    }

    func test_evaluateMessage_regexInlineFlag() {
        self.flushPersistanceManager()

        let filter = Filter(context: self.testSubject.context)
        filter.filterType = .deny
        filter.denyFolderType = .junk
        filter.filterTarget = .body
        filter.filterMatching = .regex
        filter.filterCase = .caseInsensitive
        filter.text = "(?i)[a-z]{3}"
        try? self.testSubject.context.save()

        let lowerResult = self.testSubject.evaluateMessage(body: "abc", sender: "1234567").action
        XCTAssertEqual(lowerResult, .junk, "(?i)[a-z]{3} should match lowercase abc")

        let upperResult = self.testSubject.evaluateMessage(body: "ABC", sender: "1234567").action
        XCTAssertEqual(upperResult, .junk, "(?i)[a-z]{3} should match uppercase ABC via inline flag")
    }

    // MARK: AI Filtering list tests

    func test_automaticFilters_onlyActiveLanguagesApply() {
        self.flushPersistanceManager()
        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [self.denyBody("הלוואה")],
            NLLanguage.english.rawValue: [self.denyBody("loan")]
        ])
        self.setLanguage(.hebrew, isActive: true)
        self.setLanguage(.english, isActive: false)
        try? self.testSubject.context.save()

        let hebrewResult = self.testSubject.evaluateMessage(body: "הלוואה מהירה", sender: "1234567").action
        let englishResult = self.testSubject.evaluateMessage(body: "fast loan", sender: "1234567").action

        XCTAssertEqual(hebrewResult, .junk)
        XCTAssertEqual(englishResult, .allow, "a list whose language is off must not block")
    }

    func test_automaticFilters_denyUsesRecordFolder() {
        self.flushPersistanceManager()
        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [self.denyBody("sale", folder: "promotion")]
        ])
        self.setLanguage(.hebrew, isActive: true)
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "big sale today", sender: "1234567")

        XCTAssertEqual(result.action, .promotion)
        XCTAssertEqual(result.match, .automaticFilter(NLLanguage.hebrew.localizedName!))
    }

    func test_automaticFilters_skipsRecordsItCannotUse() {
        self.flushPersistanceManager()
        let unknownMatching = FilterExportRecord(text: "spam",
                                                 type: "deny",
                                                 folder: "junk",
                                                 target: "body",
                                                 matching: "fuzzy",
                                                 caseSensitivity: "insensitive")
        let invalidRegex = FilterExportRecord(text: "(spam",
                                              type: "deny",
                                              folder: "junk",
                                              target: "body",
                                              matching: "regex",
                                              caseSensitivity: nil)
        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [unknownMatching,
                                         invalidRegex,
                                         self.denyBody("spam", folder: "inbox"),
                                         self.denyBody(" "),
                                         self.denyBody("spam", folder: "transaction")]
        ])
        self.setLanguage(.hebrew, isActive: true)
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "(spam here", sender: "1234567").action

        XCTAssertEqual(result, .transaction, "only the last record is usable")
    }

    func test_automaticFilters_legacyCacheBlocksNothing() {
        self.flushPersistanceManager()
        let cacheRecord = AutomaticFiltersCache(context: self.testSubject.context)
        cacheRecord.uuid = UUID()
        cacheRecord.filtersData = "eyJmaWx0ZXJMaXN0cyI6eyJoZSI6eyJhbGxvd0JvZHkiOltdLCJhbGxvd1NlbmRlcnMiOltdLCJkZW55Qm9keSI6WyJ3b3JkIl0sImRlbnlTZW5kZXIiOltdfX19"
        cacheRecord.age = Date()
        self.setLanguage(.hebrew, isActive: true)
        try? self.testSubject.context.save()

        let result = self.testSubject.evaluateMessage(body: "word", sender: "1234567").action

        XCTAssertEqual(result, .allow)
    }

    func test_activeFilterLists_decodesOnlyActiveLanguages() {
        self.flushPersistanceManager()
        let records = [self.denyBody("spam")]
        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: records,
            NLLanguage.english.rawValue: records,
            NLLanguage.arabic.rawValue: records
        ])
        try? self.testSubject.context.save()
        let cacheRecord = try? self.testSubject.context.fetch(AutomaticFiltersCache.fetchRequest()).first
        let filtersData = cacheRecord?.filtersData ?? ""

        let activeFilterLists = ActiveFilterLists(encoded: filtersData, activeLanguages: [NLLanguage.hebrew.rawValue])

        XCTAssertEqual(activeFilterLists?.lists.count, 1)
        XCTAssertEqual(activeFilterLists?.lists.first?.name, NLLanguage.hebrew.localizedName)
        XCTAssertEqual(activeFilterLists?.lists.first?.records, records)
    }

    func test_automaticFilters_performance() {
        self.flushPersistanceManager()
        let languages: [NLLanguage] = [.hebrew, .english, .arabic, .spanish, .french,
                                       .portuguese, .german, .japanese, .korean, .italian]
        var recordsByLanguage: [String: [FilterExportRecord]] = [:]

        for language in languages {
            var records: [FilterExportRecord] = []
            for index in 0..<48 {
                records.append(self.allowSender("Sender\(language.rawValue)\(index)"))
            }
            for index in 0..<197 {
                records.append(self.denyBody("phrase \(language.rawValue) \(index)"))
            }
            recordsByLanguage[language.rawValue] = records
            self.setLanguage(language, isActive: true)
        }
        self.saveFilterLists(recordsByLanguage)
        try? self.testSubject.context.save()

        let options = XCTMeasureOptions()
        options.iterationCount = 10

        self.measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: options) {
            let result = self.testSubject.evaluateMessage(body: "a message that matches nothing", sender: "1234567")
            XCTAssertEqual(result.action, .allow)
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
    
    private func allowSender(_ sender: String) -> FilterExportRecord {
        let pattern = "(?i)^\(NSRegularExpression.escapedPattern(for: sender))$"
        return FilterExportRecord(text: pattern,
                                  type: "allow",
                                  folder: nil,
                                  target: "sender",
                                  matching: "regex",
                                  caseSensitivity: nil)
    }

    private func allowBody(_ text: String) -> FilterExportRecord {
        return FilterExportRecord(text: text,
                                  type: "allow",
                                  folder: nil,
                                  target: "body",
                                  matching: "contains",
                                  caseSensitivity: "insensitive")
    }

    private func denyBody(_ text: String, folder: String = "junk") -> FilterExportRecord {
        return FilterExportRecord(text: text,
                                  type: "deny",
                                  folder: folder,
                                  target: "body",
                                  matching: "contains",
                                  caseSensitivity: "insensitive")
    }

    private func setLanguage(_ language: NLLanguage, isActive: Bool) {
        let languageRecord = AutomaticFiltersLanguage(context: self.testSubject.context)
        languageRecord.lang = language.rawValue
        languageRecord.isActive = isActive
    }

    private func saveFilterLists(_ recordsByLanguage: [String: [FilterExportRecord]]) {
        var entries: [FilterListCatalogEntry] = []
        var sections: [FilterListsCacheSection] = []

        for (language, records) in recordsByLanguage {
            let entry = FilterListCatalogEntry(id: "ai-\(language)",
                                               name: language,
                                               url: "\(language).sfsfilters",
                                               language: language)
            let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                              version: FilterExportPayload.currentVersion,
                                              exportedAt: Date(),
                                              appVersion: "3.3.0",
                                              name: language,
                                              revision: nil,
                                              filters: records,
                                              forceClearBeforeImport: nil)
            let section = FilterListsCacheSection(url: entry.resolvedURL!.absoluteString,
                                                  etag: nil,
                                                  payload: payload)
            entries.append(entry)
            sections.append(section)
        }

        let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                version: FilterListCatalogResponse.currentVersion,
                                                lists: entries)
        let cache = FilterListsCache(catalogETag: nil, catalog: catalog, lists: sections)
        let cacheRecord = AutomaticFiltersCache(context: self.testSubject.context)
        cacheRecord.uuid = UUID()
        cacheRecord.filtersData = cache.encoded
        cacheRecord.age = Date()
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
        
        self.saveFilterLists([
            NLLanguage.hebrew.rawValue: [self.denyBody("קורונה"),
                                         self.denyBody("חדשות")],
            NLLanguage.english.rawValue: [self.denyBody("test1"),
                                          self.denyBody("spam")]
        ])
        
        let automaticFiltersLanguageHE = AutomaticFiltersLanguage(context: self.testSubject.context)
        automaticFiltersLanguageHE.lang = NLLanguage.hebrew.rawValue
        automaticFiltersLanguageHE.isActive = true
        
        let automaticFiltersLanguageEN = AutomaticFiltersLanguage(context: self.testSubject.context)
        automaticFiltersLanguageEN.lang = NLLanguage.english.rawValue
        automaticFiltersLanguageEN.isActive = false
        
        try? self.testSubject.context.save()
    }
}
