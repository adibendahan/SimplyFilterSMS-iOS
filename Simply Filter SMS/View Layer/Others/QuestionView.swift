//
//  QuestionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI


//MARK: - View -
struct QuestionView: View {
    
    @Environment(\.layoutDirection)
    var layoutDirection
    
    @StateObject var model: QuestionView.Model

    var body: some View {
        VStack (alignment: .leading) {
            Button {
                withAnimation {
                    self.model.isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: self.layoutDirection == .leftToRight ? "chevron.right.circle" : "chevron.left.circle")
                        .rotationEffect(.degrees(self.model.isExpanded ? 90 : 0))
                        .frame(width: 16, height: 16, alignment: .leading)
                        .padding(.trailing, 8)
                    
                    Text(self.model.text)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .textCase(.none)
                }
            }
            
            if self.model.isExpanded {
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


//MARK: - Model -
extension QuestionView {
    
    class Model: ObservableObject, Identifiable {
        enum QuestionAction {
            case none, activateFilters
        }
        
        let id: UUID = UUID()
        
        @Published var text: String
        @Published var answer: String
        @Published var action: QuestionAction
        @Published var onAction: (() -> ())? = nil
        @Published var isExpanded: Bool = false
        
        init(text: String,
             answer: String,
             action: QuestionAction = .none,
             onAction: (() -> ())? = nil) {
            
            self.text = text
            self.answer = answer
            self.action = action
            self.onAction = onAction
        }
    }
}


//MARK: - Preview -
struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        
        let model = QuestionView.Model(text: "Question text?", answer: "Short answer.")
        QuestionView(model: model)
            .padding()
    }
}
