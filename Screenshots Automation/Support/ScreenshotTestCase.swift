//
//  ScreenshotTestCase.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

@MainActor
class ScreenshotTestCase: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        self.continueAfterFailure = false
    }

    override func tearDown() async throws {
        self.deliverIfPassed()
        try await super.tearDown()
    }

    func launchStudio() -> ScreenshotStudio {
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeRight
        }
        let studio = ScreenshotStudio()
        self.studio = studio
        return studio
    }

    func capture(_ shot: Shot, file: StaticString = #filePath, line: UInt = #line) {
        guard let studio = self.studio else {
            XCTFail("\(shot) was captured before the app was launched", file: file, line: line)
            return
        }
        self.settle()
        let screen = Self.screen(showing: studio.device)
        let upright = Self.upright(screen.screenshot())
        let image = Self.stretched(upright, to: studio.device.stretchedPixelSize)
        guard let data = image.pngData() else {
            XCTFail("\(shot) could not be encoded", file: file, line: line)
            return
        }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = shot.attachmentName(on: studio.device)
        attachment.lifetime = .keepAlways
        self.add(attachment)
        let pendingShot = PendingShot(data: data, fileName: shot.fileName(on: studio.device))
        self.pendingShots.append(pendingShot)
    }

    //MARK: - Private -
    private var studio: ScreenshotStudio?
    private let settleDuration: TimeInterval = 1.5
    private let deliveryFolderKey = "SCREENSHOT_DELIVERY_FOLDER"
    private var pendingShots: [PendingShot] = []

    private struct PendingShot {
        let data: Data
        let fileName: String
    }

    private func deliverIfPassed() {
        let failureCount = self.testRun?.totalFailureCount ?? 0
        guard let folder = ProcessInfo.processInfo.environment[self.deliveryFolderKey],
              failureCount == 0 else { return }
        for pendingShot in self.pendingShots {
            let destination = URL(fileURLWithPath: folder).appendingPathComponent(pendingShot.fileName)
            do {
                try pendingShot.data.write(to: destination, options: .atomic)
            } catch {
                XCTFail("\(pendingShot.fileName) could not be written to \(folder): \(error)")
            }
        }
    }

    private func settle() {
        let animationsFinished = XCTestExpectation(description: "animations finished")
        animationsFinished.isInverted = true
        self.wait(for: [animationsFinished], timeout: self.settleDuration)
    }

    private static func screen(showing device: ShotDevice) -> XCUIScreen {
        guard device == .duoInner else { return XCUIScreen.main }
        let largest = XCUIScreen.screens.max { Self.pixelCount(of: $0) < Self.pixelCount(of: $1) }
        return largest ?? XCUIScreen.main
    }

    private static func pixelCount(of screen: XCUIScreen) -> CGFloat {
        let image = screen.screenshot().image
        return image.size.width * image.size.height * image.scale * image.scale
    }

    private static func stretched(_ image: UIImage, to pixelSize: CGSize?) -> UIImage {
        guard let pixelSize, image.size != pixelSize else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }

    private static func upright(_ screenshot: XCUIScreenshot) -> UIImage {
        let image = screenshot.image
        guard let pixels = UIImage(data: screenshot.pngRepresentation)?.cgImage else { return image }
        let exact = UIImage(cgImage: pixels, scale: 1, orientation: image.imageOrientation)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: exact.size, format: format)
        return renderer.image { _ in
            exact.draw(in: CGRect(origin: .zero, size: exact.size))
        }
    }
}
