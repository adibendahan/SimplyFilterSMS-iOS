//
//  QuestionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI

struct QuestionView: View {
    
    @Environment(\.layoutDirection)
    var layoutDirection
    
    @StateObject var model: QuestionViewModel
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack (alignment: .leading) {
            Button {
                withAnimation {
                    self.isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: self.layoutDirection == .leftToRight ? "chevron.right.circle" : "chevron.left.circle")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16, height: 16, alignment: .leading)
                        .padding(.trailing, 8)
                    
                    Text(self.model.text)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .textCase(.none)
                }
            }
            
            if isExpanded {
                if let onAction = self.model.onAction {
                    Button {
                        onAction()
                    } label: {
                        Text(.init(self.model.answer))
                            .font(.system(size: 16, weight: .thin, design: .default))
                            .transition(.opacitySlowInFastOut)
                            .padding(.leading, 32)
                    }
                }
                else {
                    Text(.init(self.model.answer))
                        .font(.system(size: 16, weight: .thin, design: .default))
                        .transition(.opacitySlowInFastOut)
                        .padding(.leading, 32)
                }
            }
        } // VStack
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
    
        let model = QuestionViewModel(text: "Question text?", answer: "Short answer.")
        QuestionView(model: model)
            .padding()
    }
}
