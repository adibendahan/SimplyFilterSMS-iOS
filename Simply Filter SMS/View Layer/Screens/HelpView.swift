//
//  HelpView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI
import MessageUI
import UniformTypeIdentifiers


//MARK: - View -
struct HelpView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var rowIconSize: CGFloat = 20

    @StateObject var model: ViewModel

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        model.onRequestScreen?(.enableExtension)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "switch.2")
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: rowIconSize, maxHeight: .infinity, alignment: .center)
                                .font(.body)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("help_enableFiltering_title"~)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("help_enableFiltering_caption"~)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("a11y_help_enableFilteringHint"~)

                    Button {
                        model.onRequestScreen?(.enableReportingExtension)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: rowIconSize, maxHeight: .infinity, alignment: .center)
                                .font(.body)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("help_enableReporting_title"~)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("help_enableReporting_caption"~)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("a11y_help_enableReportingHint"~)
                } header: {
                    Text("help_getStarted"~)
                        .accessibilityAddTraits(.isHeader)
                }

                Section {
                    ForEach(HelpFAQ.allCases, id: \.self) { item in
                        DisclosureGroup(isExpanded: expansion(item)) {
                            Group {
                                if let attributed = try? AttributedString(markdown: item.answer, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                    Text(attributed)
                                } else {
                                    Text(item.answer)
                                }
                            }
                            .font(.footnote.weight(.regular))
                            .foregroundColor(.primary)
                            .padding(.leading, -20)
                            .padding(.top, -4)
                            .padding(.bottom, 4)
                            .listRowSeparator(.hidden)
                        } label: {
                            Text(item.question)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                        }
                        .accessibilityHint("a11y_help_faqHint"~)
                    }
                } header: {
                    Text("faq_section"~)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    Text("faq_subtitle"~)
                }
                .transaction { transaction in
                    if reduceMotion {
                        transaction.animation = nil
                    }
                }

                Section {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            model.composeMailScreen = true
                        } else {
                            model.setClipboard(content: kSupportEmail, displayName: "aboutView_sendMail"~)
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("aboutView_sendMail"~)
                                    .foregroundColor(.primary)
                                Text(kSupportEmail)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("a11y_help_emailHint"~)

                    Link(destination: .appGithubURL) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("aboutView_github"~)
                                    .foregroundColor(.primary)
                                Text(URL.appGithubURL.lastPathComponent)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image("GitHub")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("aboutView_contactSection"~)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("filterList_menu_enableExtension"~)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
            }
            .sheet(isPresented: $model.composeMailScreen) { } content: {
                MailView(isShowing: $model.composeMailScreen, result: $model.result)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .ignoresSafeArea(.container, edges: .bottom)
        .modifier(EmbeddedNotificationView(model: model.notification))
    }

    private func expansion(_ item: HelpFAQ) -> Binding<Bool> {
        Binding(
            get: { model.expandedFAQ == item },
            set: { open in
                withAnimation(reduceMotion ? nil : .easeInOut) {
                    if open {
                        model.expandedFAQ = item
                    } else if model.expandedFAQ == item {
                        model.expandedFAQ = nil
                    }
                }
            }
        )
    }
}


enum HelpFAQ: String, CaseIterable, Hashable {
    case notFiltering, iMessage, testFilters,
         howItWorks, smartFilters, trustedCountries, ai, report,
         whereFiltered, folders,
         privacy, shareFilters

    var question: String {
        switch self {
        case .notFiltering: return "faq_question_notFiltering"~
        case .iMessage: return "faq_question_3"~
        case .testFilters: return "faq_question_testFilters"~
        case .howItWorks: return "faq_question_1"~
        case .smartFilters: return "faq_question_smartFilters"~
        case .trustedCountries: return "faq_question_trustedCountries"~
        case .ai: return "help_automaticFiltering_question"~
        case .report: return "faq_question_report"~
        case .whereFiltered: return "faq_question_4"~
        case .folders: return "faq_question_5"~
        case .privacy: return "faq_question_2"~
        case .shareFilters: return "faq_question_shareFilters"~
        }
    }

    var answer: String {
        switch self {
        case .notFiltering: return "faq_answer_notFiltering"~
        case .iMessage: return "faq_answer_3"~
        case .testFilters: return "faq_answer_testFilters"~
        case .howItWorks: return "faq_answer_1"~
        case .smartFilters: return "faq_answer_smartFilters"~
        case .trustedCountries: return "faq_answer_trustedCountries"~
        case .ai: return "help_automaticFiltering"~
        case .report: return "faq_answer_report"~
        case .whereFiltered: return "faq_answer_4"~
        case .folders: return "faq_answer_5"~
        case .privacy: return "faq_answer_2"~
        case .shareFilters: return "faq_answer_shareFilters"~
        }
    }
}


//MARK: - ViewModel -
extension HelpView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var expandedFAQ: HelpFAQ?
        @Published var composeMailScreen: Bool = false
        @Published var result: Result<MFMailComposeResult, Error>?
        @Published var notification: NotificationView.ViewModel
        var onRequestScreen: ((Screen) -> Void)?

        init(appManager: AppManagerProtocol = AppManager.shared,
             onRequestScreen: ((Screen) -> Void)? = nil) {
            self.notification = NotificationView.ViewModel(notification: .onClipboardSet(""))
            self.onRequestScreen = onRequestScreen
            super.init(appManager: appManager)

            NotificationCenter.default.addObserver(forName: .onClipboardSet, object: nil, queue: .main) { [weak self] not in
                guard let notificationObject = not.object as? NotificationView.Notification else { return }
                self?.showNotification(notificationObject)
            }
        }

        func setClipboard(content: String, displayName: String) {
            UIPasteboard.general.setValue(content, forPasteboardType: UTType.plainText.identifier)
            NotificationCenter.default.post(name: .onClipboardSet, object: NotificationView.Notification.onClipboardSet(displayName))
        }

        func showNotification(_ notification: NotificationView.Notification) {
            if !self.notification.show {
                self.notification.setNotification(notification)
                withAnimation {
                    self.notification.show = true
                }
            } else {
                withAnimation {
                    self.notification.setNotification(notification)
                }
            }
        }
    }
}


//MARK: - Preview -
#Preview("Collapsed") {
    HelpView(model: HelpView.ViewModel(appManager: AppManager.previews))
}

#Preview("Expanded") {
    let model = HelpView.ViewModel(appManager: AppManager.previews)
    model.expandedFAQ = .notFiltering
    return HelpView(model: model)
}
