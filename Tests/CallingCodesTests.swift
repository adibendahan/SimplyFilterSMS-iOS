//
//  CallingCodesTests.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 13/03/2026.
//

import XCTest
@testable import Simply_Filter_SMS

class CallingCodesTests: XCTestCase {

    func test_e164_match() {
        // +972 — Israel
        let entry = CallingCodes.callingCode(for: "+97250123456")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.callingCode, "+972")
    }

    func test_formattedNumber_normalization() {
        // Spaces, dashes, parentheses should be stripped
        let entry = CallingCodes.callingCode(for: "+972 050-123-4567")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.callingCode, "+972")
    }

    func test_alphanumericSender_returnsNil() {
        XCTAssertNil(CallingCodes.callingCode(for: "Apple"))
        XCTAssertNil(CallingCodes.callingCode(for: "BANK"))
    }

    func test_localFormatNumber_returnsNil() {
        // No leading +
        XCTAssertNil(CallingCodes.callingCode(for: "0501234567"))
        XCTAssertNil(CallingCodes.callingCode(for: "12345"))
    }

    func test_unrecognizedPlusPrefix_returnsNil() {
        // +0 is not a valid ITU country code
        XCTAssertNil(CallingCodes.callingCode(for: "+0123456789"))
    }

    func test_nanpGroupedCode() {
        // +1868 is Trinidad — should resolve to the NANP group (+1)
        let entry = CallingCodes.callingCode(for: "+18682001234")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.callingCode, "+1")
        XCTAssertTrue(entry?.isoCountryCodes.contains("US") ?? false)
    }

    func test_sharedCode_plusSeven() {
        // +7 — Russia & Kazakhstan
        let entry = CallingCodes.callingCode(for: "+79161234567")
        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.callingCode, "+7")
        XCTAssertTrue(entry?.isoCountryCodes.contains("RU") ?? false)
    }

    func test_longestPrefixWins() {
        // +972 should win over a hypothetical +97 or +9 match
        let entry = CallingCodes.callingCode(for: "+97250000000")
        XCTAssertEqual(entry?.callingCode, "+972")
    }
}
