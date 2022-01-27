//
//  FilterListViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation

class FilterListViewModel: ObservableObject {
    @Published var filters: Dictionary<FilterType, [Filter]> = [:]
    @Published var title: String
    @Published var isAppFirstRun: Bool
    @Published var isAutomaticFilteringOn: Bool
    @Published var isNavigationActive: Bool
    @Published var activeLanguages: String?
    
    private let persistanceManager: PersistanceManagerProtocol
    private let defaultsManager: DefaultsManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         defaultsManager: DefaultsManagerProtocol = AppManager.shared.defaultsManager) {
        
        let isAutomaticFilteringOn = persistanceManager.isAutomaticFilteringOn
        
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.title = "filterList_filters"~
        self.isAppFirstRun = defaultsManager.isAppFirstRun
        self.isNavigationActive = false
        self.isAutomaticFilteringOn = isAutomaticFilteringOn
        
        if isAutomaticFilteringOn {
            self.activeLanguages = persistanceManager.activeAutomaticLanguages
        }
    }
    
    var isEmpty: Bool {
        var filterCount = 0
        FilterType.allCases.forEach({ filterCount += self.filters[$0]?.count ?? 0})
        return filterCount == 0
    }
    
    func refresh() {
        let fetchedFilters = self.persistanceManager.getFilters()
        
        for filterType in FilterType.allCases {
            filters[filterType] = fetchedFilters.filter({ $0.filterType == filterType })
        }
        
        self.isAppFirstRun = defaultsManager.isAppFirstRun
        let isAutomaticFilteringOn = persistanceManager.isAutomaticFilteringOn
        self.isAutomaticFilteringOn = isAutomaticFilteringOn
        self.activeLanguages = isAutomaticFilteringOn ? persistanceManager.activeAutomaticLanguages : nil
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
    
    func loadDebugData() {
        self.persistanceManager.loadDebugData()
        self.refresh()
    }
}
