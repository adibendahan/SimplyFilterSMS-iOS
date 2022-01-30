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
    @Published var isAllUnknownFilteringOn: Bool
    
    private let persistanceManager: PersistanceManagerProtocol
    private let defaultsManager: DefaultsManagerProtocol
    private let automaticFilterManager: AutomaticFilterManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         defaultsManager: DefaultsManagerProtocol = AppManager.shared.defaultsManager,
         automaticFilterManager: AutomaticFilterManagerProtocol = AppManager.shared.automaticFiltersManager) {
        
        let isAutomaticFilteringOn = automaticFilterManager.isAutomaticFilteringOn
        
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.automaticFilterManager = automaticFilterManager
        self.title = "filterList_filters"~
        self.isAppFirstRun = defaultsManager.isAppFirstRun
        self.isNavigationActive = false
        self.isAutomaticFilteringOn = isAutomaticFilteringOn
        self.isAllUnknownFilteringOn = automaticFilterManager.automaticRuleState(for: .allUnknown)
        
        if isAutomaticFilteringOn {
            self.activeLanguages = automaticFilterManager.activeAutomaticFiltersTitle
        }
    }
    
    var isEmpty: Bool {
        guard self.isAllUnknownFilteringOn == false else {
            return self.filters[.allow]?.count ?? 0 == 0
        }
        
        var filterCount = 0
        FilterType.allCases.forEach({ filterCount += self.filters[$0]?.count ?? 0})
        return filterCount == 0
    }
    
    func refresh() {
        let fetchedFilters = self.persistanceManager.fetchFilterRecords()
        
        for filterType in FilterType.allCases {
            filters[filterType] = fetchedFilters.filter({ $0.filterType == filterType })
        }
        
        self.isAppFirstRun = self.defaultsManager.isAppFirstRun
        let isAutomaticFilteringOn = self.automaticFilterManager.isAutomaticFilteringOn
        self.isAutomaticFilteringOn = isAutomaticFilteringOn
        self.activeLanguages = isAutomaticFilteringOn ? self.automaticFilterManager.activeAutomaticFiltersTitle : nil
        self.isAllUnknownFilteringOn = self.automaticFilterManager.automaticRuleState(for: .allUnknown)
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
