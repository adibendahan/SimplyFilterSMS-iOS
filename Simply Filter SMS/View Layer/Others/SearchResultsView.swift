//
//  SearchResultsView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct SearchResultsView: View {

    @ObservedObject var model: ViewModel

    var body: some View {
        List {
            if self.model.isShowingSuggestions {
                Section {
                    ForEach(self.model.suggestionRows) { row in
                        self.button(for: row)
                    }
                } header: {
                    Text("search_suggestions"~)
                        .accessibilityAddTraits(.isHeader)
                } // Section
            }

            if self.model.isShowingRecents {
                Section {
                    ForEach(self.model.recentQueries, id: \.self) { query in
                        Button {
                            self.model.pickRecent(query)
                        } label: {
                            AdaptiveRow {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                    .adaptiveIconColumn()
                                    .accessibilityHidden(true)
                            } content: {
                                Text(query)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    HStack {
                        Text("search_recent"~)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button("search_clearRecent"~) {
                            self.model.clearRecents()
                        }
                        .textCase(nil)
                    }
                } // Section
            }

            ForEach(self.model.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        self.button(for: row)
                    }
                } header: {
                    Text(section.kind.title)
                        .accessibilityAddTraits(.isHeader)
                } // Section
            }
        } // List
        .listStyle(.insetGrouped)
        .overlay {
            if self.model.hasNoResults {
                ContentUnavailableView.search(text: self.model.query)
            }
        }
    }


    //MARK: - Private -
    private func button(for row: Row) -> some View {
        return Button {
            self.model.select(row)
        } label: {
            self.label(for: row)
        }
        .foregroundStyle(.primary)
        .accessibilityIdentifier("\(TestIdentifier.searchResult.rawValue)-\(row.kind)-\(row.title)")
    }

    private func label(for row: Row) -> some View {
        return AdaptiveRow {
            self.icon(row.icon)
                .adaptiveIconColumn()
                .accessibilityHidden(true)
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                Text(AttributedString(row.title).highlighting(self.model.query))
                    .multilineTextAlignment(.leading)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } trailing: {
            HStack(spacing: 8) {
                if let value = row.value {
                    Text(value)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private func icon(_ icon: Icon) -> some View {
        switch icon {
        case .symbol(let name, let color):
            Image(systemName: name)
                .foregroundStyle(color)
        case .text(let text):
            Text(text)
        }
    }
}


//MARK: - Rows -
extension SearchResultsView {
    struct ResultSection: Identifiable {
        let kind: SearchResultKind
        let rows: [Row]

        var id: SearchResultKind {
            return self.kind
        }
    }

    struct Row: Identifiable {
        let kind: SearchResultKind
        let result: SearchResult
        let title: String
        let subtitle: String?
        let value: String?
        let icon: Icon

        var id: String {
            return self.result.id
        }
    }

    enum Icon {
        case symbol(String, Color)
        case text(String)
    }
}


extension SearchAction {
    var color: Color {
        switch self {
        case .addAllowFilter:
            return FilterType.allow.iconColor
        case .addDenyFilter:
            return FilterType.deny.iconColor
        case .addLanguageFilter:
            return FilterType.denyLanguage.iconColor
        case .stayReachable:
            return .green
        case .testFilters, .exportFilters, .importFilters:
            return WhatsNewEntry.filterTransfer.color
        case .reportMessage, .improveAIFiltering:
            return WhatsNewEntry.aiFiltering.color
        case .help:
            return WhatsNewEntry.help.color
        case .whatsNew, .about:
            return .gray
        case .accentColor:
            return WhatsNewEntry.accentColor.color
        case .tipJar:
            return WhatsNewEntry.tipJar.color
        }
    }
}


//MARK: - ViewModel -
extension SearchResultsView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var query: String = ""
        @Published private(set) var sections: [ResultSection] = []
        @Published private(set) var recentQueries: [String] = []
        @Published private(set) var suggestionRows: [Row] = []
        private let onSelect: (SearchResult) -> Void
        private let onPickRecent: (String) -> Void

        init(appManager: AppManagerProtocol = AppManager.shared,
             onSelect: @escaping (SearchResult) -> Void,
             onPickRecent: @escaping (String) -> Void) {
            self.onSelect = onSelect
            self.onPickRecent = onPickRecent
            super.init(appManager: appManager)
        }

        var isShowingRecents: Bool {
            return self.query.isEmpty && !self.recentQueries.isEmpty
        }

        var isShowingSuggestions: Bool {
            return self.query.isEmpty && !self.suggestionRows.isEmpty
        }

        func reloadEmptyState() {
            let searchManager = self.appManager.searchManager
            self.recentQueries = searchManager.recentQueries
            self.suggestionRows = searchManager.suggestions.map { self.makeRow($0, kind: $0.kind) }
        }

        func pickRecent(_ query: String) {
            Log.debug("recent search picked, query: \(query)")
            self.onPickRecent(query)
        }

        func clearRecents() {
            self.appManager.searchManager.clearRecentQueries()
            self.recentQueries = []
        }

        var hasNoResults: Bool {
            let term = self.query.trimmingCharacters(in: .whitespacesAndNewlines)
            return !term.isEmpty && self.sections.isEmpty
        }

        func update(query: String) {
            self.query = query
            let resultSections = self.appManager.searchManager.sections(matching: query)
            self.sections = resultSections.map { resultSection in
                let rows = resultSection.results.map { self.makeRow($0, kind: resultSection.kind) }
                return ResultSection(kind: resultSection.kind, rows: rows)
            }
        }

        func select(_ row: Row) {
            Log.debug("result selected, kind: \(row.kind), title: \(row.title)")
            self.onSelect(row.result)
        }


        //MARK: - Private -
        private func makeRow(_ result: SearchResult, kind: SearchResultKind) -> Row {
            let row: Row
            switch result {
            case .aiLanguage(let language):
                row = self.languageRow(language, kind: kind)
            case .smartFilter(let rule):
                row = self.smartFilterRow(rule, kind: kind)
            case .communityList(let communityList):
                row = self.communityListRow(communityList, kind: kind)
            case .filter(let filter):
                row = self.filterRow(filter, kind: kind)
            case .help(let faq):
                row = Row(kind: kind, result: result, title: faq.question, subtitle: nil, value: nil, icon: .symbol("questionmark.bubble", WhatsNewEntry.help.color))
            case .action(let action):
                row = Row(kind: kind, result: result, title: action.title, subtitle: nil, value: nil, icon: .symbol(action.iconName, action.color))
            }
            return row
        }

        private func languageRow(_ language: NLLanguage, kind: SearchResultKind) -> Row {
            let filterListManager = self.appManager.filterListManager
            let localizedName = language.localizedName ?? language.rawValue
            let nativeName = language.nativeName.flatMap { $0 == localizedName ? nil : $0 }
            let ruleCount = filterListManager.filterListRuleCounts[language]
            let ruleCountText = ruleCount.map { String.localizedStringWithFormat("autoFilter_ruleCount"~, $0) }
            let isActive = filterListManager.isFilterListActive(for: language)
            return Row(kind: kind,
                       result: .aiLanguage(language),
                       title: localizedName,
                       subtitle: self.joined([nativeName, ruleCountText]),
                       value: self.onOffText(isActive),
                       icon: .symbol("bolt.shield.fill", .indigo))
        }

        private func smartFilterRow(_ rule: SmartFilterType, kind: SearchResultKind) -> Row {
            let smartFilterManager = self.appManager.smartFilterManager
            let subtitle: String?
            if rule == .shortSender, let format = rule.subtitle {
                subtitle = String.localizedStringWithFormat(format, smartFilterManager.selectedChoice(for: rule))
            } else {
                subtitle = nil
            }
            let icon: Icon
            if rule.isTextIcon {
                icon = .text(rule.icon)
            } else {
                icon = .symbol(rule.icon, rule.iconColor)
            }
            return Row(kind: kind,
                       result: .smartFilter(rule),
                       title: rule.title,
                       subtitle: subtitle,
                       value: self.onOffText(smartFilterManager.isSmartFilterActive(for: rule)),
                       icon: icon)
        }

        private func communityListRow(_ communityList: CommunityListItem, kind: SearchResultKind) -> Row {
            let ruleCountText = communityList.ruleCount.map { String.localizedStringWithFormat("autoFilter_ruleCount"~, $0) }
            let authorText = communityList.author.map { String(format: "communityLists_byAuthor"~, $0) }
            return Row(kind: kind,
                       result: .communityList(communityList),
                       title: communityList.name,
                       subtitle: self.joined([ruleCountText, communityList.localeLabel, authorText]),
                       value: self.onOffText(communityList.isActive),
                       icon: .symbol("person.2.circle", .indigo))
        }

        private func filterRow(_ filter: Filter, kind: SearchResultKind) -> Row {
            let filterType = filter.filterType
            let title: String
            if filterType == .denyLanguage {
                title = NLLanguage(filterText: filter.text ?? "").localizedName ?? (filter.text ?? "")
            } else {
                title = filter.text ?? ""
            }
            return Row(kind: kind,
                       result: .filter(filter),
                       title: title,
                       subtitle: self.joined(self.optionNames(of: filter)),
                       value: nil,
                       icon: .symbol(filterType.iconName, filterType.iconColor))
        }

        private func optionNames(of filter: Filter) -> [String?] {
            let filterType = filter.filterType
            let folder = filterType == .allow ? nil : filter.messageFolder.name
            guard filterType != .denyLanguage else { return [folder] }
            let caseName = filter.filterCase == .caseSensitive ? filter.filterCase.name : nil
            return [folder, filter.filterTarget.name, filter.filterMatching.name, caseName]
        }

        private func onOffText(_ isOn: Bool) -> String {
            let result: String
            if isOn {
                result = "autoFilter_ON"~
            } else {
                result = "autoFilter_OFF"~
            }
            return result
        }

        private func joined(_ parts: [String?]) -> String? {
            let presentParts = parts.compactMap { $0 }.filter { !$0.isEmpty }
            guard !presentParts.isEmpty else { return nil }
            return presentParts.joined(separator: " · ")
        }
    }
}
