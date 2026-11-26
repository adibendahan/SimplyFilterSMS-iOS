//
//  SearchManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import Foundation
import NaturalLanguage

protocol SearchManagerProtocol: AnyObject {
    var recentQueries: [String] { get }
    var suggestions: [SearchResult] { get }
    var lastQuery: String? { get }

    func sections(matching query: String) -> [SearchResultSection]
    func recordSearch(_ query: String)
    func clearRecentQueries()
    func forgetLastQuery()
    func resetSession()
    func setPendingFocus(_ focus: SearchFocus)
    func takeFocus<Value>(_ value: KeyPath<SearchFocus, Value?>) -> Value?
    func indexSpotlightItems()
    func spotlightResult(for identifier: String) -> SearchResult?
}


//MARK: - Results -
enum SearchResultKind: Int, CaseIterable, Identifiable {
    case list, aiLanguage, smartFilter, communityList, allowFilter, denyFilter, languageFilter, help, action

    var id: Self { self }

    var title: String {
        switch self {
        case .list:
            return "autoFilter_yourFilters"~
        case .aiLanguage:
            return "autoFilter_title"~
        case .smartFilter:
            return "autoFilter_smartFilters"~
        case .communityList:
            return "communityLists_title"~
        case .allowFilter:
            return "filterList_allowed"~
        case .denyFilter:
            return "filterList_denied"~
        case .languageFilter:
            return "filterList_deniedLanguage"~
        case .help:
            return "menu_help"~
        case .action:
            return "search_menu"~
        }
    }
}

enum SearchResult: Identifiable {
    case list(SearchList)
    case aiLanguage(NLLanguage)
    case smartFilter(SmartFilterType)
    case communityList(CommunityListItem)
    case filter(Filter)
    case help(HelpFAQ)
    case action(SearchAction)

    var id: String {
        switch self {
        case .list(let list):
            return "list-\(list)"
        case .aiLanguage(let language):
            return "aiLanguage-\(language.rawValue)"
        case .smartFilter(let rule):
            return "smartFilter-\(rule.rawValue)"
        case .communityList(let communityList):
            return "communityList-\(communityList.id)"
        case .filter(let filter):
            return "filter-\(filter.uuid?.uuidString ?? filter.objectID.uriRepresentation().absoluteString)"
        case .help(let faq):
            return "help-\(faq.rawValue)"
        case .action(let action):
            return "action-\(action)"
        }
    }

    var kind: SearchResultKind {
        switch self {
        case .list:
            return .list
        case .aiLanguage:
            return .aiLanguage
        case .smartFilter:
            return .smartFilter
        case .communityList:
            return .communityList
        case .filter(let filter):
            switch filter.filterType {
            case .allow:
                return .allowFilter
            case .deny:
                return .denyFilter
            case .denyLanguage:
                return .languageFilter
            }
        case .help:
            return .help
        case .action:
            return .action
        }
    }

    var opensScreen: Bool {
        switch self {
        case .smartFilter:
            return false
        case .list, .aiLanguage, .communityList, .filter, .help, .action:
            return true
        }
    }
}

struct SearchResultSection: Identifiable {
    let kind: SearchResultKind
    let results: [SearchResult]

    var id: SearchResultKind {
        return self.kind
    }
}

enum SearchList: CaseIterable {
    case aiFiltering, communityLists, allow, deny, denyLanguage

    var title: String {
        switch self {
        case .aiFiltering:
            return "autoFilter_title"~
        case .communityLists:
            return "communityLists_title"~
        case .allow:
            return FilterType.allow.name
        case .deny:
            return FilterType.deny.name
        case .denyLanguage:
            return FilterType.denyLanguage.name
        }
    }

    var iconName: String {
        switch self {
        case .aiFiltering:
            return "bolt.shield.fill"
        case .communityLists:
            return "person.2.fill"
        case .allow:
            return FilterType.allow.iconName
        case .deny:
            return FilterType.deny.iconName
        case .denyLanguage:
            return FilterType.denyLanguage.iconName
        }
    }

