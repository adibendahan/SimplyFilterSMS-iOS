//
//  mock_FlowManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FlowManager: FlowManagerProtocol {

    var recordLaunchCounter = 0
    var requestCounter = 0
    var enableWhatsNewCounter = 0
    var enableNotificationPermissionExplainerCounter = 0
    var nextCounter = 0
    var completeCounter = 0
    var resetSessionCounter = 0

    var nextScreen: Screen?
    var recordLaunchClosure: ((Screen) -> Bool)?
    var requestClosure: ((Screen) -> ())?
    var nextClosure: (() -> Screen?)?
    var completeClosure: ((Screen) -> ())?

    func recordLaunch(_ screen: Screen) -> Bool {
        self.recordLaunchCounter += 1
        return self.recordLaunchClosure?(screen) ?? true
    }

    func request(_ screen: Screen) {
        self.requestCounter += 1
        self.requestClosure?(screen)
    }

    func enableWhatsNew() {
        self.enableWhatsNewCounter += 1
    }

    func enableNotificationPermissionExplainer() {
        self.enableNotificationPermissionExplainerCounter += 1
    }

    func next() -> Screen? {
        self.nextCounter += 1
        if let nextClosure = self.nextClosure {
            return nextClosure()
        }
        return self.nextScreen
    }

    func complete(_ screen: Screen) {
        self.completeCounter += 1
        self.completeClosure?(screen)
    }

    func resetSession() {
        self.resetSessionCounter += 1
    }
}
