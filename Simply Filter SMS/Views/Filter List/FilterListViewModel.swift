//
//  FilterListViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation

class FilterListViewModel: ObservableObject {
    @Published var filters: [Filter] = []
    @Published var filterType: FilterType
    @Published var isAllUnknownFilteringOn: Bool
    @Published var canBlockAnotherLanguage: Bool
    @Published var footer: String
    
    private let persistanceManager: PersistanceManagerProtocol
    private let automaticFilterManager: AutomaticFilterManagerProtocol
    
    init(filterType: FilterType,
         persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         automaticFilterManager: AutomaticFilterManagerProtocol = AppManager.shared.automaticFiltersManager) {
        
        self.filterType = filterType
        self.persistanceManager = persistanceManager
        self.automaticFilterManager = automaticFilterManager
        
        self.isAllUnknownFilteringOn = automaticFilterManager.automaticRuleState(for: .allUnknown)
        self.canBlockAnotherLanguage = !automaticFilterManager.languages(for: .blockLanguage).isEmpty
        
        switch filterType {
        case .deny:
            self.footer = "help_deny"~
        case .allow:
            self.footer = "help_allow"~
        case .denyLanguage:
            self.footer = "lang_how"~
        }
    }

    func refresh() {
        let fetchedFilters = self.persistanceManager.fetchFilterRecords(for: self.filterType)

        self.filters = fetchedFilters.filter({ $0.filterType == self.filterType })
        self.isAllUnknownFilteringOn = self.automaticFilterManager.automaticRuleState(for: .allUnknown)
        self.canBlockAnotherLanguage = !self.automaticFilterManager.languages(for: .blockLanguage).isEmpty
    }
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        self.persistanceManager.deleteFilters(withOffsets: offsets, in: filters)
        self.refresh()
    }
    
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        self.persistanceManager.updateFilter(filter, denyFolder: denyFolder)
        self.refresh()
    }
    
    func deleteFilters(_ filters: Set<Filter>) {
        self.persistanceManager.deleteFilters(filters)
        self.refresh()
    }
}
