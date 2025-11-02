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
        VStack(spacing: 0) {
            Spacer(minLength: 0)
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
            .frame(maxWidth: .infinity)
            .modifier(FooterBackground())
            .contentShape(Rectangle())
            .onTapGesture {
                self.onTap?()
            }
        }
    }
}

private struct FooterBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    Color.clear
                        .glassEffect(.regular, in: .rect(cornerRadius: 0))
                        .ignoresSafeArea(.container, edges: .bottom)
                }
        } else {
            content
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
            .modifier(EmbeddedFooterView())
    }
}
