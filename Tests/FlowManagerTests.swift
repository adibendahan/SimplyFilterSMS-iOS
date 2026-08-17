//
//  FlowManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FlowManagerTests: XCTestCase {

    private var defaultsManager: mock_DefaultsManager!
    private var isFirstRun = true
    private var lastSeenWhatsNewVersion = 0
    private var testSubject: FlowManager!

    override func setUp() {
        super.setUp()
        self.isFirstRun = true
        self.lastSeenWhatsNewVersion = 0
        self.defaultsManager = mock_DefaultsManager()
        self.defaultsManager.isAppFirstRunClosure = { [unowned self] in
            return self.isFirstRun
        }
        self.defaultsManager.lastSeenWhatsNewVersionClosure = { [unowned self] in
            return self.lastSeenWhatsNewVersion
        }
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
    }

    override func tearDown() {
        self.testSubject = nil
        self.defaultsManager = nil
        super.tearDown()
    }

    func test_firstRun_winsOverFileAndWhatsNew() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.next(), .enableExtension)
        XCTAssertNil(self.testSubject.next())
    }

    func test_importWaitsUntilFirstRunCompletes() {
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))

        XCTAssertEqual(self.testSubject.next(), .enableExtension)

        self.isFirstRun = false
        XCTAssertNil(self.testSubject.next())

        self.testSubject.complete(.enableExtension)
        XCTAssertEqual(self.testSubject.next(), .filterImport)
    }

    func test_afterFirstRun_fileBeatsWhatsNew() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.enableWhatsNew()

        XCTAssertEqual(self.testSubject.next(), .filterImport)
    }

    func test_whatsNew_waitsUntilEnabled() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)

        XCTAssertNil(self.testSubject.next())
        self.testSubject.enableWhatsNew()
        XCTAssertEqual(self.testSubject.next(), .whatsNew)
    }

    func test_whatsNew_skippedWhenLaunchClaimedSession() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.complete(.filterImport)
        self.testSubject.enableWhatsNew()

        XCTAssertNil(self.testSubject.next())
    }

    func test_lastLaunchURLWins() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        XCTAssertTrue(self.testSubject.recordLaunch(.tipJar))

        XCTAssertEqual(self.testSubject.next(), .tipJar)
    }

    func test_userRequest_doesNotBeatFirstRun() {
        self.testSubject.request(.about)

        XCTAssertEqual(self.testSubject.next(), .enableExtension)
    }

    func test_userRequest_afterFirstRun() {
        self.isFirstRun = false
        self.lastSeenWhatsNewVersion = currentWhatsNewVersion
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        self.testSubject.request(.about)

        XCTAssertEqual(self.testSubject.next(), .about)
    }

    func test_userRequest_whatsNew_afterLaunchClaimedSession() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.filterImport))
        self.testSubject.complete(.filterImport)
        self.testSubject.request(.whatsNew)

        XCTAssertEqual(self.testSubject.next(), .whatsNew)
    }

    func test_enableExtensionDeepLink_ignoredDuringFirstRun() {
        XCTAssertFalse(self.testSubject.recordLaunch(.enableExtension))
        XCTAssertEqual(self.testSubject.next(), .enableExtension)

        self.isFirstRun = false
        self.testSubject.complete(.enableExtension)
        XCTAssertNil(self.testSubject.next())
    }

    func test_recordLaunch_returnsTrueWhenQueued() {
        self.isFirstRun = false
        self.testSubject = FlowManager(defaultsManager: self.defaultsManager)
        XCTAssertTrue(self.testSubject.recordLaunch(.tipJar))
    }
}
