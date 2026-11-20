//
//  HelpView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI
import AppIntents
import NaturalLanguage
import MessageUI
import UniformTypeIdentifiers


//MARK: - View -
struct HelpView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.colorScheme)
    private var colorScheme

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22

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
                        AdaptiveRow {
                            Image(systemName: "switch.2")
                                .foregroundStyle(.tint)
                                .font(.body)
                                .adaptiveIconColumn(width: 22)
                                .accessibilityHidden(true)
                        } content: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("help_enableFiltering_title"~)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("help_enableFiltering_caption"~)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("a11y_help_enableFilteringHint"~)

                    Button {
                        model.onRequestScreen?(.enableReportingExtension)
                        dismiss()
                    } label: {
                        AdaptiveRow {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.tint)
                                .font(.body)
                                .adaptiveIconColumn(width: 22)
                                .accessibilityHidden(true)
                        } content: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("help_enableReporting_title"~)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("help_enableReporting_caption"~)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("a11y_help_enableReportingHint"~)
                } header: {
                    Text("help_getStarted"~)
                        .accessibilityAddTraits(.isHeader)
                }

                Section {
                    if model.showsSiriTips {
                        VStack(spacing: 10) {
                            ScrollView(.horizontal) {
                                HStack(spacing: 10) {
                                    ForEach(model.siriTipSlots, id: \.self) { slot in
                                        siriTipView(model.siriTip(at: slot))
                                            .containerRelativeFrame(.horizontal)
                                            .id(slot)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollIndicators(.hidden)
                            .scrollTargetBehavior(.viewAligned)
                            .scrollPosition(id: $model.siriTipSlot)
                            .onScrollSettled(of: model.siriTipSlot) {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    model.recenterSiriTips()
                                }
                            }

                            HStack(spacing: 7) {
                                ForEach(HelpSiriTip.allCases, id: \.self) { tip in
                                    Circle()
                                        .fill(tip == model.currentSiriTip ? Color.primary : Color.secondary.opacity(0.4))
                                        .frame(width: 7, height: 7)
                                }
                            }
                            .accessibilityHidden(true)
                        }
                    }

                    VStack(spacing: 10) {
                        Text("help_shortcuts_caption"~)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        ShortcutsLink()
                            .shortcutsLinkStyle(colorScheme == .dark ? .darkOutline : .lightOutline)
                    }
                    .frame(maxWidth: .infinity)
                } header: {
                    Text("help_siriShortcuts"~)
                        .accessibilityAddTraits(.isHeader)
                }

                Section {
                    NavigationLink {
                        FAQView(model: model.faqViewModel) {
                            dismiss()
                        }
                    } label: {
                        AdaptiveRow {
                            Image(systemName: "questionmark.bubble")
                                .foregroundStyle(.tint)
                                .font(.body)
                                .adaptiveIconColumn(width: 22)
                                .accessibilityHidden(true)
                        } content: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("help_faq_title"~)
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text("help_faq_caption"~)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("faq_section"~)
                        .accessibilityAddTraits(.isHeader)
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
                                .foregroundStyle(.tint)
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
            .navigationTitle("menu_help"~)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
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
    }

    @ViewBuilder
    private func siriTipView(_ tip: HelpSiriTip) -> some View {
        switch tip {
        case .addFilter:
            SiriTipView(intent: AddFilterIntent(list: .block), isVisible: $model.showsSiriTips)
        case .checkMessage:
            SiriTipView(intent: CheckMessageIntent(), isVisible: $model.showsSiriTips)
        case .removeFilter:
            SiriTipView(intent: RemoveFilterIntent(), isVisible: $model.showsSiriTips)
        case .blockLanguage:
            SiriTipView(intent: BlockLanguageIntent(language: model.siriTipLanguage), isVisible: $model.showsSiriTips)
        case .updateLists:
            SiriTipView(intent: UpdateFilterListsIntent(), isVisible: $model.showsSiriTips)
        }
    }
}


private extension View {
    @ViewBuilder
    func onScrollSettled<Value: Equatable>(of value: Value, perform action: @escaping () -> Void) -> some View {
        if #available(iOS 18.0, *) {
            self.onScrollPhaseChange { _, phase in
                if phase == .idle {
                    action()
                }
            }
        } else {
            self.onChange(of: value) { _, _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    action()
                }
            }
        }
    }
}


enum HelpSiriTip: CaseIterable, Hashable {
    case addFilter, checkMessage, removeFilter, blockLanguage, updateLists
}


//MARK: - ViewModel -
extension HelpView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var siriTipSlot: Int?
        let siriTipLanguage: LanguageEntity?
        @Published var showsSiriTips: Bool {
            didSet {
                guard !self.showsSiriTips else { return }
                Log.debug("help siri tips, dismissed")
                self.appManager.defaultsManager.didDismissHelpSiriTips = true
            }
        }
        @Published var composeMailScreen: Bool = false {
            didSet {
                guard oldValue != self.composeMailScreen else { return }
                Log.debug("mail compose, shown: \(oldValue) → \(self.composeMailScreen)")
            }
        }
        @Published var result: Result<MFMailComposeResult, Error>?
        var onRequestScreen: ((Screen) -> Void)?
        let faqViewModel: FAQView.ViewModel

        init(appManager: AppManagerProtocol = AppManager.shared,
             onRequestScreen: ((Screen) -> Void)? = nil) {
            self.onRequestScreen = onRequestScreen
            self.showsSiriTips = !appManager.defaultsManager.didDismissHelpSiriTips
            self.siriTipSlot = HelpSiriTip.allCases.count + Int.random(in: 0..<HelpSiriTip.allCases.count)
            self.siriTipLanguage = Self.makeSiriTipLanguage()
            self.faqViewModel = FAQView.ViewModel(appManager: appManager)
            super.init(appManager: appManager)
        }

        var siriTipSlots: [Int] {
            return Array(0..<(HelpSiriTip.allCases.count * Self.siriTipCopies))
        }

        var currentSiriTip: HelpSiriTip? {
            return self.siriTipSlot.map { self.siriTip(at: $0) }
        }

        func siriTip(at slot: Int) -> HelpSiriTip {
            return HelpSiriTip.allCases[slot % HelpSiriTip.allCases.count]
        }

        func recenterSiriTips() {
            guard let slot = self.siriTipSlot else { return }
            let tipCount = HelpSiriTip.allCases.count
            let middleSlot = tipCount + slot % tipCount
            guard middleSlot != slot else { return }
            self.siriTipSlot = middleSlot
        }

        func setClipboard(content: String, displayName: String) {
            UIPasteboard.general.setValue(content, forPasteboardType: UTType.plainText.identifier)
            Log.debug("copied to clipboard, item: \(displayName), content: \(content)")
            self.appManager.flowManager.requestToast(.onClipboardSet(displayName))
        }


        //MARK: - Private -
        private static let siriTipCopies = 3

        private static func makeSiriTipLanguage() -> LanguageEntity? {
            let deviceLanguage = Locale.preferredLanguages.first ?? ""
            let candidates = NLLanguage.allSupportedCases.filter { !deviceLanguage.hasPrefix($0.rawValue) }
            let language = candidates.randomElement()
            return language.map { LanguageEntity(id: $0.rawValue) }
        }
    }
}


//MARK: - Preview -
#Preview {
    HelpView(model: HelpView.ViewModel(appManager: AppManager.previews))
}
