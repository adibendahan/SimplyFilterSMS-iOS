//
//  mock_PersistanceManager.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 29/01/2022.
//

import Foundation
import XCTest
import CoreData
import NaturalLanguage
@testable import Simply_Filter_SMS

class mock_PersistanceManager: PersistanceManagerProtocol {

    var isAutomaticFilteringOnCounter = 0
    var automaticFiltersCacheAgeCounter = 0
    var activeAutomaticLanguagesCounter = 0
    var addFilterCounter = 0
    var isDuplicateFilterCounter = 0
    var deleteFiltersOffsetsCounter = 0
    var deleteFiltersCounter = 0
    var updateFilterCounter = 0
    var languagesCounter = 0
    var getFrequentlyAskedQuestionsCounter = 0
    var getFiltersCounter = 0
    var initAutomaticFilteringCounter = 0
    var languageAutomaticStateCounter = 0
    var setLanguageAtumaticStateCounter = 0
    var cacheAutomaticFilterListCounter = 0
    var isCacheStaleCounter = 0
    
    var isAutomaticFilteringOnClosure: (() -> (Bool))?
    var automaticFiltersCacheAgeClosure: (() -> (Date?))?
    var activeAutomaticLanguagesClosure: (() -> (String?))?
    var addFilterClosure: ((String, FilterType, DenyFolderType) -> ())?
    var isDuplicateFilterClosure: ((String, FilterType) -> (Bool))?
    var deleteFiltersOffsetsClosure: ((IndexSet, [Filter]) -> ())?
    var deleteFiltersClosure: ((Set<Filter>) -> ())?
    var updateFilterClosure: ((Filter, DenyFolderType) -> ())?
    var languagesClosure: ((LanguageListView.Mode) -> ([NLLanguage]))?
    var getFrequentlyAskedQuestionsClosure: (() -> ([QuestionViewModel]))?
    var getFiltersClosure: (() -> ([Filter]))?
    var initAutomaticFilteringClosure: (() -> ())?
    var languageAutomaticStateClosure: ((NLLanguage) -> (Bool))?
    var setLanguageAtumaticStateClosure: ((NLLanguage, Bool) -> ())?
    var cacheAutomaticFilterListClosure: ((AutomaticFilterList) -> ())?
    var isCacheStaleClosure: ((AutomaticFilterList) -> (Bool))?
    
    var isAutomaticFilteringOn: Bool {
        get {
            self.isAutomaticFilteringOnCounter += 1
            return self.isAutomaticFilteringOnClosure?() ?? false
        }
    }
    
    var automaticFiltersCacheAge: Date? {
        get {
            self.automaticFiltersCacheAgeCounter += 1
            return self.automaticFiltersCacheAgeClosure?() ?? nil
        }
    }
    var activeAutomaticLanguages: String? {
        get {
            self.activeAutomaticLanguagesCounter += 1
            return self.activeAutomaticLanguagesClosure?() ?? nil
        }
    }

    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType) {
        self.addFilterCounter += 1
        self.addFilterClosure?(text, type, denyFolder)
    }

    func isDuplicateFilter(text: String, type: FilterType) -> Bool {
        self.isDuplicateFilterCounter += 1
        return self.isDuplicateFilterClosure?(text, type) ?? false
    }

    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        self.deleteFiltersOffsetsCounter += 1
        self.deleteFiltersOffsetsClosure?(offsets, filters)
    }

    func deleteFilters(_ filters: Set<Filter>) {
        self.deleteFiltersCounter += 1
        self.deleteFiltersClosure?(filters)
    }

    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        self.updateFilterCounter += 1
        self.updateFilterClosure?(filter, denyFolder)
    }

    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        self.languagesCounter += 1
        return self.languagesClosure?(type) ?? []
    }

    func getFrequentlyAskedQuestions() -> [QuestionViewModel] {
        self.getFrequentlyAskedQuestionsCounter += 1
        return self.getFrequentlyAskedQuestionsClosure?() ?? []
    }

    func getFilterRecords() -> [Filter] {
        self.getFiltersCounter += 1
        return self.getFiltersClosure?() ?? []
    }

    func initAutomaticFiltering() {
        self.initAutomaticFilteringCounter += 1
        self.initAutomaticFilteringClosure?()
    }

    func languageAutomaticState(for language: NLLanguage) -> Bool {
        self.languageAutomaticStateCounter += 1
        return self.languageAutomaticStateClosure?(language) ?? false
    }

    func setLanguageAtumaticState(for language: NLLanguage, value: Bool) {
        self.setLanguageAtumaticStateCounter += 1
        self.setLanguageAtumaticStateClosure?(language, value)
    }

    func saveCache(with filterList: AutomaticFilterList) {
        self.cacheAutomaticFilterListCounter += 1
        self.cacheAutomaticFilterListClosure?(filterList)
    }

    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool {
        self.isCacheStaleCounter += 1
        return self.isCacheStaleClosure?(newFilterList) ?? false
    }
    
    #warning("Adi - Missing implementation + testing")
    func automaticRuleState(for rule: RuleType) -> Bool {
        return false
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        
    }
    
    func selectedChoice(for rule: RuleType) -> Int {
        return 0
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        
    }
    

    //MARK: Helpers
    private var persistance = PersistanceManager(inMemory: true)
    var context: NSManagedObjectContext
    var preview: PersistanceManagerProtocol
    
    init() {
        self.context = persistance.context
        self.preview = persistance
    }
    
    func resetCounters() {
        self.isAutomaticFilteringOnCounter = 0
        self.automaticFiltersCacheAgeCounter = 0
        self.activeAutomaticLanguagesCounter = 0
        self.addFilterCounter = 0
        self.isDuplicateFilterCounter = 0
        self.deleteFiltersOffsetsCounter = 0
        self.deleteFiltersCounter = 0
        self.updateFilterCounter = 0
        self.languagesCounter = 0
        self.getFrequentlyAskedQuestionsCounter = 0
        self.getFiltersCounter = 0
        self.initAutomaticFilteringCounter = 0
        self.languageAutomaticStateCounter = 0
        self.setLanguageAtumaticStateCounter = 0
        self.cacheAutomaticFilterListCounter = 0
        self.isCacheStaleCounter = 0
    }
    
    //MARK: Unused
    func loadDebugData() {}
}
