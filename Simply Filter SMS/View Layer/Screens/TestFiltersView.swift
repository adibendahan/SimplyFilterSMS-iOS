//
//  TestFiltersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import SwiftUI
import UIKit


//MARK: - View -
struct TestFiltersView: View {
    
    @Environment(\.dismiss)
    var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    
    @FocusState private var focusedField: Field?
    @StateObject private var model: ViewModel

    init(model: ViewModel = ViewModel()) {
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack(alignment: .top) {
                            Text("testFilters_senderTitle"~)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)

                            TextField("", text: $model.sender)
                                .focused($focusedField, equals: .sender)
                                .padding(.top, 18)
                                .accessibilityLabel("testFilters_senderTitle"~)
                                .accessibilityIdentifier(TestIdentifier.testSenderInput.rawValue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 15)

                        Divider()
                            .padding(.leading, 20)

                        ZStack(alignment: .top) {
                            Text("testFilters_messageTitle"~)
                                .font(.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)

                            TextEditor(text: $model.text)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 80, idealHeight: 80, alignment: .top)
                                .focused($focusedField, equals: .text)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 18)
                                .accessibilityLabel("testFilters_messageTitle"~)
                                .accessibilityIdentifier(TestIdentifier.testBodyInput.rawValue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 15)

                        ZStack(alignment: .topLeading) {
                            if let result = self.model.result {
                                TestFilterResultRow(result: result)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                    .id(result.action.rawValue)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.bottom, 15)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    Text("testFilters_footer"~)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                }
                .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.28), value: self.model.result?.action.rawValue)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .onChange(of: self.model.result) { result in
                guard UIAccessibility.isVoiceOverRunning, let result else { return }
                UIAccessibility.post(notification: .announcement, argument: TestFilterResultRow.accessibilityText(for: result))
            }
            .onAppear {
                guard self.model.result == nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    focusedField = .text
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
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
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
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var text: String = "" {
            didSet { self.updateResult() }
        }
        @Published var sender: String = "" {
            didSet { self.updateResult() }
        }
        @Published var result: MessageEvaluationResult?
        
        private lazy var bodyOnlySender: String = {
            let evaluator = self.appManager.messageEvaluationManager
            let candidates = (0...9).map { String(repeating: String($0), count: 12) }
            return candidates.first(where: { evaluator.evaluateMessage(body: "", sender: $0).action == .allow })
                ?? candidates[0]
        }()
        
        func updateResult() {
            guard !self.text.isEmpty || !self.sender.isEmpty else {
                if self.result != nil {
                    self.result = nil
                }
                return
            }

            let next = self.appManager.messageEvaluationManager.evaluateMessage(
                body: self.text,
                sender: self.sender.isEmpty ? self.bodyOnlySender : self.sender
            )
            guard next != self.result else { return }
            self.result = next
        }
    }
}


//MARK: - Preview -
#Preview("Empty") {
    TestFiltersView(model: TestFiltersView.ViewModel(appManager: AppManager.previews))
}

#Preview("Junk result") {
    let model = TestFiltersView.ViewModel(appManager: AppManager.previews)
    model.sender = "Amazon"
    model.text = "Your package has shipped. Track it here: https://amzn.to/xyz"
    model.result = MessageEvaluationResult(action: .junk, match: .userFilter("amazon"))
    return TestFiltersView(model: model)
}

#Preview("Allowed result") {
    let model = TestFiltersView.ViewModel(appManager: AppManager.previews)
    model.sender = "Mom"
    model.text = "Running late, be home soon"
    model.result = MessageEvaluationResult(action: .allow, match: .noMatch)
    return TestFiltersView(model: model)
}
