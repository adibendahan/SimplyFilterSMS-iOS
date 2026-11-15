//
//  Element.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

extension XCUIElementQuery {
    subscript(_ identifier: TestIdentifier) -> XCUIElement {
        return self[identifier.rawValue].firstMatch
    }
}
