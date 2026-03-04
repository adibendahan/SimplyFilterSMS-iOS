//
//  QuestionView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI
import UIKit


//MARK: - View -
struct QuestionView: View {

    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ScaledMetric(relativeTo: .body) private var questionFontSize: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var chevronSize: CGFloat = 16

    @StateObject var model: ViewModel
    @Namespace private var answerID

    var body: some View {
        VStack (alignment: .leading) {
            Button {
                withAnimation(reduceMotion ? nil : .default) {
                    self.model.isExpanded.toggle()
                }
                if self.model.isExpanded {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        UIAccessibility.post(notification: .layoutChanged, argument: nil)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: self.layoutDirection == .leftToRight ? "chevron.right.circle" : "chevron.left.circle")
                        .rotationEffect(.degrees(reduceMotion ? 0 : (self.model.isExpanded ? 90 : 0)))
                        .frame(width: chevronSize, height: chevronSize, alignment: .leading)
                        .padding(.trailing, 8)
                        .accessibilityHidden(true)

                    Text(self.model.text)
                        .font(.system(size: questionFontSize, weight: .semibold, design: .default))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .textCase(.none)
                }
            }
            .accessibilityAddTraits(self.model.isExpanded ? .isSelected : [])

            if self.model.isExpanded {
                if let onAction = self.model.onAction {
                    Button {
                        onAction()
                    } label: {
                        Text(.init(self.model.answer))
                            .font(.system(size: questionFontSize, weight: .thin, design: .default))
                            .transition(.opacitySlowInFastOut)
                            .padding(.leading, 32)
                    }
                    .accessibilityIdentifier("answer_\(self.model.id)")
                }
                else {
                    Text(.init(self.model.answer))
                        .font(.system(size: questionFontSize, weight: .thin, design: .default))
                        .transition(.opacitySlowInFastOut)
                        .padding(.leading, 32)
                        .accessibilityIdentifier("answer_\(self.model.id)")
                }
            }
        } // VStack
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}


//MARK: - Model -
extension QuestionView {
    
    class ViewModel: ObservableObject, Identifiable {
        enum QuestionAction {
            case none, activateFilters
        }
        
        var id: String  { self.text }
        
        @Published private(set) var text: String
        @Published private(set) var answer: String
        @Published private(set) var action: QuestionAction
        @Published private(set) var onAction: (() -> ())? = nil
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
        
        let model = QuestionView.ViewModel(text: "Question text?", answer: "Short answer.")
        QuestionView(model: model)
            .padding()
    }
}
