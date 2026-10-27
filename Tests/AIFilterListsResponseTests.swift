//
//  AIFilterListsResponseTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 28/10/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AIFilterListsResponseTests: XCTestCase {

    func test_initData_valid() throws {
        let response = try XCTUnwrap(AIFilterListsResponse(data: self.json(records: [self.record(text: "promo")])))

        XCTAssertEqual(response.version, 1)
        XCTAssertEqual(response.revision, 7)
        XCTAssertEqual(response.filterLists["en"]?.count, 1)
        XCTAssertEqual(response.validatedLists["en"]?.first?.text, "promo")
    }

    func test_initData_wrongFormat() {
        XCTAssertNil(AIFilterListsResponse(data: self.json(format: "simply-filter-sms-filters", records: [])))
    }

    func test_initData_unsupportedVersion() {
        XCTAssertNil(AIFilterListsResponse(data: self.json(version: AIFilterListsResponse.currentVersion + 1, records: [])))
        XCTAssertNil(AIFilterListsResponse(data: self.json(version: 0, records: [])))
    }

    func test_initData_garbage() {
        XCTAssertNil(AIFilterListsResponse(data: Data("not json".utf8)))
    }

    func test_validatedLists_dropsInvalidRecordsOnly() throws {
        let records = [
            self.record(text: "promo"),
            self.record(text: "(?i)^Apple$", type: "allow", target: "sender", matching: "regex", filterCase: nil),
            self.record(text: "(unclosed", matching: "regex", filterCase: nil),
            self.record(text: "   "),
            self.record(text: "promo", folder: "spam"),
            self.record(text: "lang:en", type: "denyLanguage")
        ]
        let response = try XCTUnwrap(AIFilterListsResponse(data: self.json(records: records)))
        let validated = response.validatedLists["en"] ?? []

        XCTAssertEqual(response.filterLists["en"]?.count, 6)
        XCTAssertEqual(validated.map(\.text), ["promo", "(?i)^Apple$"])
        XCTAssertEqual(validated.last?.type, .allow)
        XCTAssertEqual(validated.last?.filterMatching, .regex)
    }


    //MARK: Helpers
    private func record(text: String,
                        type: String = "deny",
                        folder: String = "junk",
                        target: String = "body",
                        matching: String = "contains",
                        filterCase: String? = "insensitive") -> [String: String] {
        var record = ["text": text, "type": type, "folder": folder, "target": target, "matching": matching]
        record["case"] = filterCase
        return record
    }

    private func json(format: String = AIFilterListsResponse.formatIdentifier,
                      version: Int = 1,
                      records: [[String: String]]) -> Data {
        let object: [String: Any] = ["format": format,
                                     "version": version,
                                     "revision": 7,
                                     "updatedAt": "2026-10-28T00:00:00Z",
                                     "filterLists": ["en": records]]
        return try! JSONSerialization.data(withJSONObject: object)
    }
}
