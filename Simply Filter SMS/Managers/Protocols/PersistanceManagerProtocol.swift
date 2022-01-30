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
    var context: NSManagedObjectContext { get }
    var isAutomaticFilteringOn: Bool { get }
    var automaticFiltersCacheAge: Date? { get }
    var activeAutomaticLanguages: String? { get }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType)
    func isDuplicateFilter(text: String, type: FilterType) -> Bool
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter])
    func deleteFilters(_ filters: Set<Filter>)
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType)
    func languages(for type: LanguageListView.Mode) -> [NLLanguage]
    func getFrequentlyAskedQuestions() -> [QuestionViewModel]
    func getFilters() -> [Filter]
    
    func initAutomaticFiltering()
    func languageAutomaticState(for language: NLLanguage) -> Bool
    func setLanguageAtumaticState(for language: NLLanguage, value: Bool)
    func cacheAutomaticFilterList(_ filterList: AutomaticFilterList)
    func isCacheStale(comparedTo newFilterList: AutomaticFilterList) -> Bool
    func automaticRuleState(for rule: RuleType) -> Bool
    func setAutomaticRuleState(for rule: RuleType, value: Bool)
    func selectedChoice(for rule: RuleType) -> Int
    func setSelectedChoice(for rule: RuleType, choice: Int)
    
    // DEBUG:
    var preview: PersistanceManagerProtocol { get }
    func loadDebugData()
}

