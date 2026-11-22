//
//  ReportMessageView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import SwiftUI
import IdentityLookup
import UIKit


//MARK: - View -
struct ReportMessageView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.accessibilityVoiceOverEnabled)
    private var voiceOverEnabled

    @FocusState private var focusedField: Field?
    @StateObject private var model: ViewModel

    init(model: ViewModel = ViewModel()) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
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
                            .frame(minHeight: 80, idealHeight: 80, alignment: .top)
                            .focused($focusedField, equals: .text)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 15)
                            .accessibilityIdentifier(TestIdentifier.testBodyInput.rawValue)
                    }
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 0, trailing: 20))

                    Picker(selection: $model.selectedReport, label: EmptyView()) {
                        ForEach(ReportType.allCases.filter { $0 != .junkAndBlockSender }, id: \.rawValue) { reportType in
                            Text(reportType.name)
                                .font(.body)
                                .tag(reportType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 12, trailing: 20))

                    ReportSubmitButton(phase: self.model.state.submitPhase) {
                        withAnimation {
                            self.model.reportMessage()
                            self.focusedField = nil
                        }
                    }
                    .listRowSeparator(.hidden)
                    .padding(.bottom, 8)
                    .disabled(self.model.text.isEmpty && self.model.sender.isEmpty)
                    .accessibilityIdentifier(TestIdentifier.testYourFiltersButton.rawValue)
                    .accessibilityHint("a11y_reportMessage_submitHint"~)
                } header: {
                    Spacer()
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                } footer: {
                    ZStack {
                        Text("reportingExtension_footer"~)
                            .multilineTextAlignment(.center)
                            .limitedDynamicTypeSize()
                            .opacity(self.model.state.isResult ? 0 : 1)

                        Text(self.model.state.resultText ?? "")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.primary)
                            .multilineTextAlignment(.center)
                            .entrance(isShown: self.model.state.isResult, delay: ReportMessageMotion.thanksDelay, rise: ReportMessageMotion.thanksRise)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .disabled(self.model.state != .userInput)
            .onAppear {
                if self.model.state == .userInput {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        focusedField = .sender
                    }
                }
            }
            .navigationTitle("reportMessage_title"~)
            .if(self.model.state == .userInput) {
                $0
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
            .onChange(of: self.model.state) { _, newState in
                if case .result(let text) = newState {
                    UIAccessibility.post(notification: .announcement, argument: text)
                    let delay: TimeInterval = voiceOverEnabled ? 3 : 2.5
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        dismiss()
                    }
                }
            }
        }
    }
}


//MARK: - Motion -
private enum ReportMessageMotion {
    static let thanksDelay: Double = 0.3
    static let thanksRise: CGFloat = 8
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

        var submitPhase: ReportSubmitButton.Phase {
            switch self {
            case .userInput:
                return .idle
            case .loading:
                return .sending
            case .result(_):
                return .done
            }
        }

        var resultText: String? {
            if case .result(let text) = self { return text }
            return nil
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
                async let apiCall = self.appManager.reportMessageService.reportMessage(reportMessageRequestBody: requestBody)
                async let minDelay: Void = Task.sleep(nanoseconds: 1_500_000_000)
                let didSend = await apiCall
                try? await minDelay
                Log.debug("report finished, sent: \(didSend) → thank you shown")
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