    var screen: Screen {
        switch self {
        case .aiFiltering:
            return .filterLists
        case .communityLists:
            return .communityLists
        case .allow:
            return FilterType.allow.screen
        case .deny:
            return FilterType.deny.screen
        case .denyLanguage:
            return FilterType.denyLanguage.screen
        }
    }
}

enum SearchAction: CaseIterable {
    case addAllowFilter, addDenyFilter, addLanguageFilter, stayReachable,
         testFilters, reportMessage, improveAIFiltering, exportFilters, importFilters,
         help, whatsNew, about, accentColor, tipJar

    var title: String {
        switch self {
        case .addAllowFilter:
            return "addFilter_addFilter_allow"~
        case .addDenyFilter:
            return "addFilter_addFilter_deny"~
        case .addLanguageFilter:
            return "addFilter_addLanguage"~
        case .stayReachable:
            return "stayReachable_title"~
        case .testFilters:
            return "testFilters_title"~
        case .reportMessage:
            return "reportMessage_title"~
        case .improveAIFiltering:
            return "autoFilter_improveAIFiltering"~
        case .exportFilters:
            return "menu_exportFilters"~
        case .importFilters:
            return "menu_importFilters"~
        case .help:
            return "menu_help"~
        case .whatsNew:
            return "whatsNew_menuItem"~
        case .about:
            return "filterList_menu_about"~
        case .accentColor:
            return "accentColor_menuItem"~
        case .tipJar:
            return "tipJar_menuItem"~
        }
    }

    var iconName: String {
        switch self {
        case .addAllowFilter:
            return FilterType.allow.iconName
        case .addDenyFilter:
            return FilterType.deny.iconName
        case .addLanguageFilter:
            return "globe"
        case .stayReachable:
            return "person.badge.shield.checkmark"
        case .testFilters:
            return "arrow.up.message"
        case .reportMessage:
            return "exclamationmark.bubble"
        case .improveAIFiltering:
            return "wand.and.stars"
        case .exportFilters:
            return "square.and.arrow.up"
        case .importFilters:
            return "square.and.arrow.down"
        case .help:
            return "questionmark.circle"
        case .whatsNew:
            return "sparkles"
        case .about:
            return "info.circle"
        case .accentColor:
            return "paintpalette"
        case .tipJar:
            return "heart.fill"
        }
    }

    var screen: Screen? {
        switch self {
        case .addAllowFilter:
            return .addAllowFilter
        case .addDenyFilter:
            return .addDenyFilter
        case .addLanguageFilter:
            return .addLanguageFilter
        case .stayReachable:
            return .stayReachable
        case .testFilters:
            return .filterTester
        case .reportMessage:
            return .reportMessage
        case .improveAIFiltering:
            return .enableReportingExtension
        case .exportFilters, .importFilters:
            return nil
        case .help:
            return .help
        case .whatsNew:
            return .whatsNew
        case .about:
            return .about
        case .accentColor:
            return .chooseAccentColor
        case .tipJar:
            return .tipJar
        }
    }
}


//MARK: - Focus -
enum SearchFocus: Equatable {
    case filter(UUID)
    case communityList(String)
    case help(HelpFAQ)
    case aiLanguage(NLLanguage)

    var target: String {
        switch self {
        case .filter(let uuid):
            return uuid.uuidString
        case .communityList(let id):
            return id
        case .help(let faq):
            return faq.rawValue
        case .aiLanguage(let language):
            return language.rawValue
        }
    }

    var filterID: UUID? {
        guard case .filter(let uuid) = self else { return nil }
        return uuid
    }

    var communityListID: String? {
        guard case .communityList(let id) = self else { return nil }
        return id
    }

    var faq: HelpFAQ? {
        guard case .help(let faq) = self else { return nil }
        return faq
    }

    var language: NLLanguage? {
        guard case .aiLanguage(let language) = self else { return nil }
        return language
    }
}
