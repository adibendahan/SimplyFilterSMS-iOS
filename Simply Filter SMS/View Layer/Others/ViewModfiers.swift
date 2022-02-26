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
    var model: NotificationView.ViewModel
    
    func body(content: Content) -> some View {
        ZStack (alignment: .top) {
            content
            NotificationView(model: model)
        }
    }
}
