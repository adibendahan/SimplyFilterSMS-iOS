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
    
    
    //MARK: - Fetching -
    func fetchFilterRecords() -> [Filter]
    func fetchFilterRecords(for filterType: FilterType) -> [Filter]
    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage]
    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule]
    func fetchAutomaticFiltersCacheRecords() -> [AutomaticFiltersCache]
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage?
    func fetchAutomaticFiltersRuleRecord(for rule: RuleType) -> AutomaticFiltersRule?
    
    
    //MARK: - Helpers -
    func initAutomaticFiltering(languages: [NLLanguage], rules: [RuleType])
    func isDuplicateFilter(text: String) -> Bool
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType)
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter])
    func deleteFilters(_ filters: Set<Filter>)
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType)
    func saveCache(with filterList: AutomaticFilterList)
    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool

    func loadDebugData()
}

