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
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType)
    func isDuplicateFilter(text: String, type: FilterType) -> Bool
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter])
    func deleteFilters(_ filters: Set<Filter>)
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType)
    func languages(for type: LanguageListViewType) -> [NLLanguage]
    func getFrequentlyAskedQuestions() -> [QuestionViewModel]
    func getFilters() -> [Filter]
    
    func preview() -> PersistanceManagerProtocol
    func loadDebugData()
}

