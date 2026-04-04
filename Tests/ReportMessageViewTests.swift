//
//  ReportMessageViewTests.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 20/03/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS


class ReportMessageViewTests: XCTestCase {

    var mockAppManager: mock_AppManager!
    var mockReportService: mock_ReportMessageService!
    var testSubject: ReportMessageView.ViewModel!

    //MARK: Test Lifecycle

    override func setUp() {
        super.setUp()

        self.mockAppManager = mock_AppManager()
        self.mockReportService = mock_ReportMessageService()
        self.mockAppManager.reportMessageService = self.mockReportService
        self.testSubject = ReportMessageView.ViewModel(appManager: self.mockAppManager)
    }

    override func tearDown() {
        super.tearDown()

        self.testSubject = nil
        self.mockReportService = nil
        self.mockAppManager = nil
    }


    //MARK: Tests

    func test_initialState() {
        XCTAssertEqual(self.testSubject.state, .userInput)
        XCTAssertEqual(self.testSubject.text, "")
        XCTAssertEqual(self.testSubject.sender, "")
        XCTAssertEqual(self.testSubject.selectedReport, .junk)
    }

    func test_reportMessage_transitionsToLoadingThenResult() async {
        // Prepare
        self.testSubject.sender = "12345"
        self.testSubject.text = "Buy cheap meds"
        self.mockReportService.reportMessageClosure = { _ in return true }

        // Act
        self.testSubject.reportMessage()

        // Assert loading state is set synchronously
        XCTAssertEqual(self.testSubject.state, .loading)

        // Wait for async task to complete (minimum delay in reportMessage is 1.5s)
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Assert result state
        if case .result(let text) = self.testSubject.state {
            XCTAssertFalse(text.isEmpty, "Result text should not be empty")
        } else {
            XCTFail("Expected .result state, got \(self.testSubject.state)")
        }
    }

    func test_reportMessage_callsServiceWithCorrectParameters() async {
        // Prepare
        self.testSubject.sender = "99887"
        self.testSubject.text = "Win a prize"
        self.testSubject.selectedReport = .junk

        var capturedBody: ReportMessageRequestBody?
        self.mockReportService.reportMessageClosure = { body in
            capturedBody = body
            return true
        }

        // Act
        self.testSubject.reportMessage()
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Assert
        XCTAssertEqual(self.mockReportService.reportMessageCounter, 1)
        XCTAssertEqual(capturedBody?.sender, "99887")
        XCTAssertEqual(capturedBody?.body, "Win a prize")
    }

    func test_reportMessage_transitionsToResultEvenOnFailure() async {
        // Prepare
        self.testSubject.sender = "12345"
        self.testSubject.text = "Some text"
        self.mockReportService.reportMessageClosure = { _ in return false }

        // Act
        self.testSubject.reportMessage()
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Assert — result state reached regardless of service success/failure
        XCTAssertTrue(self.testSubject.state.isResult, "Should show result state even when service returns false")
    }
}
