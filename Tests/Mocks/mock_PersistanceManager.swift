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
    var isDuplicateFilterLanguageCounter = 0
    var deleteFiltersOffsetsCounter = 0
    var deleteFiltersCounter = 0
    var updateFilterDenyFolderCounter = 0
    var updateFilterCaseCounter = 0
    var updateFilterTargetCounter = 0
    var updateFilterMatchingCounter = 0
    var fetchFilterRecordsCounter = 0
    var saveCacheCounter = 0
    var isCacheStaleCounter = 0
    var commitContextCounter = 0
    var fetchFilterRecordsForTypeCounter = 0
    var fetchAutomaticFiltersLanguageRecordsCounter = 0
    var fetchAutomaticFiltersRuleRecordsCounter = 0
    var fetchAutomaticFiltersCacheRecordsCounter = 0
    var fetchAutomaticFiltersLanguageRecordCounter = 0
    var fetchAutomaticFiltersRuleRecordCounter = 0
    var ensuredAutomaticFiltersLanguageRecordCounter = 0
    var ensuredAutomaticFiltersRuleRecordCounter = 0
    
    var addFilterClosure: ((String, FilterType, DenyFolderType, FilterTarget, FilterMatching, FilterCase) -> ())?
    var isDuplicateFilterClosure: ((String, FilterTarget, FilterMatching, FilterCase) -> (Bool))?
    var isDuplicateFilterLanguageClosure: ((NLLanguage) -> (Bool))?
    var deleteFiltersOffsetsClosure: ((IndexSet, [Filter]) -> ())?
    var deleteFiltersClosure: ((Set<Filter>) -> ())?
    var updateFilterDenyFolderClosure: ((Filter, DenyFolderType) -> ())?
    var updateFilterCaseClosure: ((Filter, FilterCase) -> ())?
    var updateFilterTargetClosure: ((Filter, FilterTarget) -> ())?
    var updateFilterMatchingClosure: ((Filter, FilterMatching) -> ())?
    var fetchFilterRecordsClosure: (() -> ([Filter]))?
    var saveCacheClosure: ((AutomaticFilterList) -> ())?
    var isCacheStaleClosure: ((AutomaticFilterList) -> (Bool))?
    var commitContextClosure: (() -> ())?
    var fetchFilterRecordsForTypeClosure: ((FilterType) -> ([Filter]))?
    var fetchAutomaticFiltersLanguageRecordsClosure: (() -> ([AutomaticFiltersLanguage]))?
    var fetchAutomaticFiltersRuleRecordsClosure: (() -> ([AutomaticFiltersRule]))?
    var fetchAutomaticFiltersCacheRecordsClosure: (() -> ([AutomaticFiltersCache]))?
    var fetchAutomaticFiltersLanguageRecordClosure: ((NLLanguage) -> (AutomaticFiltersLanguage?))?
    var fetchAutomaticFiltersRuleRecordClosure: ((RuleType) -> (AutomaticFiltersRule?))?
    var ensuredAutomaticFiltersLanguageRecordClosure: ((NLLanguage) -> (AutomaticFiltersLanguage))?
    var ensuredAutomaticFiltersRuleRecordClosure: ((RuleType) -> (AutomaticFiltersRule))?
    
    func addFilter(text: String,
                   type: FilterType,
                   denyFolder: DenyFolderType,
                   filterTarget: FilterTarget,
                   filterMatching: FilterMatching,
                   filterCase: FilterCase) {
        
        self.addFilterCounter += 1
        self.addFilterClosure?(text, type, denyFolder, filterTarget, filterMatching, filterCase)
    }

    func isDuplicateFilter(text: String,
                           filterTarget: FilterTarget,
                           filterMatching: FilterMatching,
                           filterCase: FilterCase) -> Bool {
        
        self.isDuplicateFilterCounter += 1
        return self.isDuplicateFilterClosure?(text, filterTarget, filterMatching, filterCase) ?? false
    }

    func isDuplicateFilter(language: NLLanguage) -> Bool {
        self.isDuplicateFilterLanguageCounter += 1
        return self.isDuplicateFilterLanguageClosure?(language) ?? false
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
        self.updateFilterDenyFolderCounter += 1
        self.updateFilterDenyFolderClosure?(filter, denyFolder)
    }
    
    func updateFilter(_ filter: Filter, filterMatching: FilterMatching) {
        self.updateFilterMatchingCounter += 1
        self.updateFilterMatchingClosure?(filter, filterMatching)
    }
    
    func updateFilter(_ filter: Filter, filterCase: FilterCase) {
        self.updateFilterCaseCounter += 1
        self.updateFilterCaseClosure?(filter, filterCase)
    }
    
    func updateFilter(_ filter: Filter, filterTarget: FilterTarget) {
        self.updateFilterTargetCounter += 1
        self.updateFilterTargetClosure?(filter, filterTarget)
    }

    func fetchFilterRecords() -> [Filter] {
        self.fetchFilterRecordsCounter += 1
        return self.fetchFilterRecordsClosure?() ?? []
    }
    
    func fetchFilterRecords(for filterType: FilterType) -> [Filter] {
        self.fetchFilterRecordsForTypeCounter += 1
        return self.fetchFilterRecordsForTypeClosure?(filterType) ?? []
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
    
    func ensuredAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule {
        self.ensuredAutomaticFiltersRuleRecordCounter += 1
        return self.ensuredAutomaticFiltersRuleRecordClosure?(rule) ?? AutomaticFiltersRule(context: self.context)
    }
    
    func ensuredAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage {
        self.ensuredAutomaticFiltersLanguageRecordCounter += 1
        return self.ensuredAutomaticFiltersLanguageRecordClosure?(language) ?? AutomaticFiltersLanguage(context: self.context)
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
        self.updateFilterDenyFolderCounter = 0
        self.updateFilterCaseCounter = 0
        self.updateFilterMatchingCounter = 0
        self.updateFilterTargetCounter = 0
        self.fetchFilterRecordsCounter = 0
        self.saveCacheCounter = 0
        self.isCacheStaleCounter = 0
        self.commitContextCounter = 0
        self.fetchFilterRecordsForTypeCounter = 0
        self.fetchAutomaticFiltersLanguageRecordsCounter = 0
        self.fetchAutomaticFiltersRuleRecordsCounter = 0
        self.fetchAutomaticFiltersCacheRecordsCounter = 0
        self.fetchAutomaticFiltersLanguageRecordCounter = 0
        self.fetchAutomaticFiltersRuleRecordCounter = 0
        self.ensuredAutomaticFiltersRuleRecordCounter = 0
        self.ensuredAutomaticFiltersLanguageRecordCounter = 0
    }
    
    //MARK: Unused
    func loadDebugData() {}
}
