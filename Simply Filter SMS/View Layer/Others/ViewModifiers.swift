//
//  ViewModifiers.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import SwiftUI


struct EmbeddedCloseButtonModifier: ViewModifier {
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
