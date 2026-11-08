//
//  PersistenceManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import CoreData
import NaturalLanguage

protocol PersistenceManagerProtocol: AnyObject {
    
    //MARK: - Context -
    var context: NSManagedObjectContext { get }
    var fingerprint: String { get }
    
    func commitContext() -> Bool
    func commitAndAnnounce() -> Bool
    func reloadContainer()
    
    //MARK: - Fetching -
    func fetchFilterRecords() -> [Filter]
    func fetchFilterRecords(for filterType: FilterType) -> [Filter]
    func fetchAutomaticFiltersLanguageRecords() -> [AutomaticFiltersLanguage]
    func fetchAutomaticFiltersRuleRecords() -> [AutomaticFiltersRule]
    func fetchFilterListsCacheRecords() -> [FilterListsCache]
    func fetchAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage?
    func fetchAutomaticFiltersRuleRecord(for rule: SmartFilterType) -> AutomaticFiltersRule?
    func ensuredAutomaticFiltersRuleRecord(for rule: SmartFilterType) -> AutomaticFiltersRule
    func ensuredAutomaticFiltersLanguageRecord(for language: NLLanguage) -> AutomaticFiltersLanguage
    
    
    //MARK: - Helpers -
    func blockableLanguages() -> [NLLanguage]
    func isDuplicateFilter(language: NLLanguage) -> Bool
    func isDuplicateFilter(text: String,
                           filterTarget: FilterTarget,
                           filterMatching: FilterMatching,
                           filterCase: FilterCase) -> Bool
    
    @discardableResult
    func addFilter(text: String, type: FilterType,
                   denyFolder: MessageFolder,
                   filterTarget: FilterTarget,
                   filterMatching: FilterMatching,
                   filterCase: FilterCase) -> Filter?
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter])
    func deleteFilters(_ filters: Set<Filter>)
    func updateFilter(_ filter: Filter, denyFolder: MessageFolder)
    func updateFilter(_ filter: Filter, filterMatching: FilterMatching)
    func updateFilter(_ filter: Filter, filterCase: FilterCase)
    func updateFilter(_ filter: Filter, filterTarget: FilterTarget)
    func updateFilter(_ filter: Filter, filterText: String)
    func cachedFilterLists() -> FilterListsSnapshot?
    func cachedFilterListCatalog() -> FilterListCatalogResponse?
    func saveCache(_ cache: FilterListsSnapshot) -> Bool
    func touchCache()
    func selectedCountries(for rule: SmartFilterType) -> [String]
    func setSelectedCountries(_ countries: [String], for rule: SmartFilterType)

    #if DEBUG
    func clearAllUserData()
    func resetContainer()
    #endif // DEBUG
}


extension NSNotification.Name {
    static let filtersStateChanged: NSNotification.Name = NSNotification.Name("FiltersStateChanged")
    static let persistentStoreReloaded: NSNotification.Name = NSNotification.Name("PersistentStoreReloaded")
    static let filtersSaveFailed: NSNotification.Name = NSNotification.Name("FiltersSaveFailed")
}
