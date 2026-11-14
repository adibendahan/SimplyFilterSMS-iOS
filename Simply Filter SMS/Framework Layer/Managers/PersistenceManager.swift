//
//  PersistenceManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import CoreData
import NaturalLanguage
import UIKit

class PersistenceManager: PersistenceManagerProtocol {


    //MARK: - Initialization -
    required init(inMemory: Bool = false) {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        self.container = container

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions.first!.cloudKitContainerOptions = nil
        }
        else if let storeURL = self.container.persistentStoreDescriptions.first?.url?.deletingLastPathComponent(),
                !FileManager.default.directoryExistsAtPath(storeURL.path) {

            do {
                try FileManager.default.createDirectory(at: storeURL,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                Log.error("could not create the store directory, path: \(storeURL.path)", error: error)
            }
        }

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error {
                Log.error("store load failed, path: \(storeDescription.url?.path)", error: error)
            }
            else {
                Log.debug("store loaded, path: \(storeDescription.url?.path)")
            }

            container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.stalenessInterval = 0
        })
    }


    //MARK: - Public API (PersistenceManagerProtocol) -
    //MARK: Context
    private(set) var container: NSPersistentCloudKitContainer

    var context: NSManagedObjectContext {
        return self.container.viewContext
    }

    var fingerprint: String {
        var fingerprint = ""
        fingerprint.append(self.fetchFilterRecords().map({ "\($0.uuid?.uuidString ?? "")" }).joined())
        fingerprint.append(self.fetchAutomaticFiltersRuleRecords().map({ "\($0.ruleId)\($0.isActive)\($0.selectedCountries ?? "")" }).joined())
        fingerprint.append(self.fetchAutomaticFiltersLanguageRecords().map({ "\($0.lang ?? "")\($0.isActive)" }).joined())
        return fingerprint
    }

    func commitContext() -> Bool {
        guard self.context.hasChanges else {
            Log.debug("no changes → skipped")
            return true
        }

        let inserted = self.context.insertedObjects.count
        let updated = self.context.updatedObjects.count
        let deleted = self.context.deletedObjects.count

        do {
            try self.context.save()
            Log.debug("saved, inserted: \(inserted), updated: \(updated), deleted: \(deleted)")
            return true
        } catch {
            Log.error("save failed, inserted: \(inserted), updated: \(updated), deleted: \(deleted) → rolled back", error: error)
            self.context.rollback()
            return false
        }
    }

    func commitAndAnnounce() -> Bool {
        let saved = self.commitContext()
        NotificationCenter.default.post(name: saved ? .filtersStateChanged : .filtersSaveFailed, object: nil)
        return saved
    }

    func reloadContainer() {
        guard let storeURL = self.container.persistentStoreDescriptions.first?.url else {
            Log.debug("no store url → skipped")
            return
        }
        guard storeURL != URL(fileURLWithPath: "/dev/null") else {
            Log.debug("in-memory store → skipped")
            return
        }

        Log.debug("reloading, path: \(storeURL.path)")
        if let loadedStore = self.container.persistentStoreCoordinator.persistentStore(for: storeURL) {
            _ = self.commitContext()
            self.container.viewContext.reset()

            do {
                try self.container.persistentStoreCoordinator.remove(loadedStore)
            } catch {
                Log.error("could not remove the loaded store", error: error)
            }
        }

        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        self.container = container

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error {
                Log.error("store load failed, path: \(storeDescription.url?.path)", error: error)
            }
            else {
                Log.debug("store loaded, path: \(storeDescription.url?.path)")
            }

            container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.stalenessInterval = 0

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .persistentStoreReloaded, object: nil)
            }
        })
    }

    //MARK: Fetching
    func fetchFilterRecords() -> [Filter] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \Filter.type, ascending: false),
                              NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
        var filters: [Filter] = []

        self.fetch(Filter.self, sortDescriptor: sortDescriptor)?.forEach {
            filters.append($0)
        }

        return filters
    }

    func fetchFilterRecords(for filterType: FilterType) -> [Filter] {
        let sortDescriptor = [NSSortDescriptor(key: "text", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))]
        let predicate = NSPredicate(format: "type == %ld", filterType.rawValue)
        var filters: [Filter] = []

        self.fetch(Filter.self, predicate: predicate, sortDescriptor: sortDescriptor)?.forEach {
            filters.append($0)
        }

        return filters
    }

    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersLanguage.lang, ascending: true)]
        var automaticFiltersLanguageRecords: [AutomaticFiltersLanguage] = []

        self.fetch(AutomaticFiltersLanguage.self, sortDescriptor: sortDescriptor)?.forEach {
            automaticFiltersLanguageRecords.append($0)
        }

        return automaticFiltersLanguageRecords
    }

    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersRule.ruleId, ascending: true)]
        var automaticFiltersRuleRecords: [AutomaticFiltersRule] = []

        self.fetch(AutomaticFiltersRule.self, sortDescriptor: sortDescriptor)?.forEach {
            automaticFiltersRuleRecords.append($0)
        }

        return automaticFiltersRuleRecords
    }

    func fetchFilterListsCacheRecords() -> [FilterListsCache] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \FilterListsCache.age, ascending: false)]
        var filterListsCacheRecords: [FilterListsCache] = []

        self.fetch(FilterListsCache.self, sortDescriptor: sortDescriptor)?.forEach {
            filterListsCacheRecords.append($0)
        }

        return filterListsCacheRecords
    }

    func fetchCommunityListRecords() -> [CommunityList] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \CommunityList.url, ascending: true)]
        var communityListRecords: [CommunityList] = []

        self.fetch(CommunityList.self, sortDescriptor: sortDescriptor)?.forEach {
            communityListRecords.append($0)
        }

        return communityListRecords
    }

    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage? {
        let predicate = NSPredicate(format: "lang == %@", language.rawValue)
        guard let automaticFiltersLanguageRecord =
                self.fetch(AutomaticFiltersLanguage.self, predicate: predicate)?.first else { return nil }
        return automaticFiltersLanguageRecord
    }

    func fetchAutomaticFiltersRuleRecord(for rule: SmartFilterType) -> AutomaticFiltersRule? {
        let predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRuleRecord =
                self.fetch(AutomaticFiltersRule.self, predicate: predicate)?.first else { return nil }
        return automaticFiltersRuleRecord
    }

    func ensuredAutomaticFiltersRuleRecord(for rule: SmartFilterType) -> AutomaticFiltersRule {
        if let existing = self.fetchAutomaticFiltersRuleRecord(for: rule) {
            return existing
        }
        else {
            Log.debug("no record, rule: \(rule) → created")
            let newRule = AutomaticFiltersRule(context: self.context)
            newRule.ruleId = rule.rawValue
            newRule.smartFilterType = rule
            newRule.isActive = false
            return newRule
        }
    }

    func ensuredAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage {
        let predicate = NSPredicate(format: "lang == %@", language.rawValue)
        var isActive = false
        var ensuredAutomaticFiltersLanguage: AutomaticFiltersLanguage? = nil

        if let automaticFiltersLanguageRecords = self.fetch(AutomaticFiltersLanguage.self, predicate: predicate),
            !automaticFiltersLanguageRecords.isEmpty {

            if automaticFiltersLanguageRecords.count == 1, let automaticFiltersLanguageRecord = automaticFiltersLanguageRecords.first {
                ensuredAutomaticFiltersLanguage = automaticFiltersLanguageRecord
            }
            else {
                let activeAutomaticFiltersLanguageRecords = self.fetch(AutomaticFiltersLanguage.self,
                                                                       predicate: NSPredicate(format: "lang == %@ AND isActive == %@",
                                                                                              language.rawValue,
                                                                                              NSNumber(booleanLiteral: true)))
                isActive = (activeAutomaticFiltersLanguageRecords ?? []).count > 0
                Log.debug("duplicate records, language: \(language.rawValue), count: \(automaticFiltersLanguageRecords.count), isActive: \(isActive) → deleted")
                automaticFiltersLanguageRecords.forEach(self.context.delete)
            }
        }

        guard let ensuredAutomaticFiltersLanguage = ensuredAutomaticFiltersLanguage else {
            Log.debug("no record, language: \(language.rawValue), isActive: \(isActive) → created")
            let newLanguage = AutomaticFiltersLanguage(context: self.context)
            newLanguage.lang = language.rawValue
            newLanguage.isActive = isActive
            return newLanguage
        }

        return ensuredAutomaticFiltersLanguage
    }

    func ensuredCommunityListRecord(for url: String) -> CommunityList {
        let predicate = NSPredicate(format: "url == %@", url)
        let communityListRecords = self.fetch(CommunityList.self, predicate: predicate) ?? []

        guard let firstRecord = communityListRecords.first else {
            Log.debug("no record, url: \(url) → created")
            let newRecord = CommunityList(context: self.context)
            newRecord.url = url
            newRecord.isActive = false
            return newRecord
        }

        let duplicateRecords = communityListRecords.dropFirst()
        guard !duplicateRecords.isEmpty else { return firstRecord }

        let isActive = communityListRecords.contains(where: \.isActive)
        Log.debug("duplicate records, url: \(url), count: \(communityListRecords.count), isActive: \(isActive) → merged")
        duplicateRecords.forEach(self.context.delete)
        firstRecord.isActive = isActive
        return firstRecord
    }

    func deleteCommunityListRecords(for url: String) {
        let predicate = NSPredicate(format: "url == %@", url)
        let communityListRecords = self.fetch(CommunityList.self, predicate: predicate) ?? []
        Log.debug("deleting, url: \(url), records: \(communityListRecords.count)")
        communityListRecords.forEach(self.context.delete)
    }


    //MARK: Helpers
    func isDuplicateFilter(text: String,
                           filterTarget: FilterTarget = .all,
                           filterMatching: FilterMatching = .contains,
                           filterCase: FilterCase = .caseInsensitive) -> Bool {

        let predicate = NSPredicate(format: "text == %@ AND targetValue == %ld AND matchingValue == %ld AND caseValue == %ld",
                                    text, filterTarget.rawValue, filterMatching.rawValue, filterCase.rawValue)
        guard let _ = self.fetch(Filter.self, predicate: predicate)?.first else { return false }
        return true
    }

    func blockableLanguages() -> [NLLanguage] {
        return NLLanguage.allSupportedCases
            .filter({ !self.isDuplicateFilter(language: $0) })
            .sorted(by: NLLanguage.displayOrder)
    }

    func isDuplicateFilter(language: NLLanguage) -> Bool {
        let predicate = NSPredicate(format: "text == %@", language.filterText)
        guard let _ = self.fetch(Filter.self, predicate: predicate)?.first else { return false }
        return true
    }

    @discardableResult
    func addFilter(text: String, type: FilterType,
                   denyFolder: MessageFolder = .junk,
                   filterTarget: FilterTarget = .all,
                   filterMatching: FilterMatching = .contains,
                   filterCase: FilterCase = .caseInsensitive) -> Filter? {

        guard !self.isDuplicateFilter(text: text,
                                      filterTarget: filterTarget,
                                      filterMatching: filterMatching,
                                      filterCase: filterCase) else {
            Log.debug("duplicate, text: \(text), target: \(filterTarget), matching: \(filterMatching), case: \(filterCase) → skipped")
            return nil
        }

        let newFilter = Filter(context: self.context)
        newFilter.uuid = UUID()
        newFilter.filterType = type
        newFilter.messageFolder = denyFolder
        newFilter.filterMatching = filterMatching
        newFilter.filterTarget = filterTarget
        newFilter.filterCase = filterCase
        newFilter.text = text
        if type == .allow {
            Log.debug("adding, text: \(text), type: \(type), target: \(filterTarget), matching: \(filterMatching), case: \(filterCase)")
        }
        else {
            Log.debug("adding, text: \(text), type: \(type), folder: \(denyFolder), target: \(filterTarget), matching: \(filterMatching), case: \(filterCase)")
        }
        guard self.commitAndAnnounce() else { return nil }
        return newFilter
    }

    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        let toDelete = offsets.map({ filters[$0] })
        let deletedTexts = toDelete.map({ $0.text ?? "nil" })
        Log.debug("deleting, count: \(toDelete.count), texts: \(deletedTexts)")
        toDelete.forEach({ self.context.delete($0) })
        guard self.commitAndAnnounce() else { return }
    }

    func deleteFilters(_ filters: Set<Filter>) {
        let deletedTexts = filters.map({ $0.text ?? "nil" })
        Log.debug("deleting, count: \(filters.count), texts: \(deletedTexts)")
        filters.forEach({ self.context.delete($0) })
        guard self.commitAndAnnounce() else { return }
    }

    func updateFilter(_ filter: Filter, denyFolder: MessageFolder) {
        Log.debug("folder changed, text: \(filter.text), folder: \(filter.messageFolder) → \(denyFolder)")
        filter.messageFolder = denyFolder
        guard self.commitAndAnnounce() else { return }
    }

    func updateFilter(_ filter: Filter, filterMatching: FilterMatching) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filterMatching,
                                      filterCase: filter.filterCase) else {
            Log.debug("duplicate, text: \(filter.text), matching: \(filterMatching) → skipped")
            return
        }
        Log.debug("matching changed, text: \(filter.text), matching: \(filter.filterMatching) → \(filterMatching)")
        filter.filterMatching = filterMatching
        guard self.commitAndAnnounce() else { return }
    }

    func updateFilter(_ filter: Filter, filterCase: FilterCase) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filterCase) else {
            Log.debug("duplicate, text: \(filter.text), case: \(filterCase) → skipped")
            return
        }
        Log.debug("case changed, text: \(filter.text), case: \(filter.filterCase) → \(filterCase)")
        filter.filterCase = filterCase
        guard self.commitAndAnnounce() else { return }
    }

    func updateFilter(_ filter: Filter, filterTarget: FilterTarget) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filter.filterCase) else {
            Log.debug("duplicate, text: \(filter.text), target: \(filterTarget) → skipped")
            return
        }
        Log.debug("target changed, text: \(filter.text), target: \(filter.filterTarget) → \(filterTarget)")
        filter.filterTarget = filterTarget
        guard self.commitAndAnnounce() else { return }
    }

    func updateFilter(_ filter: Filter, filterText: String) {
        guard !self.isDuplicateFilter(text: filterText,
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filter.filterCase) else {
            Log.debug("duplicate, text: \(filterText) → skipped")
            return
        }
        Log.debug("text changed, text: \(filter.text) → \(filterText)")
        filter.text = filterText
        guard self.commitAndAnnounce() else { return }
    }

    func selectedCountries(for rule: SmartFilterType) -> [String] {
        guard let json = self.fetchAutomaticFiltersRuleRecord(for: rule)?.selectedCountries else { return [] }

        do {
            return try JSONDecoder().decode([String].self, from: Data(json.utf8))
        } catch {
            Log.error("countries don't decode, rule: \(rule), json: \(json)", error: error)
            return []
        }
    }

    func setSelectedCountries(_ countries: [String], for rule: SmartFilterType) {
        let record = self.ensuredAutomaticFiltersRuleRecord(for: rule)

        do {
            let data = try JSONEncoder().encode(countries)
            record.selectedCountries = String(decoding: data, as: UTF8.self)
        } catch {
            Log.error("countries don't encode, rule: \(rule), countries: \(countries)", error: error)
        }

        guard self.commitAndAnnounce() else { return }
    }

    func cachedFilterLists() -> FilterListsSnapshot? {
        let cacheRecords = self.fetchFilterListsCacheRecords()
        guard let encodedSnapshot = cacheRecords.first?.data else {
            Log.debug("no cache row, rows: \(cacheRecords.count) → reading the 3.2 cache")
            return self.legacyFilterLists()
        }
        if let decodedCache = self.decodedCache, decodedCache.encodedSnapshot == encodedSnapshot {
            return decodedCache.snapshot
        }
        guard let snapshot = FilterListsSnapshot(encoded: encodedSnapshot) else {
            Log.debug("cache row doesn't decode, rows: \(cacheRecords.count), bytes: \(encodedSnapshot.utf8.count)")
            return nil
        }
        Log.debug("cache read, rows: \(cacheRecords.count), lists: \(snapshot.lists.count), bytes: \(encodedSnapshot.utf8.count)")
        self.decodedCache = (encodedSnapshot: encodedSnapshot, snapshot: snapshot)
        return snapshot
    }

    func cachedFilterListCatalog() -> FilterListCatalogResponse? {
        guard let encodedSnapshot = self.fetchFilterListsCacheRecords().first?.data else {
            return self.legacyFilterLists()?.catalog
        }
        return FilterListCatalogResponse(encodedCache: encodedSnapshot)
    }

    func saveCache(_ snapshot: FilterListsSnapshot) -> Bool {
        guard let encodedSnapshot = snapshot.encoded else {
            Log.error("snapshot doesn't encode, lists: \(snapshot.lists.count)")
            return false
        }

        let cacheRecords = self.fetchFilterListsCacheRecords()
        let duplicateRecords = cacheRecords.dropFirst()
        Log.debug("saving the cache, lists: \(snapshot.lists.count), bytes: \(encodedSnapshot.utf8.count), duplicateRowsDeleted: \(duplicateRecords.count)")
        for duplicateRecord in duplicateRecords {
            self.context.delete(duplicateRecord)
        }

        let cacheRecord: FilterListsCache
        if let existingRecord = cacheRecords.first {
            cacheRecord = existingRecord
        }
        else {
            cacheRecord = FilterListsCache(context: self.context)
        }
        if cacheRecord.uuid == nil {
            cacheRecord.uuid = UUID()
        }
        cacheRecord.data = encodedSnapshot
        cacheRecord.age = Date()
        return self.commitContext()
    }

    func saveCachedList(_ cacheSection: FilterListsCacheSection) -> Bool {
        guard let cacheRecord = self.fetchFilterListsCacheRecords().first,
              let cachedSnapshot = self.cachedFilterLists() else {
            Log.debug("no cache row → skipped, url: \(cacheSection.url)")
            return false
        }
        let otherSections = cachedSnapshot.lists.filter { $0.url != cacheSection.url }
        let snapshot = FilterListsSnapshot(catalogETag: cachedSnapshot.catalogETag,
                                           catalog: cachedSnapshot.catalog,
                                           lists: otherSections + [cacheSection])
        guard let encodedSnapshot = snapshot.encoded else {
            Log.error("snapshot doesn't encode, lists: \(snapshot.lists.count)")
            return false
        }
        Log.debug("saving a cached list, url: \(cacheSection.url), lists: \(snapshot.lists.count), bytes: \(encodedSnapshot.utf8.count)")
        cacheRecord.data = encodedSnapshot
        return self.commitContext()
    }

    func touchCache() {
        guard let cacheRecord = self.fetchFilterListsCacheRecords().first else {
            Log.debug("no cache row → skipped")
            return
        }
        let oldAge = cacheRecord.age
        cacheRecord.age = Date()
        Log.debug("cache age reset, age: \(oldAge) → \(cacheRecord.age)")
        _ = self.commitContext()
    }

    #if DEBUG
    func clearAllUserData() {
        for filter in fetchFilterRecords() {
            self.context.delete(filter)
        }
        for language in fetchAutomaticFiltersLanguageRecords() {
            self.context.delete(language)
        }
        for rule in fetchAutomaticFiltersRuleRecords() {
            self.context.delete(rule)
        }
        for communityList in fetchCommunityListRecords() {
            self.context.delete(communityList)
        }
        _ = commitContext()
    }

    func resetContainer() {
        // Get a reference to a NSPersistentStoreCoordinator
        let storeContainer = self.container.persistentStoreCoordinator


        // Delete each existing persistent store
        for store in storeContainer.persistentStores {
            do {
                try storeContainer.destroyPersistentStore(
                    at: store.url!,
                    ofType: store.type,
                    options: nil
                )
            } catch {
                Log.error("could not destroy the store, path: \(store.url?.path)", error: error)
            }
        }

        self.reloadContainer()
    }
    #endif // DEBUG

    //MARK: - Private -
    private var decodedCache: (encodedSnapshot: String, snapshot: FilterListsSnapshot)?

    private func legacyFilterLists() -> FilterListsSnapshot? {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        guard let legacyData = self.fetch(AutomaticFiltersCache.self, sortDescriptor: sortDescriptor)?.first?.filtersData else { return nil }
        return FilterListsSnapshot(legacyEncoded: legacyData)
    }

    private func fetch<T: NSManagedObject>(_ entity: T.Type,
                                           predicate: NSPredicate? = nil,
                                           sortDescriptor: [NSSortDescriptor]? = nil) -> [T]? {

        let fetchRequest = NSFetchRequest<T>(entityName: NSStringFromClass(T.self))
        if let predicate = predicate { fetchRequest.predicate = predicate }
        if let sortDescriptor = sortDescriptor { fetchRequest.sortDescriptors = sortDescriptor }
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let searchResult = try self.context.fetch(fetchRequest)

            if searchResult.count > 0 {
                return searchResult
            } else {
                return nil
            }

        } catch {
            Log.error("fetch failed, entity: \(fetchRequest.entityName)", error: error)
            return nil
        }
    }
}
