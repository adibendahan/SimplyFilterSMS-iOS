//
//  ApplicationTestCase.swift
//  UI Tests
//
//  Created by Adi Ben-Dahan on 18/06/2022.
//

import XCTest
import UIKit

class ApplicationTestCase: XCTestCase {
    private let snapshotBasePath = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent(".screenshots")
        .path

    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func sleep(seconds: Double) {
        let delayExpectation = XCTestExpectation()
        delayExpectation.isInverted = true
        wait(for: [delayExpectation], timeout: seconds)
    }

    /// Sheet/push/keyboard animations and Home footer layout.
    func waitForUIToSettle() {
        sleep(seconds: 2.0)
    }

    func snapshotSettled(_ name: String, file: StaticString = #file, line: UInt = #line) {
        waitForUIToSettle()
        snapshot(name, file: file, line: line)
    }

    func snapshot(_ name: String, file: StaticString = #file, line: UInt = #line) {
        let screenshot = XCUIScreen.main.screenshot()
        var image = screenshot.image
        if XCUIDevice.shared.orientation.isLandscape {
            image = Self.uprightImage(image)
        }
        guard let imageData = image.pngData() else {
            XCTFail("Failed to encode screenshot", file: file, line: line)
            return
        }

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

    private static func uprightImage(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
