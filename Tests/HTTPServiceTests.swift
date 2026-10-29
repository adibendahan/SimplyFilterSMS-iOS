//
//  HTTPServiceTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class HTTPServiceTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(StubURLProtocol.self)
        StubURLProtocol.reset()
    }

    override func tearDown() {
        URLProtocol.unregisterClass(StubURLProtocol.self)
        StubURLProtocol.reset()
        super.tearDown()
    }


    //MARK: Tests
    func test_fetchIfModified_modified() async throws {
        // Prepare
        let data = Data("list".utf8)
        StubURLProtocol.respond(statusCode: 200, headers: ["ETag": "\"he-2\""], data: data)
        let request = FilterListRequest(url: self.listURL, etag: "\"he-1\"")

        // Act
        let result = try await self.testSubject.fetchIfModified(request: request)

        // Verify
        XCTAssertEqual(result, .modified(data, etag: "\"he-2\""))
        XCTAssertEqual(StubURLProtocol.lastRequest?.url, self.listURL)
        XCTAssertEqual(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "If-None-Match"), "\"he-1\"")
    }

    func test_fetchIfModified_notModified() async throws {
        // Prepare
        StubURLProtocol.respond(statusCode: 304, headers: [:], data: Data())
        let request = FilterListRequest(url: self.listURL, etag: "\"he-1\"")

        // Act
        let result = try await self.testSubject.fetchIfModified(request: request)

        // Verify
        XCTAssertEqual(result, .notModified)
    }

    func test_fetchIfModified_noETag() async throws {
        // Prepare
        let data = Data("list".utf8)
        StubURLProtocol.respond(statusCode: 200, headers: [:], data: data)
        let request = FilterListRequest(url: self.listURL, etag: nil)

        // Act
        let result = try await self.testSubject.fetchIfModified(request: request)

        // Verify
        XCTAssertEqual(result, .modified(data, etag: nil))
        XCTAssertNil(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "If-None-Match"))
    }

    func test_fetchIfModified_serverError() async {
        // Prepare
        StubURLProtocol.respond(statusCode: 500, headers: [:], data: Data())
        let request = FilterListRequest(url: self.listURL, etag: nil)

        // Act
        var didThrow = false
        do {
            _ = try await self.testSubject.fetchIfModified(request: request)
        } catch {
            didThrow = true
        }

        // Verify
        XCTAssertTrue(didThrow)
    }


    //MARK: Private Variables and Helpers
    private let testSubject = HTTPService()
    private let listURL = URL(string: "https://filters.example.com/he.sfsfilters")!
}

private class StubURLProtocol: URLProtocol {
    static var statusCode = 200
    static var headers: [String: String] = [:]
    static var data = Data()
    static var lastRequest: URLRequest?

    static func respond(statusCode: Int, headers: [String: String], data: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
    }

    static func reset() {
        self.respond(statusCode: 200, headers: [:], data: Data())
        self.lastRequest = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.host == "filters.example.com"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        Self.lastRequest = self.request

        guard let url = self.request.url,
              let response = HTTPURLResponse(url: url,
                                             statusCode: Self.statusCode,
                                             httpVersion: "HTTP/1.1",
                                             headerFields: Self.headers) else {
            self.client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        self.client?.urlProtocol(self, didLoad: Self.data)
        self.client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}
