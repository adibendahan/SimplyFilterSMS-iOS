//
//  SearchManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import Foundation
import NaturalLanguage

class SearchManager: SearchManagerProtocol {

    //MARK: - Initialization -
    init(persistenceManager: PersistenceManagerProtocol,
         defaultsManager: DefaultsManagerProtocol,
         smartFilterManager: SmartFilterManagerProtocol,
         filterListManager: FilterListManagerProtocol) {
        self.persistenceManager = persistenceManager
        self.defaultsManager = defaultsManager
        self.smartFilterManager = smartFilterManager
        self.filterListManager = filterListManager
    }


    //MARK: - Public API (SearchManagerProtocol) -
    private(set) var lastQuery: String?

    var recentQueries: [String] {
        get {
            let result: [String]
            if kSearchHistoryKeepsAcrossLaunches {
                result = self.defaultsManager.recentSearchQueries
            } else {
                result = self.sessionRecentQueries
            }
            return result
        }
        set {
            if kSearchHistoryKeepsAcrossLaunches {
                self.defaultsManager.recentSearchQueries = newValue
            } else {
                self.sessionRecentQueries = newValue
            }
        }
    }

    func sections(matching query: String) -> [SearchResultSection] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return [] }

        var sections: [SearchResultSection] = []
        for kind in SearchResultKind.allCases {
            let results = self.results(of: kind, matching: term)
            guard !results.isEmpty else { continue }
            sections.append(SearchResultSection(kind: kind, results: results))
        }

        let resultCount = sections.reduce(0) { $0 + $1.results.count }
        Log.debug("searched, query: \(term), kinds: \(sections.map(\.kind)), results: \(resultCount)")
        return sections
    }

    var suggestions: [SearchResult] {
        let candidates = self.suggestionCandidates
        let picks = self.weightedPicks(from: candidates, count: kSearchSuggestionCount)
        var orderedPicks: [SuggestionCandidate] = []
        for grade in [SuggestionGrade.high, .medium, .low] {
            orderedPicks.append(contentsOf: picks.filter { $0.grade == grade })
        }
        var suggestions = orderedPicks.map(\.result)
        if !self.defaultsManager.didTip {
            suggestions.append(.action(.tipJar))
        }
        Log.debug("suggestions drawn, candidates: \(candidates.count), kinds: \(suggestions.map(\.kind)), tipJar: \(!self.defaultsManager.didTip)")
        return suggestions
    }

    func recordSearch(_ query: String) {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        var queries = self.recentQueries.filter { $0.caseInsensitiveCompare(term) != .orderedSame }
        queries.insert(term, at: 0)
        self.recentQueries = Array(queries.prefix(kSearchHistoryMaxCount))
        self.lastQuery = term
        Log.debug("search recorded, query: \(term), recents: \(self.recentQueries.count), keptAcrossLaunches: \(kSearchHistoryKeepsAcrossLaunches)")
    }

    func clearRecentQueries() {
        Log.debug("recent searches cleared, recents: \(self.recentQueries.count), last: \(self.lastQuery)")
        self.recentQueries = []
        self.lastQuery = nil
    }

    func resetSession() {
        Log.debug("search session reset, last: \(self.lastQuery), recents: \(self.recentQueries.count), keptAcrossLaunches: \(kSearchHistoryKeepsAcrossLaunches)")
        self.lastQuery = nil
        self.sessionRecentQueries = []
    }

    func setPendingFocus(_ focus: SearchFocus) {
        Log.debug("focus pending, target: \(focus.target), replaced: \(self.pendingFocus?.target)")
        self.pendingFocus = focus
    }

    func takeFocusedFilter() -> UUID? {
        guard case .filter(let uuid) = self.pendingFocus else { return nil }
        self.clearPendingFocus()
        return uuid
    }

    func takeFocusedCommunityList() -> String? {
        guard case .communityList(let id) = self.pendingFocus else { return nil }
        self.clearPendingFocus()
        return id
    }

    func takeFocusedFAQ() -> HelpFAQ? {
        guard case .help(let faq) = self.pendingFocus else { return nil }
        self.clearPendingFocus()
        return faq
    }


    //MARK: - Private -
    private weak var persistenceManager: PersistenceManagerProtocol?
    private var defaultsManager: DefaultsManagerProtocol
    private var sessionRecentQueries: [String] = []
    private let smartFilterManager: SmartFilterManagerProtocol
    private let filterListManager: FilterListManagerProtocol
    private var pendingFocus: SearchFocus?

    private func clearPendingFocus() {
        Log.debug("focus taken, target: \(self.pendingFocus?.target)")
        self.pendingFocus = nil
    }

    private func results(of kind: SearchResultKind, matching term: String) -> [SearchResult] {
        let results: [SearchResult]
        switch kind {
        case .aiLanguage:
            let languages = self.filterListManager.filterListLanguages.filter { language in
                return self.matches(language.localizedName, term) || self.matches(language.nativeName, term)
            }
            results = languages.map { .aiLanguage($0) }
        case .smartFilter:
            let rules = self.smartFilterManager.smartFilterTypes.filter { self.matches($0.title, term) }
            results = rules.map { .smartFilter($0) }
        case .communityList:
            let communityLists = self.filterListManager.communityLists.filter { communityList in
                return self.matches(communityList.name, term) || self.matches(communityList.author, term) || self.matches(communityList.description, term)
            }
            results = communityLists.map { .communityList($0) }
        case .allowFilter:
            results = self.filterResults(of: .allow, matching: term)
        case .denyFilter:
            results = self.filterResults(of: .deny, matching: term)
        case .languageFilter:
            results = self.filterResults(of: .denyLanguage, matching: term)
        case .help:
            let faqs = HelpFAQ.allCases.filter { self.matches($0.question, term) }
            results = faqs.map { .help($0) }
        case .action:
            let actions = self.availableActions.filter { self.matches($0.title, term) }
            results = actions.map { .action($0) }
        }
        return results
    }

    private func filterResults(of filterType: FilterType, matching term: String) -> [SearchResult] {
        let filters = self.persistenceManager?.fetchFilterRecords(for: filterType) ?? []
        let matchingFilters = filters.filter { self.matches(self.searchableText(of: $0), term) }
        return matchingFilters.map { .filter($0) }
    }

    private func searchableText(of filter: Filter) -> String? {
        let result: String?
        if filter.filterType == .denyLanguage {
            result = NLLanguage(filterText: filter.text ?? "").localizedName
        } else {
            result = filter.text
        }
        return result
    }

    private enum SuggestionGrade: Int {
        case low = 1
        case medium = 3
        case high = 5
    }

    private struct SuggestionCandidate {
        let result: SearchResult
        let grade: SuggestionGrade
    }

    private var suggestionCandidates: [SuggestionCandidate] {
        let filterListManager = self.filterListManager
        let smartFilterManager = self.smartFilterManager
        var candidates: [SuggestionCandidate] = [
            SuggestionCandidate(result: .action(.testFilters), grade: .high),
            SuggestionCandidate(result: .help(.notFiltering), grade: .high),
            SuggestionCandidate(result: .action(.improveAIFiltering), grade: .medium),
            SuggestionCandidate(result: .action(.reportMessage), grade: .medium),
            SuggestionCandidate(result: .help(.siriShortcuts), grade: .medium),
            SuggestionCandidate(result: .action(.accentColor), grade: .low)
        ]

        let languages = filterListManager.filterListLanguages
        let hasActiveLanguage = languages.contains { filterListManager.isFilterListActive(for: $0) }
        if !hasActiveLanguage, let language = self.preferredLanguage(in: languages) {
            candidates.append(SuggestionCandidate(result: .aiLanguage(language), grade: .high))
        }

        let hasActiveCommunityList = filterListManager.activeCommunityListsCount > 0
        if !hasActiveCommunityList, let communityList = filterListManager.communityLists.first(where: { $0.isCurated }) {
            candidates.append(SuggestionCandidate(result: .communityList(communityList), grade: .high))
            candidates.append(SuggestionCandidate(result: .help(.communityLists), grade: .medium))
        }

        if !self.defaultsManager.didOpenStayReachable {
            candidates.append(SuggestionCandidate(result: .action(.stayReachable), grade: .high))
        }

        for rule in smartFilterManager.smartFilterTypes where rule != .allUnknown && !smartFilterManager.isSmartFilterActive(for: rule) {
            candidates.append(SuggestionCandidate(result: .smartFilter(rule), grade: .medium))
        }
        if !smartFilterManager.isSmartFilterActive(for: .countryAllowlist) {
            candidates.append(SuggestionCandidate(result: .help(.allowByCountry), grade: .medium))
        }

        let gradedFAQs: Set<HelpFAQ> = [.notFiltering, .siriShortcuts, .communityLists, .allowByCountry]
        for faq in HelpFAQ.allCases where !gradedFAQs.contains(faq) {
            candidates.append(SuggestionCandidate(result: .help(faq), grade: .low))
        }
        return candidates
    }

    private func preferredLanguage(in languages: [NLLanguage]) -> NLLanguage? {
        let deviceLanguageCode = Locale.current.language.languageCode?.identifier ?? ""
        let deviceLanguage = languages.first { $0.rawValue == deviceLanguageCode }
        return deviceLanguage ?? languages.first
    }

    private func weightedPicks(from candidates: [SuggestionCandidate], count: Int) -> [SuggestionCandidate] {
        var remaining = candidates
        var picks: [SuggestionCandidate] = []
        while picks.count < count, !remaining.isEmpty {
            let totalWeight = remaining.reduce(0) { $0 + $1.grade.rawValue }
            var roll = Int.random(in: 0..<totalWeight)
            var chosenIndex = remaining.count - 1
            for (index, candidate) in remaining.enumerated() {
                if roll < candidate.grade.rawValue {
                    chosenIndex = index
                    break
                }
                roll -= candidate.grade.rawValue
            }
            picks.append(remaining.remove(at: chosenIndex))
        }
        return picks
    }

    private var availableActions: [SearchAction] {
        let hasFilters = !(self.persistenceManager?.fetchFilterRecords().isEmpty ?? true)
        return SearchAction.allCases.filter { $0 != .exportFilters || hasFilters }
    }

    private func matches(_ text: String?, _ term: String) -> Bool {
        guard let text else { return false }
        return text.localizedStandardContains(term)
    }
}
