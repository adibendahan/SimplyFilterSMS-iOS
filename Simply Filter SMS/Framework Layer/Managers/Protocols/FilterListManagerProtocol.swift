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
    var isCheckingFilterLists: Bool { get }
    
    func isFilterListActive(for language: NLLanguage) -> Bool
    func setFilterListActive(for language: NLLanguage, value: Bool)
    @MainActor func refreshFilterLists() async
    @MainActor func updateFilterListsWhenOnline()
}
