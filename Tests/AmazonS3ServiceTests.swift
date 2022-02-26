//
//  AmazonS3ServiceTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 15/02/2022.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AmazonS3ServiceTests: XCTestCase {

    var httpService = mock_HTTPService()
    
    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        
        self.httpService = mock_HTTPService()
        self.testSubject = AmazonS3Service(httpService: self.httpService)
    }
    
    //MARK: Tests
    func test_fetchAutomaticFilters() {
        // Prepare
        var correctType = false
        var correctTask = false
        var correctURL = false
        var correctPath = false
        var correctHTTPMethod = false
        let expectation = self.expectation(description: "URLRequest")

        self.httpService.executeClosure = { (type, baseURL, request) in
            correctType = type is AutomaticFilterListsResponse.Type?
            correctURL = baseURL.absoluteString == "https://grizz-apps-dev.s3.us-east-2.amazonaws.com"
            correctPath = request.path == "/simply-filter-sms/1.0.0/automatic_filters.json"
            correctHTTPMethod = request.method == .get
            correctTask = request.task.isPlain
        }
        
        // Act
        Task (priority: .userInitiated) {
            let _ = await self.testSubject.fetchAutomaticFilters()
            expectation.fulfill()
        }
        
        // Verify
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(self.httpService.executeCounter, 1)
        XCTAssertTrue(correctURL)
        XCTAssertTrue(correctPath)
        XCTAssertTrue(correctHTTPMethod)
        XCTAssertTrue(correctTask)
        XCTAssertTrue(correctType)
    }
    
    // MARK: Private Variables and Helpers
    private var testSubject: AmazonS3ServiceProtocol = AmazonS3Service(httpService: mock_HTTPService())
}
