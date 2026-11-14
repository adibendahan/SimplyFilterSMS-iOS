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
            guard entry.entryType == .aiFilteringLanguage, let langRawValue = entry.language else { continue }
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
        let automaticFiltersLanguage = persistenceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        Log.debug("language changed, language: \(language.rawValue), active: \(automaticFiltersLanguage.isActive) → \(value)")
        automaticFiltersLanguage.isActive = value
        _ = persistenceManager.commitAndAnnounce()
    }
    
    var communityLists: [CommunityListItem] {
        guard let persistenceManager = self.persistenceManager else { return [] }
        let snapshot = persistenceManager.cachedFilterLists()
        let communityListRecords = persistenceManager.fetchCommunityListRecords()
        let activeURLs = Self.activeURLs(in: communityListRecords)
        let curatedURLs = snapshot?.catalog.curatedCommunityListURLs ?? []
        let userURLs = communityListRecords.compactMap(\.url).filter { !curatedURLs.contains($0) }

        var communityLists: [CommunityListItem] = []
        for url in curatedURLs + userURLs.uniqued() {
            let communityList = CommunityListItem(url: url,
                                                  catalogEntry: snapshot?.catalog.curatedEntry(for: url),
                                                  cacheSection: snapshot?.cacheSection(for: url),
                                                  isActive: activeURLs.contains(url))
            communityLists.append(communityList)
        }
        return communityLists
    }

    var activeCommunityListsCount: Int {
        let communityListRecords = self.persistenceManager?.fetchCommunityListRecords() ?? []
        return Self.activeURLs(in: communityListRecords).count
    }

    func setCommunityListActive(_ communityList: CommunityListItem, value: Bool) {
        guard let persistenceManager = self.persistenceManager else { return }
        let communityListRecord = persistenceManager.ensuredCommunityListRecord(for: communityList.url)
        Log.debug("community list changed, url: \(communityList.url), active: \(communityListRecord.isActive) → \(value)")
        communityListRecord.isActive = value
        _ = persistenceManager.commitAndAnnounce()
    }

    func removeCommunityList(_ communityList: CommunityListItem) {
        guard let persistenceManager = self.persistenceManager else { return }
        Log.debug("community list removed, url: \(communityList.url), curated: \(communityList.isCurated)")
        persistenceManager.deleteCommunityListRecords(for: communityList.url)
        _ = persistenceManager.commitAndAnnounce()
    }

    func previewCommunityList(at url: URL) async -> Result<CommunityListItem, CommunityListPreviewError> {
        guard url.scheme?.lowercased() == "https", url.host != nil else {
            Log.debug("community list link isn't https, url: \(url.absoluteString) → refused")
            return .failure(.invalidLink)
        }
        let isListed = self.communityLists.contains(where: { $0.url == url.absoluteString })
        guard !isListed else {
            Log.debug("community list already listed, url: \(url.absoluteString) → refused")
            return .failure(.alreadySubscribed)
        }
        guard self.networkSyncManager?.networkStatus == .online else {
            Log.debug("offline, url: \(url.absoluteString) → refused")
            return .failure(.offline)
        }

        let listResponse = await self.filterListService?.fetchFilterList(at: url, etag: nil)
        guard case .modified(let downloadedList, let downloadedETag) = listResponse else {
            Log.debug("community list preview failed, url: \(url.absoluteString)")
            return .failure(.notAList)
        }
        guard Locale.listLocale(from: downloadedList.locale) != nil else {
            Log.debug("community list has no valid locale, url: \(url.absoluteString), locale: \(downloadedList.locale ?? "nil") → refused")
            return .failure(.invalidLocale)
        }
        Log.debug("community list previewed, url: \(url.absoluteString), records: \(downloadedList.filters.count)")
        let cacheSection = FilterListsCacheSection(url: url.absoluteString, etag: downloadedETag, payload: downloadedList)
        let communityList = CommunityListItem(url: url.absoluteString, catalogEntry: nil, cacheSection: cacheSection, isActive: false)
        return .success(communityList)
    }

    @MainActor
    func subscribeCommunityList(_ communityList: CommunityListItem) async -> Bool {
        if let refreshTask = self.refreshTask {
            Log.debug("refresh in progress → waiting, url: \(communityList.url)")
            await refreshTask.value
        }
        guard let persistenceManager = self.persistenceManager, let cacheSection = communityList.cacheSection else {
            Log.error("community list has no file, url: \(communityList.url)")
            return false
        }
        guard persistenceManager.saveCachedList(cacheSection) else {
            Log.error("community list not cached, url: \(communityList.url)")
            return false
        }
        self.setCommunityListActive(communityList, value: true)
        Log.debug("community list subscribed, url: \(communityList.url), records: \(cacheSection.payload.filters.count), etag: \(cacheSection.etag ?? "nil")")
        return true
    }

    func onFilterListsUpdateFinished(_ handler: @escaping () -> Void) {
        guard self.isFilterListsUpdateInProgress else {
            handler()
            return
        }
        self.updateFinishedHandlers.append(handler)
    }

    @MainActor
    func updateFilterListsWhenOnline() {
        guard !ProcessInfo.processInfo.isInTestingMode else {
            Log.debug("testing mode → skipped")
            return
        }
        guard !self.didCheckFilterListsToday else {
            Log.debug("already checked today, lastCheck: \(self.filterListsLastUpdated) → skipped")
            return
        }
        self.isFilterListsUpdateInProgress = true
        self.networkSyncManager?.onFirstStatusKnown { [weak self] in
            MainActor.assumeIsolated {
                guard let self else { return }
                guard self.networkSyncManager?.networkStatus == .online else {
                    Log.debug("offline → waiting to be back online")
                    self.finishFilterListsUpdate()
                    self.updateFilterListsOnNextOnline()
                    return
                }
                Task(priority: .background) { @MainActor in
                    await self.refreshFilterLists()
                    self.finishFilterListsUpdate()
                }
            }
        }
    }
    
    //MARK: - Private  -
    
    private weak var filterListService: FilterListServiceProtocol?
    private weak var persistenceManager: PersistenceManagerProtocol?
    private weak var networkSyncManager: NetworkSyncManagerProtocol?
    private var refreshTask: Task<Void, Never>?
    private var isFilterListsUpdateInProgress = false
    private var updateFinishedHandlers: [() -> Void] = []
    private var networkStatusTask: Task<Void, Never>?

    @MainActor
    private var didCheckFilterListsToday: Bool {
        guard let cachedCatalog = self.persistenceManager?.cachedFilterListCatalog() else { return false }
        guard cachedCatalog.version >= FilterListCatalogResponse.currentVersion else {
            Log.debug("cached catalog is older, version: \(cachedCatalog.version), current: \(FilterListCatalogResponse.currentVersion) → not checked")
            return false
        }
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
                Log.debug("back online → refreshing")
                self.updateFilterListsInBackground()
                return
            }
        }
    }

    @MainActor
    private func finishFilterListsUpdate() {
        guard self.isFilterListsUpdateInProgress else { return }
        self.isFilterListsUpdateInProgress = false
        let handlers = self.updateFinishedHandlers
        self.updateFinishedHandlers = []
        handlers.forEach { $0() }
    }

    @MainActor
    private func updateFilterListsInBackground() {
        Task(priority: .background) {
            await self.refreshFilterLists()
        }
    }
    
    @MainActor
    func refreshFilterLists() async {
        if let refreshTask = self.refreshTask {
            Log.debug("refresh in progress → joining")
            await refreshTask.value
            return
        }
        let cacheAgeDays = self.filterListsLastUpdated?.daysBetween(date: Date())
        Log.debug("refreshing, cacheAgeDays: \(cacheAgeDays)")
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
        let communityURLs = persistenceManager.fetchCommunityListRecords().compactMap(\.url)
        let (revalidatedLists, hasFailedLists) = await self.fetchLists(in: catalog,
                                                                       communityURLs: communityURLs,
                                                                       revalidating: cachedSnapshot,
                                                                       service: filterListService)

        let refreshedSnapshot = FilterListsSnapshot(catalogETag: catalogETag, catalog: catalog, lists: revalidatedLists)
        let hasSnapshotChanged = refreshedSnapshot != cachedSnapshot
        let hasNewFilters = Self.hasNewFilters(from: cachedSnapshot, to: refreshedSnapshot)
        Log.debug("refreshed, lists: \(revalidatedLists.count), changed: \(hasSnapshotChanged), newFilters: \(hasNewFilters), failures: \(hasFailedLists)")

        guard hasSnapshotChanged else {
            if !hasFailedLists {
                Log.debug("no changes → cache age touched")
                persistenceManager.touchCache()
            }
            else {
                Log.debug("no changes, some lists failed → cache age kept")
            }
            return
        }
        guard persistenceManager.saveCache(refreshedSnapshot) else {
            Log.error("saving the cache failed")
            return
        }
        if hasNewFilters {
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
            Log.debug("catalog downloaded, lists: \(downloadedCatalog.lists.count), sentETag: \(cachedSnapshot?.catalogETag), newETag: \(downloadedETag)")
            catalog = downloadedCatalog
            catalogETag = downloadedETag
        case .notModified:
            guard let cachedSnapshot = cachedSnapshot else {
                Log.debug("catalog not modified, cache unreadable → stopped")
                return nil
            }
            Log.debug("catalog not modified")
            catalog = cachedSnapshot.catalog
            catalogETag = cachedSnapshot.catalogETag
        case nil:
            Log.debug("catalog fetch failed → kept the cache")
            return nil
        }

        return (catalog, catalogETag)
    }

    private func fetchLists(in catalog: FilterListCatalogResponse,
                            communityURLs: [String],
                            revalidating cachedSnapshot: FilterListsSnapshot?,
                            service: FilterListServiceProtocol) async -> (lists: [FilterListsCacheSection], hasFailedLists: Bool) {
        var revalidatedLists: [FilterListsCacheSection] = []
        var listURLs: [URL] = []
        var hasFailedLists = false

        for catalogEntry in catalog.lists {
            guard let listURL = catalogEntry.resolvedURL else {
                Log.debug("catalog entry has no valid url, list: \(catalogEntry.id), url: \(catalogEntry.url) → skipped")
                continue
            }
            guard !listURLs.contains(listURL) else {
                Log.debug("catalog entry repeats a url, list: \(catalogEntry.id), url: \(listURL) → skipped")
                continue
            }
            listURLs.append(listURL)
        }
        for communityURL in communityURLs {
            guard let listURL = URL(string: communityURL), !listURLs.contains(listURL) else { continue }
            listURLs.append(listURL)
        }

        for listURL in listURLs {
            let cachedSection = cachedSnapshot?.lists.first(where: { $0.url == listURL.absoluteString })
            let listResponse = await service.fetchFilterList(at: listURL, etag: cachedSection?.etag)

            let listName = listURL.lastPathComponent
            let hasCachedSection = cachedSection != nil
            switch listResponse {
            case .modified(let downloadedList, let downloadedETag):
                let downloadedSection = FilterListsCacheSection(url: listURL.absoluteString, etag: downloadedETag, payload: downloadedList)
                revalidatedLists.append(downloadedSection)
                Log.debug("list downloaded, list: \(listName), revision: \(downloadedList.revision), records: \(downloadedList.filters.count), sentETag: \(cachedSection?.etag), newETag: \(downloadedETag)")
            case .notModified:
                if let cachedSection = cachedSection {
                    revalidatedLists.append(cachedSection)
                }
                Log.debug("list not modified, list: \(listName), cached: \(hasCachedSection)")
            case nil:
                hasFailedLists = true
                if let cachedSection = cachedSection {
                    revalidatedLists.append(cachedSection)
                }
                Log.debug("list fetch failed, list: \(listName), cached: \(hasCachedSection)")
            }
        }

        return (revalidatedLists, hasFailedLists)
    }

    private static func activeURLs(in communityListRecords: [CommunityList]) -> Set<String> {
        return Set(communityListRecords.filter(\.isActive).compactMap(\.url))
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
