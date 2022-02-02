//
//  FilterListViewModelTests.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 29/01/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FilterListViewModelTests: XCTestCase {
    
    private var testSubject: FilterListViewModel = FilterListViewModel(filterType: .deny)
    private var persistanceManager = mock_PersistanceManager()
    private var defaultsManager = mock_DefaultsManager()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.persistanceManager = mock_PersistanceManager()
        self.defaultsManager = mock_DefaultsManager()
        self.testSubject = FilterListViewModel(filterType: .deny, persistanceManager: self.persistanceManager)
        self.persistanceManager.resetCounters()
        self.defaultsManager.resetCounters()
    }
    
    //MARK: Tests
    
    func test_refresh() {
        // Prepare
        self.defaultsManager.isAppFirstRunClosure = { return false }
        
        // Act
        self.testSubject.refresh()
        
        // Verify
        XCTAssertEqual(self.persistanceManager.fetchFilterRecordsForTypeCounter, 1)
        #warning("Adi - Incomplete test: add appFilterManager usage test.")
    }

    func test_deleteFiltersOffsets() {
        // Prepare
        let filter = self.makeFilter()
        
        // Act
        self.testSubject.deleteFilters(withOffsets: IndexSet(arrayLiteral: 0), in: [filter])
        
        // Verify
        XCTAssertEqual(self.persistanceManager.deleteFiltersOffsetsCounter, 1)
        XCTAssertTrue(self.testSubject.filters.isEmpty) // Verify refresh
    }
    
    func test_deleteFilters() {
        // Prepare
        let filter = self.makeFilter()
        
        // Act
        self.testSubject.deleteFilters(Set(arrayLiteral: filter))
        
        // Verify
        XCTAssertEqual(self.persistanceManager.deleteFiltersCounter, 1)
        XCTAssertTrue(self.testSubject.filters.isEmpty) // Verify refresh
    }
    
    func test_updateFilter() {
        // Prepare
        let filter = self.makeFilter()
        
        // Act
        self.testSubject.updateFilter(filter, denyFolder: .promotion)
        
        // Verify
        XCTAssertEqual(self.persistanceManager.updateFilterCounter, 1)
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