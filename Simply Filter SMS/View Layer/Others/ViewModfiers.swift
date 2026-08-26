//
//  ViewModfiers.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import SwiftUI


struct EmbeddedFooterView: ViewModifier {
    var isHidden: Bool = false
    var onTap: (() ->())? = nil

    @Environment(\.needsStackedLayout) private var needsStackedLayout

    func body(content: Content) -> some View {
        Group {
            if needsStackedLayout {
                content
                    .accessibilitySortPriority(1)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        footerContent
                    }
            } else {
                ZStack(alignment: .bottom) {
                    content
                        .accessibilitySortPriority(1)
                    footerContent
                }
            }
        }
    }

    @ViewBuilder
    private var footerContent: some View {
        if !isHidden {
            FooterView(onTap: onTap)
                .ignoresSafeArea(.keyboard, edges: .all)
                .allowsHitTesting(!ProcessInfo.processInfo.isInTestingMode)
        }
    }
}


struct EmbeddedCloseButton: ViewModifier {
    var onTap: (() ->())? = nil

    @ScaledMetric(relativeTo: .body) private var closeIconSize: CGFloat = 20

    func body(content: Content) -> some View {
        ZStack (alignment: .topTrailing) {
            content
            Button {
                onTap?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: closeIconSize))
                    .foregroundColor(.secondary)
            }
            .tint(.primary)
            .accessibilityLabel("general_close"~)
            .padding()
            .contentShape(Rectangle())
        }
    }
}

struct EmbeddedNotificationView: ViewModifier {
    @ObservedObject var model: NotificationView.ViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.needsStackedLayout) private var needsStackedLayout

    private let compactTopPadding: CGFloat = 25

    func body(content: Content) -> some View {
        Group {
            if needsStackedLayout {
                content
                    .safeAreaInset(edge: .top, spacing: 0) {
                        notificationInsetContent
                    }
            } else {
                ZStack(alignment: .top) {
                    content
                    notificationOverlayContent
                }
            }
        }
        .animation(reduceMotion ? nil : .interpolatingSpring(mass: 1, stiffness: 200, damping: 30), value: model.show)
    }

    @ViewBuilder
    private var notificationInsetContent: some View {
        if model.show {
            HStack {
                Spacer(minLength: 0)
                NotificationView(model: model)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var notificationOverlayContent: some View {
        if model.show {
            HStack {
                Spacer(minLength: 0)
                NotificationView(model: model)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, compactTopPadding)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
