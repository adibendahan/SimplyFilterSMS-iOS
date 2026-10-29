//
//  AutomaticFilterManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/01/2022.
//

import Foundation
import NaturalLanguage

class AutomaticFilterManager: AutomaticFilterManagerProtocol {
    
    //MARK: - Initialization -
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         filterListService: FilterListServiceProtocol = AppManager.shared.filterListService) {
        
        self.persistanceManager = persistanceManager
        self.filterListService = filterListService
    }
    
    
    //MARK: - Public API (AutomaticFilterManagerProtocol) -
    var isAutomaticFilteringOn: Bool {
        var isAutomaticFilteringOn = false
        
        let automaticFiltersLanguageRecords = self.persistanceManager?.fetchAutomaticFiltersLanguageRecords()
        let supportedLanguages: [NLLanguage] = self.languages(for: .automaticBlocking)
        
        for automaticFilterLanguage in automaticFiltersLanguageRecords ?? [] {
            if let langRawValue = automaticFilterLanguage.lang {
                let lang = NLLanguage(rawValue: langRawValue)
                
                if supportedLanguages.contains(lang) &&
                    automaticFilterLanguage.isActive == true {
                    
                    isAutomaticFilteringOn = true
                    break
                }
            }
        }
        
        return isAutomaticFilteringOn
    }
    
    var rules: [RuleType] {
        return RuleType.allCases
    }
    
    var activeAutomaticFiltersTitle: String? {
        var activeLanguagesString = ""
        var automaticFilterNames: [String] = []
        
        let automaticFiltersLanguageRecords = self.persistanceManager?.fetchAutomaticFiltersLanguageRecords()
        let supportedLanguages = self.languages(for: .automaticBlocking)
        
        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords ?? [] {
            if let langRawValue = automaticFiltersLanguageRecord.lang,
               automaticFiltersLanguageRecord.isActive == true {
                
                let lang = NLLanguage(rawValue: langRawValue)
                
                if supportedLanguages.contains(lang),
                   let localizedName = lang.localizedName {
                    
                    automaticFilterNames.append(localizedName)
                }
            }
        }
        
        guard automaticFilterNames.count > 0 else { return nil }
        let count = automaticFilterNames.count - 1
        
        for (index, string) in automaticFilterNames.enumerated() {
            if index < count {
                activeLanguagesString.append(string + ", ")
            }
            else {
                activeLanguagesString.append(string)
                
                if count > 0 {
                    activeLanguagesString.append(".")
                }
            }
        }
        
        return activeLanguagesString.isEmpty ? nil : activeLanguagesString
    }
    
    var automaticFiltersCacheAge: Date? {
        guard let persistanceManager = self.persistanceManager,
              let cache = persistanceManager.fetchAutomaticFiltersCacheRecords().first else { return nil }
        
        return cache.age
    }
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        guard let persistanceManager = self.persistanceManager else { return [] }
        var supportedLanguages: [NLLanguage] = []
        
        switch type {
        case .blockLanguage:
            let remainingSupportedLanguages = NLLanguage.allSupportedCases
                .filter({ !persistanceManager.isDuplicateFilter(language: $0) })
                .sorted(by: Self.languageSortOrder)
            supportedLanguages.append(contentsOf: remainingSupportedLanguages)
            
        case .automaticBlocking:
            if let cache = persistanceManager.cachedFilterLists() {
                
                for entry in cache.catalog.lists {
                    guard let langRawValue = entry.language else { continue }
                    let language = NLLanguage(langRawValue)
                    
                    if language != .undetermined,
                       !supportedLanguages.contains(language) {
                        supportedLanguages.append(language)
                    }
                }
                
            }
            
            supportedLanguages.sort(by: Self.languageSortOrder)
        }
        
        return supportedLanguages
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        guard let persistanceManager = self.persistanceManager else { return false }
        let automaticFiltersLanguage = persistanceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        return automaticFiltersLanguage.isActive
    }
    
    func setLanguageAutomaticState(for language: NLLanguage, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        AppManager.logger.debug("setLanguageAutomaticState — '\(language.localizedName ?? language.rawValue, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersLanguage = persistanceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        automaticFiltersLanguage.isActive = value
        _ = persistanceManager.commitAndAnnounce()
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        AppManager.logger.debug("setAutomaticRuleState — '\(rule.title, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersRule = persistanceManager.ensuredAutomaticFiltersRuleRecord(for: rule)
        automaticFiltersRule.isActive = value
        if automaticFiltersRule.ruleType == .shortSender && automaticFiltersRule.selectedChoice < 3 {
            automaticFiltersRule.selectedChoice = 6
        }
        _ = persistanceManager.commitAndAnnounce()
    }

    func selectedChoice(for rule: RuleType) -> Int {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return 0 }
        return Int(automaticFiltersRule.selectedChoice)
    }

    func setSelectedChoice(for rule: RuleType, choice: Int) {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        AppManager.logger.debug("setSelectedChoice — '\(rule.title, privacy: .public)' → \(choice, privacy: .public)")
        automaticFiltersRule.selectedChoice = Int64(choice)
        _ = persistanceManager.commitAndAnnounce()
    }

    func selectedCountries(for rule: RuleType) -> [String] {
        return self.persistanceManager?.selectedCountries(for: rule) ?? []
    }

    func setSelectedCountries(_ countries: [String], for rule: RuleType) {
        AppManager.logger.debug("setSelectedCountries — \(countries, privacy: .public)")
        self.persistanceManager?.setSelectedCountries(countries, for: rule)
    }

    func updateAutomaticFiltersIfNeeded() async {
        await self.refreshFilterLists(force: false)
    }

    func forceUpdateAutomaticFilters() async {
        AppManager.logger.debug("forceUpdateAutomaticFilters — forcing fetch")
        await self.refreshFilterLists(force: true)
    }
    
    //MARK: - Private  -
    
    private static func languageSortOrder(_ a: NLLanguage, _ b: NLLanguage) -> Bool {
        let currentLocale: NLLanguage? = Locale.current.language.languageCode.map { NLLanguage(rawValue: $0.identifier) }
        var priority: [NLLanguage] = [.english, .hebrew]
        if let current = currentLocale, !priority.contains(current) {
            priority.insert(current, at: 0)
        } else if currentLocale == .hebrew {
            priority = [.hebrew, .english]
        }
        let ai = priority.firstIndex(of: a)
        let bi = priority.firstIndex(of: b)
        switch (ai, bi) {
        case let (ai?, bi?):
            return ai < bi
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case (nil, nil):
            let locale = Locale(identifier: "en_US")
            let an = locale.localizedString(forIdentifier: a.rawValue) ?? a.rawValue
            let bn = locale.localizedString(forIdentifier: b.rawValue) ?? b.rawValue
            return an < bn
        }
    }
    
    private weak var filterListService: FilterListServiceProtocol?
    private weak var persistanceManager: PersistanceManagerProtocol?
    private var refreshTask: Task<Void, Never>?
    private var shouldFetchFilters: Bool {
        guard self.persistanceManager?.cachedFilterLists() != nil else { return true }
        var shouldFetchFilters = true
        
        if let cacheAge = self.automaticFiltersCacheAge,
           cacheAge.daysBetween(date: Date()) < kUpdateAutomaticFiltersMinDays {
            
            shouldFetchFilters = false
        }
        
        return shouldFetchFilters
    }
    
    @MainActor
    private func refreshFilterLists(force: Bool) async {
        if let refreshTask = self.refreshTask {
            AppManager.logger.debug("refreshFilterLists — joining the refresh in progress")
            await refreshTask.value
            return
        }
        guard force || self.shouldFetchFilters else {
            AppManager.logger.debug("refreshFilterLists — cache is fresh, skipping fetch")
            return
        }
        let refreshTask = Task { await self.performRefresh(force: force) }
        self.refreshTask = refreshTask
        await refreshTask.value
        self.refreshTask = nil
    }

    @MainActor
    private func performRefresh(force: Bool) async {
        guard let persistanceManager = self.persistanceManager,
              let filterListService = self.filterListService else { return }

        let cache = persistanceManager.cachedFilterLists()
        let catalogETagToSend = force ? nil : cache?.catalogETag
        let catalogResponse = await filterListService.fetchFilterListCatalog(etag: catalogETagToSend)
        let catalog: FilterListCatalogResponse
        let catalogETag: String?

        switch catalogResponse {
        case .modified(let fetchedCatalog, let etag):
            catalog = fetchedCatalog
            catalogETag = etag
        case .notModified:
            guard let cache = cache else { return }
            catalog = cache.catalog
            catalogETag = cache.catalogETag
        case nil:
            AppManager.logger.debug("performRefresh — catalog fetch failed, keeping the cache")
            return
        }

        var lists: [FilterListsCacheSection] = []
        var fetchedURLs: Set<URL> = []
        var hasFailures = false

        for entry in catalog.lists {
            guard let url = entry.resolvedURL,
                  !fetchedURLs.contains(url) else { continue }
            fetchedURLs.insert(url)

            let cachedSection = cache?.lists.first(where: { $0.url == url.absoluteString })
            let listETagToSend = force ? nil : cachedSection?.etag
            let listResponse = await filterListService.fetchFilterList(at: url, etag: listETagToSend)

            switch listResponse {
            case .modified(let payload, let etag):
                lists.append(FilterListsCacheSection(url: url.absoluteString, etag: etag, payload: payload))
            case .notModified:
                if let cachedSection = cachedSection {
                    lists.append(cachedSection)
                }
            case nil:
                hasFailures = true
                if let cachedSection = cachedSection {
                    lists.append(cachedSection)
                }
            }
        }

        let newCache = FilterListsCache(catalogETag: catalogETag, catalog: catalog, lists: lists)
        let hasNewFilters = Self.hasNewFilters(from: cache, to: newCache)
        AppManager.logger.debug("performRefresh — lists: \(lists.count, privacy: .public), changed: \(newCache != cache, privacy: .public), new filters: \(hasNewFilters, privacy: .public), failures: \(hasFailures, privacy: .public)")

        guard newCache != cache else {
            if !hasFailures {
                persistanceManager.touchCache()
            }
            return
        }
        guard persistanceManager.saveCache(newCache) else { return }
        if hasNewFilters {
            NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)
        }
    }

    private static func hasNewFilters(from oldCache: FilterListsCache?, to newCache: FilterListsCache) -> Bool {
        let oldLists = oldCache?.lists ?? []
        let oldURLs = Set(oldLists.map({ $0.url }))
        let newURLs = Set(newCache.lists.map({ $0.url }))
        guard oldURLs == newURLs else { return true }

        for newList in newCache.lists {
            guard let oldList = oldLists.first(where: { $0.url == newList.url }) else { return true }

            if let newRevision = newList.payload.revision,
               let oldRevision = oldList.payload.revision {

                if newRevision > oldRevision {
                    return true
                }
            }
            else if newList.payload.filters != oldList.payload.filters {
                return true
            }
        }

        return false
    }
}
