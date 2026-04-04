//
//  PersistanceManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import CoreData
import NaturalLanguage
import UIKit

class PersistanceManager: PersistanceManagerProtocol {

    
    //MARK: - Initialization -
    required init(inMemory: Bool = false) {
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        self.container = container

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        else if let storeURL = self.container.persistentStoreDescriptions.first?.url?.deletingLastPathComponent(),
                !FileManager.default.directoryExistsAtPath(storeURL.path) {

            try? FileManager.default.createDirectory(at: storeURL,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                AppManager.logger.error("ERROR! While initializing PersistanceManager: \(error), \(error.userInfo)")
            }

            container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.stalenessInterval = 0
        })
    }


    //MARK: - Public API (PersistanceManagerProtocol) -
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
    
    func commitContext() {
        guard self.context.hasChanges else { return }
        
        do {
            try self.context.save()
        } catch {
            let nsError = error as NSError
            AppManager.logger.error("ERROR! While commiting context: \(nsError), \(nsError.userInfo)")
        }
    }
    
    func reloadContainer() {
        guard let storeURL = self.container.persistentStoreDescriptions.first?.url, storeURL != URL(fileURLWithPath: "/dev/null") else { return }
        AppManager.logger.debug("reloadContainer — reloading persistent store")
        if let loadedStore = self.container.persistentStoreCoordinator.persistentStore(for: storeURL) {
            self.commitContext()
            self.container.viewContext.reset()
            try? self.container.persistentStoreCoordinator.remove(loadedStore)
        }
        
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        self.container = container

        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                AppManager.logger.error("ERROR! While initializing PersistanceManager: \(error), \(error.userInfo)")
            }

            container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.stalenessInterval = 0
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
    
    func fetchAutomaticFiltersCacheRecords() -> [AutomaticFiltersCache] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        var automaticFiltersCacheRecords: [AutomaticFiltersCache] = []
        
        self.fetch(AutomaticFiltersCache.self, sortDescriptor: sortDescriptor)?.forEach {
            automaticFiltersCacheRecords.append($0)
        }
        
        return automaticFiltersCacheRecords
    }
    
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage? {
        let predicate = NSPredicate(format: "lang == %@", language.rawValue)
        guard let automaticFiltersLanguageRecord =
                self.fetch(AutomaticFiltersLanguage.self, predicate: predicate)?.first else { return nil }
        return automaticFiltersLanguageRecord
    }
    
    func fetchAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule? {
        let predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRuleRecord =
                self.fetch(AutomaticFiltersRule.self, predicate: predicate)?.first else { return nil }
        return automaticFiltersRuleRecord
    }
    
    func ensuredAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule {
        if let existing = self.fetchAutomaticFiltersRuleRecord(for: rule) {
            return existing
        }
        else {
            let newRule = AutomaticFiltersRule(context: self.context)
            newRule.ruleId = rule.rawValue
            newRule.ruleType = rule
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
                automaticFiltersLanguageRecords.forEach(self.context.delete)
            }
        }
        
        guard let ensuredAutomaticFiltersLanguage = ensuredAutomaticFiltersLanguage else {
            let newLanguage = AutomaticFiltersLanguage(context: self.context)
            newLanguage.lang = language.rawValue
            newLanguage.isActive = isActive
            self.commitContext()
            return newLanguage
        }
        
        return ensuredAutomaticFiltersLanguage
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
    
    func isDuplicateFilter(language: NLLanguage) -> Bool {
        let predicate = NSPredicate(format: "text == %@", language.filterText)
        guard let _ = self.fetch(Filter.self, predicate: predicate)?.first else { return false }
        return true
    }
    
    @discardableResult
    func addFilter(text: String, type: FilterType,
                   denyFolder: DenyFolderType = .junk,
                   filterTarget: FilterTarget = .all,
                   filterMatching: FilterMatching = .contains,
                   filterCase: FilterCase = .caseInsensitive) -> Filter? {

        guard !self.isDuplicateFilter(text: text,
                                      filterTarget: filterTarget,
                                      filterMatching: filterMatching,
                                      filterCase: filterCase) else {
            AppManager.logger.debug("addFilter — skipped duplicate: '\(text, privacy: .public)'")
            return nil
        }

        let newFilter = Filter(context: self.context)
        newFilter.uuid = UUID()
        newFilter.filterType = type
        newFilter.denyFolderType = denyFolder
        newFilter.filterMatching = filterMatching
        newFilter.filterTarget = filterTarget
        newFilter.filterCase = filterCase
        newFilter.text = text
        AppManager.logger.debug("addFilter — '\(text, privacy: .public)' | type: \(type.logDescription, privacy: .public) | folder: \(denyFolder.logDescription, privacy: .public) | target: \(filterTarget.logDescription, privacy: .public) | matching: \(filterMatching.logDescription, privacy: .public) | case: \(filterCase.logDescription, privacy: .public)")
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
        return newFilter
    }

    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        let toDelete = offsets.map({ filters[$0] })
        AppManager.logger.debug("deleteFilters — \(toDelete.count, privacy: .public) filter(s): \(toDelete.compactMap({ $0.text }).joined(separator: ", "), privacy: .public)")
        toDelete.forEach({ self.context.delete($0) })
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func deleteFilters(_ filters: Set<Filter>) {
        AppManager.logger.debug("deleteFilters — \(filters.count, privacy: .public) filter(s): \(filters.compactMap({ $0.text }).joined(separator: ", "), privacy: .public)")
        filters.forEach({ self.context.delete($0) })
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        AppManager.logger.debug("updateFilter — '\(filter.text ?? "", privacy: .public)' denyFolder → \(denyFolder.logDescription, privacy: .public)")
        filter.denyFolderType = denyFolder
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func updateFilter(_ filter: Filter, filterMatching: FilterMatching) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filterMatching,
                                      filterCase: filter.filterCase) else {
            AppManager.logger.debug("updateFilter — skipped duplicate: '\(filter.text ?? "", privacy: .public)' filterMatching → \(filterMatching.logDescription, privacy: .public)")
            return
        }
        AppManager.logger.debug("updateFilter — '\(filter.text ?? "", privacy: .public)' filterMatching → \(filterMatching.logDescription, privacy: .public)")
        filter.filterMatching = filterMatching
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func updateFilter(_ filter: Filter, filterCase: FilterCase) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filterCase) else {
            AppManager.logger.debug("updateFilter — skipped duplicate: '\(filter.text ?? "", privacy: .public)' filterCase → \(filterCase.logDescription, privacy: .public)")
            return
        }
        AppManager.logger.debug("updateFilter — '\(filter.text ?? "", privacy: .public)' filterCase → \(filterCase.logDescription, privacy: .public)")
        filter.filterCase = filterCase
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func updateFilter(_ filter: Filter, filterTarget: FilterTarget) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filter.filterCase) else {
            AppManager.logger.debug("updateFilter — skipped duplicate: '\(filter.text ?? "", privacy: .public)' filterTarget → \(filterTarget.logDescription, privacy: .public)")
            return
        }
        AppManager.logger.debug("updateFilter — '\(filter.text ?? "", privacy: .public)' filterTarget → \(filterTarget.logDescription, privacy: .public)")
        filter.filterTarget = filterTarget
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func updateFilter(_ filter: Filter, filterText: String) {
        guard !self.isDuplicateFilter(text: filterText,
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filter.filterCase) else {
            AppManager.logger.debug("updateFilter — skipped duplicate: '\(filter.text ?? "", privacy: .public)' text → '\(filterText, privacy: .public)'")
            return
        }
        AppManager.logger.debug("updateFilter — '\(filter.text ?? "", privacy: .public)' text → '\(filterText, privacy: .public)'")
        filter.text = filterText
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }
    
    func selectedCountries(for rule: RuleType) -> [String] {
        guard let record = self.fetchAutomaticFiltersRuleRecord(for: rule),
              let json = record.selectedCountries,
              let data = json.data(using: .utf8),
              let countries = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return countries
    }

    func setSelectedCountries(_ countries: [String], for rule: RuleType) {
        let record = self.ensuredAutomaticFiltersRuleRecord(for: rule)
        if let data = try? JSONEncoder().encode(countries),
           let json = String(data: data, encoding: .utf8) {
            record.selectedCountries = json
        }
        self.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func saveCache(with filterList: AutomaticFilterListsResponse) {
        AppManager.logger.debug("saveCache — saving new automatic filters cache")
        self.deleteExistingCaches()
        let newCache = AutomaticFiltersCache(context: self.context)
        newCache.uuid = UUID()
        newCache.hashed = filterList.hashed
        newCache.filtersData = filterList.encoded
        newCache.age = Date()
        self.commitContext()
    }

    func isCacheStale(comparedTo newFilterList: AutomaticFilterListsResponse) -> Bool {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        guard let automaticFiltersCache = self.fetch(AutomaticFiltersCache.self, sortDescriptor: sortDescriptor)?.first else {
            AppManager.logger.debug("isCacheStale — no existing cache, returning stale")
            return true
        }
        let isStale = automaticFiltersCache.filtersData != newFilterList.encoded
        AppManager.logger.debug("isCacheStale — \(isStale ? "stale" : "fresh", privacy: .public)")
        if !isStale {
            automaticFiltersCache.age = Date()
            self.commitContext()
        }
        return isStale
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
        commitContext()
    }

    func resetContainer() {
        // Get a reference to a NSPersistentStoreCoordinator
        let storeContainer = self.container.persistentStoreCoordinator
        

        // Delete each existing persistent store
        for store in storeContainer.persistentStores {
            try? storeContainer.destroyPersistentStore(
                at: store.url!,
                ofType: store.type,
                options: nil
            )
        }

        self.reloadContainer()
    }
    #endif // DEBUG
    
    //MARK: - Private -
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
            AppManager.logger.error("ERROR! While fetching \(entity): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func deleteExistingCaches() {
        let request: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        guard let caches = try? self.context.fetch(request) else { return }
        
        for cache in caches {
            self.context.delete(cache)
        }
    }
}
