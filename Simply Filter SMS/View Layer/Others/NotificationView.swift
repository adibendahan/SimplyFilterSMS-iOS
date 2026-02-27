//
//  NotificationView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 08/02/2022.
//

import SwiftUI
import UIKit
import Foundation

struct NotificationView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var model: ViewModel
    @State private var offset: CGFloat = -200

    private let kHideOffset: CGFloat = -200
    private let kShowOffset: CGFloat = 25

    var body: some View {
        HStack (alignment: .center, spacing: 8) {
            Image(systemName: self.model.icon)
                .font(.body)
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 0))
                .foregroundColor(self.model.iconColor)

            VStack (alignment: .leading, spacing: 0) {
                Text(self.model.title)
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                Text(self.model.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 4))

            Button {
                self.model.onButtonTap?()
            } label: {
                Text(self.model.buttonTitle)
                    .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                    .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .background(Color.secondary.opacity(0.2))
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
            .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
        .accessibilityElement(children: .combine)
        .background(.ultraThinMaterial)
        .containerShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .global)
                .onChanged({ value in
                    let horizontalAmount = value.translation.width as CGFloat
                    let verticalAmount = value.translation.height as CGFloat

                    if abs(horizontalAmount) < abs(verticalAmount) && verticalAmount < -20  {
                        self.model.onButtonTap?()
                    }
                })
                .onEnded { value in
                    let horizontalAmount = value.translation.width as CGFloat
                    let verticalAmount = value.translation.height as CGFloat

                    if abs(horizontalAmount) < abs(verticalAmount) && verticalAmount < 0  {
                        self.model.onButtonTap?()
                    }
                })
        .offset(y: self.offset)
        .accessibilityHidden(offset != kShowOffset)
        .animation(reduceMotion ? nil : .interpolatingSpring(mass: 1, stiffness: 200, damping: 30, initialVelocity: offset == kShowOffset ? 25 : 0), value: offset)
        .onTapGesture {
            withAnimation {
                self.model.show = false
            }
        }
        .onReceive(model.$show) { show in
            withAnimation {
                self.setShow(show)
            }
        }
    }

    private func setShow(_ show: Bool) {
        if show && self.offset == kHideOffset {
            self.offset = kShowOffset
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "\(self.model.title). \(self.model.subtitle)"
                )
            }
        }
        else if !show && self.offset == kShowOffset {
            self.offset = kHideOffset
            let callback = self.model.onHide
            self.model.onHide = nil
            callback?()
        }
    }
    
    class ViewModel: ObservableObject {
        @Published var icon: String
        @Published var iconColor: Color
        @Published var title: String
        @Published var subtitle: String
        @Published var buttonTitle: String
        @Published var onButtonTap: (() -> ())?
        @Published var show: Bool {
            didSet {
                if show {
                    scheduleAutoHide()
                } else {
                    autoHideWork?.cancel()
                    autoHideWork = nil
                }
            }
        }
        var onHide: (() -> Void)?

        private var currentTimeout: TimeInterval?
        private var autoHideWork: DispatchWorkItem?

        init(notification: Notification) {
            self.icon = notification.icon
            self.iconColor = notification.iconColor
            self.title = notification.title
            self.subtitle = notification.subtitle
            self.buttonTitle = notification.buttonTitle
            self.currentTimeout = notification.timeout
            self.show = false
            self.onButtonTap = {
                withAnimation {
                    self.show = false
                }
            }
        }

        func setNotification(_ notification: Notification) {
            self.icon = notification.icon
            self.iconColor = notification.iconColor
            self.title = notification.title
            self.subtitle = notification.subtitle
            self.buttonTitle = notification.buttonTitle
            self.currentTimeout = notification.timeout
        }

        func setOnButtonTap(_ newOnButtonTap: (() -> ())?) {
            self.onButtonTap = {
                newOnButtonTap?()
                withAnimation {
                    self.show = false
                }
            }
        }

        private func scheduleAutoHide() {
            autoHideWork?.cancel()
            guard let timeout = currentTimeout else { return }
            let work = DispatchWorkItem { [weak self] in
                withAnimation {
                    self?.show = false
                }
            }
            autoHideWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: work)
        }
    }
    
    enum Notification {
        case offline, cloudSyncOperationComplete, automaticFiltersUpdated, onClipboardSet(String), tipSuccessful
        
        var icon: String {
            switch self {
            case .offline:
                return "icloud.slash.fill"
            case .cloudSyncOperationComplete:
                return "icloud.and.arrow.down.fill"
            case .automaticFiltersUpdated:
                return "bolt.shield.fill"
            case .onClipboardSet:
                return "doc.on.clipboard.fill"
            case .tipSuccessful:
                return "heart.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .offline:
                return .red.opacity(0.4)
            case .cloudSyncOperationComplete:
                return .green.opacity(0.6)
            case .automaticFiltersUpdated:
                return .indigo.opacity(0.6)
            case .onClipboardSet:
                return .accentColor.opacity(0.6)
            case .tipSuccessful:
                return .pink.opacity(0.8)
            }
        }


        var title: String {
            switch self {
            case .offline:
                return "notification_offline_title"~
            case .cloudSyncOperationComplete:
                return "notification_sync_title"~
            case .automaticFiltersUpdated:
                return "notification_automatic_title"~
            case .onClipboardSet(let contentDescription):
                return contentDescription
            case .tipSuccessful:
                return "tipJar_toast_title"~
            }
        }

        var subtitle: String {
            switch self {
            case .offline:
                return "notification_offline_subtitle"~
            case .cloudSyncOperationComplete:
                return "notification_sync_subtitle"~
            case .automaticFiltersUpdated:
                return "notification_automatic_subtitle"~
            case .onClipboardSet:
                return "notification_clipboard_subtitle"~
            case .tipSuccessful:
                return "tipJar_toast_subtitle"~
            }
        }

        var buttonTitle: String {
            return "notification_hide"~
        }

        var timeout: TimeInterval? {
            switch self {
            case .offline:
                return nil
            case .cloudSyncOperationComplete, .automaticFiltersUpdated:
                return 6
            case .onClipboardSet:
                return 3
            case .tipSuccessful:
                return 3
            }
        }
    }
}

struct NotificationToastView_Previews: PreviewProvider {
    static var previews: some View {
        let model = NotificationView.ViewModel(notification: .automaticFiltersUpdated)
        NavigationView {
            List {
                Button("Tap me") {
                    model.show = true
                }
            }
            .navigationTitle("Preview")
        }
        .preferredColorScheme(.dark)
        .modifier(EmbeddedNotificationView(model: model))
    }
}


