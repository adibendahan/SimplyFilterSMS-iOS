//
//  FooterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/01/2022.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack (alignment: .center, spacing: 0) {
            Rectangle()
                .frame(height: 1, alignment: .bottom)
                .foregroundColor(.primary.opacity(0.05))
                .padding(.bottom, 8)
            Text("Simply Filter SMS v\(Text(appVersion))\n\(Text("general_copyright"~))")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .background(.ultraThinMaterial)
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
    }
}
