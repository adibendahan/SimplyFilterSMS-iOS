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
    var model: NotificationView.ViewModel

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            NotificationView(model: model)
        }
    }
}
