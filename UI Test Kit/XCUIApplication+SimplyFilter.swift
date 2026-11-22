//
//  XCUIApplication+SimplyFilter.swift
//  UI Test Kit
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

extension XCUIApplication {
    @MainActor
    static func launchSimplyFilter(arguments: [String], environment: [String: String] = [:]) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.grizz.apps.dev.Simply-Filter-SMS")
        app.launchArguments = ["-Testing"] + arguments
        app.launchEnvironment = environment
        app.launch()
        app.dismissLaunchScreens()
        return app
    }

    var hasWideWindow: Bool {
        let frame = self.windows.firstMatch.frame
        return frame.width > frame.height
    }

    //MARK: - Private -
    @MainActor
    private func dismissLaunchScreens() {
        XCTAssertTrue(self.buttons[.appMenuButton].waitForExistence(timeout: 15), "Home did not appear")
        let callToAction = self.buttons[.callToActionButton]
        while callToAction.exists {
            let cancel = self.buttons[.cancelButton]
            if cancel.exists {
                cancel.tap()
            }
            else {
                callToAction.tap()
            }
            _ = callToAction.waitForNonExistence(timeout: 3)
            _ = callToAction.waitForExistence(timeout: 1)
        }
    }
}
