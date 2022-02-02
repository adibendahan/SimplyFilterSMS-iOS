//
//  FooterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/01/2022.
//

import SwiftUI

struct FooterView: View {
    var onTap: (() ->())? = nil
    
    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            Rectangle()
                .frame(height: 1, alignment: .bottom)
                .foregroundColor(.primary.opacity(0.05))
                .padding(.bottom, 8)
            Text("Simply Filter SMS v\(Text(appVersion))\n\(Text(String(format: "general_copyright"~, Calendar.current.component(.year, from: Date()))))")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .background(.ultraThinMaterial)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .onTapGesture {
            self.onTap?()
        }
    }
}

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

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .modifier(EmbeddedFooterView())
    }
}
