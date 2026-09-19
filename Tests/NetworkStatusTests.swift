//
//  NetworkStatusTests.swift
//  Tests
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class NetworkStatusTests: XCTestCase {

    func test_comingBackFromOfflineIsAReconnection() {
        XCTAssertTrue(NetworkStatus.online.isReconnection(from: .offline))
    }

    func test_theFirstReportIsNotAReconnection() {
        XCTAssertFalse(NetworkStatus.online.isReconnection(from: .unknown))
        XCTAssertFalse(NetworkStatus.offline.isReconnection(from: .unknown))
    }

    func test_nothingElseIsAReconnection() {
        XCTAssertFalse(NetworkStatus.online.isReconnection(from: .online))
        XCTAssertFalse(NetworkStatus.offline.isReconnection(from: .online))
        XCTAssertFalse(NetworkStatus.offline.isReconnection(from: .offline))
        XCTAssertFalse(NetworkStatus.unknown.isReconnection(from: .offline))
        XCTAssertFalse(NetworkStatus.unknown.isReconnection(from: .online))
    }
}
