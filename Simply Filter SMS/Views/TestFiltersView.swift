//
//  TestFiltersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import SwiftUI
import IdentityLookup

struct TestFiltersView: View {
    
    enum Field: Int, Hashable, Equatable {
        case text, sender
    }
    
    @FocusState private var focusedField: Field?
    
    @State private var text: String = ""
    @State private var sender: String = ""
    @StateObject private var fadeTextModel = FadingTextView.Model()
    
    private var messageEvaluationManager = MessageEvaluationManager()
    
    var body: some View {
        NavigationView {
            Form {
                ZStack (alignment: .top) {
                    Text("testFilters_senderTitle"~)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -20)
                        .foregroundColor(.secondary)
                    
                    TextField("", text: $sender)
                        .focused($focusedField, equals: .sender)
                }
                .listRowInsets(EdgeInsets(top: 30, leading: 20, bottom: 15, trailing: 20))
                
                ZStack (alignment: .top) {
                    Text("testFilters_messageTitle"~)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $text)
                        .frame(height: 150, alignment: .top)
                        .focused($focusedField, equals: .text)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 15)
                }
                
                
                FadingTextView(model: self.fadeTextModel)
                    .font(.title3.bold())
                
                Button {
                    let sender = self.sender.isEmpty ? "1234567" : self.sender
                    self.fadeTextModel.text = self.messageEvaluationManager.evaluateMessage(body: self.text, sender: sender).testResult
                    self.focusedField = nil
                } label: {
                    Text("testFilters_action"~)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButton())
                .listRowSeparator(.hidden)
                .padding(.bottom, 20)
            }
            .navigationTitle("testFilters_title"~)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    focusedField = .text
                }
            }
            .onChange(of: focusedField) { newValue in
                if newValue != nil && !self.fadeTextModel.text.isEmpty {
                    self.fadeTextModel.text = ""
                }
            }
        }
    }
}

struct TestFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            TestFiltersView()
        }
    }
}
