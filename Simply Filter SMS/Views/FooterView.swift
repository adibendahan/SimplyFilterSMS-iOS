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
            Text("Simply Filter SMS v\(Text(appVersion))\n\(Text(String(format: "general_copyright"~, Calendar.current.component(.year, from: Date()))))")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .background(.ultraThinMaterial)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
    }
}
