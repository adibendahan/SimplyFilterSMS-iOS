//
//  OverlayWindowModifier.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 06/11/2026.
//

import SwiftUI
import UIKit

//MARK: - View -
struct OverlayWindowModifier: ViewModifier {
    let model: ViewModel

    func body(content: Content) -> some View {
        content
            .background(OverlayWindowInstaller(model: self.model))
    }
}


//MARK: - ViewModel -
extension OverlayWindowModifier {

    class ViewModel: BaseViewModel, ObservableObject {
        let toastViewModel: ToastView.ViewModel
        @Published private(set) var confettiTier: TipTier?

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.toastViewModel = ToastView.ViewModel(toast: .offline)
            super.init(appManager: appManager)

            appManager.flowManager.setToastPresenter { [weak self] in
                self?.showNextToast()
            }
            self.showNextToast()
        }

        func hideToast() {
            self.delayedToastShow?.cancel()
            self.delayedToastShow = nil
            self.toastViewModel.show = false
        }

        private func showNextToast() {
            guard let nextToast = self.appManager.flowManager.nextToast() else {
                self.hideToastIfCancelled()
                return
            }
            self.presentToast(nextToast)
        }

        private func hideToastIfCancelled() {
            guard !self.appManager.flowManager.isToastShowing else { return }
            self.hideToast()
        }

        private func presentToast(_ toast: ToastView.Toast) {
            guard !self.toastViewModel.show else {
                self.replaceToast(with: toast)
                return
            }

            self.configureToast(toast)
            self.toastViewModel.setToast(toast)
            self.showToast(after: toast.showDelay)
        }

        private func replaceToast(with toast: ToastView.Toast) {
            Log.debug("toast replaced, toast: \(toast.logName)")
            self.toastViewModel.onHide = nil
            withAnimation {
                self.toastViewModel.show = false
            }

            self.showToast(after: self.kToastReplaceDelay) { [weak self] in
                self?.configureToast(toast)
                self?.toastViewModel.setToast(toast)
            }
        }

        private func showToast(after delay: TimeInterval, prepare: (() -> Void)? = nil) {
            self.delayedToastShow?.cancel()
            let delayedToastShow = DispatchWorkItem { [weak self] in
                prepare?()
                withAnimation {
                    self?.toastViewModel.show = true
                }
            }
            self.delayedToastShow = delayedToastShow
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: delayedToastShow)
        }

        private func configureToast(_ toast: ToastView.Toast) {
            Log.debug("toast shown, toast: \(toast.logName), delay: \(toast.showDelay)")
            self.toastViewModel.onHide = { [weak self] in
                Log.debug("toast hidden, toast: \(toast.logName)")
                self?.confettiTier = nil
                self?.appManager.flowManager.completeToast(toast)
            }

            let onTap = { [weak self] in
                guard let self else { return }
                withAnimation { self.toastViewModel.show = false }
                self.appManager.flowManager.didTapToast(toast)
            }
            let onDismiss = { [weak self] in
                guard let self else { return }
                self.appManager.flowManager.didDismissToast(toast)
            }

            self.toastViewModel.onTap = toast.isTappable ? onTap : nil
            self.toastViewModel.setOnButtonTap(toast.buttonActsAsTap ? onTap : onDismiss)
            self.confettiTier = toast.confettiTier
        }

        private let kToastReplaceDelay: TimeInterval = 0.35
        private var delayedToastShow: DispatchWorkItem?
    }
}


//MARK: - Window -
private struct OverlayWindowInstaller: UIViewRepresentable {
    let model: OverlayWindowModifier.ViewModel

    func makeUIView(context: Context) -> OverlayWindowAnchor {
        return OverlayWindowAnchor(model: self.model)
    }

    func updateUIView(_ uiView: OverlayWindowAnchor, context: Context) {
    }
}

private final class OverlayWindowAnchor: UIView {
    private let model: OverlayWindowModifier.ViewModel
    private var overlayWindow: PassthroughWindow?

    init(model: OverlayWindowModifier.ViewModel) {
        self.model = model
        super.init(frame: .zero)
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard self.overlayWindow == nil,
              let windowScene = self.window?.windowScene else { return }

        let host = UIHostingController(rootView: OverlayWindowContent(model: self.model))
        host.view.backgroundColor = .clear

        let overlayWindow = PassthroughWindow(windowScene: windowScene, toastViewModel: self.model.toastViewModel)
        overlayWindow.rootViewController = host
        overlayWindow.windowLevel = UIWindow.Level(UIWindow.Level.normal.rawValue + 1)
        overlayWindow.isHidden = false
        self.overlayWindow = overlayWindow
    }
}

private final class PassthroughWindow: UIWindow {
    private let toastViewModel: ToastView.ViewModel

    init(windowScene: UIWindowScene, toastViewModel: ToastView.ViewModel) {
        self.toastViewModel = toastViewModel
        super.init(windowScene: windowScene)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.toastViewModel.show && self.toastViewModel.visibleFrame.contains(point)
    }
}

private struct OverlayWindowContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var model: OverlayWindowModifier.ViewModel

    var body: some View {
        ZStack(alignment: .top) {
            if !self.reduceMotion, let confettiTier = self.model.confettiTier {
                ConfettiView(
                    birthRate: confettiTier.confettiBirthRate,
                    lifetime: confettiTier.confettiLifetime,
                    velocity: confettiTier.confettiVelocity
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            ToastView(model: self.model.toastViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .adaptiveLayoutEnvironment()
    }
}
