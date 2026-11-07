//
//  FiltersViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 29/01/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FiltersViewModelTests: XCTestCase {
    
    private var testSubject: FiltersView.ViewModel = FiltersView.ViewModel(filterType: .deny)
    private var persistenceManager = mock_PersistenceManager()
    private var defaultsManager = mock_DefaultsManager()
    private var filterListManager = mock_FilterListManager()
    private var smartFilterManager = mock_SmartFilterManager()
    private var appManager = mock_AppManager()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        let appManager = mock_AppManager()
        self.appManager = appManager
        self.persistenceManager = mock_PersistenceManager()
        self.defaultsManager = mock_DefaultsManager()
        appManager.persistenceManager = self.persistenceManager
        appManager.defaultsManager = self.defaultsManager
        appManager.filterListManager = self.filterListManager
        appManager.smartFilterManager = self.smartFilterManager
        
        self.testSubject = FiltersView.ViewModel(filterType: .deny, appManager: appManager)
        self.persistenceManager.resetCounters()
        self.defaultsManager.resetCounters()
        self.filterListManager.resetCounters()
        self.smartFilterManager.resetCounters()
        self.appManager.resetCounters()
    }
    
    //MARK: Tests
    
    func test_refresh() {
        // Prepare
        self.defaultsManager.isAppFirstRunClosure = { return false }
        self.smartFilterManager.isSmartFilterActiveClosure = { smartFilterType in
            switch smartFilterType {
            case .allUnknown:
                return true
            default:
                return false
            }
        }
        
        self.filterListManager.languagesClosure = { _ in
            return [.hebrew, .english]
        }
        
        // Act
        self.testSubject.refresh()
        
        // Verify
        XCTAssertEqual(self.persistenceManager.fetchFilterRecordsForTypeCounter, 1)
        XCTAssertEqual(self.smartFilterManager.isSmartFilterActiveCounter, 1)
        XCTAssertEqual(self.filterListManager.languagesCounter, 1)
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
        self.persistenceManager.fetchFilterRecordsForTypeClosure = { _ in stored }
        self.persistenceManager.deleteFiltersClosure = { deleted in
            stored.removeAll { deleted.contains($0) }
        }
        self.testSubject.refresh()
        XCTAssertEqual(self.testSubject.regularRowViewModels.count, 1)
        
        // Act
        self.testSubject.deleteFilters(withOffsets: IndexSet(arrayLiteral: 0),
                                       rowViewModels: self.testSubject.regularRowViewModels)
        
        // Verify
        XCTAssertEqual(self.persistenceManager.deleteFiltersCounter, 1)
        XCTAssertTrue(self.testSubject.filters.isEmpty)
    }
    
    func test_deleteFilters() {
        // Prepare
        let filter = self.makeFilter()
        var stored = [filter]
        self.persistenceManager.fetchFilterRecordsForTypeClosure = { _ in stored }
        self.persistenceManager.deleteFiltersClosure = { deleted in
            stored.removeAll { deleted.contains($0) }
        }
        self.testSubject.refresh()
        
        // Act
        self.testSubject.deleteFilters(Set(arrayLiteral: filter))
        
        // Verify
        XCTAssertEqual(self.persistenceManager.deleteFiltersCounter, 1)
        XCTAssertTrue(self.testSubject.filters.isEmpty)
    }
    
    private func makeFilter() -> Filter {
        let filter = Filter(context: self.persistenceManager.context)
        filter.messageFolder = .junk
        filter.filterType = .deny
        filter.text = "newFilter"
        filter.uuid = UUID()
        
        return filter
    }
}
