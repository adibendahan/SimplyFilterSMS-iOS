//
//  DefaultsManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 20/08/2026.
//

import Foundation
import SwiftUI
import XCTest
@testable import Simply_Filter_SMS

class DefaultsManagerTests: XCTestCase {

    private var previousRGB: [String: Double] = kNoColorDict
    private var testSubject: DefaultsManager!

    override func setUp() {
        super.setUp()
        self.testSubject = DefaultsManager()
        self.previousRGB = self.testSubject.accentColorRGB
        self.testSubject.accentColorRGB = kNoColorDict
    }

    override func tearDown() {
        self.testSubject.accentColorRGB = self.previousRGB
        self.testSubject = nil
        super.tearDown()
    }

    func test_accentColorRGB_defaultMeansNoColor() {
        XCTAssertEqual(self.testSubject.accentColorRGB, kNoColorDict)
        XCTAssertNil(Color(accentRGB: self.testSubject.accentColorRGB))
    }

    func test_accentColorRGB_roundTrip() {
        let rgb = ["red": 1.0, "green": 0.0, "blue": 0.0]
        self.testSubject.accentColorRGB = rgb

        XCTAssertEqual(self.testSubject.accentColorRGB["red"] ?? 0, 1, accuracy: 0.02)
        XCTAssertEqual(self.testSubject.accentColorRGB["green"] ?? 1, 0, accuracy: 0.02)
        XCTAssertEqual(self.testSubject.accentColorRGB["blue"] ?? 1, 0, accuracy: 0.02)
        XCTAssertNotNil(Color(accentRGB: self.testSubject.accentColorRGB))
    }

    func test_accentColorRGB_readsNumberDictionaryWithoutWiping() {
        UserDefaults.standard.set(
            ["red": NSNumber(value: 0.2), "green": NSNumber(value: 0.4), "blue": NSNumber(value: 0.6)],
            forKey: "accentColorRGB"
        )

        XCTAssertEqual(self.testSubject.accentColorRGB["red"] ?? 0, 0.2, accuracy: 0.02)
        XCTAssertEqual(self.testSubject.accentColorRGB["green"] ?? 0, 0.4, accuracy: 0.02)
        XCTAssertEqual(self.testSubject.accentColorRGB["blue"] ?? 0, 0.6, accuracy: 0.02)
        XCTAssertNotNil(Color(accentRGB: self.testSubject.accentColorRGB))
        XCTAssertEqual(self.testSubject.accentColorRGB["red"] ?? 0, 0.2, accuracy: 0.02)
    }

    func test_accentColorRGB_resetClearsStorage() {
        self.testSubject.accentColorRGB = ["red": 0, "green": 1, "blue": 0]
        self.testSubject.accentColorRGB = kNoColorDict

        XCTAssertEqual(self.testSubject.accentColorRGB, kNoColorDict)
        XCTAssertNil(Color(accentRGB: self.testSubject.accentColorRGB))
    }
}
