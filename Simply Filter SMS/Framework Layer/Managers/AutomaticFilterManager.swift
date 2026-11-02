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
         filterListService: FilterListServiceProtocol = AppManager.shared.filterListService,
         networkSyncManager: NetworkSyncManagerProtocol = AppManager.shared.networkSyncManager) {
        
        self.persistanceManager = persistanceManager
        self.filterListService = filterListService
        self.networkSyncManager = networkSyncManager
    }
    
    deinit {
        self.networkStatusTask?.cancel()
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
            if let catalog = persistanceManager.cachedFilterListCatalog() {
                
                for entry in catalog.lists {
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

    @MainActor
    func updateAutomaticFiltersIfNeeded() async {
        await self.refreshFilterLists()
    }

    @MainActor
    func updateAutomaticFiltersWhenOnline() {
        guard !ProcessInfo.processInfo.isInTestingMode else {
            AppManager.logger.debug("updateAutomaticFiltersWhenOnline — testing mode, keeping the seeded filter lists")
            return
        }
        guard !self.didCheckFilterListsToday else {
            AppManager.logger.debug("updateAutomaticFiltersWhenOnline — today's check already succeeded")
            return
        }
        AppManager.logger.debug("updateAutomaticFiltersWhenOnline — waiting for network status")
        self.networkSyncManager?.onFirstStatusKnown { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard self.networkSyncManager?.networkStatus == .online else {
                    AppManager.logger.debug("updateAutomaticFiltersWhenOnline — offline, checking once back online")
                    self.updateAutomaticFiltersOnNextOnline()
                    return
                }
                self.updateAutomaticFiltersInBackground()
            }
        }
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
    private weak var networkSyncManager: NetworkSyncManagerProtocol?
    private var refreshTask: Task<Void, Never>?
    private var networkStatusTask: Task<Void, Never>?

    @MainActor
    private var didCheckFilterListsToday: Bool {
        guard let lastCheck = self.automaticFiltersCacheAge else { return false }
        return lastCheck.daysBetween(date: Date()) == 0
    }

    @MainActor
    private func updateAutomaticFiltersOnNextOnline() {
        guard self.networkStatusTask == nil else { return }
        let networkStatusChanges = NotificationCenter.default.notifications(named: .networkStatusChange)
        self.networkStatusTask = Task { @MainActor [weak self] in
            for await notification in networkStatusChanges {
                guard let networkStatus = notification.object as? NetworkStatus, networkStatus == .online else { continue }
                guard let self else { return }
                self.networkStatusTask = nil
                AppManager.logger.debug("updateAutomaticFiltersOnNextOnline — back online")
                self.updateAutomaticFiltersInBackground()
                return
            }
        }
    }

    @MainActor
    private func updateAutomaticFiltersInBackground() {
        AppManager.logger.debug("updateAutomaticFiltersInBackground — triggering automatic filter update check")
        Task(priority: .background) {
            await self.updateAutomaticFiltersIfNeeded()
        }
    }
    
    @MainActor
    private func refreshFilterLists() async {
        if let refreshTask = self.refreshTask {
            AppManager.logger.debug("refreshFilterLists — joining the refresh in progress")
            await refreshTask.value
            return
        }
        var cacheAgeDescription = "none"
        if let cacheAge = self.automaticFiltersCacheAge {
            cacheAgeDescription = "\(cacheAge.daysBetween(date: Date()))d"
        }
        AppManager.logger.debug("refreshFilterLists — fetching | cache age: \(cacheAgeDescription, privacy: .public)")
        let refreshTask = Task { await self.performRefresh() }
        self.refreshTask = refreshTask
        await refreshTask.value
        self.refreshTask = nil
    }

    @MainActor
    private func performRefresh() async {
        guard let persistanceManager = self.persistanceManager,
              let filterListService = self.filterListService else { return }

        let cache = persistanceManager.cachedFilterLists()
        let catalogResponse = await filterListService.fetchFilterListCatalog(etag: cache?.catalogETag)
        let catalog: FilterListCatalogResponse
        let catalogETag: String?

        switch catalogResponse {
        case .modified(let fetchedCatalog, let etag):
            catalog = fetchedCatalog
            catalogETag = etag
        case .notModified:
            guard let cache = cache else {
                AppManager.logger.debug("performRefresh — catalog not modified but there is no readable cache, stopping")
                return
            }
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
            let listResponse = await filterListService.fetchFilterList(at: url, etag: cachedSection?.etag)

            let listName = url.lastPathComponent
            let hasCachedSection = cachedSection != nil
            switch listResponse {
            case .modified(let payload, let etag):
                let section = FilterListsCacheSection(url: url.absoluteString, etag: etag, payload: payload)
                lists.append(section)
                var revisionDescription = "none"
                if let revision = payload.revision {
                    revisionDescription = "\(revision)"
                }
                AppManager.logger.debug("performRefresh — \(listName, privacy: .public): downloaded | revision: \(revisionDescription, privacy: .public), records: \(payload.filters.count, privacy: .public)")
            case .notModified:
                if let cachedSection = cachedSection {
                    lists.append(cachedSection)
                }
                AppManager.logger.debug("performRefresh — \(listName, privacy: .public): not modified | kept cached: \(hasCachedSection, privacy: .public)")
            case nil:
                hasFailures = true
                if let cachedSection = cachedSection {
                    lists.append(cachedSection)
                }
                AppManager.logger.debug("performRefresh — \(listName, privacy: .public): failed | kept cached: \(hasCachedSection, privacy: .public)")
            }
        }

        let newCache = FilterListsCache(catalogETag: catalogETag, catalog: catalog, lists: lists)
        let hasChanges = newCache != cache
        let hasNewFilters = Self.hasNewFilters(from: cache, to: newCache)
        AppManager.logger.debug("performRefresh — lists: \(lists.count, privacy: .public), changed: \(hasChanges, privacy: .public), new filters: \(hasNewFilters, privacy: .public), failures: \(hasFailures, privacy: .public)")

        guard hasChanges else {
            if !hasFailures {
                AppManager.logger.debug("performRefresh — no changes, touching the cache age")
                persistanceManager.touchCache()
            }
            else {
                AppManager.logger.debug("performRefresh — no changes but some lists failed, leaving the cache age alone")
            }
            return
        }
        guard persistanceManager.saveCache(newCache) else {
            AppManager.logger.error("performRefresh — saving the cache failed")
            return
        }
        if hasNewFilters {
            AppManager.logger.debug("performRefresh — posting automaticFiltersUpdated")
            NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)
        }
    }

    private static func hasNewFilters(from oldCache: FilterListsCache?, to newCache: FilterListsCache) -> Bool {
        let oldLists = oldCache?.lists ?? []
        guard oldLists.count == newCache.lists.count else { return true }

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
