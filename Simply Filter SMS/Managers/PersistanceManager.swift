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
                fatalError("Unresolved error \(error), \(error.userInfo)")
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
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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
    

    //MARK: Helpers
    func initAutomaticFiltering(languages: [NLLanguage], rules: [RuleType]) {
        self.initAutomaticFiltersLanguage(languages: languages)
        self.initAutomaticFiltersRule(rules: rules)
        
        self.commitContext()
    }
    
    func isDuplicateFilter(text: String) -> Bool {
        let predicate = NSPredicate(format: "text == %@", text)
        guard let _ = self.fetch(Filter.self, predicate: predicate)?.firstObject as? Filter else { return false }
        return true
    }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType = .junk) {
        guard !self.isDuplicateFilter(text: text) else { return }
        
        let newFilter = Filter(context: self.context)
        newFilter.uuid = UUID()
        newFilter.filterType = type
        newFilter.denyFolderType = denyFolder
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
        struct AllowEntry {
            let text: String
            let folder: DenyFolderType
        }
        
        let _ = [AllowEntry(text: "נתניהו", folder: .junk),
                 AllowEntry(text: "הלוואה", folder: .junk),
                 AllowEntry(text: "הימור", folder: .junk),
                 AllowEntry(text: "גנץ", folder: .junk),
                 AllowEntry(text: "Weed", folder: .junk),
                 AllowEntry(text: "Bet", folder: .junk)].map { entry -> Filter in
            let newFilter = Filter(context: self.context)
            newFilter.uuid = UUID()
            newFilter.filterType = .deny
            newFilter.denyFolderType = entry.folder
            newFilter.text = entry.text
            return newFilter
        }
        
        let _ = ["Adi", "דהאן", "דהן", "עדי"].map { allowText -> Filter in
            let newFilter = Filter(context: self.context)
            newFilter.uuid = UUID()
            newFilter.filterType = .allow
            newFilter.text = allowText
            return newFilter
        }
        
        let langFilter = Filter(context: self.context)
        langFilter.uuid = UUID()
        langFilter.filterType = .denyLanguage
        langFilter.text = NLLanguage.arabic.filterText
        
        self.commitContext()
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
            print("ERROR! While fetching \(entity): \(error.localizedDescription)")
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
    
    private func initAutomaticFiltersLanguage(languages: [NLLanguage]) {
        let automaticFiltersLanguageRecords = self.fetchAutomaticFiltersLanguageRecords()
        var uninitializedLanguages: [NLLanguage] = languages

        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords {
            if let langRawValue = automaticFiltersLanguageRecord.lang {
                let lang = NLLanguage(langRawValue)
                
                if !uninitializedLanguages.contains(lang) {
                    self.context.delete(automaticFiltersLanguageRecord)
                }
                else {
                    uninitializedLanguages.removeAll(where: { $0 == lang })
                }
            }
        }
        
        for uninitializedLanguage in uninitializedLanguages {
            let newLang = AutomaticFiltersLanguage(context: self.context)
            newLang.lang = uninitializedLanguage.rawValue
            newLang.isActive = false
        }
    }
    
    private func initAutomaticFiltersRule(rules: [RuleType]) {
        let automaticFiltersRuleRecords = self.fetchAutomaticFiltersRuleRecords()
        var uninitializedRules: [RuleType] = rules

        for automaticFiltersRuleRecord in automaticFiltersRuleRecords {
            if let rule = automaticFiltersRuleRecord.ruleType {

                if !uninitializedRules.contains(rule) {
                    self.context.delete(automaticFiltersRuleRecord)
                }
                else {
                    uninitializedRules.removeAll(where: { $0 == rule })
                }
            }
            else {
                self.context.delete(automaticFiltersRuleRecord)
            }
        }
        
        for uninitializedRule in uninitializedRules {
            let newRule = AutomaticFiltersRule(context: self.context)
            newRule.ruleId = uninitializedRule.rawValue
            newRule.selectedChoice = uninitializedRule == .shortSender ? 6 : 0
            newRule.isActive = false
        }
    }
    
}
