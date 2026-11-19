//
//  ScenarioTestCase.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
class ScenarioTestCase: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        self.continueAfterFailure = false
    }

    func launchApp(remoteLists: SimplyFilterApp.RemoteLists = .off, phoneLanguages: [Language] = [.english]) -> SimplyFilterApp {
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeRight
        }
        return SimplyFilterApp(remoteLists: remoteLists, phoneLanguages: phoneLanguages)
    }
}
