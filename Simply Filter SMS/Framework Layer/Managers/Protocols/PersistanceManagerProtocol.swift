//
//  PersistanceManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import CoreData
import NaturalLanguage

protocol PersistanceManagerProtocol: AnyObject {
    
    //MARK: - Context -
    var context: NSManagedObjectContext { get }
    
    func commitContext()
    func reloadContainer()
    
    //MARK: - Fetching -
    func fetchFilterRecords() -> [Filter]
    func fetchFilterRecords(for filterType: FilterType) -> [Filter]
    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage]
    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule]
    func fetchAutomaticFiltersCacheRecords() -> [AutomaticFiltersCache]
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage?
    func fetchAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule?
    func ensuredAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule
    func ensuredAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage
    
    
    //MARK: - Helpers -
    func isDuplicateFilter(language: NLLanguage) -> Bool
    func isDuplicateFilter(text: String,
                           filterTarget: FilterTarget,
                           filterMatching: FilterMatching,
                           filterCase: FilterCase) -> Bool
    
    func addFilter(text: String, type: FilterType,
                   denyFolder: DenyFolderType,
                   filterTarget: FilterTarget,
                   filterMatching: FilterMatching,
                   filterCase: FilterCase)
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter])
    func deleteFilters(_ filters: Set<Filter>)
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType)
    func updateFilter(_ filter: Filter, filterMatching: FilterMatching)
    func updateFilter(_ filter: Filter, filterCase: FilterCase)
    func updateFilter(_ filter: Filter, filterTarget: FilterTarget)
    func saveCache(with filterList: AutomaticFilterList)
    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool

    func loadDebugData()
}

