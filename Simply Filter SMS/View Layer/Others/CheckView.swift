//
//  CheckView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 08/07/2022.
//

import SwiftUI

struct CheckView: View {
    
    @State private var checkViewAppear = false
    @State var size: CGFloat = 100
    
    var body: some View {
        Path { path in
            path.addLines([
                .init(x: 0, y: size/2),
                .init(x: size/3, y: size),
                .init(x: size, y: 0),
            ])
        }
        .trim(from: 0, to: checkViewAppear ? 1 : 0)
        .stroke(style: StrokeStyle(lineWidth: size/10 + 2, lineCap: .round))
        .animation(.easeInOut, value: checkViewAppear)
        .frame(width: size, height: size, alignment: .center)
        .onAppear() {
            withAnimation {
                self.checkViewAppear.toggle()
            }
        }
    }
}


struct CheckView_Previews: PreviewProvider {
    static var previews: some View {
        CheckView()
    }
}
