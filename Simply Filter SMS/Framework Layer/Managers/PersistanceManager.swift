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
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                AppManager.logger.error("ERROR! While initializing PersistanceManager: \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
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
        fingerprint.append(self.fetchAutomaticFiltersRuleRecords().map({ "\($0.ruleId)\($0.isActive)" }).joined())
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
        
        if let loadedStore = self.container.persistentStoreCoordinator.persistentStore(for: storeURL) {
            self.commitContext()
            self.container.viewContext.reset()
            try? self.container.persistentStoreCoordinator.remove(loadedStore)
        }
        
        let container = AppPersistentCloudKitContainer(name: kAppWorkingDirectory)
        self.container = container

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                AppManager.logger.error("ERROR! While initializing PersistanceManager: \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
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
        let sortDescriptor = [NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
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
    
    func fetchChosenSubActions() -> [DenyFolderType] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \ChosenSubActions.actionId, ascending: true)]
        guard var chosenSubActionsIds =
                self.fetch(ChosenSubActions.self, sortDescriptor: sortDescriptor) else { return kDefaultSubActions }
        
        while chosenSubActionsIds.count > kMaximumFoldersSelected {
            if let folderToDelete = chosenSubActionsIds.popLast() {
                self.context.delete(folderToDelete)
            }
        }
        
        self.commitContext()
        var chosenSubActions = chosenSubActionsIds.map({ DenyFolderType(rawValue: $0.actionId) ?? .junk })
        chosenSubActions.removeAll(where: { !$0.isSubFolder })
        return chosenSubActions
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
    
    func addFilter(text: String, type: FilterType,
                   denyFolder: DenyFolderType = .junk,
                   filterTarget: FilterTarget = .all,
                   filterMatching: FilterMatching = .contains,
                   filterCase: FilterCase = .caseInsensitive) {
        
        guard !self.isDuplicateFilter(text: text,
                                      filterTarget: filterTarget,
                                      filterMatching: filterMatching,
                                      filterCase: filterCase) else { return }
        
        let newFilter = Filter(context: self.context)
        newFilter.uuid = UUID()
        newFilter.filterType = type
        newFilter.denyFolderType = denyFolder
        newFilter.filterMatching = filterMatching
        newFilter.filterTarget = filterTarget
        newFilter.filterCase = filterCase
        newFilter.text = text
        
        self.commitContext()
    }
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        offsets.map({ filters[$0] }).forEach({ self.context.delete($0) })
        self.commitContext()
    }
    
    func deleteFilters(_ filters: Set<Filter>) {
        filters.forEach({ self.context.delete($0) })
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        filter.denyFolderType = denyFolder
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, filterMatching: FilterMatching) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filterMatching,
                                      filterCase: filter.filterCase) else { return }
        
        filter.filterMatching = filterMatching
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, filterCase: FilterCase) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filterCase) else { return }
        
        filter.filterCase = filterCase
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, filterTarget: FilterTarget) {
        guard !self.isDuplicateFilter(text: filter.text ?? "",
                                      filterTarget: filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filter.filterCase) else { return }
        
        filter.filterTarget = filterTarget
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, filterText: String) {
        guard !self.isDuplicateFilter(text: filterText,
                                      filterTarget: filter.filterTarget,
                                      filterMatching: filter.filterMatching,
                                      filterCase: filter.filterCase) else { return }
        
        filter.text = filterText
        self.commitContext()
    }
    
    func updateChosenSubActions(_ chosenSubActions: [DenyFolderType]) {
        let request: NSFetchRequest<ChosenSubActions> = ChosenSubActions.fetchRequest()
        guard let oldSubActions = try? self.context.fetch(request) else { return }
        
        for oldSubAction in oldSubActions {
            self.context.delete(oldSubAction)
        }
        self.commitContext()
        
        let _ = chosenSubActions.map({
            let newSubAction = ChosenSubActions(context: self.context)
            newSubAction.actionId = $0.rawValue
        })
        self.commitContext()
        
        var denyFilters = self.fetchFilterRecords(for: .deny)
        denyFilters.append(contentsOf: self.fetchFilterRecords(for: .denyLanguage))
        
        for filter in denyFilters {
            if !chosenSubActions.contains(filter.denyFolderType) {
                filter.denyFolderType = filter.denyFolderType.parent ?? .junk
            }
        }
        self.commitContext()
    }
    
    func saveCache(with filterList: AutomaticFilterListsResponse) {
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
        guard let automaticFiltersCache = self.fetch(AutomaticFiltersCache.self, sortDescriptor: sortDescriptor)?.first else { return true }
        
        let isStale = automaticFiltersCache.filtersData != newFilterList.encoded
        
        if !isStale {
            automaticFiltersCache.age = Date()
            self.commitContext()
        }
        
        return isStale
    }
    
    #if DEBUG
    func loadDebugData() {
        
        let langCode = Bundle.main.preferredLocalizations[0]
        
        if langCode == "he" {
            self.addFilter(text: "Adi",
                           type: .allow,
                           filterTarget: .body,
                           filterMatching: .exact,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "bit",
                           type: .allow,
                           filterTarget: .sender,
                           filterMatching: .exact,
                           filterCase: .caseSensitive)
            
            self.addFilter(text: "עדי",
                           type: .allow,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            
            self.addFilter(text: "קנאביס",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .all,
                           filterMatching: .exact,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "גנץ",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "נתניהו",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: NLLanguage.arabic.filterText,
                           type: .denyLanguage,
                           denyFolder: .junk,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
        }
        else {
            self.addFilter(text: "Adi",
                           type: .allow,
                           filterTarget: .body,
                           filterMatching: .exact,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "Apple",
                           type: .allow,
                           filterTarget: .sender,
                           filterMatching: .exact,
                           filterCase: .caseSensitive)
            
            
            self.addFilter(text: "Bet",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .body,
                           filterMatching: .exact,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "Bitcoin",
                           type: .deny,
                           denyFolder: .transaction,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "Cash",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .all,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "Loan",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: "Mortgage",
                           type: .deny,
                           denyFolder: .junk,
                           filterTarget: .all,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
            
            self.addFilter(text: NLLanguage.arabic.filterText,
                           type: .denyLanguage,
                           denyFolder: .junk,
                           filterTarget: .body,
                           filterMatching: .contains,
                           filterCase: .caseInsensitive)
        }
    }

    func reset() {
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
    #endif
    
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
