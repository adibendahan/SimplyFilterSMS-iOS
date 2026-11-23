//
//  StayReachableManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 24/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class StayReachableManagerTests: XCTestCase {

    private var persistenceManager: mock_PersistenceManager!
    private var defaultsManager: mock_DefaultsManager!
    private var testSubject: StayReachableManager!

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistenceManager = mock_PersistenceManager()
        self.defaultsManager = mock_DefaultsManager()
        self.testSubject = StayReachableManager(persistenceManager: self.persistenceManager,
                                                defaultsManager: self.defaultsManager)
    }

    override func tearDown() {
        self.testSubject = nil
        self.defaultsManager = nil
        self.persistenceManager = nil
        super.tearDown()
    }

    //MARK: Tests
    func test_rememberedSections_restoresEachFiltersCurrentText() {
        // Prepare
        let filters = self.allowFilters(["Adi", "Herzl"])
        self.defaultsManager.stayReachableFilterIDs = [["language": "en",
                                                        "firstName": filters[0].uuid!.uuidString,
                                                        "street": filters[1].uuid!.uuidString]]
        filters[1].text = "Herzl St"

        // Act
        let sections = self.testSubject.rememberedSections(in: filters)

        // Verify
        XCTAssertEqual(sections.map(\.language), [.english])
        XCTAssertEqual(sections[0].texts, ["Adi", "", "Herzl St"])
        XCTAssertEqual(sections[0].restoredFilters[.firstName], filters[0])
        XCTAssertEqual(sections[0].restoredFilters[.street], filters[1])
        XCTAssertTrue(sections[0].isUnchanged(.street))
    }

    func test_rememberedSections_deletedFilters_dropsTheirFieldsAndBlankSections() {
        // Prepare
        let filters = self.allowFilters(["Adi"])
        self.defaultsManager.stayReachableFilterIDs = [["language": "en",
                                                        "firstName": filters[0].uuid!.uuidString,
                                                        "surname": UUID().uuidString],
                                                       ["language": "he",
                                                        "firstName": UUID().uuidString]]

        // Act
        let sections = self.testSubject.rememberedSections(in: filters)

        // Verify
        XCTAssertEqual(sections.map(\.language), [.english])
        XCTAssertEqual(sections[0].texts, ["Adi", "", ""])
        XCTAssertNil(sections[0].restoredFilters[.surname])
    }

    func test_isAlreadyAllowed_skipsTheFieldsOwnFilter() {
        // Prepare
        let filters = self.allowFilters(["Adi"])

        // Act
        let isAllowedByAnother = self.testSubject.isAlreadyAllowed("ADI", excluding: nil, in: filters)
        let isAllowedExcludingOwn = self.testSubject.isAlreadyAllowed("ADI", excluding: filters[0], in: filters)

        // Verify
        XCTAssertTrue(isAllowedByAnother)
        XCTAssertFalse(isAllowedExcludingOwn)
    }

    func test_save_addsExactCaseInsensitiveAllowFilters() {
        // Prepare
        var english = StayReachableSection(language: .english)
        english.firstName = "Adi"
        english.street = " Herzl "
        var addedTexts: [String] = []
        self.persistenceManager.addFilterClosure = { text, type, _, target, matching, filterCase in
            XCTAssertEqual(type, .allow)
            XCTAssertEqual(target, .all)
            XCTAssertEqual(matching, .exact)
            XCTAssertEqual(filterCase, .caseInsensitive)
            addedTexts.append(text)
        }

        // Act
        self.testSubject.save([english])

        // Verify
        XCTAssertEqual(addedTexts, ["Adi", "Herzl"])
        XCTAssertEqual(self.persistenceManager.updateFilterTextCounter, 0)
    }

    func test_save_editedRestoredField_updatesItsFilter() {
        // Prepare
        let filters = self.allowFilters(["Adi"])
        var english = StayReachableSection(language: .english)
        english.firstName = "Adie"
        english.restoredFilters[.firstName] = filters[0]
        var updatedFilter: Filter?
        var updatedText: String?
        self.persistenceManager.updateFilterTextClosure = { filter, text in
            updatedFilter = filter
            updatedText = text
        }

        // Act
        self.testSubject.save([english])

        // Verify
        XCTAssertEqual(updatedFilter, filters[0])
        XCTAssertEqual(updatedText, "Adie")
        XCTAssertEqual(self.persistenceManager.addFilterCounter, 0)
    }

    func test_save_unchangedRestoredField_leavesItsFilter() {
        // Prepare
        let filters = self.allowFilters(["Adi"])
        var english = StayReachableSection(language: .english)
        english.firstName = "Adi"
        english.restoredFilters[.firstName] = filters[0]

        // Act
        self.testSubject.save([english])

        // Verify
        XCTAssertEqual(self.persistenceManager.updateFilterTextCounter, 0)
        XCTAssertEqual(self.persistenceManager.addFilterCounter, 0)
    }

    func test_save_clearedRestoredField_deletesItsFilter() {
        // Prepare
        let filters = self.allowFilters(["Adi", "Herzl"])
        var english = StayReachableSection(language: .english)
        english.firstName = " "
        english.restoredFilters[.firstName] = filters[0]
        english.street = "Herzl"
        english.restoredFilters[.street] = filters[1]
        var deletedFilters: Set<Filter> = []
        self.persistenceManager.deleteFiltersClosure = { deletedFilters = $0 }

        // Act
        self.testSubject.save([english])

        // Verify
        XCTAssertEqual(deletedFilters, [filters[0]])
        XCTAssertEqual(self.persistenceManager.deleteFiltersCounter, 1)
    }

    func test_save_nothingCleared_deletesNothing() {
        // Prepare
        var english = StayReachableSection(language: .english)
        english.firstName = "Adi"

        // Act
        self.testSubject.save([english])

        // Verify
        XCTAssertEqual(self.persistenceManager.deleteFiltersCounter, 0)
    }

    func test_save_remembersEachFieldsFilterID() {
        // Prepare
        let restoredFilters = self.allowFilters(["Adi"])
        let savedFilters = self.allowFilters(["Herzl"])
        var english = StayReachableSection(language: .english)
        english.firstName = "Adi"
        english.restoredFilters[.firstName] = restoredFilters[0]
        english.street = "Herzl"
        let emptyHebrew = StayReachableSection(language: Locale.LanguageCode("he"))
        self.persistenceManager.fetchFilterRecordsForTypeClosure = { _ in savedFilters }

        // Act
        self.testSubject.save([english, emptyHebrew])

        // Verify
        XCTAssertEqual(self.defaultsManager.stayReachableFilterIDs, [["language": "en",
                                                                      "firstName": restoredFilters[0].uuid!.uuidString,
                                                                      "street": savedFilters[0].uuid!.uuidString]])
    }

    //MARK: Private
    private func allowFilters(_ texts: [String]) -> [Filter] {
        var filters: [Filter] = []
        for text in texts {
            let filter = Filter(context: self.persistenceManager.context)
            filter.uuid = UUID()
            filter.text = text
            filter.filterType = .allow
            filter.filterTarget = .all
            filter.filterMatching = .exact
            filter.filterCase = .caseInsensitive
            filters.append(filter)
        }
        return filters
    }
}
