//
//  ViewModfiers.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import SwiftUI


struct EmbeddedFooterView: ViewModifier {
    var onTap: (() ->())? = nil
    
    func body(content: Content) -> some View {
        ZStack (alignment: .bottom) {
            content
            FooterView(onTap: onTap)
        }
    }
}


struct EmbeddedCloseButton: ViewModifier {
    var onTap: (() ->())? = nil
    
    func body(content: Content) -> some View {
        ZStack (alignment: .topTrailing) {
            content
            Button {
                onTap?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
    }
}

struct EmbeddedNotificationView: ViewModifier {
    @ObservedObject var model: NotificationView.ViewModel
    @State private var offset: CGFloat = -200
    
    let kHideOffset: CGFloat = -200
    let kShowOffset: CGFloat = 25
    
    func body(content: Content) -> some View {
        ZStack (alignment: .top) {
            content
            NotificationView(model: model)
                .offset(y: self.offset)
                .animation(.interpolatingSpring(mass: 1, stiffness: offset == kShowOffset ? 200 : 0, damping: 30, initialVelocity: offset == kShowOffset ? 25 : 0), value: offset)
                .onTapGesture {
                    withAnimation {
                        self.model.show = false
                    }
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
        }
        else if !show && self.offset == kShowOffset {
            self.offset = kHideOffset
        }
    }
}
