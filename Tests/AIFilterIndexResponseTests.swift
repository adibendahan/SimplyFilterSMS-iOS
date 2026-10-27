//
//  AIFilterIndexResponseTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 28/10/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AIFilterIndexResponseTests: XCTestCase {

    func test_initData_valid() throws {
        let response = try XCTUnwrap(AIFilterIndexResponse(data: self.json(lists: ["en", "he"])))

        XCTAssertEqual(response.version, 1)
        XCTAssertEqual(response.lists, ["en", "he"])
    }

    func test_initData_wrongFormat() {
        XCTAssertNil(AIFilterIndexResponse(data: self.json(format: FilterExportPayload.formatIdentifier)))
    }

    func test_initData_unsupportedVersion() {
        XCTAssertNil(AIFilterIndexResponse(data: self.json(version: AIFilterIndexResponse.currentVersion + 1)))
        XCTAssertNil(AIFilterIndexResponse(data: self.json(version: 0)))
    }

    func test_initData_garbage() {
        XCTAssertNil(AIFilterIndexResponse(data: Data("not json".utf8)))
    }


    //MARK: Helpers
    private func json(format: String = AIFilterIndexResponse.formatIdentifier,
                      version: Int = 1,
                      lists: [String] = ["en"]) -> Data {
        let object: [String: Any] = ["format": format, "version": version, "lists": lists]
        return try! JSONSerialization.data(withJSONObject: object)
    }
}
