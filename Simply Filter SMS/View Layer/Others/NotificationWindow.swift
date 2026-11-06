//
//  NotificationWindow.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 06/11/2026.
//

import SwiftUI
import UIKit

//MARK: - View -
struct NotificationWindowView: ViewModifier {
    let model: ViewModel

    func body(content: Content) -> some View {
        content
            .background(NotificationWindowInstaller(notification: self.model.notification))
    }
}


//MARK: - ViewModel -
extension NotificationWindowView {

    class ViewModel: BaseViewModel, ObservableObject {
        let notification: NotificationView.ViewModel
        var onRequestSheet: ((Screen) -> Void)?

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
            guard let nextNotification = self.appManager.flowManager.nextNotification() else { return }
            self.present(nextNotification)
        }

        private func present(_ notification: NotificationView.Notification) {
            let notificationName = String(describing: notification)
            AppManager.logger.debug("Notification — shown: \(notificationName, privacy: .public)")
            self.notification.onHide = { [weak self] in
                AppManager.logger.debug("Notification — hidden: \(notificationName, privacy: .public)")
                self?.appManager.flowManager.completeNotification()
            }
            self.notification.onTap = nil

            switch notification {
            case .enableReportingExtension:
                let onTap = { [weak self] in
                    guard let self = self else { return }
                    self.appManager.defaultsManager.didDismissReportingExtensionNudge = true
                    withAnimation { self.notification.show = false }
                    self.onRequestSheet?(.enableReportingExtension)
                }
                self.notification.onTap = onTap
                self.notification.setOnButtonTap(onTap)

            case .tipPromotion:
                self.notification.onTap = { [weak self] in
                    withAnimation { self?.notification.show = false }
                    self?.onRequestSheet?(.tipJar)
                }
                self.notification.setOnButtonTap(nil)

            case .offline:
                self.notification.setOnButtonTap { [weak self] in
                    self?.appManager.defaultsManager.lastOfflineNotificationDismiss = Date()
                }

            default:
                self.notification.setOnButtonTap(nil)
            }

            guard !self.notification.show else {
                withAnimation {
                    self.notification.setNotification(notification)
                }
                return
            }

            self.notification.setNotification(notification)
            self.delayedShow?.cancel()
            let delayedShow = DispatchWorkItem { [weak self] in
                withAnimation {
                    self?.notification.show = true
                }
            }
            self.delayedShow = delayedShow
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: delayedShow)
        }

        private var delayedShow: DispatchWorkItem?
    }
}


//MARK: - Window -
private struct NotificationWindowInstaller: UIViewRepresentable {
    let notification: NotificationView.ViewModel

    func makeUIView(context: Context) -> NotificationWindowAnchor {
        return NotificationWindowAnchor(notification: self.notification)
    }

    func updateUIView(_ uiView: NotificationWindowAnchor, context: Context) {
    }
}

private final class NotificationWindowAnchor: UIView {
    private let notification: NotificationView.ViewModel
    private var overlayWindow: PassthroughWindow?

    init(notification: NotificationView.ViewModel) {
        self.notification = notification
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

        let host = UIHostingController(rootView: NotificationWindowContent(notification: self.notification))
        host.view.backgroundColor = .clear

        let overlayWindow = PassthroughWindow(windowScene: windowScene, notification: self.notification)
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

private struct NotificationWindowContent: View {
    let notification: NotificationView.ViewModel

    var body: some View {
        NotificationView(model: self.notification)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .adaptiveLayoutEnvironment()
    }
}
