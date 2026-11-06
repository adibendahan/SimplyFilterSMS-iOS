//
//  FilterListManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/01/2022.
//

import Foundation
import NaturalLanguage

class FilterListManager: FilterListManagerProtocol {
    
    //MARK: - Initialization -
    init(persistenceManager: PersistenceManagerProtocol = AppManager.shared.persistenceManager,
         filterListService: FilterListServiceProtocol = AppManager.shared.filterListService,
         networkSyncManager: NetworkSyncManagerProtocol = AppManager.shared.networkSyncManager) {
        
        self.persistenceManager = persistenceManager
        self.filterListService = filterListService
        self.networkSyncManager = networkSyncManager
    }
    
    deinit {
        self.networkStatusTask?.cancel()
    }
    
    
    //MARK: - Public API (FilterListManagerProtocol) -
    var hasActiveFilterLists: Bool {
        var hasActiveFilterLists = false
        
        let automaticFiltersLanguageRecords = self.persistenceManager?.fetchAutomaticFiltersLanguageRecords()
        let supportedLanguages: [NLLanguage] = self.filterListLanguages
        
        for filterListLanguageRecord in automaticFiltersLanguageRecords ?? [] {
            if let langRawValue = filterListLanguageRecord.lang {
                let lang = NLLanguage(rawValue: langRawValue)
                
                if supportedLanguages.contains(lang) &&
                    filterListLanguageRecord.isActive == true {
                    
                    hasActiveFilterLists = true
                    break
                }
            }
        }
        
        return hasActiveFilterLists
    }
    
