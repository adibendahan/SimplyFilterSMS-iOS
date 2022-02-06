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
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        self.persistanceManager = persistanceManager
        
        self.initAutomaticFiltering()
    }
    
    
    //MARK: - Public API (AutomaticFilterManagerProtocol) -
    var isAutomaticFilteringOn: Bool {
        var isAutomaticFilteringOn = false
        
        let automaticFiltersLanguageRecords = self.persistanceManager.fetchAutomaticFiltersLanguageRecords()
        let supportedLanguages: [NLLanguage] = self.languages(for: .automaticBlocking)
        
        for automaticFilterLanguage in automaticFiltersLanguageRecords {
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
        
        let automaticFiltersLanguageRecords = self.persistanceManager.fetchAutomaticFiltersLanguageRecords()
        let supportedLanguages = self.languages(for: .automaticBlocking)
        
        for automaticFiltersLanguageRecord in automaticFiltersLanguageRecords {
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
        guard let cache = self.persistanceManager.fetchAutomaticFiltersCacheRecords().first else { return nil }
        
        return cache.age
    }
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        var supportedLanguages: [NLLanguage] = []
        
        switch type {
        case .blockLanguage:
            let remainingSupportedLanguages = NLLanguage.allSupportedCases
                .filter({ !self.persistanceManager.isDuplicateFilter(language: $0) })
                .sorted(by: { $0.rawValue < $1.rawValue })
            supportedLanguages.append(contentsOf: remainingSupportedLanguages)
            
        case .automaticBlocking:
            supportedLanguages.append(.english)
            supportedLanguages.append(.hebrew)
            supportedLanguages.sort(by: { $0.rawValue < $1.rawValue })
        }

        return supportedLanguages
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        guard let automaticFiltersLanguage = self.persistanceManager.fetchAutomaticFiltersLanguageRecord(for: language) else { return false }
        return automaticFiltersLanguage.isActive
    }
    
    func setLanguageAtumaticState(for language: NLLanguage, value: Bool) {
        guard let automaticFiltersLanguage = self.persistanceManager.fetchAutomaticFiltersLanguageRecord(for: language) else { return }
        automaticFiltersLanguage.isActive = value
        self.persistanceManager.commitContext()
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        guard let automaticFiltersRule = self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        guard let automaticFiltersRule = self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        automaticFiltersRule.isActive = value
        self.persistanceManager.commitContext()
    }

    func selectedChoice(for rule: RuleType) -> Int {
        guard let automaticFiltersRule = self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return 0 }
        return Int(automaticFiltersRule.selectedChoice)
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        guard let automaticFiltersRule = self.persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        automaticFiltersRule.selectedChoice = Int64(choice)
        self.persistanceManager.commitContext()
    }
    
    func fetchAutomaticFilterList(completion: @escaping (AutomaticFilterList?) -> ()) {
    
        self.urlRequestExecutor.execute(type: AutomaticFilterList.self,
                                        baseURL: .appBaseURL,
                                        request: AutomaticFiltersRequest()) { result in
            
            switch result {
            case .success(let filterList):
                completion(filterList)
            case .failure(let error):
                let nsError = error as NSError
                AppManager.logger.error("ERROR! While fetching Automatic Filter List: \(nsError), \(nsError.userInfo)")
                completion(nil)
            }
        }
    }
    
    func forceUpdateAutomaticFilters(completion: (()->())?) {
        self.fetchAutomaticFilterList { [weak self] automaticFilterList in
            guard let automaticFilterList = automaticFilterList else { return }
            
            self?.updateCacheIfNeeded(newFilterList: automaticFilterList, force: true)
            completion?()
        }
    }
    
    //MARK: - Private  -
    
    private let urlRequestExecutor = URLRequestExecutor()
    private let persistanceManager: PersistanceManagerProtocol
    private var shouldFetchFilters: Bool {
        var shouldFetchFilters = true
        
        if let cacheAge = self.automaticFiltersCacheAge,
           cacheAge.daysBetween(date: Date()) < kUpdateAutomaticFiltersMinDays {
            
            shouldFetchFilters = false
        }
        
        return shouldFetchFilters
    }
    
    private func updateCacheIfNeeded(newFilterList: AutomaticFilterList, force: Bool = false) {
        guard force || self.persistanceManager.isCacheStale(comparedTo: newFilterList) else { return }
        self.persistanceManager.saveCache(with: newFilterList)
    }
    
    private func fetchFiltersIfNeeded() {
        guard self.shouldFetchFilters else { return }
        
        self.fetchAutomaticFilterList { [weak self] automaticFilterList in
            guard let automaticFilterList = automaticFilterList else { return }
            
            self?.updateCacheIfNeeded(newFilterList: automaticFilterList)
        }
    }
    
    private func initAutomaticFiltering() {
        let languages = self.languages(for: .automaticBlocking)
        self.persistanceManager.initAutomaticFiltering(languages: languages, rules: RuleType.allCases)
        self.fetchFiltersIfNeeded()
    }
}
