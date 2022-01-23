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
    
    private let persistanceManager: PersistanceManagerProtocol
    private let defaultsManager: DefaultsManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol,
         defaultsManager: DefaultsManagerProtocol) {
        
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.title = "filterList_filters"~
        self.isAppFirstRun = defaultsManager.isAppFirstRun
    }
    
    var isEmpty: Bool {
        var filterCount = 0
        FilterType.allCases.forEach({ filterCount += self.filters[$0]?.count ?? 0})
        return filterCount == 0
    }
    
    func fetchFilters() {
        let fetchedFilters = self.persistanceManager.getFilters()
        
        for filterType in FilterType.allCases {
            filters[filterType] = fetchedFilters.filter({ $0.filterType == filterType })
        }
    }
    
    func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        self.persistanceManager.deleteFilters(withOffsets: offsets, in: filters)
        self.fetchFilters()
    }
    
    func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        self.persistanceManager.updateFilter(filter, denyFolder: denyFolder)
        self.fetchFilters()
    }
    
    func deleteFilters(_ filters: Set<Filter>) {
        self.persistanceManager.deleteFilters(filters)
        self.fetchFilters()
    }
    
    func loadDebugData() {
        self.persistanceManager.loadDebugData()
        self.fetchFilters()
    }
}


enum FilterListSheetView: Int, Identifiable {
    var id: Self { self }
    
    case addFilter=0, enableExtension, about, addLanguageFilter
}
