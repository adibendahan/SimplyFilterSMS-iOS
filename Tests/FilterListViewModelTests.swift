//
//  FilterListViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 29/01/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FilterListViewModelTests: XCTestCase {
    
    private var testSubject: FilterListView.ViewModel = FilterListView.ViewModel(filterType: .deny)
    private var persistanceManager = mock_PersistanceManager()
    private var defaultsManager = mock_DefaultsManager()
    private var automaticFilterManager = mock_AutomaticFilterManager()
    private var appManager = mock_AppManager()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        let appManager = mock_AppManager()
        self.appManager = appManager
        self.persistanceManager = mock_PersistanceManager()
        self.defaultsManager = mock_DefaultsManager()
        appManager.persistanceManager = self.persistanceManager
        appManager.defaultsManager = self.defaultsManager
        appManager.automaticFilterManager = self.automaticFilterManager
        
        self.testSubject = FilterListView.ViewModel(filterType: .deny, appManager: appManager)
        self.persistanceManager.resetCounters()
        self.defaultsManager.resetCounters()
        self.automaticFilterManager.resetCounters()
        self.appManager.resetCounters()
    }
    
    //MARK: Tests
    
    func test_refresh() {
        // Prepare
        self.defaultsManager.isAppFirstRunClosure = { return false }
        self.automaticFilterManager.automaticRuleStateClosure = { ruleType in
            switch ruleType {
            case .allUnknown:
                return true
            default:
                return false
            }
        }
        
        self.automaticFilterManager.languagesClosure = { _ in
            return [.hebrew, .english]
        }
        
        // Act
        self.testSubject.refresh()
        
        // Verify
        XCTAssertEqual(self.persistanceManager.fetchFilterRecordsForTypeCounter, 1)
        XCTAssertEqual(self.automaticFilterManager.automaticRuleStateCounter, 1)
        XCTAssertEqual(self.automaticFilterManager.languagesCounter, 1)
        XCTAssertEqual(self.testSubject.isAllUnknownFilteringOn, true)
        XCTAssertEqual(self.testSubject.canBlockAnotherLanguage, true)
    }

    func test_setFilterOptionsCollapsed_persistsPreference() {
        // Act
        self.testSubject.setFilterOptionsCollapsed(true)

        // Verify
        XCTAssertTrue(self.testSubject.isFilterOptionsCollapsed)
        XCTAssertEqual(self.defaultsManager.isFilterOptionsCollapsedSetCounter, 1)
    }

    func test_deleteFiltersOffsets() {
        // Prepare
        let filter = self.makeFilter()
        var stored = [filter]
        self.persistanceManager.fetchFilterRecordsForTypeClosure = { _ in stored }
        self.persistanceManager.deleteFiltersClosure = { deleted in
            stored.removeAll { deleted.contains($0) }
        }
        self.testSubject.refresh()
        XCTAssertEqual(self.testSubject.regularRowViewModels.count, 1)
        
        // Act
        self.testSubject.deleteFilters(withOffsets: IndexSet(arrayLiteral: 0),
                                       rowViewModels: self.testSubject.regularRowViewModels)
        
        // Verify
        XCTAssertEqual(self.persistanceManager.deleteFiltersCounter, 1)
        XCTAssertTrue(self.testSubject.filters.isEmpty)
    }
    
    func test_deleteFilters() {
        // Prepare
        let filter = self.makeFilter()
        var stored = [filter]
        self.persistanceManager.fetchFilterRecordsForTypeClosure = { _ in stored }
        self.persistanceManager.deleteFiltersClosure = { deleted in
            stored.removeAll { deleted.contains($0) }
        }
        self.testSubject.refresh()
        
        // Act
        self.testSubject.deleteFilters(Set(arrayLiteral: filter))
        
        // Verify
        XCTAssertEqual(self.persistanceManager.deleteFiltersCounter, 1)
        XCTAssertTrue(self.testSubject.filters.isEmpty)
    }
    
    private func makeFilter() -> Filter {
        let filter = Filter(context: self.persistanceManager.context)
        filter.denyFolderType = .junk
        filter.filterType = .deny
        filter.text = "newFilter"
        filter.uuid = UUID()
        
        return filter
    }
}
