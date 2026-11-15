//
//  ScreenshotTestCase.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

@MainActor
class ScreenshotTestCase: XCTestCase {
    var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    override func setUp() async throws {
        try await super.setUp()
        self.continueAfterFailure = false
    }

    @discardableResult
    func launchStudio() -> ScreenshotStudio {
        if self.isPad {
            XCUIDevice.shared.orientation = .landscapeRight
        }
        return ScreenshotStudio()
    }

    func capture(_ shot: Shot, file: StaticString = #filePath, line: UInt = #line) {
        self.settle()
        var image = XCUIScreen.main.screenshot().image
        if XCUIDevice.shared.orientation.isLandscape {
            image = Self.upright(image)
        }
        guard let data = image.pngData() else {
            XCTFail("\(shot) could not be encoded", file: file, line: line)
            return
        }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
        attachment.name = shot.attachmentName
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }

    //MARK: - Private -
    private let settleDuration: TimeInterval = 1.5

    private func settle() {
        let animationsFinished = XCTestExpectation(description: "animations finished")
        animationsFinished.isInverted = true
        self.wait(for: [animationsFinished], timeout: self.settleDuration)
    }

    private static func upright(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
