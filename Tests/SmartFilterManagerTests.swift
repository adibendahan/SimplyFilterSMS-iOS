//
//  SmartFilterManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import Foundation
import XCTest
import CoreData
@testable import Simply_Filter_SMS

class SmartFilterManagerTests: XCTestCase {

    var persistanceManager = mock_PersistanceManager()

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.persistanceManager = mock_PersistanceManager()
        self.testSubject = SmartFilterManager(persistanceManager: self.persistanceManager)
    }


    //MARK: Tests
    func test_ruleState() {
        // Prepare
        self.persistanceManager.fetchAutomaticFiltersRuleRecordClosure = { rule in
            let automaticFiltersRuleRecord = AutomaticFiltersRule(context: self.persistanceManager.context)
            automaticFiltersRuleRecord.ruleId = rule.rawValue
            automaticFiltersRuleRecord.isActive = rule == .email
            return automaticFiltersRuleRecord
        }
        
        // Act
        let resultExpectedTrue = self.testSubject.ruleState(for: .email)
        let resultExpectedFalse = self.testSubject.ruleState(for: .links)
        
        // Verify
        XCTAssertTrue(resultExpectedTrue)
        XCTAssertFalse(resultExpectedFalse)
        XCTAssertEqual(self.persistanceManager.fetchAutomaticFiltersRuleRecordCounter, 2)
    }
    
    func test_setRuleState() {
        // Act
        self.testSubject.setRuleState(for: .links, value: true)
        
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


    //MARK: Private Variables and Helpers
    private var testSubject: SmartFilterManagerProtocol = SmartFilterManager(persistanceManager: mock_PersistanceManager())
}
