//
//  URLRequestTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class URLRequestTests: XCTestCase {

    //MARK: Tests
    func test_reportMessageRequest() throws {
        // Prepare
        let body = ReportMessageRequestBody(sender: "BANK", body: "Hello", type: "junk")

        // Act
        let request = URLRequest(request: ReportMessageRequest(body: body))

        // Verify
        XCTAssertEqual(request.url?.absoluteString, "https://api.ben-dahan.com/report")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(request.httpBody)) as? [String: Any])
        let classification = try XCTUnwrap(json["classification"] as? [String: Any])
        XCTAssertEqual(classification["sender"] as? String, "BANK")
        XCTAssertEqual(classification["bodies"] as? [String], ["Hello"])
        XCTAssertEqual(classification["type"] as? String, "junk")
    }

    func test_filterListCatalogRequest() {
        // Act
        let request = URLRequest(request: FilterListCatalogRequest(etag: "catalog-etag"))

        // Verify
        XCTAssertEqual(request.url?.absoluteString, "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/3.3.0/ai/catalog.json")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "catalog-etag")
    }

    func test_filterListRequest() {
        // Prepare
        let url = URL(string: "https://raw.githubusercontent.com/example/lists/main/list.sfsfilters")!

        // Act
        let request = URLRequest(request: FilterListRequest(url: url, etag: "list-etag"))

        // Verify
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "list-etag")
    }

    func test_filterListRequest_withoutETag() {
        // Act
        let request = URLRequest(request: FilterListRequest(url: .filterListCatalogURL, etag: nil))

        // Verify
        XCTAssertNil(request.value(forHTTPHeaderField: "If-None-Match"))
    }
}
