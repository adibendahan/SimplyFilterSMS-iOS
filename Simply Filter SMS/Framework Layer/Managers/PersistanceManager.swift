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
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                AppManager.logger.error("ERROR! While initializing PersistanceManager: \(error), \(error.userInfo)")
            }
            
            container.viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
    }
    
    
    //MARK: - Public API (PersistanceManagerProtocol) -
    //MARK: Context
    var context: NSManagedObjectContext {
        return self.container.viewContext
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
    
    
    //MARK: Fetching
    func fetchFilterRecords() -> [Filter] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \Filter.type, ascending: false),
                              NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
        var filters: [Filter] = []
        
        self.fetch(Filter.self, sortDescriptor: sortDescriptor)?.forEach {
            guard let filter = $0 as? Filter else { return }
            filters.append(filter)
        }
        
        return filters
    }
    
    func fetchFilterRecords(for filterType: FilterType) -> [Filter] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
        let predicate = NSPredicate(format: "type == %ld", filterType.rawValue)
        var filters: [Filter] = []
        
        self.fetch(Filter.self, predicate: predicate, sortDescriptor: sortDescriptor)?.forEach {
            guard let filter = $0 as? Filter else { return }
            filters.append(filter)
        }
        
        return filters
    }
    
    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersLanguage.lang, ascending: true)]
        var automaticFiltersLanguageRecords: [AutomaticFiltersLanguage] = []
        
        self.fetch(AutomaticFiltersLanguage.self, sortDescriptor: sortDescriptor)?.forEach {
            guard let automaticFiltersLanguageRecord = $0 as? AutomaticFiltersLanguage else { return }
            automaticFiltersLanguageRecords.append(automaticFiltersLanguageRecord)
        }
        
        return automaticFiltersLanguageRecords
    }

    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersRule.ruleId, ascending: true)]
        var automaticFiltersRuleRecords: [AutomaticFiltersRule] = []
        
        self.fetch(AutomaticFiltersRule.self, sortDescriptor: sortDescriptor)?.forEach {
            guard let automaticFiltersRuleRecord = $0 as? AutomaticFiltersRule else { return }
            automaticFiltersRuleRecords.append(automaticFiltersRuleRecord)
        }
        
        return automaticFiltersRuleRecords
    }
    
    func fetchAutomaticFiltersCacheRecords() -> [AutomaticFiltersCache] {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        var automaticFiltersCacheRecords: [AutomaticFiltersCache] = []
        
        self.fetch(AutomaticFiltersCache.self, sortDescriptor: sortDescriptor)?.forEach {
            guard let automaticFiltersCacheRecord = $0 as? AutomaticFiltersCache else { return }
            automaticFiltersCacheRecords.append(automaticFiltersCacheRecord)
        }
        
        return automaticFiltersCacheRecords
    }
    
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage? {
        let predicate = NSPredicate(format: "lang == %@", language.rawValue)
        guard let automaticFiltersLanguageRecord =
                self.fetch(AutomaticFiltersLanguage.self, predicate: predicate)?.firstObject as? AutomaticFiltersLanguage else { return nil }
        return automaticFiltersLanguageRecord
    }
    
    func fetchAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule? {
        let predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRuleRecord =
                self.fetch(AutomaticFiltersRule.self, predicate: predicate)?.firstObject as? AutomaticFiltersRule else { return nil }
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
        if let existing = self.fetchAutomaticFiltersLanguageRecord(for: language) {
            return existing
        }
        else {
            let newLanguage = AutomaticFiltersLanguage(context: self.context)
            newLanguage.lang = language.rawValue
            newLanguage.isActive = false
            return newLanguage
        }
    }
    

    //MARK: Helpers
    func isDuplicateFilter(text: String,
                           filterTarget: FilterTarget = .all,
                           filterMatching: FilterMatching = .contains,
                           filterCase: FilterCase = .caseInsensitive) -> Bool {
        
        let predicate = NSPredicate(format: "text == %@ AND targetValue == %ld AND matchingValue == %ld AND caseValue == %ld",
                                    text, filterTarget.rawValue, filterMatching.rawValue, filterCase.rawValue)
        guard let _ = self.fetch(Filter.self, predicate: predicate)?.firstObject as? Filter else { return false }
        return true
    }
    
    func isDuplicateFilter(language: NLLanguage) -> Bool {
        let predicate = NSPredicate(format: "text == %@", language.filterText)
        guard let _ = self.fetch(Filter.self, predicate: predicate)?.firstObject as? Filter else { return false }
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
        filter.filterMatching = filterMatching
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, filterCase: FilterCase) {
        filter.filterCase = filterCase
        self.commitContext()
    }
    
    func updateFilter(_ filter: Filter, filterTarget: FilterTarget) {
        filter.filterTarget = filterTarget
        self.commitContext()
    }
    
    func saveCache(with filterList: AutomaticFilterList) {
        self.deleteExistingCaches()
        
        let newCache = AutomaticFiltersCache(context: self.context)
        newCache.uuid = UUID()
        newCache.hashed = filterList.hashed
        newCache.filtersData = filterList.encoded
        newCache.age = Date()
        
        self.commitContext()
    }
    
    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool {
        let sortDescriptor = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        guard let automaticFiltersCache = self.fetch(AutomaticFiltersCache.self, sortDescriptor: sortDescriptor)?.firstObject as? AutomaticFiltersCache else { return true }
        
        let isStale = automaticFiltersCache.hashed != newFilterList.hashed
        
        if !isStale {
            automaticFiltersCache.age = Date()
            self.commitContext()
        }
        
        return isStale
    }
    
    func loadDebugData() {
        self.addFilter(text: "נתניהו", type: .deny, denyFolder: .promotion, filterTarget: .body, filterMatching: .contains, filterCase: .caseInsensitive)
        self.addFilter(text: "הלוואה", type: .deny, denyFolder: .transaction, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.addFilter(text: "הימור", type: .deny, denyFolder: .transaction, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.addFilter(text: "גנץ", type: .deny, denyFolder: .transaction, filterTarget: .all, filterMatching: .contains, filterCase: .caseInsensitive)
        self.addFilter(text: "Weed", type: .deny, denyFolder: .transaction, filterTarget: .all, filterMatching: .exact, filterCase: .caseInsensitive)
        self.addFilter(text: "Bet", type: .deny, denyFolder: .transaction, filterTarget: .all, filterMatching: .exact, filterCase: .caseInsensitive)
        self.addFilter(text: "Adi", type: .allow, denyFolder: .junk, filterTarget: .body, filterMatching: .exact, filterCase: .caseInsensitive)
        self.addFilter(text: "עדי", type: .allow, denyFolder: .junk, filterTarget: .body, filterMatching: .exact, filterCase: .caseInsensitive)
        self.addFilter(text: "דהן", type: .allow, denyFolder: .junk, filterTarget: .body, filterMatching: .exact, filterCase: .caseInsensitive)
        self.addFilter(text: "דהאן", type: .allow, denyFolder: .junk, filterTarget: .body, filterMatching: .exact, filterCase: .caseInsensitive)
        self.addFilter(text: NLLanguage.arabic.filterText, type: .denyLanguage, denyFolder: .junk, filterTarget: .body, filterMatching: .contains, filterCase: .caseInsensitive)
    }
    
    //MARK: - Private -
    private let container: NSPersistentCloudKitContainer
    
    private func fetch<T: NSManagedObject>(_ entity: T.Type,
                                           predicate: NSPredicate? = nil,
                                           sortDescriptor: [NSSortDescriptor]? = nil) -> NSMutableArray? {

        let fetchRequest = NSFetchRequest<T>(entityName: NSStringFromClass(T.self))
        if let predicate = predicate { fetchRequest.predicate = predicate }
        if let sortDescriptor = sortDescriptor { fetchRequest.sortDescriptors = sortDescriptor }
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let searchResult = try self.context.fetch(fetchRequest)
            
            if searchResult.count > 0 {
                return NSMutableArray(array: searchResult)
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
