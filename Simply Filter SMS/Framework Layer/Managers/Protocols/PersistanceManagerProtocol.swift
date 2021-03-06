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
    var fingerprint: String { get }
    
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
    func updateFilter(_ filter: Filter, filterText: String)
    func saveCache(with filterList: AutomaticFilterListsResponse)
    func isCacheStale(comparedTo newFilterList: AutomaticFilterListsResponse) -> Bool

    #if DEBUG
    func loadDebugData()
    func reset()
    #endif
}

