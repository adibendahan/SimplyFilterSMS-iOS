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
         amazonS3Service: AmazonS3ServiceProtocol = AppManager.shared.amazonS3Service) {
        
        self.persistanceManager = persistanceManager
        self.amazonS3Service = amazonS3Service
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
                .sorted(by: { $0.rawValue < $1.rawValue })
            supportedLanguages.append(contentsOf: remainingSupportedLanguages)
            
        case .automaticBlocking:
            if let persistanceManager = self.persistanceManager,
               let cache = persistanceManager.fetchAutomaticFiltersCacheRecords().first?.filtersData,
               let automaticFilters = AutomaticFilterListsResponse(base64String: cache) {
                
                for langRawValue in automaticFilters.filterLists.keys {
                    let language = NLLanguage(langRawValue)
                    
                    if language != .undetermined {
                        supportedLanguages.append(language)
                    }
                }
            
            }

            supportedLanguages.sort(by: { $0.rawValue < $1.rawValue })
        }

        return supportedLanguages
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        guard let persistanceManager = self.persistanceManager else { return false }
        let automaticFiltersLanguage = persistanceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        return automaticFiltersLanguage.isActive
    }
    
    func setLanguageAutmaticState(for language: NLLanguage, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        let automaticFiltersLanguage = persistanceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        automaticFiltersLanguage.isActive = value
        persistanceManager.commitContext()
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        let automaticFiltersRule = persistanceManager.ensuredAutomaticFiltersRuleRecord(for: rule)
        automaticFiltersRule.isActive = value
        persistanceManager.commitContext()
    }

    func selectedChoice(for rule: RuleType) -> Int {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return 0 }
        return Int(automaticFiltersRule.selectedChoice)
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        automaticFiltersRule.selectedChoice = Int64(choice)
        persistanceManager.commitContext()
    }
    
    func updateAutomaticFiltersIfNeeded() {
        guard self.shouldFetchFilters else { return }
        
        Task(priority: .background) {
            if let automaticFilterList = await self.amazonS3Service?.fetchAutomaticFilters() {
                self.updateCacheIfNeeded(newFilterList: automaticFilterList)
            }
        }
    }
    
    func forceUpdateAutomaticFilters() async {
        guard let automaticFilterList = await self.amazonS3Service?.fetchAutomaticFilters() else { return }
        self.updateCacheIfNeeded(newFilterList: automaticFilterList, force: true)
    }
    
    //MARK: - Private  -
    
    private weak var amazonS3Service: AmazonS3ServiceProtocol?
    private weak var persistanceManager: PersistanceManagerProtocol?
    private var shouldFetchFilters: Bool {
        var shouldFetchFilters = true
        
        if let cacheAge = self.automaticFiltersCacheAge,
           cacheAge.daysBetween(date: Date()) < kUpdateAutomaticFiltersMinDays {
            
            shouldFetchFilters = false
        }
        
        return shouldFetchFilters
    }
    
    private func updateCacheIfNeeded(newFilterList: AutomaticFilterListsResponse, force: Bool = false) {
        guard let persistanceManager = self.persistanceManager else { return }
        
        let isCacheStale = persistanceManager.isCacheStale(comparedTo: newFilterList)
        
        if force || isCacheStale {
            persistanceManager.saveCache(with: newFilterList)
        }

        if isCacheStale {
            NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)
        }
    }
}
