//
//  FilterListServiceTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 15/02/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FilterListServiceTests: XCTestCase {

    var httpService = mock_HTTPService()
    var networkSyncManager = mock_NetworkSyncManager()

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()

        self.httpService = mock_HTTPService()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.networkSyncManager.networkStatusClosure = { .online }
        self.testSubject = FilterListService(httpService: self.httpService, networkSyncManager: self.networkSyncManager)
    }
    
    //MARK: Tests
    func test_fetchFilterListCatalog() async {
        // Prepare
        var requestedURL: URL?
        var sentETag: String?
        self.httpService.fetchIfModifiedClosure = { request in
            requestedURL = request.url
            sentETag = request.headers["If-None-Match"]
            return .modified(self.catalogData(), etag: "new-etag")
        }

        // Act
        let response = await self.testSubject.fetchFilterListCatalog(etag: "old-etag")

        // Verify
        XCTAssertEqual(requestedURL?.absoluteString, "https://grizz-apps-dev.s3.us-east-2.amazonaws.com/simply-filter-sms/3.3.0/ai/catalog.json")
        XCTAssertEqual(sentETag, "old-etag")
        XCTAssertEqual(response, .modified(FilterListCatalogResponse(data: self.catalogData())!, etag: "new-etag"))
    }

    func test_fetchFilterList_notModified() async {
        // Prepare
        let url = URL(string: "https://example.com/he.sfsfilters")!
        var requestedURL: URL?
        self.httpService.fetchIfModifiedClosure = { request in
            requestedURL = request.url
            return .notModified
        }

        // Act
        let response = await self.testSubject.fetchFilterList(at: url, etag: "etag")

        // Verify
        XCTAssertEqual(requestedURL, url)
        XCTAssertEqual(response, .notModified)
    }

    func test_fetchFilterList_invalidData() async {
        // Prepare
        self.httpService.fetchIfModifiedClosure = { _ in .modified(Data("not json".utf8), etag: "etag") }

        // Act
        let response = await self.testSubject.fetchFilterList(at: URL(string: "https://example.com/he.sfsfilters")!, etag: nil)

        // Verify
        XCTAssertNil(response)
    }

    func test_fetchFilterList_requestFails() async {
        // Prepare
        self.httpService.fetchIfModifiedClosure = { _ in throw RequestError.noData }

        // Act
        let response = await self.testSubject.fetchFilterList(at: URL(string: "https://example.com/he.sfsfilters")!, etag: nil)

        // Verify
        XCTAssertNil(response)
    }

    func test_fetch_offline() async {
        // Prepare
        self.networkSyncManager.networkStatusClosure = { .offline }

        // Act
        let response = await self.testSubject.fetchFilterListCatalog(etag: nil)

        // Verify
        XCTAssertNil(response)
        XCTAssertEqual(self.httpService.fetchIfModifiedCounter, 0)
    }
    
    // MARK: Private Variables and Helpers
    private var testSubject: FilterListServiceProtocol = FilterListService(httpService: mock_HTTPService(), networkSyncManager: mock_NetworkSyncManager())

    private func catalogData() -> Data {
        let object: [String: Any] = [
            "format": FilterListCatalogResponse.formatIdentifier,
            "version": 1,
            "lists": [["id": "ai-he", "name": "Hebrew", "url": "he.sfsfilters", "language": "he"]]
        ]
        return try! JSONSerialization.data(withJSONObject: object)
    }
}
