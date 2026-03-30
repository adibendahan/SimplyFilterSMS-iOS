//
//  ApplicationTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 18/06/2022.
//

import XCTest

class ApplicationTestCase: XCTestCase {
    private let snapshotBasePath = "/Users/adi/Developer/SimplyFilterSMS-iOS/.screenshots"

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func sleep(seconds: Double) {
        let delayExpectation = XCTestExpectation()
        delayExpectation.isInverted = true
        wait(for: [delayExpectation], timeout: seconds)
    }

    func snapshot(_ name: String, file: StaticString = #file, line: UInt = #line) {
        let screenshot = XCUIScreen.main.screenshot()
        let imageData = screenshot.pngRepresentation

        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "UnknownDevice"
        let safeSimulator = simulatorName.replacingOccurrences(of: " ", with: "_")
        let locale = Locale.current.language.languageCode?.identifier ?? "UnknownLanguage"

        let baseURL = URL(fileURLWithPath: snapshotBasePath, isDirectory: true)
        let localeFolderURL = baseURL.appendingPathComponent(locale, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: localeFolderURL, withIntermediateDirectories: true)
        } catch {
            XCTFail("Failed to create directory: \(error)", file: file, line: line)
            return
        }

        let fileName = "\(safeSimulator)_\(name).png"
        let fileURL = localeFolderURL.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            print("📸 Saved snapshot: \(fileURL.path)")
        } catch {
            XCTFail("Failed to save screenshot: \(error)", file: file, line: line)
        }

        let attachment = XCTAttachment(data: imageData, uniformTypeIdentifier: "public.png")
        attachment.name = fileName
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
