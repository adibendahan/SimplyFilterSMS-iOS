//
//  AddFilterIntentTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 19/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AddFilterIntentTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistenceManager = PersistenceManager(inMemory: true)
        let appManager = mock_AppManager()
        appManager.persistenceManager = self.persistenceManager
        SimplyFilterSMSShortcuts.appManager = appManager
    }


    //MARK: Tests
    @MainActor
    func test_perform_block_addsDeniedFilterWithAddFilterDefaults() async throws {
        // Act
        try await self.perform(list: .block, text: "  Free Prize. ")

        // Verify
        let filters = self.persistenceManager.fetchFilterRecords()
        XCTAssertEqual(filters.count, 1)
        let filter = try XCTUnwrap(filters.first)
        XCTAssertEqual(filter.text, "Free Prize")
        XCTAssertEqual(filter.filterType, .deny)
        XCTAssertEqual(filter.messageFolder, .junk)
        XCTAssertEqual(filter.filterTarget, .all)
        XCTAssertEqual(filter.filterMatching, .contains)
        XCTAssertEqual(filter.filterCase, .caseInsensitive)
    }

    @MainActor
    func test_perform_allow_addsAllowedFilter() async throws {
        // Act
        try await self.perform(list: .allow, text: "Dana")

        // Verify
        let filters = self.persistenceManager.fetchFilterRecords(for: .allow)
        XCTAssertEqual(filters.map({ $0.text }), ["Dana"])
    }

    @MainActor
    func test_perform_duplicate_doesNotAddSecondFilter() async throws {
        // Prepare
        try await self.perform(list: .block, text: "prize")

        // Act
        try await self.perform(list: .allow, text: "Prize!")

        // Verify
        let filters = self.persistenceManager.fetchFilterRecords()
        XCTAssertEqual(filters.count, 1)
        XCTAssertEqual(filters.first?.filterType, .deny)
    }

    @MainActor
    func test_perform_onlyPunctuation_addsNothing() async throws {
        // Act
        try await self.perform(list: .block, text: " . ")

        // Verify
        XCTAssertTrue(self.persistenceManager.fetchFilterRecords().isEmpty)
    }

    func test_dictatedFilterText() {
        XCTAssertEqual("  win cash. ".dictatedFilterText, "win cash")
        XCTAssertEqual("win cash?!".dictatedFilterText, "win cash")
        XCTAssertEqual("הלוואה מהירה.".dictatedFilterText, "הלוואה מהירה")
        XCTAssertEqual("無料。".dictatedFilterText, "無料")
        XCTAssertEqual("bit.ly/abc".dictatedFilterText, "bit.ly/abc")
        XCTAssertEqual("win . ".dictatedFilterText, "win")
        XCTAssertEqual("...".dictatedFilterText, "")
    }


    //MARK: Private
    private var persistenceManager: PersistenceManager!

    @MainActor
    private func perform(list: FilterListChoice, text: String) async throws {
        let intent = AddFilterIntent()
        intent.list = list
        intent.text = text
        _ = try await intent.perform()
    }
}
