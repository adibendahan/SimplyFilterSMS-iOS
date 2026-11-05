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

    //MARK: Tests
    func test_initData_valid() throws {
        // Prepare
        let data = self.json()

        // Act
        let response = try XCTUnwrap(FilterListCatalogResponse(data: data))

        // Verify
        XCTAssertEqual(response.version, 1)
        XCTAssertEqual(response.lists, [
            FilterListCatalogEntry(id: "ai-he", name: "Hebrew", url: "he.sfsfilters", language: "he"),
            FilterListCatalogEntry(id: "community", name: "Community", url: "https://example.com/list.sfsfilters", language: nil)
        ])
    }

    func test_initData_wrongFormat() {
        // Prepare
        let data = self.json(format: FilterExportPayload.formatIdentifier)

        // Act
        let response = FilterListCatalogResponse(data: data)

        // Verify
        XCTAssertNil(response)
    }

    func test_initData_unsupportedVersion() {
        // Prepare
        let newerData = self.json(version: FilterListCatalogResponse.currentVersion + 1)
        let zeroData = self.json(version: 0)

        // Act
        let newerResponse = FilterListCatalogResponse(data: newerData)
        let zeroResponse = FilterListCatalogResponse(data: zeroData)

        // Verify
        XCTAssertNil(newerResponse)
        XCTAssertNil(zeroResponse)
    }

    func test_initData_garbage() {
        // Prepare
        let data = Data("not json".utf8)

        // Act
        let response = FilterListCatalogResponse(data: data)

        // Verify
        XCTAssertNil(response)
    }


    //MARK: - Private -
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
