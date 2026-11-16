//
//  ShotDevice.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 17/11/2026.
//

import XCTest

enum ShotDevice: String {
    case iphone
    case ipad
    case duoOuter = "duo-outer"
    case duoInner = "duo-inner"

    @MainActor
    init(app: XCUIApplication) {
        let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
        let isDuo = model == Self.duoModelIdentifier
        let isWide = app.hasWideWindow
        switch (isDuo, isWide) {
        case (true, true):
            self = .duoInner
        case (true, false):
            self = .duoOuter
        case (false, true):
            self = .ipad
        case (false, false):
            self = .iphone
        }
    }

    var usesSplitLayout: Bool {
        switch self {
        case .ipad, .duoInner:
            return true
        case .iphone, .duoOuter:
            return false
        }
    }

    var stretchedPixelSize: CGSize? {
        switch self {
        case .duoInner:
            return CGSize(width: 2853, height: 2007)
        case .iphone, .ipad, .duoOuter:
            return nil
        }
    }

    //MARK: - Private -
    private static let duoModelIdentifier = "iPhone19,4"
}