    var activeFilterListsTitle: String? {
        var activeLanguagesString = ""
        var activeFilterListNames: [String] = []
        
        let automaticFiltersLanguageRecords = self.persistenceManager?.fetchAutomaticFiltersLanguageRecords()
        let supportedLanguages = self.filterListLanguages
        
        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords ?? [] {
            if let langRawValue = automaticFiltersLanguageRecord.lang,
               automaticFiltersLanguageRecord.isActive == true {
                
                let lang = NLLanguage(rawValue: langRawValue)
                
                if supportedLanguages.contains(lang),
                   let localizedName = lang.localizedName {
                    
                    activeFilterListNames.append(localizedName)
                }
            }
        }
        
        guard activeFilterListNames.count > 0 else { return nil }
        let count = activeFilterListNames.count - 1
        
        for (index, string) in activeFilterListNames.enumerated() {
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
    
    var filterListsLastUpdated: Date? {
        guard let persistenceManager = self.persistenceManager,
              let cache = persistenceManager.fetchFilterListsCacheRecords().first else { return nil }
        
        return cache.age
    }
    
    var filterListLanguages: [NLLanguage] {
        guard let catalog = self.persistenceManager?.cachedFilterListCatalog() else { return [] }
        var filterListLanguages: [NLLanguage] = []

        for entry in catalog.lists {
            guard let langRawValue = entry.language else { continue }
            let language = NLLanguage(langRawValue)

            if language != .undetermined,
               !filterListLanguages.contains(language) {
                filterListLanguages.append(language)
            }
        }

        return filterListLanguages.sorted(by: NLLanguage.displayOrder)
    }
    
    func isFilterListActive(for language: NLLanguage) -> Bool {
        guard let persistenceManager = self.persistenceManager else { return false }
        let automaticFiltersLanguage = persistenceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        return automaticFiltersLanguage.isActive
    }
    
    func setFilterListActive(for language: NLLanguage, value: Bool) {
        guard let persistenceManager = self.persistenceManager else { return }
        AppManager.logger.debug("setFilterListActive — '\(language.localizedName ?? language.rawValue, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersLanguage = persistenceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        automaticFiltersLanguage.isActive = value
        _ = persistenceManager.commitAndAnnounce()
    }
    
    @MainActor
    func updateFilterListsWhenOnline() {
        guard !ProcessInfo.processInfo.isInTestingMode else {
            AppManager.logger.debug("updateFilterListsWhenOnline — testing mode, keeping the seeded filter lists")
            return
        }
        guard !self.didCheckFilterListsToday else {
            AppManager.logger.debug("updateFilterListsWhenOnline — today's check already succeeded")
            return
        }
        AppManager.logger.debug("updateFilterListsWhenOnline — waiting for network status")
        self.isCheckingFilterLists = true
        self.networkSyncManager?.onFirstStatusKnown { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard self.networkSyncManager?.networkStatus == .online else {
                    AppManager.logger.debug("updateFilterListsWhenOnline — offline, checking once back online")
                    self.finishFilterListsCheck()
                    self.updateFilterListsOnNextOnline()
                    return
                }
                Task(priority: .background) { @MainActor in
                    await self.refreshFilterLists()
                    self.finishFilterListsCheck()
                }
            }
        }
    }
    
    //MARK: - Private  -
    
    private weak var filterListService: FilterListServiceProtocol?
    private weak var persistenceManager: PersistenceManagerProtocol?
    private weak var networkSyncManager: NetworkSyncManagerProtocol?
    private var refreshTask: Task<Void, Never>?
    private(set) var isCheckingFilterLists = false
    private var networkStatusTask: Task<Void, Never>?

    @MainActor
    private var didCheckFilterListsToday: Bool {
        guard self.persistenceManager?.cachedFilterListCatalog() != nil else { return false }
        guard let lastCheckDate = self.filterListsLastUpdated else { return false }
        return lastCheckDate.daysBetween(date: Date()) == 0
    }

    @MainActor
    private func updateFilterListsOnNextOnline() {
        guard self.networkStatusTask == nil else { return }
        let networkStatusChanges = NotificationCenter.default.notifications(named: .networkStatusChange)
        self.networkStatusTask = Task { @MainActor [weak self] in
            for await notification in networkStatusChanges {
                guard let networkStatus = notification.object as? NetworkStatus, networkStatus == .online else { continue }
                guard let self else { return }
                self.networkStatusTask = nil
                AppManager.logger.debug("updateFilterListsOnNextOnline — back online")
                self.updateFilterListsInBackground()
                return
            }
        }
    }

    @MainActor
    private func finishFilterListsCheck() {
        guard self.isCheckingFilterLists else { return }
        self.isCheckingFilterLists = false
        NotificationCenter.default.post(name: .filterListsCheckFinished, object: nil)
    }

    @MainActor
    private func updateFilterListsInBackground() {
        AppManager.logger.debug("updateFilterListsInBackground — triggering automatic filter update check")
        Task(priority: .background) {
            await self.refreshFilterLists()
        }
    }
    
    @MainActor
    func refreshFilterLists() async {
        if let refreshTask = self.refreshTask {
            AppManager.logger.debug("refreshFilterLists — joining the refresh in progress")
            await refreshTask.value
            return
        }
        var cacheAgeDescription = "none"
        if let cacheAge = self.filterListsLastUpdated {
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
        guard let persistenceManager = self.persistenceManager,
              let filterListService = self.filterListService else { return }

        let cachedSnapshot = persistenceManager.cachedFilterLists()
        guard let revalidatedCatalog = await self.fetchCatalog(revalidating: cachedSnapshot, service: filterListService) else { return }
        let (catalog, catalogETag) = revalidatedCatalog
        let (revalidatedLists, hasFailedLists) = await self.fetchLists(in: catalog, revalidating: cachedSnapshot, service: filterListService)

        let refreshedSnapshot = FilterListsSnapshot(catalogETag: catalogETag, catalog: catalog, lists: revalidatedLists)
        let hasSnapshotChanged = refreshedSnapshot != cachedSnapshot
        let hasNewFilters = Self.hasNewFilters(from: cachedSnapshot, to: refreshedSnapshot)
        AppManager.logger.debug("performRefresh — lists: \(revalidatedLists.count, privacy: .public), changed: \(hasSnapshotChanged, privacy: .public), new filters: \(hasNewFilters, privacy: .public), failures: \(hasFailedLists, privacy: .public)")

        guard hasSnapshotChanged else {
            if !hasFailedLists {
                AppManager.logger.debug("performRefresh — no changes, touching the cache age")
                persistenceManager.touchCache()
            }
            else {
                AppManager.logger.debug("performRefresh — no changes but some lists failed, leaving the cache age alone")
            }
            return
        }
        guard persistenceManager.saveCache(refreshedSnapshot) else {
            AppManager.logger.error("performRefresh — saving the cache failed")
            return
        }
        if hasNewFilters {
            AppManager.logger.debug("performRefresh — posting filterListsUpdated")
            NotificationCenter.default.post(name: .filterListsUpdated, object: nil)
        }
    }

    private func fetchCatalog(revalidating cachedSnapshot: FilterListsSnapshot?,
                              service: FilterListServiceProtocol) async -> (catalog: FilterListCatalogResponse, catalogETag: String?)? {
        let catalogResponse = await service.fetchFilterListCatalog(etag: cachedSnapshot?.catalogETag)
        let catalog: FilterListCatalogResponse
        let catalogETag: String?

        switch catalogResponse {
        case .modified(let downloadedCatalog, let downloadedETag):
            catalog = downloadedCatalog
            catalogETag = downloadedETag
        case .notModified:
            guard let cachedSnapshot = cachedSnapshot else {
                AppManager.logger.debug("performRefresh — catalog not modified but there is no readable cache, stopping")
                return nil
            }
            catalog = cachedSnapshot.catalog
            catalogETag = cachedSnapshot.catalogETag
        case nil:
            AppManager.logger.debug("performRefresh — catalog fetch failed, keeping the cache")
            return nil
        }

        return (catalog, catalogETag)
    }

    private func fetchLists(in catalog: FilterListCatalogResponse,
                            revalidating cachedSnapshot: FilterListsSnapshot?,
                            service: FilterListServiceProtocol) async -> (lists: [FilterListsCacheSection], hasFailedLists: Bool) {
        var revalidatedLists: [FilterListsCacheSection] = []
        var requestedURLs: Set<URL> = []
        var hasFailedLists = false

        for catalogEntry in catalog.lists {
            guard let listURL = catalogEntry.resolvedURL,
                  !requestedURLs.contains(listURL) else { continue }
            requestedURLs.insert(listURL)

            let cachedSection = cachedSnapshot?.lists.first(where: { $0.url == listURL.absoluteString })
            let listResponse = await service.fetchFilterList(at: listURL, etag: cachedSection?.etag)

            let listName = listURL.lastPathComponent
            let hasCachedSection = cachedSection != nil
            switch listResponse {
            case .modified(let downloadedList, let downloadedETag):
                let downloadedSection = FilterListsCacheSection(url: listURL.absoluteString, etag: downloadedETag, payload: downloadedList)
                revalidatedLists.append(downloadedSection)
                var revisionDescription = "none"
                if let revision = downloadedList.revision {
                    revisionDescription = "\(revision)"
                }
                AppManager.logger.debug("performRefresh — \(listName, privacy: .public): downloaded | revision: \(revisionDescription, privacy: .public), records: \(downloadedList.filters.count, privacy: .public)")
            case .notModified:
                if let cachedSection = cachedSection {
                    revalidatedLists.append(cachedSection)
                }
                AppManager.logger.debug("performRefresh — \(listName, privacy: .public): not modified | kept cached: \(hasCachedSection, privacy: .public)")
            case nil:
                hasFailedLists = true
                if let cachedSection = cachedSection {
                    revalidatedLists.append(cachedSection)
                }
                AppManager.logger.debug("performRefresh — \(listName, privacy: .public): failed | kept cached: \(hasCachedSection, privacy: .public)")
            }
        }

        return (revalidatedLists, hasFailedLists)
    }

    private static func hasNewFilters(from cachedSnapshot: FilterListsSnapshot?, to refreshedSnapshot: FilterListsSnapshot) -> Bool {
        let cachedLists = cachedSnapshot?.lists ?? []
        guard cachedLists.count == refreshedSnapshot.lists.count else { return true }

        for refreshedList in refreshedSnapshot.lists {
            guard let cachedList = cachedLists.first(where: { $0.url == refreshedList.url }) else { return true }

            if let refreshedRevision = refreshedList.payload.revision,
               let cachedRevision = cachedList.payload.revision {

                if refreshedRevision > cachedRevision {
                    return true
                }
            }
            else if refreshedList.payload.filters != cachedList.payload.filters {
                return true
            }
        }

        return false
    }
}
