//
//  QuestionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI

struct Question: Identifiable {
    let id: UUID = UUID()
    let text: String
    let answer: String
    var action: QuestionAction = .none
}

enum QuestionAction {
    case none, activateFilters
}

struct QuestionView: View {
    @Environment(\.layoutDirection)
    var layoutDirection
    
    @State private var isExpanded: Bool = false
    @State var question: Question
    @State var action:(() -> Void)?
    
    var body: some View {
        VStack (alignment: .leading) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: layoutDirection == .leftToRight ? "chevron.right.circle" : "chevron.left.circle")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 16, height: 16, alignment: .leading)
                        .padding(.trailing, 8)
                    
                    Text(question.text)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .textCase(.none)
                }
            }
            
            if isExpanded {
                if let action = action {
                    Button {
                        action()
                    } label: {
                        Text(.init(question.answer))
                            .font(.system(size: 16, weight: .thin, design: .default))
                            .transition(.opacitySlowInFastOut)
                            .padding(.leading, 32)
                    }
                }
                else {
                    Text(.init(question.answer))
                        .font(.system(size: 16, weight: .thin, design: .default))
                        .transition(.opacitySlowInFastOut)
                        .padding(.leading, 32)
                }
            }
        } // VStack
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView(question: Question(text: "Question text?", answer: "Short answer."))
    }
}
