//
//  FilterListCatalogResponseTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 28/10/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FilterListCatalogResponseTests: XCTestCase {

    func test_initData_valid() throws {
        let response = try XCTUnwrap(FilterListCatalogResponse(data: self.json()))

        XCTAssertEqual(response.version, 1)
        XCTAssertEqual(response.lists, [
            FilterListCatalogEntry(id: "ai-he", name: "Hebrew", url: "he.sfsfilters", language: "he"),
            FilterListCatalogEntry(id: "community", name: "Community", url: "https://example.com/list.sfsfilters", language: nil)
        ])
    }

    func test_initData_wrongFormat() {
        XCTAssertNil(FilterListCatalogResponse(data: self.json(format: FilterExportPayload.formatIdentifier)))
    }

    func test_initData_unsupportedVersion() {
        XCTAssertNil(FilterListCatalogResponse(data: self.json(version: FilterListCatalogResponse.currentVersion + 1)))
        XCTAssertNil(FilterListCatalogResponse(data: self.json(version: 0)))
    }

    func test_initData_garbage() {
        XCTAssertNil(FilterListCatalogResponse(data: Data("not json".utf8)))
    }


    //MARK: Helpers
    private func json(format: String = FilterListCatalogResponse.formatIdentifier,
                      version: Int = 1) -> Data {
        let object: [String: Any] = [
            "format": format,
            "version": version,
            "lists": [
                ["id": "ai-he", "name": "Hebrew", "url": "he.sfsfilters", "language": "he"],
                ["id": "community", "name": "Community", "url": "https://example.com/list.sfsfilters"]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: object)
    }
}
