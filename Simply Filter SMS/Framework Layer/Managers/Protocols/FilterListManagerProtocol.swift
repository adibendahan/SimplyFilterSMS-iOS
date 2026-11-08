//
//  FilterListManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/01/2022.
//

import Foundation
import NaturalLanguage

protocol FilterListManagerProtocol {
    var hasActiveFilterLists: Bool { get }
    var activeFilterListsTitle: String? { get }
    var filterListsLastUpdated: Date? { get }
    var filterListLanguages: [NLLanguage] { get }
    
    func isFilterListActive(for language: NLLanguage) -> Bool
    func setFilterListActive(for language: NLLanguage, value: Bool)
    @MainActor func refreshFilterLists() async
    @MainActor func updateFilterListsWhenOnline()
    func onFilterListsUpdateFinished(_ handler: @escaping () -> Void)
}


extension NSNotification.Name {
    static let filterListsUpdated: NSNotification.Name = NSNotification.Name("FilterListsUpdated")
}
