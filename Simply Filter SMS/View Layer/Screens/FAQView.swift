//
//  FAQView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/11/2026.
//

import SwiftUI


//MARK: - View -
struct FAQView: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ObservedObject var model: ViewModel
    let onClose: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Section {
                ForEach(self.model.visibleItems, id: \.self) { item in
                    DisclosureGroup(isExpanded: self.expansion(item)) {
                        Text(self.answerText(for: item))
                        .font(.label.weight(.regular))
                        .foregroundColor(.text)
                        .padding(.leading, LayoutOffset.disclosureFlush)
                        .padding(.bottom, Spacing.tight)
                        .listRowSeparator(.hidden)
                        .accessibilityIdentifier("\(TestIdentifier.faqAnswer.rawValue)-\(item.rawValue)")
                    } label: {
                        Text(AttributedString(item.question).highlighting(self.model.searchTerm))
                            .font(.description.weight(.semibold))
                            .foregroundColor(.text)
                            .multilineTextAlignment(.leading)
                    }
                    .accessibilityHint("a11y_faq_answerHint"~)
                    .revealHighlight(isRevealed: self.model.revealedFAQ == item)
                }
            } footer: {
                Text("faq_subtitle"~)
            }
            .transaction { transaction in
                if self.reduceMotion {
                    transaction.animation = nil
                }
            }

            if self.model.visibleItems.isEmpty {
                Section {
                    Text("general_noResults"~)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("faq_section"~)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: self.$model.searchQuery, prompt: "general_search"~)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    self.onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .tint(.primary)
                .accessibilityLabel("general_close"~)
                .accessibilityIdentifier(TestIdentifier.closeButton.rawValue)
                .contentShape(Rectangle())
            }
        }
        .onAppear {
            guard let faq = self.model.revealedFAQ else { return }
            DispatchQueue.main.async {
                proxy.scrollTo(faq, anchor: .center)
            }
        }
        } // ScrollViewReader
    }

    private func answerText(for item: HelpFAQ) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let answer = (try? AttributedString(markdown: item.answer, options: options)) ?? AttributedString(item.answer)
        return answer.highlighting(self.model.searchTerm)
    }

    private func expansion(_ item: HelpFAQ) -> Binding<Bool> {
        return Binding(
            get: { self.model.expandedFAQs.contains(item) },
            set: { open in
                withAnimation(self.reduceMotion ? nil : .easeInOut) {
                    self.model.setExpanded(item, open: open)
                }
            }
        )
    }
}


enum HelpFAQ: String, CaseIterable, Hashable {
    case notFiltering, iMessage, filterTester,
         howItWorks, smartFilters, allowByCountry, ai, communityLists, report, stayReachable, siriShortcuts,
         whereFiltered, folders,
         iCloudSync, privacy, shareFilters

    var question: String {
        switch self {
        case .notFiltering: return "faq_notFiltering_question"~
        case .iMessage: return "faq_iMessage_question"~
        case .filterTester: return "faq_filterTester_question"~
        case .howItWorks: return "faq_howItWorks_question"~
        case .smartFilters: return "faq_smartFilters_question"~
        case .allowByCountry: return "faq_allowByCountry_question"~
        case .ai: return "faq_ai_question"~
        case .communityLists: return "faq_communityLists_question"~
        case .report: return "faq_report_question"~
        case .stayReachable: return "faq_stayReachable_question"~
        case .siriShortcuts: return "faq_siriShortcuts_question"~
        case .whereFiltered: return "faq_whereFiltered_question"~
        case .folders: return "faq_folders_question"~
        case .iCloudSync: return "faq_iCloudSync_question"~
        case .privacy: return "faq_privacy_question"~
        case .shareFilters: return "faq_shareFilters_question"~
        }
    }

    var answer: String {
        switch self {
        case .notFiltering: return "faq_notFiltering_answer"~
        case .iMessage: return "faq_iMessage_answer"~
        case .filterTester: return "faq_filterTester_answer"~
        case .howItWorks: return "faq_howItWorks_answer"~
        case .smartFilters: return "faq_smartFilters_answer"~
        case .allowByCountry: return "faq_allowByCountry_answer"~
        case .ai: return "faq_ai_answer"~
        case .communityLists: return "faq_communityLists_answer"~
        case .report: return "faq_report_answer"~
        case .stayReachable: return "faq_stayReachable_answer"~
        case .siriShortcuts: return "faq_siriShortcuts_answer"~
        case .whereFiltered: return "faq_whereFiltered_answer"~
        case .folders: return "faq_folders_answer"~
        case .iCloudSync: return "faq_iCloudSync_answer"~
        case .privacy: return "faq_privacy_answer"~
        case .shareFilters: return "faq_shareFilters_answer"~
        }
    }
}


//MARK: - ViewModel -
extension FAQView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var expandedFAQs: Set<HelpFAQ> = []
        @Published var searchQuery: String = "" {
            didSet {
                guard oldValue != self.searchQuery else { return }
                self.updateVisibleItems()
            }
        }
        @Published private(set) var visibleItems: [HelpFAQ] = HelpFAQ.allCases
        @Published private(set) var revealedFAQ: HelpFAQ?

        var searchTerm: String {
            return self.searchQuery.trimmingCharacters(in: .whitespaces)
        }

        func setExpanded(_ item: HelpFAQ, open: Bool) {
            if !open {
                self.expandedFAQs.remove(item)
            } else if self.isSearching {
                self.expandedFAQs.insert(item)
            } else {
                self.expandedFAQs = [item]
            }
        }

        func reveal(_ item: HelpFAQ) {
            Log.debug("search focus revealed, faq: \(item.rawValue)")
            self.setExpanded(item, open: true)
            self.revealedFAQ = item
            DispatchQueue.main.asyncAfter(deadline: .now() + kSearchRevealDuration) { [weak self] in
                if self?.revealedFAQ == item {
                    self?.revealedFAQ = nil
                }
            }
        }


        //MARK: - Private -
        private var isSearching: Bool {
            return !self.searchTerm.isEmpty
        }

        private func updateVisibleItems() {
            let query = self.searchTerm
            let items: [HelpFAQ]
            if query.isEmpty {
                items = HelpFAQ.allCases
            } else {
                items = HelpFAQ.allCases.filter { item in
                    item.question.localizedCaseInsensitiveContains(query) ||
                    item.answer.replacingOccurrences(of: "**", with: "").localizedCaseInsensitiveContains(query)
                }
            }
            self.visibleItems = items
            self.expandedFAQs = self.isSearching ? Set(items) : []
        }
    }
}


//MARK: - Preview -
#Preview("Collapsed") {
    NavigationView {
        FAQView(model: FAQView.ViewModel(appManager: AppManager.previews), onClose: {})
    }
}

#Preview("Expanded") {
    let model = FAQView.ViewModel(appManager: AppManager.previews)
    model.setExpanded(.notFiltering, open: true)
    return NavigationView {
        FAQView(model: model, onClose: {})
    }
}
