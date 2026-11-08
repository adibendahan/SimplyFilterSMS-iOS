//
//  FlowManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/08/2026.
//

import Foundation

protocol FlowManagerProtocol {
    var didShowToastThisSession: Bool { get }
    var isToastShowing: Bool { get }

    func recordLaunch(_ screen: Screen) -> Bool
    func setScreenPresenter(_ presentNextScreen: @escaping () -> Void)
    func requestScreen(_ screen: Screen)
    func enableWhatsNew()
    func nextScreen() -> Screen?
    func completeScreen(_ screen: Screen)
    func resetSession()

    func startAppEventToasts()
    func setToastPresenter(_ showNextToast: @escaping () -> Void)
    func setHomeIdleCheck(_ isHomeIdle: @escaping () -> Bool)
    func requestToast(_ toast: ToastView.Toast)
    func nextToast() -> ToastView.Toast?
    func completeToast(_ toast: ToastView.Toast)
    func didTapToast(_ toast: ToastView.Toast)
    func didDismissToast(_ toast: ToastView.Toast)
    func showSessionNudges()
    func showWaitingNudge()
}
