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

    

    var addFilterCounter = 0
    var isDuplicateFilterCounter = 0
    var deleteFiltersOffsetsCounter = 0
    var deleteFiltersCounter = 0
    var updateFilterCounter = 0
    var fetchFilterRecordsCounter = 0
    var initAutomaticFilteringCounter = 0
    var saveCacheCounter = 0
    var isCacheStaleCounter = 0
    var commitContextCounter = 0
    var fetchFilterRecordsForTypeCounter = 0
    var fetchAutomaticFiltersLanguageRecordsCounter = 0
    var fetchAutomaticFiltersRuleRecordsCounter = 0
    var fetchAutomaticFiltersCacheRecordsCounter = 0
    var fetchAutomaticFiltersLanguageRecordCounter = 0
    var fetchAutomaticFiltersRuleRecordCounter = 0
    
    var addFilterClosure: ((String, FilterType, DenyFolderType) -> ())?
    var isDuplicateFilterClosure: ((String) -> (Bool))?
    var deleteFiltersOffsetsClosure: ((IndexSet, [Filter]) -> ())?
    var deleteFiltersClosure: ((Set<Filter>) -> ())?
    var updateFilterClosure: ((Filter, DenyFolderType) -> ())?
    var fetchFilterRecordsClosure: (() -> ([Filter]))?
    var initAutomaticFilteringClosure: (([NLLanguage], [RuleType]) -> ())?
    var saveCacheClosure: ((AutomaticFilterList) -> ())?
    var isCacheStaleClosure: ((AutomaticFilterList) -> (Bool))?
    var commitContextClosure: (() -> ())?
    var fetchFilterRecordsForTypeClosure: ((FilterType) -> ([Filter]))?
    var fetchAutomaticFiltersLanguageRecordsClosure: (() -> ([AutomaticFiltersLanguage]))?
    var fetchAutomaticFiltersRuleRecordsClosure: (() -> ([AutomaticFiltersRule]))?
    var fetchAutomaticFiltersCacheRecordsClosure: (() -> ([AutomaticFiltersCache]))?
    var fetchAutomaticFiltersLanguageRecordClosure: ((NLLanguage) -> (AutomaticFiltersLanguage?))?
    var fetchAutomaticFiltersRuleRecordClosure: ((RuleType) -> (AutomaticFiltersRule?))?
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType) {
        self.addFilterCounter += 1
        self.addFilterClosure?(text, type, denyFolder)
    }

    func isDuplicateFilter(text: String) -> Bool {
        self.isDuplicateFilterCounter += 1
        return self.isDuplicateFilterClosure?(text) ?? false
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

    func fetchFilterRecords() -> [Filter] {
        self.fetchFilterRecordsCounter += 1
        return self.fetchFilterRecordsClosure?() ?? []
    }
    
    func fetchFilterRecords(for filterType: FilterType) -> [Filter] {
        self.fetchFilterRecordsForTypeCounter += 1
        return self.fetchFilterRecordsForTypeClosure?(filterType) ?? []
    }

    func initAutomaticFiltering(languages: [NLLanguage], rules: [RuleType]) {
        self.initAutomaticFilteringCounter += 1
        self.initAutomaticFilteringClosure?(languages, rules)
    }
    
    func saveCache(with filterList: AutomaticFilterList) {
        self.saveCacheCounter += 1
        self.saveCacheClosure?(filterList)
    }

    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool {
        self.isCacheStaleCounter += 1
        return self.isCacheStaleClosure?(newFilterList) ?? false
    }
    
    func commitContext() {
        self.commitContextCounter += 1
        self.commitContextClosure?()
    }
    
    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage] {
        self.fetchAutomaticFiltersLanguageRecordsCounter += 1
        return self.fetchAutomaticFiltersLanguageRecordsClosure?() ?? []
    }
    
    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule] {
        self.fetchAutomaticFiltersRuleRecordsCounter += 1
        return self.fetchAutomaticFiltersRuleRecordsClosure?() ?? []
    }
    
    func fetchAutomaticFiltersCacheRecords() -> [AutomaticFiltersCache] {
        self.fetchAutomaticFiltersCacheRecordsCounter += 1
        return self.fetchAutomaticFiltersCacheRecordsClosure?() ?? []
    }
    
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage? {
        self.fetchAutomaticFiltersLanguageRecordCounter += 1
        return self.fetchAutomaticFiltersLanguageRecordClosure?(language) ?? nil
    }
    
    func fetchAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule? {
        self.fetchAutomaticFiltersRuleRecordCounter += 1
        return self.fetchAutomaticFiltersRuleRecordClosure?(rule) ?? nil
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
        self.addFilterCounter = 0
        self.isDuplicateFilterCounter = 0
        self.deleteFiltersOffsetsCounter = 0
        self.deleteFiltersCounter = 0
        self.updateFilterCounter = 0
        self.initAutomaticFilteringCounter = 0
        self.saveCacheCounter = 0
        self.isCacheStaleCounter = 0
    }
    
    //MARK: Unused
    func loadDebugData() {}
}
