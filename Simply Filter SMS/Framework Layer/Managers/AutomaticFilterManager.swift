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
                .sorted(by: Self.languageSortOrder)
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
            
            supportedLanguages.sort(by: Self.languageSortOrder)
        }
        
        return supportedLanguages
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        guard let persistanceManager = self.persistanceManager else { return false }
        let automaticFiltersLanguage = persistanceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        return automaticFiltersLanguage.isActive
    }
    
    func setLanguageAutomaticState(for language: NLLanguage, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        AppManager.logger.debug("setLanguageAutomaticState — '\(language.localizedName ?? language.rawValue, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersLanguage = persistanceManager.ensuredAutomaticFiltersLanguageRecord(for: language)
        automaticFiltersLanguage.isActive = value
        persistanceManager.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        AppManager.logger.debug("setAutomaticRuleState — '\(rule.title, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersRule = persistanceManager.ensuredAutomaticFiltersRuleRecord(for: rule)
        automaticFiltersRule.isActive = value
        if automaticFiltersRule.ruleType == .shortSender && automaticFiltersRule.selectedChoice < 3 {
            automaticFiltersRule.selectedChoice = 6
        }
        persistanceManager.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func selectedChoice(for rule: RuleType) -> Int {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return 0 }
        return Int(automaticFiltersRule.selectedChoice)
    }

    func setSelectedChoice(for rule: RuleType, choice: Int) {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        AppManager.logger.debug("setSelectedChoice — '\(rule.title, privacy: .public)' → \(choice, privacy: .public)")
        automaticFiltersRule.selectedChoice = Int64(choice)
        persistanceManager.commitContext()
        NotificationCenter.default.post(name: .filtersStateChanged, object: nil)
    }

    func selectedCountries(for rule: RuleType) -> [String] {
        return self.persistanceManager?.selectedCountries(for: rule) ?? []
    }

    func setSelectedCountries(_ countries: [String], for rule: RuleType) {
        AppManager.logger.debug("setSelectedCountries — \(countries, privacy: .public)")
        self.persistanceManager?.setSelectedCountries(countries, for: rule)
    }

    func updateAutomaticFiltersIfNeeded() {
        guard self.shouldFetchFilters else {
            AppManager.logger.debug("updateAutomaticFiltersIfNeeded — cache is fresh, skipping fetch")
            return
        }
        AppManager.logger.debug("updateAutomaticFiltersIfNeeded — cache is stale, fetching from S3")
        Task(priority: .background) {
            if let automaticFilterList = await self.amazonS3Service?.fetchAutomaticFilters() {
                self.updateCacheIfNeeded(newFilterList: automaticFilterList)
            }
        }
    }

    func forceUpdateAutomaticFilters() async {
        AppManager.logger.debug("forceUpdateAutomaticFilters — forcing S3 fetch")
        guard let automaticFilterList = await self.amazonS3Service?.fetchAutomaticFilters() else { return }
        self.updateCacheIfNeeded(newFilterList: automaticFilterList, force: true)
    }
    
    //MARK: - Private  -
    
    private static func languageSortOrder(_ a: NLLanguage, _ b: NLLanguage) -> Bool {
        let currentLocale: NLLanguage? = Locale.current.language.languageCode.map { NLLanguage(rawValue: $0.identifier) }
        var priority: [NLLanguage] = [.english, .hebrew]
        if let current = currentLocale, !priority.contains(current) {
            priority.insert(current, at: 0)
        } else if currentLocale == .hebrew {
            priority = [.hebrew, .english]
        }
        let ai = priority.firstIndex(of: a)
        let bi = priority.firstIndex(of: b)
        switch (ai, bi) {
        case let (ai?, bi?):
            return ai < bi
        case (nil, _?):
            return false
        case (_?, nil):
            return true
        case (nil, nil):
            let locale = Locale(identifier: "en_US")
            let an = locale.localizedString(forIdentifier: a.rawValue) ?? a.rawValue
            let bn = locale.localizedString(forIdentifier: b.rawValue) ?? b.rawValue
            return an < bn
        }
    }
    
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
        AppManager.logger.debug("updateCacheIfNeeded — isCacheStale: \(isCacheStale, privacy: .public), force: \(force, privacy: .public)")
        if force || isCacheStale {
            AppManager.logger.debug("updateCacheIfNeeded — saving new filter cache")
            persistanceManager.saveCache(with: newFilterList)
        }
        if isCacheStale {
            AppManager.logger.debug("updateCacheIfNeeded — posting automaticFiltersUpdated notification")
            NotificationCenter.default.post(name: .automaticFiltersUpdated, object: nil)
        }
    }
}
