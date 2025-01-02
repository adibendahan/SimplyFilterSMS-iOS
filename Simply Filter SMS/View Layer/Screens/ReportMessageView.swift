//
//  TestFiltersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import SwiftUI
import IdentityLookup


//MARK: - View -
struct ReportMessageView: View {
    
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
                            Text("reportMessage_senderTitle"~)
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
                        
                        Picker(selection: $model.selectedReport, label: EmptyView()) {
                            ForEach(ReportType.allCases, id: \.rawValue) { reportType in
                                Text(reportType.name)
                                    .font(.body)
                                    .tag(reportType)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibility(hidden: false)
                        .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 12, trailing: 20))
                        
                        Button {
                            withAnimation {
                                self.model.reportMessage()
                                self.focusedField = nil
                            }
                        } label: {
                            Text("reportMessage_report"~)
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
                    if self.model.state == .userInput {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            focusedField = .sender
                        }
                    }
                }
                
                if self.model.state != .userInput {
                    Rectangle()
                        .background(.thinMaterial)
                        .ignoresSafeArea()
                    
                    switch self.model.state {
                    case .result(let text):
                        VStack {
                            CheckView(size: 50)
                                .foregroundColor(.green)
                                .padding()
                            Text(text)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 100)
                    default:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.accentColor)
                            .scaleEffect(2)
                            .padding(.top, 130)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
            }
            .if(self.model.state == .userInput) {
                $0
                    .navigationTitle("reportMessage_title"~)
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
            .onChange(of: self.model.state) { newState in
                if newState.isResult {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            }
        }
    }
}


//MARK: - ViewModel -
extension ReportMessageView {
    
    enum Field: Int, Hashable, Equatable {
        case text, sender
    }
    
    enum ViewState: Equatable {
        case userInput, loading, result(String)
        
        var isResult: Bool {
            switch self {
            case .result(_):
                return true
            default:
                return false
            }
        }
        
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
    
    class ViewModel: BaseViewModel, @unchecked Sendable, ObservableObject {
        @Published var text: String = ""
        @Published var sender: String = ""
        @Published var state: ViewState = .userInput
        @Published var selectedReport = ReportType.junk
        
        func reportMessage() {
            self.state = .loading
            
            Task(priority: .userInitiated) {
                let requestBody = ReportMessageRequestBody(sender: self.sender,
                                                           body: self.text,
                                                           type: self.selectedReport.type)
                
                await self.appManager.reportMessageService.reportMessage(reportMessageRequestBody: requestBody)
                DispatchQueue.main.async {
                    withAnimation {
                        self.state = .result("reportMessage_thankYou"~)
                    }
                }
            }
        }
    }
}


//MARK: - Preview -
struct ReportMessageView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            ReportMessageView(model: ReportMessageView.ViewModel(appManager: AppManager.previews))
        }
    }
}
