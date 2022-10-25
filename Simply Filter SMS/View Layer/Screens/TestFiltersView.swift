//
//  TestFiltersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import SwiftUI
import IdentityLookup


//MARK: - View -
struct TestFiltersView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    var dismiss
    
    @FocusState private var focusedField: Field?
    @ObservedObject var model: ViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Form {
                    Section {
                        ZStack (alignment: .top) {
                            Text("testFilters_senderTitle"~)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, -20)
                                .foregroundColor(.secondary)
                            
                            TextField("", text: $model.sender)
                                .focused($focusedField, equals: .sender)
                                .accessibilityIdentifier(TestIdentifier.testSenderInput.rawValue)
                            
                        }
                        .listRowInsets(EdgeInsets(top: 30, leading: 20, bottom: 15, trailing: 20))
                        
                        ZStack (alignment: .top) {
                            Text("testFilters_messageTitle"~)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $model.text)
                                .frame(height: 80, alignment: .top)
                                .focused($focusedField, equals: .text)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 15)
                                .accessibilityIdentifier(TestIdentifier.testBodyInput.rawValue)
                        }
                        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
                        
                        
                        FadingTextView(model: self.model.fadeTextModel)
                            .multilineTextAlignment(.leading)
                            .frame(minHeight: 45, alignment: .top)
                        
                        Button {
                            withAnimation {
                                self.model.evaluateMessage()
                                self.focusedField = nil
                            }
                        } label: {
                            Text("testFilters_action"~)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledButton())
                        .listRowSeparator(.hidden)
                        .padding(.bottom, 8)
                        .disabled(self.model.text.isEmpty && self.model.sender.isEmpty)
                        .accessibilityIdentifier(TestIdentifier.testYourFiltersButton.rawValue)
                    } header: {
                        Spacer()
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        focusedField = .text
                    }
                }
                .onChange(of: focusedField) { newValue in
                    if newValue != nil && !self.model.fadeTextModel.text.isEmpty {
                        self.model.fadeTextModel.text = ""
                    }
                }
                
                if self.model.state == .loading {
                    Color.listBackgroundColor(for: colorScheme)
                        .opacity(0.7)
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.accentColor)
                        .scaleEffect(2)
                        .padding(.top, 130)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .navigationTitle("testFilters_title"~)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }
}


//MARK: - ViewModel -
extension TestFiltersView {
    
    enum Field: Int, Hashable, Equatable {
        case text, sender
    }
    
    enum ViewState {
        case userInput, loading, result(String)
        
        static func ==(lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.userInput, .userInput), (.loading, .loading):
                return true
            case (let .result(lhsTitle), let .result(rhsTitle)):
                return lhsTitle == rhsTitle
            default:
                return false
            }
        }
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var fadeTextModel: FadingTextView.ViewModel
        @Published var text: String = ""
        @Published var sender: String = ""
        @Published var state: ViewState = .userInput
        
        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.fadeTextModel = FadingTextView.ViewModel()
            super.init(appManager: appManager)
        }
        
        func evaluateMessage() {
            let sender = self.sender.isEmpty ? "1234567" : self.sender
            let result = self.appManager.messageEvaluationManager.evaluateMessage(body: self.text, sender: sender)
            
            if let reason = result.reason {
                self.fadeTextModel.text = "\(result.response.action.testResult)\n\("testFilters_resultReason"~) \(reason)"
            }
            else {
                self.fadeTextModel.text = result.response.action.testResult
            }
        }
    }
}


//MARK: - Preview -
struct TestFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            TestFiltersView(model: TestFiltersView.ViewModel(appManager: AppManager.previews))
        }
    }
}
