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
    var requestScreenCounter = 0
    var enableWhatsNewCounter = 0
    var nextScreenCounter = 0
    var completeScreenCounter = 0
    var resetSessionCounter = 0
    var startAppEventToastsCounter = 0
    var setToastPresenterCounter = 0
    var setScreenPresenterCounter = 0
    var setHomeIdleCheckCounter = 0
    var showWaitingNudgeCounter = 0
    var requestToastCounter = 0
    var nextToastCounter = 0
    var completeToastCounter = 0
    var didTapToastCounter = 0
    var didDismissToastCounter = 0
    var showSessionNudgesCounter = 0
    var didShowToastThisSessionGetCounter = 0
    var isToastShowingGetCounter = 0

    var recordLaunchClosure: ((Screen) -> Bool)?
    var requestScreenClosure: ((Screen) -> ())?
    var enableWhatsNewClosure: (() -> ())?
    var nextScreenClosure: (() -> Screen?)?
    var completeScreenClosure: ((Screen) -> ())?
    var resetSessionClosure: (() -> ())?
    var startAppEventToastsClosure: (() -> ())?
    var setToastPresenterClosure: ((@escaping () -> Void) -> ())?
    var setScreenPresenterClosure: ((@escaping () -> Void) -> ())?
    var setHomeIdleCheckClosure: ((@escaping () -> Bool) -> ())?
    var showWaitingNudgeClosure: (() -> ())?
    var requestToastClosure: ((ToastView.Toast) -> ())?
    var nextToastClosure: (() -> ToastView.Toast?)?
    var completeToastClosure: ((ToastView.Toast) -> ())?
    var didTapToastClosure: ((ToastView.Toast) -> ())?
    var didDismissToastClosure: ((ToastView.Toast) -> ())?
    var showSessionNudgesClosure: (() -> ())?
    var didShowToastThisSessionClosure: (() -> Bool)?
    var isToastShowingClosure: (() -> Bool)?

    var didShowToastThisSession: Bool {
        self.didShowToastThisSessionGetCounter += 1
        return self.didShowToastThisSessionClosure?() ?? false
    }

    var isToastShowing: Bool {
        self.isToastShowingGetCounter += 1
        return self.isToastShowingClosure?() ?? false
    }

    func recordLaunch(_ screen: Screen) -> Bool {
        self.recordLaunchCounter += 1
        return self.recordLaunchClosure?(screen) ?? true
    }

    func requestScreen(_ screen: Screen) {
        self.requestScreenCounter += 1
        self.requestScreenClosure?(screen)
    }

    func enableWhatsNew() {
        self.enableWhatsNewCounter += 1
        self.enableWhatsNewClosure?()
    }

    func nextScreen() -> Screen? {
        self.nextScreenCounter += 1
        return self.nextScreenClosure?()
    }

    func completeScreen(_ screen: Screen) {
        self.completeScreenCounter += 1
        self.completeScreenClosure?(screen)
    }

    func resetSession() {
        self.resetSessionCounter += 1
        self.resetSessionClosure?()
    }

    func startAppEventToasts() {
        self.startAppEventToastsCounter += 1
        self.startAppEventToastsClosure?()
    }

    func setToastPresenter(_ showNextToast: @escaping () -> Void) {
        self.setToastPresenterCounter += 1
        self.setToastPresenterClosure?(showNextToast)
    }

    func setScreenPresenter(_ presentNextScreen: @escaping () -> Void) {
        self.setScreenPresenterCounter += 1
        self.setScreenPresenterClosure?(presentNextScreen)
    }

    func setHomeIdleCheck(_ isHomeIdle: @escaping () -> Bool) {
        self.setHomeIdleCheckCounter += 1
        self.setHomeIdleCheckClosure?(isHomeIdle)
    }

    func showWaitingNudge() {
        self.showWaitingNudgeCounter += 1
        self.showWaitingNudgeClosure?()
    }

    func requestToast(_ toast: ToastView.Toast) {
        self.requestToastCounter += 1
        self.requestToastClosure?(toast)
    }

    func nextToast() -> ToastView.Toast? {
        self.nextToastCounter += 1
        return self.nextToastClosure?()
    }

    func completeToast(_ toast: ToastView.Toast) {
        self.completeToastCounter += 1
        self.completeToastClosure?(toast)
    }

    func didTapToast(_ toast: ToastView.Toast) {
        self.didTapToastCounter += 1
        self.didTapToastClosure?(toast)
    }

    func didDismissToast(_ toast: ToastView.Toast) {
        self.didDismissToastCounter += 1
        self.didDismissToastClosure?(toast)
    }

    func showSessionNudges() {
        self.showSessionNudgesCounter += 1
        self.showSessionNudgesClosure?()
    }

    func resetCounters() {
        self.recordLaunchCounter = 0
        self.requestScreenCounter = 0
        self.enableWhatsNewCounter = 0
        self.nextScreenCounter = 0
        self.completeScreenCounter = 0
        self.resetSessionCounter = 0
        self.startAppEventToastsCounter = 0
        self.setToastPresenterCounter = 0
        self.setScreenPresenterCounter = 0
        self.setHomeIdleCheckCounter = 0
        self.showWaitingNudgeCounter = 0
        self.requestToastCounter = 0
        self.nextToastCounter = 0
        self.completeToastCounter = 0
        self.didTapToastCounter = 0
        self.didDismissToastCounter = 0
        self.showSessionNudgesCounter = 0
        self.didShowToastThisSessionGetCounter = 0
        self.isToastShowingGetCounter = 0
    }
}
