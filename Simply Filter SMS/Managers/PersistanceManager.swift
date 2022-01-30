//
//  PersistanceManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import CoreData
import NaturalLanguage

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
    
    
    //MARK: - Private Members and Helpers -
    private let container: NSPersistentCloudKitContainer
    
    private func saveContext() {
        guard self.context.hasChanges else { return }
        do {
            try self.context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func deleteExistingCaches() {
        let request: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        guard let caches = try? self.context.fetch(request) else { return }
        
        for cache in caches {
            self.context.delete(cache)
        }
    }
    
    private func initAutomaticFilteringLanguages() {
        let request: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        guard let automaticFiltersLanguages = try? self.context.fetch(request) else { return }
        var uninitializedLanguages: [NLLanguage] = self.languages(for: .automaticBlocking)

        for automaticFiltersLanguage in automaticFiltersLanguages {
            if let langRawValue = automaticFiltersLanguage.lang {
                let lang = NLLanguage(langRawValue)
                
                if !uninitializedLanguages.contains(lang) {
                    self.context.delete(automaticFiltersLanguage)
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
    
    private func initAutomaticFilteringRules() {
        let request: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        guard let automaticFiltersRules = try? self.context.fetch(request) else { return }
        var uninitializedRules: [RuleType] = RuleType.allCases

        for automaticFiltersRule in automaticFiltersRules {
            if let rule = automaticFiltersRule.ruleType {

                if !uninitializedRules.contains(rule) {
                    self.context.delete(automaticFiltersRule)
                }
                else {
                    uninitializedRules.removeAll(where: { $0 == rule })
                }
            }
        }
        
        for uninitializedRule in uninitializedRules {
            let newRule = AutomaticFiltersRule(context: self.context)
            newRule.ruleId = uninitializedRule.rawValue
            newRule.selectedChoice = uninitializedRule == .shortSender ? 6 : 0
            newRule.isActive = false
        }
    }
    
    //MARK: - Public API -
    var context: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    #warning("Adi - Should move to automaticFilterManager")
    var isAutomaticFilteringOn: Bool {
        var isAutomaticFilteringOn = false
        
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        
        if let automaticFiltersLanguages = try? self.context.fetch(languageRequest) {
            let supportedLanguages: [NLLanguage] = self.languages(for: .automaticBlocking)
            
            
            for automaticFilterLanguage in automaticFiltersLanguages {
                if let langRawValue = automaticFilterLanguage.lang {
                    let lang = NLLanguage(rawValue: langRawValue)
                    
                    if supportedLanguages.contains(lang) && automaticFilterLanguage.isActive == true {
                        isAutomaticFilteringOn = true
                        break
                    }
                }
            }
        }
        
        #warning("Adi - Missing tests")
        if !isAutomaticFilteringOn {
            let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
            
            if let automaticFiltersRules = try? self.context.fetch(ruleRequest) {
                for automaticFiltersRule in automaticFiltersRules {
                    if let _ = automaticFiltersRule.ruleType {
                        
                        if automaticFiltersRule.isActive == true {
                            isAutomaticFilteringOn = true
                            break
                        }
                    }
                }
            }
        }
        
        return isAutomaticFilteringOn
    }
    
    #warning("Adi - Should move to automaticFilterManager")
    var automaticFiltersCacheAge: Date? {
        let request: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        guard let cache = try? self.context.fetch(request).first else { return nil }
        
        return cache.age
    }

    #warning("Adi - Should move to automaticFilterManager")
    var activeAutomaticLanguages: String? {
        guard self.automaticRuleState(for: .allUnknown) == false else { return RuleType.allUnknown.shortTitle }
        
        var activeLanguagesString = ""
        var automaticFilterNames: [String] = []
        
        let languageRequest: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        languageRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AutomaticFiltersLanguage.lang, ascending: true)]
        if let automaticFiltersLanguages = try? self.context.fetch(languageRequest) {
            
            let supportedLanguages = self.languages(for: .automaticBlocking)
            
            
            for automaticFiltersLanguage in automaticFiltersLanguages {
                if let langRawValue = automaticFiltersLanguage.lang,
                   automaticFiltersLanguage.isActive == true {
                    
                    let lang = NLLanguage(rawValue: langRawValue)
                    
                    if supportedLanguages.contains(lang),
                       let localizedName = lang.localizedName {
                        
                        automaticFilterNames.append(localizedName)
                    }
                }
            }
        }
        
        #warning("Adi - Missing tests")
        let ruleRequest: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        ruleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AutomaticFiltersRule.ruleId, ascending: true)]
        if let automaticFiltersRules = try? self.context.fetch(ruleRequest) {
            
            for automaticFiltersRule in automaticFiltersRules {
                if automaticFiltersRule.isActive,
                   let rule = automaticFiltersRule.ruleType,
                   let shortTitle = rule.shortTitle {
                    
                    automaticFilterNames.append(shortTitle)
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
    
    var preview: PersistanceManagerProtocol {
        let result = PersistanceManager(inMemory: true)
        result.loadDebugData()
        return result
    }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType = .junk) {
        guard !self.isDuplicateFilter(text: text, type: type) else { return }
        
        let newFilter = Filter(context: self.context)
        newFilter.uuid = UUID()
        newFilter.filterType = type
        newFilter.denyFolderType = denyFolder
        newFilter.text = text
        
        self.saveContext()
    }
    
    func isDuplicateFilter(text: String, type: FilterType) -> Bool {
        var filterExists = false
        let fetchRequest = NSFetchRequest<Filter>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld AND text == %@", type.rawValue, text)
        
        do {
            let results = try context.fetch(fetchRequest)
            filterExists = results.count > 0
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return filterExists
    }
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        offsets.map({ filters[$0] }).forEach({ self.context.delete($0) })
        self.saveContext()
    }
    
    func deleteFilters(_ filters: Set<Filter>) {
        filters.forEach({ self.context.delete($0) })
        self.saveContext()
    }
    
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        filter.denyFolderType = denyFolder
        self.saveContext()
    }
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        var supportedLanguages: [NLLanguage] = []
        
        switch type {
        case .blockLanguage:
            let remainingSupportedLanguages = NLLanguage.allSupportedCases
                .filter({ !self.isDuplicateFilter(text: $0.filterText, type: .denyLanguage) })
                .sorted(by: { $0.rawValue < $1.rawValue })
            supportedLanguages.append(contentsOf: remainingSupportedLanguages)
            
        case .automaticBlocking:
            supportedLanguages.append(.english)
            supportedLanguages.append(.hebrew)
            supportedLanguages.sort(by: { $0.rawValue < $1.rawValue })
        }

        return supportedLanguages
    }
    
    func getFrequentlyAskedQuestions() -> [QuestionViewModel] {
        return [QuestionViewModel(text: "faq_question_0"~, answer: "faq_answer_0"~, action: .activateFilters),
                QuestionViewModel(text: "faq_question_1"~, answer: "faq_answer_1"~),
                QuestionViewModel(text: "faq_question_2"~, answer: "faq_answer_2"~),
                QuestionViewModel(text: "faq_question_3"~, answer: "faq_answer_3"~),
                QuestionViewModel(text: "faq_question_4"~, answer: "faq_answer_4"~),
                QuestionViewModel(text: "faq_question_5"~, answer: "faq_answer_5"~)]
    }
    
    func getFilters() -> [Filter] {
        let request: NSFetchRequest<Filter> = Filter.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Filter.type, ascending: false),
                                   NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
        
        
        guard let filters = try? self.context.fetch(request) else { return [] }
        
        return filters
    }
    
    func initAutomaticFiltering() {
        #warning("Adi - Missing tests")
        self.initAutomaticFilteringLanguages()
        self.initAutomaticFilteringRules()
        
        self.saveContext()
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        let request: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        request.predicate = NSPredicate(format: "lang == %@", language.rawValue)
        guard let automaticFiltersLanguage = try? self.context.fetch(request).first else { return false }
        
        return automaticFiltersLanguage.isActive
    }
    
    func setLanguageAtumaticState(for language: NLLanguage, value: Bool) {
        let request: NSFetchRequest<AutomaticFiltersLanguage> = AutomaticFiltersLanguage.fetchRequest()
        request.predicate = NSPredicate(format: "lang == %@", language.rawValue)
        guard let automaticFiltersLanguage = try? self.context.fetch(request).first else { return }
        
        automaticFiltersLanguage.isActive = value
        self.saveContext()
    }
    
    func cacheAutomaticFilterList(_ filterList: AutomaticFilterList) {
        self.deleteExistingCaches()
        
        let newCache = AutomaticFiltersCache(context: self.context)
        newCache.uuid = UUID()
        newCache.hashed = filterList.hashed
        newCache.filtersData = filterList.encoded
        newCache.age = Date()
        
        self.saveContext()
    }
    
    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool {
        let request: NSFetchRequest<AutomaticFiltersCache> = AutomaticFiltersCache.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \AutomaticFiltersCache.age, ascending: false)]
        guard let cache = try? self.context.fetch(request).first else { return true }
        let isStale = cache.hashed != newFilterList.hashed
        
        if !isStale {
            cache.age = Date()
            self.saveContext()
        }
        
        return isStale
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        let request: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        request.predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRule = try? self.context.fetch(request).first else { return false }
        
        return automaticFiltersRule.isActive
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        let request: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        request.predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRule = try? self.context.fetch(request).first else { return }
        
        automaticFiltersRule.isActive = value
        self.saveContext()
    }
    
    func selectedChoice(for rule: RuleType) -> Int {
        let request: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        request.predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRule = try? self.context.fetch(request).first else { return 0 }
        
        return Int(automaticFiltersRule.selectedChoice)
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        let request: NSFetchRequest<AutomaticFiltersRule> = AutomaticFiltersRule.fetchRequest()
        request.predicate = NSPredicate(format: "ruleId == %ld", rule.rawValue)
        guard let automaticFiltersRule = try? self.context.fetch(request).first else { return }
        
        automaticFiltersRule.selectedChoice = Int64(choice)
        self.saveContext()
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
        
        self.saveContext()
    }
}
