//
//  XCUIElement+Waiting.swift
//  UI Test Kit
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

extension XCUIElement {
    func waitForValue(_ value: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    func waitUntil(_ keyPath: KeyPath<XCUIElement, Bool>, timeout: TimeInterval = 8) -> Bool {
        guard self.waitForExistence(timeout: timeout) else { return false }
        return self.wait(for: keyPath, toEqual: true, timeout: timeout)
    }
}
