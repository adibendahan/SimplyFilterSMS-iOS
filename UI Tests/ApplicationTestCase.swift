//
//  ApplicationTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 18/06/2022.
//

import XCTest

class ApplicationTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    func sleep(seconds: Double) {
        let delayExpectation = XCTestExpectation()
        delayExpectation.isInverted = true
        wait(for: [delayExpectation], timeout: seconds)
    }
}
