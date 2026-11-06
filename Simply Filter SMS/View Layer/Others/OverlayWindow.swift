//
//  OverlayWindow.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 06/11/2026.
//

import SwiftUI
import UIKit

//MARK: - View -
struct OverlayWindowView: ViewModifier {
    let model: ViewModel

    func body(content: Content) -> some View {
        content
            .background(OverlayWindowInstaller(model: self.model))
    }
}


//MARK: - ViewModel -
extension OverlayWindowView {

    class ViewModel: BaseViewModel, ObservableObject {
        let notification: NotificationView.ViewModel
        @Published private(set) var confettiTier: TipTier?

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.notification = NotificationView.ViewModel(notification: .offline)
            super.init(appManager: appManager)

            NotificationCenter.default.addObserver(forName: .notificationSlotChanged, object: nil, queue: .main) { [weak self] _ in
                self?.showNext()
            }
            self.showNext()
        }

        func hide() {
            self.delayedShow?.cancel()
            self.delayedShow = nil
            self.notification.show = false
        }

        private func showNext() {
            guard let nextNotification = self.appManager.flowManager.nextNotification() else {
                self.hideIfCancelled()
                return
            }
            self.present(nextNotification)
        }

        private func hideIfCancelled() {
            guard !self.appManager.flowManager.isNotificationShowing else { return }
            self.hide()
        }

        private func present(_ notification: NotificationView.Notification) {
            guard !self.notification.show else {
                self.replace(with: notification)
                return
            }

            self.configure(for: notification)
            self.notification.setNotification(notification)
            self.show(after: notification.showDelay)
        }

        private func replace(with notification: NotificationView.Notification) {
            let notificationName = String(describing: notification)
            AppManager.logger.debug("Notification — replacing with: \(notificationName, privacy: .public)")
            self.notification.onHide = nil
            withAnimation {
                self.notification.show = false
            }

            self.show(after: self.kReplaceDelay) { [weak self] in
                self?.configure(for: notification)
                self?.notification.setNotification(notification)
            }
        }

        private func show(after delay: TimeInterval, prepare: (() -> Void)? = nil) {
            self.delayedShow?.cancel()
            let delayedShow = DispatchWorkItem { [weak self] in
                prepare?()
                withAnimation {
                    self?.notification.show = true
                }
            }
            self.delayedShow = delayedShow
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: delayedShow)
        }

        private func configure(for notification: NotificationView.Notification) {
            let notificationName = String(describing: notification)
            AppManager.logger.debug("Notification — shown: \(notificationName, privacy: .public)")
            self.notification.onHide = { [weak self] in
                AppManager.logger.debug("Notification — hidden: \(notificationName, privacy: .public)")
                self?.confettiTier = nil
                self?.appManager.flowManager.completeNotification()
            }

            let onTap = { [weak self] in
                guard let self else { return }
                withAnimation { self.notification.show = false }
                self.appManager.flowManager.didTapNotification(notification)
            }
            let onDismiss = { [weak self] in
                guard let self else { return }
                self.appManager.flowManager.didDismissNotification(notification)
            }

            self.notification.onTap = nil
            self.notification.setOnButtonTap(onDismiss)
            self.confettiTier = nil

            switch notification {
            case .enableReportingExtension:
                self.notification.onTap = onTap
                self.notification.setOnButtonTap(onTap)

            case .tipPromotion:
                self.notification.onTap = onTap

            case .tipSuccessful(let tier):
                self.confettiTier = tier

            default:
                break
            }
        }

        private let kReplaceDelay: TimeInterval = 0.35
        private var delayedShow: DispatchWorkItem?
    }
}


//MARK: - Window -
private struct OverlayWindowInstaller: UIViewRepresentable {
    let model: OverlayWindowView.ViewModel

    func makeUIView(context: Context) -> OverlayWindowAnchor {
        return OverlayWindowAnchor(model: self.model)
    }

    func updateUIView(_ uiView: OverlayWindowAnchor, context: Context) {
    }
}

private final class OverlayWindowAnchor: UIView {
    private let model: OverlayWindowView.ViewModel
    private var overlayWindow: PassthroughWindow?

    init(model: OverlayWindowView.ViewModel) {
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

        let overlayWindow = PassthroughWindow(windowScene: windowScene, notification: self.model.notification)
        overlayWindow.rootViewController = host
        overlayWindow.windowLevel = UIWindow.Level(UIWindow.Level.normal.rawValue + 1)
        overlayWindow.isHidden = false
        self.overlayWindow = overlayWindow
    }
}

private final class PassthroughWindow: UIWindow {
    private let notification: NotificationView.ViewModel

    init(windowScene: UIWindowScene, notification: NotificationView.ViewModel) {
        self.notification = notification
        super.init(windowScene: windowScene)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return self.notification.show && self.notification.visibleFrame.contains(point)
    }
}

private struct OverlayWindowContent: View {
    @ObservedObject var model: OverlayWindowView.ViewModel

    var body: some View {
        ZStack(alignment: .top) {
            if let confettiTier = self.model.confettiTier {
                ConfettiView(
                    birthRate: confettiTier.confettiBirthRate,
                    lifetime: confettiTier.confettiLifetime,
                    velocity: confettiTier.confettiVelocity
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            NotificationView(model: self.model.notification)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .adaptiveLayoutEnvironment()
    }
}
