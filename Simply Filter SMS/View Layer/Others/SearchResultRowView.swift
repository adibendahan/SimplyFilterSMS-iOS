//
//  SearchResultRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 22/11/2026.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct SearchResultRowView: View {

    let row: Row
    let query: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            self.onSelect()
        } label: {
            self.label
        }
        .foregroundStyle(.primary)
        .accessibilityIdentifier("\(TestIdentifier.searchResult.rawValue)-\(self.row.kind)-\(self.row.title)")
    }


    //MARK: - Private -
    private var label: some View {
        return AdaptiveRow {
            self.icon
                .bounceOnAppear(isShown: self.isSelected, delay: 0)
                .adaptiveIconColumn()
                .accessibilityHidden(true)
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                Text(AttributedString(self.row.title).highlighting(self.query))
                    .multilineTextAlignment(.leading)
                if let subtitle = self.row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } trailing: {
            HStack(spacing: 8) {
                if let value = self.row.value {
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
    private var icon: some View {
        switch self.row.icon {
        case .symbol(let name, let color):
            Image(systemName: name)
                .foregroundStyle(color)
        case .text(let text):
            Text(text)
        }
    }
}


//MARK: - Row -
extension SearchResultRowView {

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

extension SearchResultRowView.Row {

    init(result: SearchResult, kind: SearchResultKind, appManager: AppManagerProtocol) {
        switch result {
        case .list(let list):
            self.init(kind: kind, result: result, title: list.title, subtitle: nil, value: nil, icon: .symbol(list.iconName, list.color))
        case .aiLanguage(let language):
            self.init(language: language, kind: kind, filterListManager: appManager.filterListManager)
        case .smartFilter(let rule):
            self.init(rule: rule, kind: kind, smartFilterManager: appManager.smartFilterManager)
        case .communityList(let communityList):
            self.init(communityList: communityList, kind: kind)
        case .filter(let filter):
            self.init(filter: filter, kind: kind)
        case .help(let faq):
            self.init(kind: kind, result: result, title: faq.question, subtitle: nil, value: nil, icon: .symbol("questionmark.bubble", WhatsNewEntry.help.color))
        case .action(let action):
            self.init(kind: kind, result: result, title: action.title, subtitle: nil, value: nil, icon: .symbol(action.iconName, action.color))
        }
    }


    //MARK: - Private -
    private init(language: NLLanguage, kind: SearchResultKind, filterListManager: FilterListManagerProtocol) {
        let localizedName = language.localizedName ?? language.rawValue
        let nativeName = language.nativeName.flatMap { $0 == localizedName ? nil : $0 }
        let ruleCount = filterListManager.filterListRuleCounts[language]
        let ruleCountText = ruleCount.map { String.localizedStringWithFormat("autoFilter_ruleCount"~, $0) }
        let isActive = filterListManager.isFilterListActive(for: language)
        self.init(kind: kind,
                  result: .aiLanguage(language),
                  title: localizedName,
                  subtitle: Self.joined([nativeName, ruleCountText]),
                  value: Self.onOffText(isActive),
                  icon: .symbol("bolt.shield.fill", .indigo))
    }

    private init(rule: SmartFilterType, kind: SearchResultKind, smartFilterManager: SmartFilterManagerProtocol) {
        let subtitle: String?
        if rule == .shortSender, let format = rule.subtitle {
            subtitle = String.localizedStringWithFormat(format, smartFilterManager.selectedChoice(for: rule))
        } else {
            subtitle = nil
        }
        let icon: SearchResultRowView.Icon
        if rule.isTextIcon {
            icon = .text(rule.icon)
        } else {
            icon = .symbol(rule.icon, rule.iconColor)
        }
        self.init(kind: kind,
                  result: .smartFilter(rule),
                  title: rule.title,
                  subtitle: subtitle,
                  value: Self.onOffText(smartFilterManager.isSmartFilterActive(for: rule)),
                  icon: icon)
    }

    private init(communityList: CommunityListItem, kind: SearchResultKind) {
        let ruleCountText = communityList.ruleCount.map { String.localizedStringWithFormat("autoFilter_ruleCount"~, $0) }
        let authorText = communityList.author.map { String(format: "communityLists_byAuthor"~, $0) }
        self.init(kind: kind,
                  result: .communityList(communityList),
                  title: communityList.name,
                  subtitle: Self.joined([ruleCountText, communityList.localeLabel, authorText]),
                  value: Self.onOffText(communityList.isActive),
                  icon: .symbol("person.2.circle", .indigo))
    }

    private init(filter: Filter, kind: SearchResultKind) {
        let filterType = filter.filterType
        let title: String
        if filterType == .denyLanguage {
            title = NLLanguage(filterText: filter.text ?? "").localizedName ?? (filter.text ?? "")
        } else {
            title = filter.text ?? ""
        }
        self.init(kind: kind,
                  result: .filter(filter),
                  title: title,
                  subtitle: Self.joined(Self.optionNames(of: filter)),
                  value: nil,
                  icon: .symbol(filterType.searchResultIconName, filterType.iconColor))
    }

    private static func optionNames(of filter: Filter) -> [String?] {
        let filterType = filter.filterType
        let folder = filterType == .allow ? nil : filter.messageFolder.name
        guard filterType != .denyLanguage else { return [folder] }
        let caseName = filter.filterCase == .caseSensitive ? filter.filterCase.name : nil
        return [folder, filter.filterTarget.name, filter.filterMatching.name, caseName]
    }

    private static func onOffText(_ isOn: Bool) -> String {
        let result: String
        if isOn {
            result = "autoFilter_ON"~
        } else {
            result = "autoFilter_OFF"~
        }
        return result
    }

    private static func joined(_ parts: [String?]) -> String? {
        let presentParts = parts.compactMap { $0 }.filter { !$0.isEmpty }
        guard !presentParts.isEmpty else { return nil }
        return presentParts.joined(separator: " · ")
    }
}


//MARK: - Colors -
extension SearchList {
    var color: Color {
        switch self {
        case .aiFiltering, .communityLists:
            return .indigo
        case .allow:
            return FilterType.allow.iconColor
        case .deny:
            return FilterType.deny.iconColor
        case .denyLanguage:
            return FilterType.denyLanguage.iconColor
        }
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

private extension FilterType {
    var searchResultIconName: String {
        switch self {
        case .allow, .deny:
            return "textformat"
        case .denyLanguage:
            return "character.bubble"
        }
    }
}
