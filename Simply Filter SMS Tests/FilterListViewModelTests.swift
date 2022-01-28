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
    
    private var testSubject: FilterListViewModel = FilterListViewModel()
    private var persistanceManager = mock_PersistanceManager()
    private var defaultsManager = mock_DefaultsManager()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.persistanceManager = mock_PersistanceManager()
        self.defaultsManager = mock_DefaultsManager()
        self.testSubject = FilterListViewModel(persistanceManager: self.persistanceManager, defaultsManager: self.defaultsManager)
        self.persistanceManager.resetCounters()
        self.defaultsManager.resetCounters()
    }
    
    //MARK: Tests
    
    func test_refresh() {
        // Prepare
        self.persistanceManager.isAutomaticFilteringOnClosure = { return true }
        self.defaultsManager.isAppFirstRunClosure = { return false }
        
        // Act
        self.testSubject.refresh()
        
        // Verify
        XCTAssert(self.persistanceManager.getFiltersCounter == 1)
        XCTAssert(self.defaultsManager.isAppFirstRunGetCounter == 1)
        XCTAssert(self.persistanceManager.isAutomaticFilteringOnCounter == 1)
    }
    
    func test_isEmpty() {
        // Prepare
        self.persistanceManager.getFiltersClosure = { return [] }
        var isEmpty = false
        
        // Act
        isEmpty = self.testSubject.isEmpty
        
        // Verify
        XCTAssert(isEmpty == true)
     
        // Prepare
        let filter = self.makeFilter()
        self.persistanceManager.getFiltersClosure = { return [filter] }
        self.testSubject.refresh()
        
        // Act
        isEmpty = self.testSubject.isEmpty
        
        // Verify
        XCTAssert(isEmpty == false)
    }
    
    func test_deleteFiltersOffsets() {
        // Prepare
        let filter = self.makeFilter()
        
        // Act
        self.testSubject.deleteFilters(withOffsets: IndexSet(arrayLiteral: 0), in: [filter])
        
        // Verify
        XCTAssert(self.persistanceManager.deleteFiltersOffsetsCounter == 1)
        XCTAssert(self.testSubject.isEmpty == true) // Verify refresh
    }
    
    func test_deleteFilters() {
        // Prepare
        let filter = self.makeFilter()
        
        // Act
        self.testSubject.deleteFilters(Set(arrayLiteral: filter))
        
        // Verify
        XCTAssert(self.persistanceManager.deleteFiltersCounter == 1)
        XCTAssert(self.testSubject.isEmpty == true) // Verify refresh
    }
    
    func test_updateFilter() {
        // Prepare
        let filter = self.makeFilter()
        
        // Act
        self.testSubject.updateFilter(filter, denyFolder: .promotion)
        
        // Verify
        XCTAssert(self.persistanceManager.updateFilterCounter == 1)
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
