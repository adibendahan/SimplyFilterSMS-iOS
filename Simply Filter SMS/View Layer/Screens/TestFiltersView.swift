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
    
    @Environment(\.dismiss)
    var dismiss
    
    @FocusState private var focusedField: Field?
    @StateObject var router: AppRouter
    @StateObject var model: ViewModel
    
    var body: some View {
        NavigationView {
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
                        
                    }
                    .listRowInsets(EdgeInsets(top: 30, leading: 20, bottom: 15, trailing: 20))
                    
                    ZStack (alignment: .top) {
                        Text("testFilters_messageTitle"~)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $model.text)
                            .frame(height: 100, alignment: .top)
                            .focused($focusedField, equals: .text)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 15)
                        
                    }
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))
                    
                    
                    FadingTextView(model: self.model.fadeTextModel)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .center)
                    
                    Button {
                        self.model.evaluateMessage()
                        self.focusedField = nil
                    } label: {
                        Text("testFilters_action"~)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .listRowSeparator(.hidden)
                    .padding(.bottom, 8)
                } header: {
                    Spacer()
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
        }
    }
}


//MARK: - ViewModel -
extension TestFiltersView {
    
    enum Field: Int, Hashable, Equatable {
        case text, sender
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var fadeTextModel: FadingTextView.ViewModel
        @Published var text: String = ""
        @Published var sender: String = ""
        
        override init(appManager: AppManagerProtocol) {
            self.fadeTextModel = FadingTextView.ViewModel()
            super.init(appManager: appManager)
        }
        
        func evaluateMessage() {
            let sender = self.sender.isEmpty ? "1234567" : self.sender
            let action = self.appManager.messageEvaluationManager.evaluateMessage(body: self.text, sender: sender)
            self.fadeTextModel.text = action.testResult
        }
    }
}


//MARK: - Preview -
struct TestFiltersView_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            TestFiltersView(router: AppRouter(appManager: AppManager.previews()),
                            model: TestFiltersView.ViewModel(appManager: AppManager.previews()))
        }
    }
}
