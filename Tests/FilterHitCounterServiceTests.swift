//
//  FilterHitCounterServiceTests.swift
//  Tests
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FilterHitCounterServiceTests: XCTestCase {

    private var suiteName: String!
    private var testDefaults: UserDefaults!
    private var testSubject: FilterHitCounterService!

    override func setUp() {
        super.setUp()
        suiteName = "test.FilterHitCounterService.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
        testSubject = FilterHitCounterService(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func test_firstIncrement_createsEntryWithCountOne() {
        testSubject.incrementCount(for: "filter-A")

        XCTAssertEqual(testSubject.counts()["filter-A"], 1)
    }

    func test_subsequentIncrements_accumulate() {
        testSubject.incrementCount(for: "filter-A")
        testSubject.incrementCount(for: "filter-A")
        testSubject.incrementCount(for: "filter-A")

        XCTAssertEqual(testSubject.counts()["filter-A"], 3)
    }

    func test_unrelatedKeys_areUnaffected() {
        testSubject.incrementCount(for: "filter-A")
        testSubject.incrementCount(for: "filter-A")
        testSubject.incrementCount(for: "filter-B")

        XCTAssertEqual(testSubject.counts()["filter-A"], 2)
        XCTAssertEqual(testSubject.counts()["filter-B"], 1)
    }

    func test_counts_returnsEmptyDictionaryWhenNoIncrements() {
        XCTAssertTrue(testSubject.counts().isEmpty)
    }
}
