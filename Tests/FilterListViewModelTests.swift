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
    
    private var testSubject: FilterListView.ViewModel = FilterListView.ViewModel(filterType: .deny)
    private var persistanceManager = mock_PersistanceManager()
    private var defaultsManager = mock_DefaultsManager()
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
        
        self.testSubject = FilterListView.ViewModel(filterType: .deny, appManager: appManager)
        self.persistanceManager.resetCounters()
        self.defaultsManager.resetCounters()
        self.appManager.resetCounters()
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
    
    private func makeFilter() -> Filter {
        let filter = Filter(context: self.persistanceManager.context)
        filter.denyFolderType = .junk
        filter.filterType = .deny
        filter.text = "newFilter"
        filter.uuid = UUID()
        
        return filter
    }
}
